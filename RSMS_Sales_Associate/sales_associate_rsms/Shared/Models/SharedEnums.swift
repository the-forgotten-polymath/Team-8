// SharedEnums.swift
// RSMS — Sales Associate Module
// All shared enumerations used across multiple features

import Foundation

// MARK: - Staff Role (RBAC)

public enum StaffRole: String, Codable, CaseIterable {
    case salesAssociate   = "sales_associate"
    case boutiqueManager  = "boutique_manager"
    case corporateAdmin   = "corporate_admin"

    var displayName: String {
        switch self {
        case .salesAssociate:  return "Sales Associate"
        case .boutiqueManager: return "Boutique Manager"
        case .corporateAdmin:  return "Corporate Admin"
        }
    }

    /// True if this role can approve discounts beyond associate threshold
    var canApproveDiscounts: Bool {
        return self == .boutiqueManager || self == .corporateAdmin
    }

    /// True if this role can access manager-level dashboard
    var canViewManagerDashboard: Bool {
        return self == .boutiqueManager || self == .corporateAdmin
    }

    /// True if this role can view analytics across all advisors
    var canViewCrossAdvisorAnalytics: Bool {
        return self == .corporateAdmin
    }
}

// MARK: - Customer Tier

enum CustomerTier: String, Codable, CaseIterable {
    case regular  = "regular"
    case standard = "standard"
    case vip      = "vip"

    var displayName: String {
        switch self {
        case .regular:  return "Regular"
        case .standard: return "Standard"
        case .vip:      return "VIP"
        }
    }

    var badgeColor: String {
        switch self {
        case .regular:  return "tierStandard"
        case .standard: return "tierVIP"
        case .vip:      return "tierVVIP"
        }
    }

    var icon: String {
        switch self {
        case .regular:  return "person.circle"
        case .standard: return "star.circle.fill"
        case .vip:      return "crown.fill"
        }
    }

    static func compute(from lifetimeSpend: Decimal) -> CustomerTier {
        if lifetimeSpend >= 200000 {
            return .vip
        } else if lifetimeSpend >= 100000 {
            return .standard
        } else {
            return .regular
        }
    }

    static func compute(spend: Decimal, purchasesPerMonth: Int) -> CustomerTier {
        if spend >= 200000 || purchasesPerMonth >= 6 {
            return .vip
        } else if spend >= 100000 || (purchasesPerMonth >= 3 && purchasesPerMonth <= 5) {
            return .standard
        } else {
            return .regular
        }
    }
}

// MARK: - Client Event Types

enum ClientEventType: String, Codable, CaseIterable {
    // Sales Events
    case boutiqueVisit         = "boutique_visit"
    case purchase              = "purchase"
    case returnProcessed       = "return_processed"
    case exchange              = "exchange"
    // Relationship Events
    case appointmentBooked     = "appointment_booked"
    case appointmentCompleted  = "appointment_completed"
    case remoteSellSession     = "remote_sell_session"
    case curatedCartViewed     = "curated_cart_viewed"
    // Product Events
    case wishlistAdded         = "wishlist_added"
    case wishlistFulfilled     = "wishlist_fulfilled"
    case warrantyRegistered    = "warranty_registered"
    case authenticationDone    = "authentication_done"
    case valuationReceived     = "valuation_received"
    // Engagement Events
    case vipEventAttended      = "vip_event_attended"
    case outreachSent          = "outreach_sent"
    case feedbackProvided      = "feedback_provided"

    var displayName: String {
        switch self {
        case .boutiqueVisit:        return "Boutique Visit"
        case .purchase:             return "Purchase"
        case .returnProcessed:      return "Return"
        case .exchange:             return "Exchange"
        case .appointmentBooked:    return "Appointment Booked"
        case .appointmentCompleted: return "Appointment Completed"
        case .remoteSellSession:    return "Remote Selling Session"
        case .curatedCartViewed:    return "Curated Cart Viewed"
        case .wishlistAdded:        return "Wishlist Item Added"
        case .wishlistFulfilled:    return "Wishlist Fulfilled"
        case .warrantyRegistered:   return "Warranty Registered"
        case .authenticationDone:   return "Authentication"
        case .valuationReceived:    return "Valuation Received"
        case .vipEventAttended:     return "VIP Event Attended"
        case .outreachSent:         return "Outreach Sent"
        case .feedbackProvided:     return "Feedback Provided"
        }
    }

