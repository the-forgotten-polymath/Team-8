import Foundation

// MARK: - Promotion Status

enum PromotionStatus: String, CaseIterable, Codable, Identifiable {
    case all = "All"
    case draft = "Draft"
    case active = "Active"
    case scheduled = "Scheduled"
    case completed = "Completed"

    var id: String { rawValue }
}

// MARK: - Promotion

struct Promotion: Codable, Identifiable, Hashable {
    let id: UUID
    let promotionName: String
    let promotionType: String
    let categoryId: UUID?
    let description: String?
    let startDate: Date
    let endDate: Date
    let appliesToAllStores: Bool
    let storeIds: [UUID]?
    let bannerImageURL: String?
    let status: String
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
        case storeIds = "store_ids"
        case bannerImageURL = "banner_image_url"
        case status
        case createdBy = "created_by"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - Create Promotion Request

struct CreatePromotionRequest: Encodable {
    let promotionName: String
    let promotionType: String
    let categoryId: UUID?
    let description: String?
    let startDate: Date
    let endDate: Date
    let appliesToAllStores: Bool
    let storeIds: [UUID]?
    let bannerImageURL: String?
    let status: String
    let createdBy: UUID?

    enum CodingKeys: String, CodingKey {
        case promotionName = "promotion_name"
        case promotionType = "promotion_type"
        case categoryId = "category_id"
        case description
        case startDate = "start_date"
        case endDate = "end_date"
        case appliesToAllStores = "applies_to_all_stores"
        case storeIds = "store_ids"
        case bannerImageURL = "banner_image_url"
        case status
        case createdBy = "created_by"
    }
}

// MARK: - Update Promotion Request

struct UpdatePromotionRequest: Encodable {
    let promotionName: String?
    let promotionType: String?
    let categoryId: UUID?
    let description: String?
    let startDate: Date?
    let endDate: Date?
    let appliesToAllStores: Bool?
    let storeIds: [UUID]?
    let bannerImageURL: String?
    let status: String?

    enum CodingKeys: String, CodingKey {
        case promotionName = "promotion_name"
        case promotionType = "promotion_type"
        case categoryId = "category_id"
        case description
        case startDate = "start_date"
        case endDate = "end_date"
        case appliesToAllStores = "applies_to_all_stores"
        case storeIds = "store_ids"
        case bannerImageURL = "banner_image_url"
        case status
    }
}

// MARK: - Sample Data

extension Promotion {

    static let sampleData: [Promotion] = [
        Promotion(
            id: UUID(),
            promotionName: "Summer Sale 2026",
            promotionType: "Discount",
            categoryId: nil,
            description: "Storewide summer discount campaign",
            startDate: Date(),
            endDate: Calendar.current.date(byAdding: .day, value: 30, to: Date())!,
            appliesToAllStores: true,
            storeIds: nil,
            bannerImageURL: nil,
            status: "Active",
            createdBy: nil,
            createdAt: Date(),
            updatedAt: Date()
        ),

        Promotion(
            id: UUID(),
            promotionName: "Luxury Watch Festival",
            promotionType: "Category Promotion",
            categoryId: nil,
            description: "Exclusive promotion for luxury watches",
            startDate: Date(),
            endDate: Calendar.current.date(byAdding: .day, value: 15, to: Date())!,
            appliesToAllStores: false,
            storeIds: [UUID()],
            bannerImageURL: nil,
            status: "Scheduled",
            createdBy: nil,
            createdAt: Date(),
            updatedAt: Date()
        ),

        Promotion(
            id: UUID(),
            promotionName: "Holiday Clearance",
            promotionType: "Clearance",
            categoryId: nil,
            description: "End of season clearance sale",
            startDate: Date(),
            endDate: Calendar.current.date(byAdding: .day, value: 10, to: Date())!,
            appliesToAllStores: false,
            storeIds: [UUID(), UUID()],
            bannerImageURL: nil,
            status: "Draft",
            createdBy: nil,
            createdAt: Date(),
            updatedAt: Date()
        )
    ]
}
