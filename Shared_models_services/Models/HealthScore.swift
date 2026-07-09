//
//  HealthScore.swift
//  RSMS_Project
//
//  Created by Yatharth Mishra on 30/06/26.
//


import Foundation

struct HealthScore: Decodable, Identifiable {
    let id: UUID
    let storeId: UUID
    let salesScore: Double
    let inventoryScore: Double
    let customerScore: Double
    let overallScore: Double
    let generatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case storeId = "store_id"
        case salesScore = "sales_score"
        case inventoryScore = "inventory_score"
        case customerScore = "customer_score"
        case overallScore = "overall_score"
        case generatedAt = "generated_at"
    }

    /// Alias used by the Audit & Compliance screen. Kept as a computed
    /// property (not a stored column) so the rest of the feature code
    /// can keep saying "compliance" without a schema change.
    var complianceScore: Double { overallScore }

    var statusText: String {
        switch overallScore {
        case 85...: return "Optimal Health"
        case 65..<85: return "Monitoring Required"
        case 45..<65: return "Action Needed"
        default: return "Critical Threshold"
        }
    }

    var colorHex: String {
        switch overallScore {
        case 85...: return "34C759"
        case 65..<85: return "FF9500"
        case 45..<65: return "FF3B30"
        default: return "FF2D55"
        }
    }
}
