//
//  StockRequestViewModel.swift
//  RSMS_Project
//
//  Created by Yatharth Mishra on 30/06/26.
//

import Foundation
import Combine

@MainActor
final class StockRequestViewModel: ObservableObject {
    
    @Published var stockRequests: [StockRequest] = []
    @Published var groupedStockRequests: [GroupedStockRequest] = []
    @Published var products: [Product] = []
    @Published var stores: [Store] = []
    @Published var warehouseInventory: [InventoryItem] = []
    @Published var surplusStoresList: [SurplusStoreRecommendation] = []
    
    @Published var isLoading = false
    @Published var errorMessage: String? = nil
    
    private let warehouseService = WarehouseService.shared
    private let productService = ProductService()
    private let userService = UserService()
    
    struct SurplusStoreRecommendation: Identifiable {
        let id = UUID()
        let store: Store
        let quantity: Int
        let surplusAmount: Int
    }
    
    func loadData(warehouseId: UUID) async {
        isLoading = true
        errorMessage = nil
        do {
            let rawRequests = try await warehouseService.fetchStockRequests()
            self.stockRequests = rawRequests
            self.products = try await productService.fetchProducts()
            self.warehouseInventory = try await warehouseService.fetchWarehouseInventory(warehouseId: warehouseId)
            
            // Fetch all users/stores to map store names
            let allUsers = try await userService.fetchUsers()
            // We can fetch stores using DatabaseService.shared.fetch
            self.stores = try await DatabaseService.shared.fetch(from: "stores", as: Store.self)
            
            // Group raw requests by order_id, fallback to raw request id
            let groupedDict = Dictionary(grouping: rawRequests) { $0.orderId ?? $0.id.uuidString }
            self.groupedStockRequests = groupedDict.map { (orderId, items) in
                let firstItem = items.first!
                
                // Determine order status:
                // - if all items are fulfilled or delivered, order is delivered
                // - if any item is pending, order is pending
                // - if any item is approved, preparing shipment, or in transit, order is active/approved
                let orderStatus: String
                if items.allSatisfy({
                    let status = $0.status.lowercased()
                    return status == "fulfilled" || status == "completed" || status == "delivered"
                }) {
                    orderStatus = "delivered"
                } else if items.contains(where: { $0.status.lowercased() == "pending" }) {
                    orderStatus = "pending"
                } else if items.contains(where: {
                    let status = $0.status.lowercased()
                    return status == "approved" || status == "preparing shipment" || status == "in transit"
                }) {
                    if let activeItem = items.first(where: {
                        let status = $0.status.lowercased()
                        return status == "approved" || status == "preparing shipment" || status == "in transit"
                    }) {
                        orderStatus = activeItem.status
                    } else {
                        orderStatus = "approved"
                    }
                } else {
                    orderStatus = firstItem.status
                }
                
                // Determine order priority: if any item is high, show High
                let orderPriority = items.contains(where: { $0.priority.lowercased() == "high" }) ? "High" : firstItem.priority

                return GroupedStockRequest(
                    orderId: orderId,
                    storeId: firstItem.storeId,
                    requestedBy: firstItem.requestedBy,
                    priority: orderPriority,
                    status: orderStatus,
                    remarks: firstItem.remarks,
                    createdAt: firstItem.createdAt,
                    items: items.sorted(by: { $0.createdAt < $1.createdAt })
                )
            }.sorted(by: { $0.createdAt > $1.createdAt })
            
        } catch {
            guard !Swift.Task.isCancelled else { return }
            self.errorMessage = error.localizedDescription
        }
        isLoading = false
    }
    
    func getProduct(for productId: UUID) -> Product? {
        products.first { $0.id == productId }
    }
    
    func getStore(for storeId: UUID) -> Store? {
        stores.first { $0.id == storeId }
    }
    
    func getWarehouseStock(for productId: UUID) -> Int {
        warehouseInventory.first { $0.productId == productId }?.quantity ?? 0
    }
    
    func searchSurplusStores(for productId: UUID) async {
        isLoading = true
        surplusStoresList = []
        do {
            // Fetch all inventory items for this product across stores
            let allInventory: [InventoryItem] = try await DatabaseService.shared.fetch(from: "inventory", as: InventoryItem.self)
            let storeInventories = allInventory.filter { $0.productId == productId && $0.storeId != nil }
            
            var recommendations: [SurplusStoreRecommendation] = []
            for inv in storeInventories {
                guard let storeId = inv.storeId, let store = getStore(for: storeId) else { continue }
                let surplus = max(0, inv.quantity - inv.reorderLevel)
                if inv.quantity > 0 {
                    recommendations.append(SurplusStoreRecommendation(store: store, quantity: inv.quantity, surplusAmount: surplus))
                }
            }
            
            // Sort by surplus quantity desc
            self.surplusStoresList = recommendations.sorted(by: { $0.surplusAmount > $1.surplusAmount })
        } catch {
            self.errorMessage = error.localizedDescription
        }
        isLoading = false
    }
    
