// CatalogViewModel.swift
// RSMS — Sales Associate Module

import Foundation
import Combine

@MainActor
class CatalogViewModel: ObservableObject {
    @Published var products: [ProductDigitalTwin] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    /// Set by the parent view from AuthViewModel.userStoreID
    var storeId: UUID? = nil

    @Published var searchQuery: String = "" {
        didSet {
            Task { await fetchCatalog() }
        }
    }

    @Published var selectedCategory: ProductCategory? {
        didSet {
            Task { await fetchCatalog() }
        }
    }

    func fetchCatalog() async {
        isLoading = true
        errorMessage = nil
        do {
            products = try await ProductDigitalTwinService.shared.fetchCatalog(
                category: selectedCategory,
                searchQuery: searchQuery,
                storeId: storeId
            )
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
