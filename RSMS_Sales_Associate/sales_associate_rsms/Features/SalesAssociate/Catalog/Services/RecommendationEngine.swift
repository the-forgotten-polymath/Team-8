// RecommendationEngine.swift
// RSMS — Sales Associate Module

import Foundation

@MainActor
final class RecommendationEngine: Sendable {
    static let shared = RecommendationEngine()
    
    private init() {}
    
    /// Recommends complementary products based on an anchor product (Rule-Based Heuristic)
    func recommendComplementary(for anchor: ProductDigitalTwin) async -> [ProductDigitalTwin] {
        // Simulate network or ML inference delay
        try? await Task.sleep(nanoseconds: 500_000_000)
        
        let allProducts = MockData.products
        var recommendations: [ProductDigitalTwin] = []
        
        switch anchor.category {
        case .watches:
            // For a watch, recommend jewellery or leather accessories
            recommendations = allProducts.filter { $0.category == .jewellery || $0.category == .leather }
        case .jewellery:
            // For jewellery, recommend watches or other jewellery
            recommendations = allProducts.filter { ($0.category == .watches || $0.category == .jewellery) && $0.id != anchor.id }
        case .leather:
            // For leather, recommend accessories or apparel
            recommendations = allProducts.filter { $0.category == .accessories || $0.category == .apparel || $0.category == .jewellery }
        default:
            // Fallback: recommend anything else
            recommendations = allProducts.filter { $0.id != anchor.id }
        }
        
        // Return up to 4 recommendations
        return Array(recommendations.prefix(4))
    }
    
    /// Recommends a full "Look" based on an occasion and optionally a client profile
    func recommendLook(forOccasion occasion: String, client: ClientDigitalTwin? = nil) async -> [ProductDigitalTwin] {
        try? await Task.sleep(nanoseconds: 700_000_000)
        
        let allProducts = MockData.products
        var look: [ProductDigitalTwin] = []
        
        if occasion.lowercased().contains("wedding") || occasion.lowercased().contains("gala") {
            // Elegant look: A watch and jewellery
            if let watch = allProducts.first(where: { $0.category == .watches }) { look.append(watch) }
            if let jewel = allProducts.first(where: { $0.category == .jewellery }) { look.append(jewel) }
        } else {
            // Everyday look: Leather and maybe a watch
            if let bag = allProducts.first(where: { $0.category == .leather }) { look.append(bag) }
            if let watch = allProducts.first(where: { $0.category == .watches }) { look.append(watch) }
        }
        
        return look
    }
}
