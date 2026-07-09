// OmnichannelViewModel.swift
// RSMS — Sales Associate Module

import SwiftUI
import Combine

@MainActor
class OmnichannelViewModel: ObservableObject {
    @Published var bopisOrders: [FulfillmentOrder] = []
    var storeId: UUID? = nil
    @Published var isLoadingBOPIS = false

    func fetchBOPISOrders() async {
        isLoadingBOPIS = true
        do {
            bopisOrders = try await OmnichannelService.shared.fetchBOPISOrders()
        } catch {
            print("Failed to fetch BOPIS: \(error)")
        }
        isLoadingBOPIS = false
    }

    func completeBOPISPickup(orderID: UUID, signature: Data) async {
        do {
            try await OmnichannelService.shared.completeBOPISPickup(orderID: orderID, signature: signature)
            await fetchBOPISOrders()
        } catch {
            print("Failed to complete pickup: \(error)")
        }
    }
}
