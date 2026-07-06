// ProductDigitalTwinService.swift
// RSMS — Sales Associate Module

import Foundation
import Supabase

@MainActor
class ProductDigitalTwinService {
    static let shared = ProductDigitalTwinService()

    private init() {}

    // MARK: - Fetch Catalog

    /// Fetches all approved products, mapping them from the `products` DB table
    /// to `ProductDigitalTwin` domain objects. Inventory stock level is scoped
    /// to the current user's store (passed via storeId).
    func fetchCatalog(
        category: ProductCategory? = nil,
        searchQuery: String = "",
        storeId: UUID? = nil
    ) async throws -> [ProductDigitalTwin] {

        if AppConstants.useMockData {
            var results = MockData.products
            if let cat = category {
                results = results.filter { $0.category == cat }
            }
            if !searchQuery.isEmpty {
                let q = searchQuery.lowercased()
                results = results.filter {
                    $0.title.lowercased().contains(q) ||
                    $0.sku.lowercased().contains(q) ||
                    $0.brand.lowercased().contains(q)
                }
            }
            try await Task.sleep(nanoseconds: 500_000_000)
            return results
        }

        let rows = try await SalesAssociateService.shared.fetchProducts(
            storeId: storeId,
            category: category?.rawValue,
            searchQuery: searchQuery
        )

        return rows.compactMap { mapToDomain($0) }
    }

    // MARK: - Fetch Single Product

    func fetchProductTwin(id: UUID, storeId: UUID? = nil) async throws -> ProductDigitalTwin? {
        if AppConstants.useMockData {
            try await Task.sleep(nanoseconds: 300_000_000)
            return MockData.products.first(where: { $0.id == id })
        }

        let rows = try await SalesAssociateService.shared.fetchProducts(storeId: storeId)
        return rows.first(where: { $0.id == id }).flatMap { mapToDomain($0) }
    }

    // MARK: - DB → Domain Mapping

    /// Maps a `ProductWithInventory` (DB row) to a `ProductDigitalTwin` (domain model).
    private func mapToDomain(_ row: ProductWithInventory) -> ProductDigitalTwin? {
        // Resolve category enum from category_name string
        let category = resolveCategory(row.categoryName)

        // Build image URL array from primary image
        var imageURLs: [URL]? = nil
        if let urlString = row.primaryImageUrl, let url = URL(string: urlString) {
            imageURLs = [url]
        }

        // Materials: use material field as single-element array if present
        var materials: [String] = []
        if let material = row.material, !material.isEmpty {
            materials = [material]
        }

        return ProductDigitalTwin(
            id: row.id,
            sku: row.sku,
            title: row.productName,
            description: row.description ?? row.shortDescription ?? "",
            category: category,
            brand: row.brand ?? "Unknown",
            collection: row.collectionName,
            materials: materials,
            price: Decimal(row.price),
            currency: AppConstants.App.currencyCode,
            authenticityCertificateID: row.certificateNumber,
            dateOfManufacture: nil,
            origin: nil,
            imageURLs: imageURLs,
            stockLevel: row.storeQuantity ?? 0
        )
    }

    /// Maps a category_name string from the DB to a `ProductCategory` enum.
    private func resolveCategory(_ name: String?) -> ProductCategory {
        guard let name = name else { return .accessories }
        // Match by rawValue (case-insensitive)
        return ProductCategory.allCases.first {
            $0.rawValue.lowercased() == name.lowercased()
        } ?? .accessories
    }
}
