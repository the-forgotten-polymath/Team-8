// Opportunity.swift
// RSMS — Sales Associate Module

import Foundation

enum OpportunityType: String, Codable, CaseIterable {
    case anniversary = "Anniversary"
    case wishlistInStock = "Wishlist In Stock"
    case warrantyExpiring = "Warranty Expiring"
    case newCollectionMatch = "New Collection Match"
    case retentionRisk = "Retention Risk"
    case vipEventInvitation = "VIP Event Invitation"
    case birthday = "Birthday"
    case membershipAnniversary = "Membership Anniversary"
}



struct Opportunity: Codable, Identifiable {
    let id: UUID
    let clientID: UUID
    let associateID: UUID
    let type: OpportunityType
    let title: String
    let description: String
    let dateGenerated: Date
    var status: OpportunityStatus
    
    // For UI convenience
    var clientName: String?
    
    // Fields for personalized recommended product & offer
    var eventDate: Date?
    var customerTier: String?
    var personalizedOffer: String?
    var recommendedProductID: UUID?
    var recommendedProductName: String?
    var recommendedProductCategory: String?
    var recommendedProductPrice: Double?
    var recommendedProductDiscountedPrice: Double?
    var recommendedProductImageURL: String?
    
    // Promo code (single-use, from customers table)
    var promoCode: String?
    var promoCodeUsed: Bool?
    var daysUntilEvent: Int?
}
