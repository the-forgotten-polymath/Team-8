// InventoryLevel.swift
// RSMS — Sales Associate Module

import Foundation

struct InventoryLevel: Codable, Identifiable {
    let id: UUID
    let productID: UUID
    let storeID: UUID
    var quantityAvailable: Int
    var quantityReserved: Int
    
    var storeName: String? // For UI convenience
}
