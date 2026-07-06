// ProductDigitalTwinService.swift
// RSMS — Sales Associate Module

import Foundation
import Supabase

@MainActor
class ProductDigitalTwinService {
    static let shared = ProductDigitalTwinService()
    
    private init() {}
    
    func fetchCatalog(category: ProductCategory? = nil, searchQuery: String = "") async throws -> [ProductDigitalTwin] {
        if AppConstants.useMockData {
            var results = MockData.products
            
            if let cat = category {
                results = results.filter { $0.category == cat }
            }
            
            if !searchQuery.isEmpty {
                let lowerQuery = searchQuery.lowercased()
                results = results.filter {
                    $0.title.lowercased().contains(lowerQuery) ||
                    $0.sku.lowercased().contains(lowerQuery) ||
                    $0.brand.lowercased().contains(lowerQuery)
                }
            }
            
            // Simulate network delay
            try await Task.sleep(nanoseconds: 500_000_000)
            return results
        }
        
        // TODO: Supabase integration
        // let query = SupabaseConfig.client.database.from("product_digital_twins").select()
        // ...
        
        return []
    }
    
    func fetchProductTwin(id: UUID) async throws -> ProductDigitalTwin? {
        if AppConstants.useMockData {
            try await Task.sleep(nanoseconds: 300_000_000)
            return MockData.products.first(where: { $0.id == id })
        }
        
        // TODO: Supabase integration
        return nil
    }
}
