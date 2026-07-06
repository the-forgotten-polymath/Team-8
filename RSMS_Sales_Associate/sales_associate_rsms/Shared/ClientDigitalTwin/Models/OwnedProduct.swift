// OwnedProduct.swift
// RSMS — Sales Associate Module

import Foundation

struct OwnedProduct: Codable, Identifiable, Sendable {
    let id: UUID
    let clientID: UUID
    let twinID: UUID                            // Links to Product Digital Twin
    let productName: String
    let serialNumber: String?
    let purchaseDate: Date
    let purchaseStore: UUID?
    let purchasePrice: Decimal
    var currentWarrantyStatus: WarrantyStatus

    enum CodingKeys: String, CodingKey {
        case id
        case clientID = "client_id"
        case twinID = "twin_id"
        case productName = "product_name"
        case serialNumber = "serial_number"
        case purchaseDate = "purchase_date"
        case purchaseStore = "purchase_store"
        case purchasePrice = "purchase_price"
        case currentWarrantyStatus = "current_warranty_status"
    }
}
