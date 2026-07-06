// OmnichannelService.swift
// RSMS — Sales Associate Module

import Foundation
import Supabase

@MainActor
class OmnichannelService {
    static let shared = OmnichannelService()
    
    private let client = SupabaseManager.shared.client
    
    private init() {}
    
    // MARK: - Fetch Orders
    func fetchBOPISOrders() async throws -> [FulfillmentOrder] {
        if AppConstants.useMockData {
            try await Task.sleep(nanoseconds: 500_000_000)
            return MockData.fulfillmentOrders.filter { $0.type == .bopis }
        }
        
        let shipments: [Shipment] = (try? await client
            .from("shipments")
            .select()
            .eq("shipment_type", value: "BOPIS")
            .execute()
            .value) ?? []
            
        return shipments.map { mapShipmentToOrder($0, type: .bopis) }
    }
    
    func fetchSFSOrders() async throws -> [FulfillmentOrder] {
        if AppConstants.useMockData {
            try await Task.sleep(nanoseconds: 500_000_000)
            return MockData.fulfillmentOrders.filter { $0.type == .sfs }
        }
        
        let shipments: [Shipment] = (try? await client
            .from("shipments")
            .select()
            .eq("shipment_type", value: "SFS")
            .execute()
            .value) ?? []
            
        return shipments.map { mapShipmentToOrder($0, type: .sfs) }
    }
    
    // MARK: - Actions
    func completeBOPISPickup(orderID: UUID, signature: Data) async throws {
        if AppConstants.useMockData {
            try await Task.sleep(nanoseconds: 800_000_000)
            if let index = MockData.fulfillmentOrders.firstIndex(where: { $0.id == orderID }) {
                MockData.fulfillmentOrders[index].status = .pickedUp
                MockData.fulfillmentOrders[index].signatureData = signature
                MockData.fulfillmentOrders[index].pickupDate = Date()
            }
            return
        }
        
        // Update shipment status in DB
        try await client
            .from("shipments")
            .update(["status": "Picked Up"])
            .eq("id", value: orderID.uuidString)
            .execute()
    }
    
    func generatePackingSlipAndShip(orderID: UUID, trackingNumber: String) async throws {
        if AppConstants.useMockData {
            try await Task.sleep(nanoseconds: 1_000_000_000)
            if let index = MockData.fulfillmentOrders.firstIndex(where: { $0.id == orderID }) {
                MockData.fulfillmentOrders[index].status = .shipping
                MockData.fulfillmentOrders[index].trackingNumber = trackingNumber
                MockData.fulfillmentOrders[index].carrier = "FedEx"
            }
            return
        }
        
        // Update shipment status in DB
        try await client
            .from("shipments")
            .update([
                "status": "Shipping",
                "tracking_reference": trackingNumber
            ])
            .eq("id", value: orderID.uuidString)
            .execute()
    }
    
    // MARK: - Inventory
    func searchInventory(productID: UUID) async throws -> [InventoryLevel] {
        if AppConstants.useMockData {
            try await Task.sleep(nanoseconds: 500_000_000)
            return MockData.inventoryLevels.filter { $0.productID == productID }
        }
        
        // Use real DB inventory
        let levels = try await SalesAssociateService.shared.fetchInventoryForProduct(productId: productID)
        return levels.map { level in
            InventoryLevel(
                id: UUID(),
                productID: productID,
                storeID: UUID(), // Not mapped back properly in the service, using generic
                quantityAvailable: level.quantity,
                quantityReserved: 0,
                storeName: level.storeName
            )
        }
    }
    
    func placeEndlessAisleOrder(productID: UUID, toStore: UUID) async throws {
        if AppConstants.useMockData {
            try await Task.sleep(nanoseconds: 1_500_000_000)
            return
        }
        
        // Create a mock stock_request in DB
        let requestPayload: [String: AnyJSON] = [
            "store_id": .string(toStore.uuidString),
            "product_id": .string(productID.uuidString),
            "requested_quantity": .integer(1),
            "status": "Pending"
        ]
        
        _ = try await client
            .from("stock_requests")
            .insert(requestPayload)
            .execute()
    }
    
    // MARK: - Helpers
    private func mapShipmentToOrder(_ shipment: Shipment, type: FulfillmentType) -> FulfillmentOrder {
        let orderStatus: FulfillmentStatus
        switch shipment.status.lowercased() {
        case "pending": orderStatus = .pending
        case "processing": orderStatus = .processing
        case "ready for pickup": orderStatus = .readyForPickup
        case "picked up": orderStatus = .pickedUp
        case "shipping": orderStatus = .shipping
        case "completed": orderStatus = .completed
        case "cancelled": orderStatus = .cancelled
        default: orderStatus = .pending
        }
        
        return FulfillmentOrder(
            id: shipment.id,
            orderNumber: shipment.shipmentNumber,
            clientID: UUID(), // Fallback: no customer ID in shipment
            storeID: UUID(), // Fallback
            type: type,
            status: orderStatus,
            orderDate: shipment.createdAt,
            items: [], // Expand with shipment_items if necessary
            carrier: nil, // Add to schema if carrier is needed
            trackingNumber: shipment.trackingReference,
            signatureData: nil,
            pickupDate: shipment.receivedDate
        )
    }
}
