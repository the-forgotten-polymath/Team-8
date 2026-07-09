//
//  DashboardViewModel.swift
//  RSMS_Project
//
//  Created by Yatharth Mishra on 30/06/26.
//

import Foundation
import Combine

@MainActor
final class DashboardViewModel: ObservableObject {
    
    @Published var warehouseStockCount = 0
    @Published var pendingShipmentsCount = 0
    @Published var pendingStockRequestsCount = 0
    @Published var pendingTransfersCount = 0
    @Published var lowStockAlertsCount = 0
    @Published var scheduledCycleCountsCount = 0
    @Published var pendingCycleCountsCount = 0
    
    @Published var recentShipments: [Shipment] = []
    @Published var recentTransfers: [Transfer] = []
    @Published var recentStockRequests: [StockRequest] = []
    
    @Published var isLoading = false
    @Published var errorMessage: String? = nil
    
    private let service = WarehouseService.shared
    
    func loadDashboardData(warehouseId: UUID) async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Fetch Inventory Stock
            let inventory = try await service.fetchWarehouseInventory(warehouseId: warehouseId)
            self.warehouseStockCount = inventory.reduce(0) { $0 + $1.quantity }
            self.lowStockAlertsCount = inventory.filter { $0.quantity <= $0.reorderLevel }.count
            
            // Fetch Shipments
            let shipments = try await service.fetchShipments()
            self.pendingShipmentsCount = shipments.filter { $0.status.lowercased() == "pending" }.count
            self.recentShipments = Array(shipments.sorted(by: { 
                let d0 = $0.receivedDate ?? $0.dispatchDate ?? $0.createdAt
                let d1 = $1.receivedDate ?? $1.dispatchDate ?? $1.createdAt
                return d0 > d1
            }).prefix(3))
            
            // Fetch Requests
            let requests = try await service.fetchStockRequests()
            self.pendingStockRequestsCount = requests.filter { $0.status.lowercased() == "pending" }.count
            self.recentStockRequests = Array(requests.sorted(by: { $0.updatedAt > $1.updatedAt }).prefix(3))
            
            // Fetch Transfers
            let transfers = try await service.fetchTransfers()
            self.pendingTransfersCount = transfers.filter { $0.status.lowercased() == "pending" }.count
            self.recentTransfers = Array(transfers.sorted(by: { $0.transferDate > $1.transferDate }).prefix(3))
            
            // Fetch Cycle Counts
            let cycleCounts = try await service.fetchCycleCounts()
            self.scheduledCycleCountsCount = cycleCounts.filter { $0.status.lowercased() == "scheduled" }.count
            self.pendingCycleCountsCount = cycleCounts.filter {
                $0.status.lowercased() == "scheduled" &&
                Calendar.current.isDateInToday($0.scheduledDate)
            }.count
            
        } catch {
            self.errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
}
