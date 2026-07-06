//
//  Product.swift
//  RSMS_Project
//
//  Created by Yatharth Mishra on 30/06/26.
//

import Foundation

struct Product: Codable, Identifiable, Equatable, Hashable {
    let id: UUID
    let sku: String
    let productName: String
    let price: Decimal
    let createdAt: Date
    let categoryId: UUID?
    let description: String?
    let brand: String?
    let serialNumber: String?
    let certificateNumber: String?
    let status: String?
    let barcode: String?
    let shortDescription: String?
    let material: String?
    let color: String?
    let size: String?
    let weight: String?
    let collectionName: String?
    let modelNumber: String?
    let warrantyDuration: String?
    let isNewArrival: Bool
    let isBestSeller: Bool
    let isLimitedEdition: Bool
    let approvalStatus: String?

    enum CodingKeys: String, CodingKey {
        case id
        case sku
        case productName = "product_name"
        case price
        case createdAt = "created_at"
        case categoryId = "category_id"
        case description
        case brand
        case serialNumber = "serial_number"
        case certificateNumber = "certificate_number"
        case status
        case barcode
        case shortDescription = "short_description"
        case material
        case color
        case size
        case weight
        case collectionName = "collection_name"
        case modelNumber = "model_number"
        case warrantyDuration = "warranty_duration"
        case isNewArrival = "is_new_arrival"
        case isBestSeller = "is_best_seller"
        case isLimitedEdition = "is_limited_edition"
        case approvalStatus = "approval_status"
    }
}
