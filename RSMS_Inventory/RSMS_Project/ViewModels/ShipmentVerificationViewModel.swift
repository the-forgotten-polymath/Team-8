//
//  ShipmentVerificationViewModel.swift
//  RSMS_Project
//
//  Created by Yatharth Mishra on 30/06/26.
//

import Foundation
import Combine

enum QRScanResult {
    case success(productName: String, expected: Int, received: Int)
    case wrongProduct
    case unrecognized
}

@MainActor
final class ShipmentVerificationViewModel: ObservableObject {
    
    @Published var shipments: [Shipment] = []
    @Published var shipmentItems: [ShipmentItem] = []
    @Published var products: [Product] = []
    
    // Scanned quantities: [ProductId: ReceivedQuantity]
    @Published var scannedQuantities: [UUID: Int] = [:]
    @Published var scannedSerials: [String] = []
    
    @Published var isLoading = false
    @Published var errorMessage: String? = nil
    @Published var isVerifiedSuccess = false
    
    private let warehouseService = WarehouseService.shared
    private let productService = ProductService()
    
    func loadShipments() async {
        isLoading = true
        errorMessage = nil
        do {
            let fetchedShipments = try await warehouseService.fetchShipments()
            self.shipments = fetchedShipments.sorted(by: { $0.createdAt > $1.createdAt })
            self.products = try await productService.fetchProducts()
        } catch {
            self.errorMessage = error.localizedDescription
        }
        isLoading = false
    }
    
    func loadShipmentItems(shipmentId: UUID) async {
        isLoading = true
        errorMessage = nil
        scannedQuantities = [:]
        isVerifiedSuccess = false
        do {
            self.products = try await productService.fetchProducts()
            self.shipmentItems = try await warehouseService.fetchShipmentItems(shipmentId: shipmentId)
            // Initialize scanned quantities with 0
            for item in shipmentItems {
                scannedQuantities[item.productId] = 0
            }
        } catch {
            self.errorMessage = error.localizedDescription
        }
        isLoading = false
    }
    
    // Processes a QR scan value
    func scanQRCode(value: String) -> QRScanResult {
        // Normalize scanned value: trim spaces/newlines, convert spaces to hyphens, and uppercase
        let normalizedScanned = value.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: " ", with: "-")
            .uppercased()
            
        // 1. Find Product where normalized qrValue matches or SKU matches
        guard let product = products.first(where: { product in
            let normalizedSKU = product.sku
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .replacingOccurrences(of: " ", with: "-")
                .uppercased()

            // qrValue is optional — only attempt QR-based matching if one is assigned
            if let qr = product.qrValue {
                let normalizedQR = qr
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                    .replacingOccurrences(of: " ", with: "-")
                    .uppercased()

                // Direct match
                if normalizedQR == normalizedScanned || normalizedSKU == normalizedScanned {
                    return true
                }

                // Check if product's QR URL contains the scanned code
                if normalizedQR.contains(normalizedScanned) && !normalizedScanned.isEmpty && normalizedScanned.count >= 4 {
                    return true
                }

                // Check if scanned URL/code contains the product QR or SKU
                if normalizedScanned.contains(normalizedQR) || normalizedScanned.contains(normalizedSKU) {
                    return true
                }
            } else {
                // No QR code — match on SKU only
                if normalizedSKU == normalizedScanned || normalizedScanned.contains(normalizedSKU) {
                    return true
                }
            }

            // Check if scanned value is a URL and the last path component matches the SKU
            if let scannedURL = URL(string: value),
               let lastComponent = scannedURL.pathComponents.last?.uppercased(),
               lastComponent == normalizedSKU {
                return true
            }

            return false
        }) else {
            return .unrecognized
        }
        
        // 2. Check whether this Product exists in the currently opened Shipment
        guard let item = shipmentItems.first(where: { $0.productId == product.id }) else {
            return .wrongProduct
        }
        
        // 3. Increase ShipmentItem.received_quantity by 1
        let currentQty = scannedQuantities[product.id] ?? 0
        let newQty = currentQty + 1
        scannedQuantities[product.id] = newQty
        
        let normVal = value.trimmingCharacters(in: .whitespacesAndNewlines)
        if !scannedSerials.contains(normVal) {
            scannedSerials.append(normVal)
        }
        
        return .success(productName: product.productName, expected: item.expectedQuantity, received: newQty)
    }
    
    // Verification Status Helpers
    func expectedQuantity(for productId: UUID) -> Int {
        shipmentItems.first(where: { $0.productId == productId })?.expectedQuantity ?? 0
    }
    
    func statusColor(for productId: UUID) -> String {
        let expected = expectedQuantity(for: productId)
        let scanned = scannedQuantities[productId] ?? 0
        
        if scanned == expected {
            return "Matched"
        } else if scanned > expected {
            return "Extra Item"
        } else if scanned == 0 {
            return "Missing"
        } else {
            return "Under"
        }
    }
    
    var isAllMatched: Bool {
        guard !shipmentItems.isEmpty else { return false }
        return shipmentItems.allSatisfy { item in
            (scannedQuantities[item.productId] ?? 0) == item.expectedQuantity
        }
    }
    
    func submitVerification(shipment: Shipment, warehouseId: UUID, userId: UUID) async {
        isLoading = true
        errorMessage = nil
        
        do {
            // 1. Update Shipment status
            try await warehouseService.updateShipmentStatus(shipmentId: shipment.id, status: "verified")
            
            // 1b. Update linked Stock Request if exists
            if let reqId = shipment.stockRequestId {
                try await warehouseService.updateStockRequestStatus(requestId: reqId, status: "delivered")
            }
            
            // 2. Update Shipment Items
            for item in shipmentItems {
                let scannedQty = scannedQuantities[item.productId] ?? 0
                let status = scannedQty == item.expectedQuantity ? "verified" : "discrepancy"
                try await warehouseService.verifyShipmentItem(itemId: item.id, receivedQty: scannedQty, status: status)
                
                // 3. Update Warehouse Inventory Stock
                let inventory = try await warehouseService.fetchWarehouseInventory(warehouseId: warehouseId)
                if let invItem = inventory.first(where: { $0.productId == item.productId }) {
                    let newQty = invItem.quantity + scannedQty
                    try await warehouseService.updateInventoryQuantity(itemId: invItem.id, newQuantity: newQty)
                }
                
                // 4. Log Exception if discrepancy
                if scannedQty != item.expectedQuantity {
                    let exceptionType = scannedQty < item.expectedQuantity ? "Missing Item" : "Extra Item"
                    let diff = abs(item.expectedQuantity - scannedQty)
                    try await warehouseService.createException(
                        shipmentId: shipment.id,
                        storeId: warehouseId, // Using warehouseId as location
                        productId: item.productId,
                        exceptionType: exceptionType,
                        priority: "high",
                        remarks: "Discrepancy of \(diff) units during shipment verification.",
                        reportedBy: userId
                    )
                }
            }
            
            // 5. Add Audit Log
            try await warehouseService.logAction(
                userId: userId,
                module: "Shipment Verification",
                action: "Verified shipment \(shipment.asnNumber ?? shipment.id.uuidString) with status: \(isAllMatched ? "Fully Verified" : "Discrepancy Logged")"
            )
            
            isVerifiedSuccess = true
            
        } catch {
            self.errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
}
