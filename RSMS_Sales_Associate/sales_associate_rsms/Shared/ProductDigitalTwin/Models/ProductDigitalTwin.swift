// ProductDigitalTwin.swift
// RSMS — Sales Associate Module

import Foundation

struct ProductDigitalTwin: Codable, Identifiable {
    let id: UUID
    var sku: String
    var title: String
    var description: String
    var category: ProductCategory
    
    // Specifications
    var brand: String
    var collection: String?
    var materials: [String]
    
    // Pricing
    var price: Decimal
    var currency: String
    
    // Provenance & Authenticity
    var authenticityCertificateID: String?
    var dateOfManufacture: Date?
    var origin: String?
    
    // Media
    var imageURLs: [URL]?
    
    // Real-time stock (could also be fetched separately from Inventory, but we'll include a simple mock status)
    var isAvailable: Bool { stockLevel > 0 }
    var stockLevel: Int
    
    enum CodingKeys: String, CodingKey {
        case id, sku, title, description, category
        case brand, collection, materials
        case price, currency
        case authenticityCertificateID = "authenticity_certificate_id"
        case dateOfManufacture = "date_of_manufacture"
        case origin
        case imageURLs = "image_urls"
        case stockLevel = "stock_level"
    }
}
