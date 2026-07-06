// ActiveCart.swift
// RSMS — Sales Associate Module

import Foundation

struct CartItem: Identifiable, Codable {
    let id: UUID
    let product: ProductDigitalTwin
    var quantity: Int
    var discountPercent: Decimal?
    
    var subtotal: Decimal {
        let base = product.price * Decimal(quantity)
        if let discount = discountPercent {
            return base * (1 - discount / 100)
        }
        return base
    }
}

struct AppliedTender: Identifiable, Codable {
    let id: UUID
    let method: PaymentMethod
    let amount: Decimal
    let timestamp: Date
    
    init(id: UUID = UUID(), method: PaymentMethod, amount: Decimal, timestamp: Date = Date()) {
        self.id = id
        self.method = method
        self.amount = amount
        self.timestamp = timestamp
    }
}

struct ActiveCart: Identifiable, Codable {
    let id: UUID
    let clientId: UUID
    var items: [CartItem]
    var orderLevelDiscountPercent: Decimal?
    var taxRate: Decimal = 0.08875 // e.g. NY State tax
    
    var appliedTenders: [AppliedTender] = []
    
    // Concierge Options
    var giftWrap: Bool = false
    var giftNote: String?
    
    var subtotal: Decimal {
        items.reduce(0) { $0 + $1.subtotal }
    }
    
    var discountedSubtotal: Decimal {
        if let discount = orderLevelDiscountPercent {
            return subtotal * (1 - discount / 100)
        }
        return subtotal
    }
    
    var tax: Decimal {
        discountedSubtotal * taxRate
    }
    
    var total: Decimal {
        discountedSubtotal + tax
    }
    
    var totalPaid: Decimal {
        appliedTenders.reduce(0) { $0 + $1.amount }
    }
    
    var remainingBalance: Decimal {
        max(0, total - totalPaid)
    }
    
    var isFullyPaid: Bool {
        remainingBalance <= 0 && !items.isEmpty
    }
    
    init(id: UUID = UUID(), clientId: UUID, items: [CartItem] = []) {
        self.id = id
        self.clientId = clientId
        self.items = items
    }
}
