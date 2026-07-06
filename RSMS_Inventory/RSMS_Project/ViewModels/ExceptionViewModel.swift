//
//  ExceptionViewModel.swift
//  RSMS_Project
//
//  Created by Yatharth Mishra on 30/06/26.
//

import Foundation
import Combine

@MainActor
final class ExceptionViewModel: ObservableObject {
    
    @Published var exceptions: [InventoryException] = []
    @Published var products: [Product] = []
    
    @Published var filterOption = FilterOption.all
    @Published var isLoading = false
    @Published var errorMessage: String? = nil
    
    enum FilterOption {
        case all, unresolved, resolved
    }
    
    private let service = WarehouseService.shared
    private let productService = ProductService()
    
    var filteredExceptions: [InventoryException] {
        switch filterOption {
        case .all:
            return exceptions
        case .unresolved:
            return exceptions.filter { $0.status.lowercased() == "unresolved" }
        case .resolved:
            return exceptions.filter { $0.status.lowercased() == "resolved" }
        }
    }
    
    func loadData() async {
        isLoading = true
        errorMessage = nil
        do {
            self.exceptions = try await service.fetchExceptions()
            self.products = try await productService.fetchProducts()
        } catch {
            self.errorMessage = error.localizedDescription
        }
        isLoading = false
    }
    
    func getProductName(for productId: UUID) -> String {
        products.first(where: { $0.id == productId })?.productName ?? "Unknown Product"
    }
    
    func resolveException(exception: InventoryException, userId: UUID) async {
        isLoading = true
        errorMessage = nil
        do {
            try await service.resolveException(exceptionId: exception.id)
            try await service.logAction(userId: userId, module: "Inventory Exceptions", action: "Resolved exception \(exception.id.uuidString)")
            await loadData()
        } catch {
            self.errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
