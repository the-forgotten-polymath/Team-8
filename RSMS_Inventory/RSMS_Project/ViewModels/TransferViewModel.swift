//
//  TransferViewModel.swift
//  RSMS_Project
//
//  Created by Yatharth Mishra on 30/06/26.
//

import Foundation
import Combine

@MainActor
final class TransferViewModel: ObservableObject {
    
    @Published var transfers: [Transfer] = []
    @Published var products: [Product] = []
    @Published var stores: [Store] = []
    @Published var stockRequests: [StockRequest] = []
    
    @Published var isLoading = false
    @Published var errorMessage: String? = nil
    
    private let warehouseService = WarehouseService.shared
    private let productService = ProductService()
    
    func loadData() async {
        isLoading = true
        errorMessage = nil
        do {
            let fetchedTransfers = try await warehouseService.fetchTransfers()
            self.transfers = fetchedTransfers.sorted(by: { $0.transferDate > $1.transferDate })
            self.products = try await productService.fetchProducts()
            self.stores = try await DatabaseService.shared.fetch(from: "stores", as: Store.self)
            self.stockRequests = try await warehouseService.fetchStockRequests()
        } catch {
            self.errorMessage = error.localizedDescription
        }
        isLoading = false
    }
    
    func getProduct(for requestId: UUID) -> Product? {
        guard let req = stockRequests.first(where: { $0.id == requestId }) else { return nil }
        return products.first { $0.id == req.productId }
    }
    
    func getQuantity(for requestId: UUID) -> Int {
        stockRequests.first(where: { $0.id == requestId })?.requestedQuantity ?? 0
    }
    
    func getStoreName(for storeId: UUID) -> String {
        stores.first(where: { $0.id == storeId })?.storeName ?? "Store"
    }
    
    func approveTransfer(transfer: Transfer, userId: UUID) async {
        isLoading = true
        errorMessage = nil
        do {
            // Update transfer status
            try await warehouseService.updateTransferStatus(transferId: transfer.id, status: "approved", approvedBy: userId)
            
            // Log audit action
            try await warehouseService.logAction(
                userId: userId,
                module: "Inter-store Transfers",
                action: "Approved transfer \(transfer.id.uuidString) from \(getStoreName(for: transfer.sourceStoreId)) to \(getStoreName(for: transfer.destinationStoreId))"
            )
            
            await loadData()
        } catch {
            self.errorMessage = error.localizedDescription
        }
        isLoading = false
    }
    
    func rejectTransfer(transfer: Transfer, userId: UUID) async {
        isLoading = true
        errorMessage = nil
        do {
            // Update transfer status
            try await warehouseService.updateTransferStatus(transferId: transfer.id, status: "rejected", approvedBy: userId)
            
            // Log audit action
            try await warehouseService.logAction(
                userId: userId,
                module: "Inter-store Transfers",
                action: "Rejected transfer \(transfer.id.uuidString) from \(getStoreName(for: transfer.sourceStoreId)) to \(getStoreName(for: transfer.destinationStoreId))"
            )
            
            await loadData()
        } catch {
            self.errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