    func fulfillRequest(request: StockRequest, warehouseId: UUID, userId: UUID) async {
        isLoading = true
        errorMessage = nil
        do {
            // 1. Check if warehouse has enough stock
            let currentStock = getWarehouseStock(for: request.productId)
            guard currentStock >= request.requestedQuantity else {
                errorMessage = "Insufficient warehouse stock to fulfill request."
                isLoading = false
                return
            }
            
            // 2. Deduct inventory quantity from Warehouse
            if let invItem = warehouseInventory.first(where: { $0.productId == request.productId }) {
                let newQty = invItem.quantity - request.requestedQuantity
                try await warehouseService.updateInventoryQuantity(itemId: invItem.id, newQuantity: newQty)
            }
            
            // 3. Update Request Status to "approved"
            try await warehouseService.updateStockRequestStatus(requestId: request.id, status: "approved")
            
            // 4. Create Shipment
            struct NewShipment: Encodable {
                let id: UUID
                let shipmentType: String
                let source: String
                let destination: String
                let stockRequestId: UUID?
                let status: String
                let createdAt: Date
                enum CodingKeys: String, CodingKey {
                    case id
                    case shipmentType = "shipment_type"
                    case source
                    case destination
                    case stockRequestId = "stock_request_id"
                    case status
                    case createdAt = "created_at"
                }
            }
            let shipmentId = UUID()
            let shipment = NewShipment(
                id: shipmentId,
                shipmentType: "outbound",
                source: "Central Warehouse",
                destination: getStore(for: request.storeId)?.storeName ?? "Store",
                stockRequestId: request.id,
                status: "dispatched",
                createdAt: Date()
            )
            try await DatabaseService.shared.insert(into: "shipments", value: shipment)
            
            // 5. Create Shipment Item
            struct NewShipmentItem: Encodable {
                let id: UUID
                let shipmentId: UUID
                let productId: UUID
                let expectedQuantity: Int
                let receivedQuantity: Int
                let status: String
                enum CodingKeys: String, CodingKey {
                    case id
                    case shipmentId = "shipment_id"
                    case productId = "product_id"
                    case expectedQuantity = "expected_quantity"
                    case receivedQuantity = "received_quantity"
                    case status
                }
            }
            let shipmentItem = NewShipmentItem(
                id: UUID(),
                shipmentId: shipmentId,
                productId: request.productId,
                expectedQuantity: request.requestedQuantity,
                receivedQuantity: 0,
                status: "pending"
            )
            try await DatabaseService.shared.insert(into: "shipment_items", value: shipmentItem)
            
            // 6. Log audit action
            try await warehouseService.logAction(
                userId: userId,
                module: "Stock Requests",
                action: "Fulfilled stock request \(request.id.uuidString) for Store: \(getStore(for: request.storeId)?.storeName ?? "Unknown")"
            )
            
            // Reload
            await loadData(warehouseId: warehouseId)
        } catch {
            self.errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func fulfillGroupedRequest(groupedRequest: GroupedStockRequest, warehouseId: UUID, userId: UUID) async {
        isLoading = true
        errorMessage = nil
        do {
            // 1. Verify warehouse stock availability for all pending items in the group first
            for item in groupedRequest.items {
                if item.status.lowercased() == "pending" {
                    let currentStock = getWarehouseStock(for: item.productId)
                    guard currentStock >= item.requestedQuantity else {
                        errorMessage = "Insufficient warehouse stock to fulfill some items in this order."
                        isLoading = false
                        return
                    }
                }
            }

            // 2. Perform atomic fulfillment for all pending items
            struct NewShipment: Encodable {
                let id: UUID
                let shipmentType: String
                let source: String
                let destination: String
                let stockRequestId: UUID?
                let status: String
                let createdAt: Date
                enum CodingKeys: String, CodingKey {
                    case id
                    case shipmentType = "shipment_type"
                    case source
                    case destination
                    case stockRequestId = "stock_request_id"
                    case status
                    case createdAt = "created_at"
                }
            }

            struct NewShipmentItem: Encodable {
                let id: UUID
                let shipmentId: UUID
                let productId: UUID
                let expectedQuantity: Int
                let receivedQuantity: Int
                let status: String
                enum CodingKeys: String, CodingKey {
                    case id
                    case shipmentId = "shipment_id"
                    case productId = "product_id"
                    case expectedQuantity = "expected_quantity"
                    case receivedQuantity = "received_quantity"
                    case status
                }
            }

            for item in groupedRequest.items {
                if item.status.lowercased() == "pending" {
                    // Deduct inventory quantity from Warehouse
                    if let invItem = warehouseInventory.first(where: { $0.productId == item.productId }) {
                        let newQty = invItem.quantity - item.requestedQuantity
                        try await warehouseService.updateInventoryQuantity(itemId: invItem.id, newQuantity: newQty)
                    }

                    // Update Request Status to "approved"
                    try await warehouseService.updateStockRequestStatus(requestId: item.id, status: "approved")

                    // Create Shipment
                    let shipmentId = UUID()
                    let destinationName = getStore(for: item.storeId)?.storeName ?? "Store"
                    let shipment = NewShipment(
                        id: shipmentId,
                        shipmentType: "outbound",
                        source: "Central Warehouse",
                        destination: destinationName,
                        stockRequestId: item.id,
                        status: "dispatched",
                        createdAt: Date()
                    )
                    try await DatabaseService.shared.insert(into: "shipments", value: shipment)

                    // Create Shipment Item
                    let shipmentItem = NewShipmentItem(
                        id: UUID(),
                        shipmentId: shipmentId,
                        productId: item.productId,
                        expectedQuantity: item.requestedQuantity,
                        receivedQuantity: 0,
                        status: "pending"
                    )
                    try await DatabaseService.shared.insert(into: "shipment_items", value: shipmentItem)

                    // Log audit action
                    try await warehouseService.logAction(
                        userId: userId,
                        module: "Stock Requests",
                        action: "Fulfilled stock request \(item.id.uuidString) for Store: \(destinationName)"
                    )
                }
            }

            // Reload grouped request list
            await loadData(warehouseId: warehouseId)
        } catch {
            guard !Swift.Task.isCancelled else { return }
            self.errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
