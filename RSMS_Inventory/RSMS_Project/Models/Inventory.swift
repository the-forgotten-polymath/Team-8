//
//  Inventory.swift
//  RSMS_Project
//
//  Created by Yatharth Mishra on 30/06/26.
//

import Foundation

struct InventoryItem: Codable, Identifiable {
    let id: UUID
    let productId: UUID
    let storeId: UUID?
    let warehouseId: UUID?
    let locationType: String
    let quantity: Int
    let reorderLevel: Int
    let lastVerifiedAt: Date?
    let createdAt: Date
    let zone: String?

    enum CodingKeys: String, CodingKey {
        case id
        case productId = "product_id"
        case storeId = "store_id"
        case warehouseId = "warehouse_id"
        case locationType = "location_type"
        case quantity
        case reorderLevel = "reorder_level"
        case lastVerifiedAt = "last_verified_at"
        case createdAt = "created_at"
        case zone
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        productId = try container.decode(UUID.self, forKey: .productId)
        storeId = try container.decodeIfPresent(UUID.self, forKey: .storeId)
        warehouseId = try container.decodeIfPresent(UUID.self, forKey: .warehouseId)
        locationType = try container.decode(String.self, forKey: .locationType)
        quantity = try container.decode(Int.self, forKey: .quantity)
        reorderLevel = try container.decode(Int.self, forKey: .reorderLevel)
        lastVerifiedAt = try container.decodeIfPresent(Date.self, forKey: .lastVerifiedAt)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        
        // Safety: If zone is not present in the JSON payload (e.g. database schema not updated yet), default to nil
        if container.contains(.zone) {
            zone = try container.decodeIfPresent(String.self, forKey: .zone)
        } else {
            zone = nil
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(productId, forKey: .productId)
        try container.encodeIfPresent(storeId, forKey: .storeId)
        try container.encodeIfPresent(warehouseId, forKey: .warehouseId)
        try container.encode(locationType, forKey: .locationType)
        try container.encode(quantity, forKey: .quantity)
        try container.encode(reorderLevel, forKey: .reorderLevel)
        try container.encodeIfPresent(lastVerifiedAt, forKey: .lastVerifiedAt)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encodeIfPresent(zone, forKey: .zone)
    }
}
