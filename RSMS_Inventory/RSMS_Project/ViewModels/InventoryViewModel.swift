//
//  InventoryViewModel.swift
//  RSMS_Project
//
//  Created by Yatharth Mishra on 30/06/26.
//

import Foundation
import Combine

@MainActor
final class InventoryViewModel: ObservableObject {
    
    @Published var inventoryItems: [InventoryItem] = []
    @Published var products: [Product] = []
    @Published var searchText = ""
    @Published var sortOption = SortOption.name
    @Published var isLoading = false
    @Published var errorMessage: String? = nil
    
    private let warehouseService = WarehouseService.shared
    private let productService = ProductService()
    
    enum SortOption {
        case name, quantity, sku
    }
    
    var filteredInventory: [InventoryItem] {
        let items = inventoryItems.filter { item in
            guard let product = getProduct(for: item.productId) else { return false }
            if searchText.isEmpty { return true }
            return product.productName.localizedCaseInsensitiveContains(searchText) ||
                   product.sku.localizedCaseInsensitiveContains(searchText)
        }
        
        switch sortOption {
        case .name:
            return items.sorted {
                let nameA = getProduct(for: $0.productId)?.productName ?? ""
                let nameB = getProduct(for: $1.productId)?.productName ?? ""
                return nameA < nameB
            }
        case .quantity:
            return items.sorted { $0.quantity > $1.quantity }
        case .sku:
            return items.sorted {
                let skuA = getProduct(for: $0.productId)?.sku ?? ""
                let skuB = getProduct(for: $1.productId)?.sku ?? ""
                return skuA < skuB
            }
        }
    }
    
    func loadData(warehouseId: UUID) async {
        isLoading = true
        errorMessage = nil
        
        do {
            self.products = try await productService.fetchProducts()
            self.inventoryItems = try await warehouseService.fetchWarehouseInventory(warehouseId: warehouseId)
        } catch {
            guard !Swift.Task.isCancelled else { return }
            self.errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func getProduct(for productId: UUID) -> Product? {
        products.first { $0.id == productId }
    }
}
