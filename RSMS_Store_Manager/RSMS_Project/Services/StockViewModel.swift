//
//  StockViewModel.swift
//  RSMS_Project
//
//  Created by Antigravity on 02/07/26.
//

import Foundation
import SwiftUI
import Combine

final class StockViewModel: ObservableObject {
    @Published var summary: InventorySummary? = nil
    @Published var stockList: [StockListItem] = []
    @Published var isLoading = true
    @Published var errorMessage: String? = nil
    
    private let repository: StockRepositoryProtocol
    private var cancellables = Set<AnyCancellable>()
    
    init(repository: StockRepositoryProtocol = StockRepository()) {
        self.repository = repository
        
        NotificationCenter.default.publisher(for: NSNotification.Name("InventoryDidUpdate"))
            .sink { [weak self] _ in
                debugLog("[DEBUG] StockViewModel: Received InventoryDidUpdate notification, reloading stock data.")
                Swift.Task { @MainActor [weak self] in
                    await self?.loadData()
                }
            }
            .store(in: &cancellables)
    }
    
    @MainActor
    func loadData() async {
        if summary == nil {
            isLoading = true
        }
        errorMessage = nil
        
        debugLog("[DEBUG] StockViewModel.loadData: Entering loadData")
        
        // Ensure session is resolved if it's nil
        if SessionManager.shared.currentUser == nil {
            debugLog("[DEBUG] StockViewModel.loadData: currentUser is nil. Resolving session...")
            await SessionManager.shared.resolveSession()
        }
        
        guard let currentUser = SessionManager.shared.currentUser else {
            debugLog("[DEBUG] StockViewModel.loadData: FAILED to resolve currentUser. Showing empty state.")
            if self.summary == nil {
                self.summary = InventorySummary(totalValue: 0, totalProducts: 0, totalUnits: 0, pendingRequestsCount: 0, lowStockCount: 0, outOfStockCount: 0)
                self.stockList = []
            }
            self.isLoading = false
            return
        }
        
        guard let storeId = currentUser.storeId else {
            debugLog("[DEBUG] StockViewModel.loadData: currentUser has NIL storeId. User profile: \(currentUser.fullName). Showing empty state.")
            if self.summary == nil {
                self.summary = InventorySummary(totalValue: 0, totalProducts: 0, totalUnits: 0, pendingRequestsCount: 0, lowStockCount: 0, outOfStockCount: 0)
                self.stockList = []
            }
            self.isLoading = false
            return
        }
        
        debugLog("[DEBUG] StockViewModel.loadData: Resolved storeId = \(storeId.uuidString) for user = \(currentUser.fullName)")
        
        do {
            let (summaryResult, stockListResult) = try await repository.fetchStockDashboardData(forStoreId: storeId)
            
            // Main thread update is guaranteed by @MainActor annotation on this method
            self.summary = summaryResult
            self.stockList = stockListResult
            
            debugLog("[DEBUG] StockViewModel.loadData: Successfully loaded summary and stock list. Total items = \(stockListResult.count)")
        } catch {
            debugLog("[DEBUG] StockViewModel.loadData: ERROR loaded: \(error)")
            self.errorMessage = error.localizedDescription
            // If we have no data, fallback to empty state, otherwise keep previous data
            if self.summary == nil {
                self.summary = InventorySummary(totalValue: 0, totalProducts: 0, totalUnits: 0, pendingRequestsCount: 0, lowStockCount: 0, outOfStockCount: 0)
                self.stockList = []
            }
        }
        
        self.isLoading = false
    }
}
