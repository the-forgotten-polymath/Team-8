//
//  Product.swift
//  RSMS_Project
//
//  Created by Yatharth Mishra on 30/06/26.
//

import Foundation

struct Product: Codable, Identifiable {
    let id: UUID
    let sku: String
    let productName: String
    let brand: String
    let categoryId: UUID
    let price: Double
    let description: String
    /// Optional because some legacy product rows may not yet have a QR value assigned.
    let qrValue: String?
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case sku
        case productName = "product_name"
        case categoryId = "category_id"
        case price
        case description
        case qrValue = "qr_value"
        case brand
        case createdAt = "created_at"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id          = try container.decode(UUID.self,   forKey: .id)
        sku         = try container.decode(String.self, forKey: .sku)
        productName = try container.decode(String.self, forKey: .productName)
        brand       = try container.decode(String.self, forKey: .brand)
        categoryId  = try container.decode(UUID.self,   forKey: .categoryId)
        price       = try container.decode(Double.self, forKey: .price)
        description = try container.decode(String.self, forKey: .description)
        createdAt   = try container.decode(Date.self,   forKey: .createdAt)

        // qr_value may be NULL for products that were seeded without a QR code.
        // Safe-decode to avoid a keyNotFound / valueNotFound crash.
        if container.contains(.qrValue) {
            qrValue = try container.decodeIfPresent(String.self, forKey: .qrValue)
        } else {
            qrValue = nil
        }
    }
}
