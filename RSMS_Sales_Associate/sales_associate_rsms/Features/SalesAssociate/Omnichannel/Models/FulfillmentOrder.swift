// FulfillmentOrder.swift
// RSMS — Sales Associate Module

import Foundation

enum FulfillmentType: String, Codable, CaseIterable {
    case bopis = "BOPIS"
    case sfs = "Ship From Store"
}

enum FulfillmentStatus: String, Codable, CaseIterable {
    case pending = "Pending"
    case processing = "Processing"
    case readyForPickup = "Ready for Pickup"
    case pickedUp = "Picked Up"
    case shipping = "Shipping"
    case completed = "Completed"
    case cancelled = "Cancelled"
}

struct FulfillmentItem: Codable, Identifiable, Equatable {
    let id: UUID
    let productID: UUID
    let quantity: Int
    
    // For UI convenience
    var productTitle: String?
    var sku: String?
}

struct FulfillmentOrder: Codable, Identifiable, Equatable {
    let id: UUID
    let orderNumber: String
    let clientID: UUID
    let storeID: UUID
    let type: FulfillmentType
    var status: FulfillmentStatus
    let orderDate: Date
    let items: [FulfillmentItem]
    
    // For Ship From Store
    var carrier: String?
    var trackingNumber: String?
    
    // For BOPIS
    var signatureData: Data?
    var pickupDate: Date?
}
