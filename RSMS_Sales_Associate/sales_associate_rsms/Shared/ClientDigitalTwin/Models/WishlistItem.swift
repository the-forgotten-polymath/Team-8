// WishlistItem.swift
// RSMS — Sales Associate Module

import Foundation

struct WishlistItem: Codable, Identifiable, Sendable {
    let id: UUID
    let clientID: UUID
    let sku: String
    let productName: String
    let addedDate: Date
    let addedBy: UUID                              // Associate ID
    var isAvailable: Bool                          // Real-time calculation if possible, or updated via background worker
    var availableStores: [UUID]?
    var notifyOnRestock: Bool
    var notes: String?

    enum CodingKeys: String, CodingKey {
        case id
        case clientID = "client_id"
        case sku
        case productName = "product_name"
        case addedDate = "added_date"
        case addedBy = "added_by"
        case isAvailable = "is_available"
        case availableStores = "available_stores"
        case notifyOnRestock = "notify_on_restock"
        case notes
    }
}
