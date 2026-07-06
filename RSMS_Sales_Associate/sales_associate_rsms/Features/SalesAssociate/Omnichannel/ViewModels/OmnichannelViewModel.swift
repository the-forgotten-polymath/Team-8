// OmnichannelViewModel.swift
// RSMS — Sales Associate Module

import SwiftUI
import Combine

@MainActor
class OmnichannelViewModel: ObservableObject {
    @Published var bopisOrders: [FulfillmentOrder] = []
    @Published var sfsOrders: [FulfillmentOrder] = []
    @Published var inventoryResults: [InventoryLevel] = []
    
    @Published var isLoadingBOPIS = false
    @Published var isLoadingSFS = false
    @Published var isSearchingInventory = false
    
    func fetchBOPISOrders() async {
        isLoadingBOPIS = true
        do {
            bopisOrders = try await OmnichannelService.shared.fetchBOPISOrders()
        } catch {
            print("Failed to fetch BOPIS: \(error)")
        }
        isLoadingBOPIS = false
    }
    
    func fetchSFSOrders() async {
        isLoadingSFS = true
        do {
            sfsOrders = try await OmnichannelService.shared.fetchSFSOrders()
        } catch {
            print("Failed to fetch SFS: \(error)")
        }
        isLoadingSFS = false
    }
    
    func completeBOPISPickup(orderID: UUID, signature: Data) async {
        do {
            try await OmnichannelService.shared.completeBOPISPickup(orderID: orderID, signature: signature)
            await fetchBOPISOrders() // refresh
        } catch {
            print("Failed to complete pickup: \(error)")
        }
    }
    
    func shipSFSOrder(orderID: UUID, trackingNumber: String) async {
        do {
            try await OmnichannelService.shared.generatePackingSlipAndShip(orderID: orderID, trackingNumber: trackingNumber)
            await fetchSFSOrders() // refresh
        } catch {
            print("Failed to ship order: \(error)")
        }
    }
    
    func searchInventory(for productID: UUID) async {
        isSearchingInventory = true
        do {
            inventoryResults = try await OmnichannelService.shared.searchInventory(productID: productID)
        } catch {
            print("Failed to search inventory: \(error)")
        }
        isSearchingInventory = false
    }
    
    func placeEndlessAisleOrder(productID: UUID, toStore: UUID) async {
        do {
            try await OmnichannelService.shared.placeEndlessAisleOrder(productID: productID, toStore: toStore)
            // Show success
        } catch {
            print("Failed to place endless aisle order: \(error)")
        }
    }
}
