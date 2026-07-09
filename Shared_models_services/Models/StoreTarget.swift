//
//  StoreTarget.swift
//  RSMS_Project
//

import Foundation

struct StoreTarget: Codable, Identifiable {
    let id: UUID
    let storeId: UUID?
    let targetMonth: String // Date mapped to string depending on decoder format
    let revenueTarget: Double
    let createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case storeId = "store_id"
        case targetMonth = "target_month"
        case revenueTarget = "revenue_target"
        case createdAt = "created_at"
    }
}