    var icon: String {
        switch self {
        case .boutiqueVisit:        return "building.2"
        case .purchase:             return "bag.fill"
        case .returnProcessed:      return "arrow.uturn.backward"
        case .exchange:             return "arrow.2.squarepath"
        case .appointmentBooked:    return "calendar.badge.plus"
        case .appointmentCompleted: return "calendar.badge.checkmark"
        case .remoteSellSession:    return "video.fill"
        case .curatedCartViewed:    return "eye.fill"
        case .wishlistAdded:        return "heart.fill"
        case .wishlistFulfilled:    return "heart.circle.fill"
        case .warrantyRegistered:   return "checkmark.shield.fill"
        case .authenticationDone:   return "lock.shield.fill"
        case .valuationReceived:    return "doc.text.fill"
        case .vipEventAttended:     return "star.fill"
        case .outreachSent:         return "paperplane.fill"
        case .feedbackProvided:     return "message.fill"
        }
    }
}

// MARK: - Payment Method

enum PaymentMethod: String, Codable, CaseIterable {
    case applePay    = "apple_pay"
    case card        = "card"
    case upi         = "upi"
    case cash        = "cash"
    case storeCredit = "store_credit"
    case giftCard    = "gift_card"
    case bankTransfer = "bank_transfer"

    var displayName: String {
        switch self {
        case .applePay:     return "Apple Pay"
        case .card:         return "Card"
        case .upi:          return "UPI"
        case .cash:         return "Cash"
        case .storeCredit:  return "Store Credit"
        case .giftCard:     return "Gift Card"
        case .bankTransfer: return "Bank Transfer"
        }
    }

    var icon: String {
        switch self {
        case .applePay:     return "apple.logo"
        case .card:         return "creditcard.fill"
        case .upi:          return "indianrupeesign.circle.fill"
        case .cash:         return "banknote.fill"
        case .storeCredit:  return "gift.fill"
        case .giftCard:     return "giftcard.fill"
        case .bankTransfer: return "building.columns.fill"
        }
    }
}

// MARK: - Communication Channel

enum CommunicationChannel: String, Codable, CaseIterable {
    case push     = "push"
    case sms      = "sms"
    case email    = "email"
    case whatsapp = "whatsapp"
    case inApp    = "in_app"

    var displayName: String {
        switch self {
        case .push:     return "Push Notification"
        case .sms:      return "SMS"
        case .email:    return "Email"
        case .whatsapp: return "WhatsApp"
        case .inApp:    return "In-App"
        }
    }
}

// MARK: - Warranty Type

enum WarrantyType: String, Codable, CaseIterable {
    case standard  = "standard"
    case extended  = "extended"
    case brandCare = "brand_care"

    var displayName: String {
        switch self {
        case .standard:  return "Standard Warranty"
        case .extended:  return "Extended Warranty"
        case .brandCare: return "Brand Care Program"
        }
    }
}

// MARK: - Warranty Status

enum WarrantyStatus: String, Codable {
    case active   = "active"
    case expiring = "expiring"   // Within 90 days
    case expired  = "expired"
    case voided   = "voided"
}

// MARK: - Occasion

enum Occasion: String, Codable, CaseIterable {
    case wedding     = "Wedding"
    case anniversary = "Anniversary"
    case birthday    = "Birthday"
    case corporate   = "Corporate"
    case travel      = "Travel"
    case graduation  = "Graduation"
    case festive     = "Festive"
    case everyday    = "Everyday Luxury"

    var icon: String {
        switch self {
        case .wedding:     return "heart.circle.fill"
        case .anniversary: return "sparkles"
        case .birthday:    return "birthday.cake.fill"
        case .corporate:   return "briefcase.fill"
        case .travel:      return "airplane.circle.fill"
        case .graduation:  return "graduationcap.fill"
        case .festive:     return "party.popper.fill"
        case .everyday:    return "sun.max.fill"
        }
    }
}

// MARK: - Relationship Type

enum RelationshipType: String, Codable, CaseIterable {
    case spouse    = "spouse"
    case child     = "child"
    case parent    = "parent"
    case sibling   = "sibling"
    case friend    = "friend"
    case colleague = "colleague"
    case other     = "other"

    var displayName: String { rawValue.capitalized }
}

// MARK: - Urgency

enum Urgency: String, Codable, CaseIterable {
    case low    = "low"
    case medium = "medium"
    case high   = "high"

