// ClientPreferences.swift
// RSMS — Sales Associate Module

import Foundation

struct ClientPreferences: Codable, Sendable {
    let clientID: UUID
    var preferredBrands: [String]
    var preferredCategories: [ProductCategory]
    var preferredColors: [String]
    var preferredMaterials: [String]
    var communicationChannel: CommunicationChannel
    var languagePreference: String
    var shoppingOccasions: [Occasion]
    var anniversaryDate: Date?
    var birthdayDate: Date?
    var notes: String?

    // Sizes are stored in a separate table but queried together
    var sizes: SizeProfile?

    enum CodingKeys: String, CodingKey {
        case clientID               = "client_id"
        case preferredBrands        = "preferred_brands"
        case preferredCategories    = "preferred_categories"
        case preferredColors        = "preferred_colors"
        case preferredMaterials     = "preferred_materials"
        case communicationChannel   = "communication_channel"
        case languagePreference     = "language_preference"
        case shoppingOccasions      = "shopping_occasions"
        case anniversaryDate        = "anniversary_date"
        case birthdayDate           = "birthday_date"
        case notes
    }
}

struct SizeProfile: Codable, Sendable {
    let clientID: UUID
    var ring: String?
    var dress: String?
    var suit: String?
    var shirt: String?
    var shoes: String?
    var wrist: String?
    var custom: [String: String]? // JSONB in postgres

    enum CodingKeys: String, CodingKey {
        case clientID = "client_id"
        case ring, dress, suit, shirt, shoes, wrist, custom
    }
}
