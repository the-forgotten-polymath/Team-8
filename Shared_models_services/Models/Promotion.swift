//
//  Promotion.swift
//  RSMS_Project
//

import Foundation

struct Promotion: Codable, Identifiable {
    let id: UUID
    let promotionName: String
    let promotionType: String
    let categoryId: UUID?
    let description: String?
    let startDate: String // date type in Postgres mapped to String or Date based on formatter
    let endDate: String
    let appliesToAllStores: Bool?
    let storeId: UUID?
    let bannerImageUrl: String?
    let status: String?
    let createdBy: UUID?
    let createdAt: Date?
    let updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case promotionName = "promotion_name"
        case promotionType = "promotion_type"
        case categoryId = "category_id"
        case description
        case startDate = "start_date"
        case endDate = "end_date"
        case appliesToAllStores = "applies_to_all_stores"
        case storeId = "store_id"
        case bannerImageUrl = "banner_image_url"
        case status
        case createdBy = "created_by"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}