    var color: String {
        switch self {
        case .low:    return "urgencyLow"
        case .medium: return "urgencyMedium"
        case .high:   return "urgencyHigh"
        }
    }
}

// MARK: - Opportunity Status

enum OpportunityStatus: String, Codable, CaseIterable {
    case new      = "new"
    case actedOn  = "acted_on"
    case converted = "converted"
    case dismissed = "dismissed"
}

// MARK: - Payment Status

enum PaymentStatus: String, Codable {
    case pending   = "pending"
    case completed = "completed"
    case failed    = "failed"
    case refunded  = "refunded"
}

// MARK: - Transaction Status

enum TransactionStatus: String, Codable {
    case draft     = "draft"
    case completed = "completed"
    case voided    = "voided"
    case refunded  = "refunded"
}

// MARK: - Receipt Type

enum ReceiptType: String, Codable {
    case digital = "digital"
    case printed = "printed"
    case gift    = "gift"
}

// MARK: - Product Category

enum ProductCategory: String, Codable, CaseIterable {
    case watches      = "Watches"
    case jewellery    = "Jewellery"
    case leather      = "Leather Goods"
    case accessories  = "Accessories"
    case fragrance    = "Fragrance"
    case apparel      = "Apparel"
    case homeDecor    = "Home Decor"
    case eyewear      = "Eyewear"

    var icon: String {
        switch self {
        case .watches:     return "applewatch"
        case .jewellery:   return "sparkle"
        case .leather:     return "bag.fill"
        case .accessories: return "tag.fill"
        case .fragrance:   return "bubbles.and.sparkles"
        case .apparel:     return "tshirt.fill"
        case .homeDecor:   return "house.fill"
        case .eyewear:     return "eyeglasses"
        }
    }
}

// MARK: - Order Type

enum OrderType: String, Codable {
    case bopis         = "bopis"
    case endlessAisle  = "endless_aisle"
    case shipFromStore = "ship_from_store"
    case reservation   = "reservation"

    var displayName: String {
        switch self {
        case .bopis:         return "BOPIS"
        case .endlessAisle:  return "Endless Aisle"
        case .shipFromStore: return "Ship From Store"
        case .reservation:   return "Reservation"
        }
    }
}

// MARK: - Order Status

enum OrderStatus: String, Codable {
    case pending        = "pending"
    case readyForPickup = "ready_for_pickup"
    case packed         = "packed"
    case shipped        = "shipped"
    case delivered      = "delivered"
    case pickedUp       = "picked_up"
    case cancelled      = "cancelled"

    var displayName: String {
        switch self {
        case .pending:        return "Pending"
        case .readyForPickup: return "Ready for Pickup"
        case .packed:         return "Packed"
        case .shipped:        return "Shipped"
        case .delivered:      return "Delivered"
        case .pickedUp:       return "Picked Up"
        case .cancelled:      return "Cancelled"
        }
    }
}

// MARK: - Appointment Type

enum AppointmentType: String, Codable, CaseIterable {
    case inStore     = "in_store"
    case videoConsult = "video_consult"
    case phoneCall   = "phone_call"
    case remoteCart  = "remote_cart"

    var displayName: String {
        switch self {
        case .inStore:      return "In-Store"
        case .videoConsult: return "Video Consult"
        case .phoneCall:    return "Phone Call"
        case .remoteCart:   return "Remote Cart"
        }
    }

    var icon: String {
        switch self {
        case .inStore:      return "building.2.fill"
        case .videoConsult: return "video.fill"
        case .phoneCall:    return "phone.fill"
        case .remoteCart:   return "cart.fill"
        }
    }
}

// MARK: - Appointment Status

enum AppointmentStatus: String, Codable, CaseIterable {
    case scheduled  = "scheduled"
    case confirmed  = "confirmed"
    case inProgress = "in_progress"
    case completed  = "completed"
    case cancelled  = "cancelled"
    case noShow     = "no_show"

    var displayName: String {
        switch self {
        case .scheduled:  return "Scheduled"
        case .confirmed:  return "Confirmed"
        case .inProgress: return "In Progress"
        case .completed:  return "Completed"
        case .cancelled:  return "Cancelled"
        case .noShow:     return "No Show"
        }
    }
}

// MARK: - Cart Status

enum CartStatus: String, Codable {
    case draft     = "draft"
    case shared    = "shared"
    case viewed    = "viewed"
    case converted = "converted"
    case expired   = "expired"
}
