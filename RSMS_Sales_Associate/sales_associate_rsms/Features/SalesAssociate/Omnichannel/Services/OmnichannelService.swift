// OmnichannelService.swift
// RSMS — Sales Associate Module

import Foundation

class OmnichannelService {
    static let shared = OmnichannelService()
    
    private init() {}
    
    // MARK: - Fetch Orders
    func fetchBOPISOrders() async throws -> [FulfillmentOrder] {
        // Mock delay
        try await Task.sleep(nanoseconds: 500_000_000)
        return MockData.fulfillmentOrders.filter { $0.type == .bopis }
    }
    
    func fetchSFSOrders() async throws -> [FulfillmentOrder] {
        // Mock delay
        try await Task.sleep(nanoseconds: 500_000_000)
        return MockData.fulfillmentOrders.filter { $0.type == .sfs }
    }
    
    // MARK: - Actions
    func completeBOPISPickup(orderID: UUID, signature: Data) async throws {
        try await Task.sleep(nanoseconds: 800_000_000)
        if let index = MockData.fulfillmentOrders.firstIndex(where: { $0.id == orderID }) {
            MockData.fulfillmentOrders[index].status = .pickedUp
            MockData.fulfillmentOrders[index].signatureData = signature
            MockData.fulfillmentOrders[index].pickupDate = Date()
        }
    }
    
    func generatePackingSlipAndShip(orderID: UUID, trackingNumber: String) async throws {
        try await Task.sleep(nanoseconds: 1_000_000_000)
        if let index = MockData.fulfillmentOrders.firstIndex(where: { $0.id == orderID }) {
            MockData.fulfillmentOrders[index].status = .shipping
            MockData.fulfillmentOrders[index].trackingNumber = trackingNumber
            MockData.fulfillmentOrders[index].carrier = "FedEx"
        }
    }
    
    // MARK: - Inventory
    func searchInventory(productID: UUID) async throws -> [InventoryLevel] {
        try await Task.sleep(nanoseconds: 500_000_000)
        return MockData.inventoryLevels.filter { $0.productID == productID }
    }
    
    func placeEndlessAisleOrder(productID: UUID, toStore: UUID) async throws {
        // Mocking an OMS order placement
        try await Task.sleep(nanoseconds: 1_500_000_000)
    }
}
