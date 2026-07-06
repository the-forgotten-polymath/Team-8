// ClientDigitalTwin.swift
// RSMS — Sales Associate Module

import Foundation

struct ClientDigitalTwin: Codable, Identifiable, Sendable {
    let id: UUID
    let customerID: UUID? // E.g., linked to a global customer record if applicable

    // Identity
    var firstName: String
    var lastName: String
    var email: String?
    var phone: String?
    var dateOfBirth: Date?

    // Tier
    var tier: CustomerTier
    var lifetimeSpend: Decimal
    var preferredStore: UUID?
    var preferredAdvisor: UUID?

    var createdAt: Date
    var updatedAt: Date

    // Nested Relationships (Populated by Service)
    var preferences: ClientPreferences?
    var events: [ClientDigitalTwinEvent]?
    var ownedProducts: [OwnedProduct]?
    var wishlistItems: [WishlistItem]?
    var consentStatus: ConsentRecord?
    var gdprFlags: GDPRFlags?

    nonisolated var fullName: String { "\(firstName) \(lastName)" }
    var initials: String {
        let f = firstName.prefix(1)
        let l = lastName.prefix(1)
        return "\(f)\(l)".uppercased()
    }

    // MARK: - Privacy & GDPR Helpers
    
    var hasDataProcessingConsent: Bool {
        // If withdrawnDate is set, consent is revoked.
        if let withdrawn = consentStatus?.withdrawnDate, withdrawn <= Date() {
            return false
        }
        // Check if data processing is explicitly allowed and GDPR flags allow processing.
        // For demo purposes, let's assume if there's NO record, we assume false.
        let consentProcess = consentStatus?.dataProcessing ?? false
        let gdprProcess = gdprFlags?.canProcess ?? true // true by default unless explicitly disabled
        return consentProcess && gdprProcess
    }
    
    var maskedEmail: String? {
        guard let email = email else { return nil }
        guard hasDataProcessingConsent else { return "***@***.***" }
        return email
    }
    
    var maskedPhone: String? {
        guard let phone = phone else { return nil }
        guard hasDataProcessingConsent else { return "***-***-****" }
        return phone
    }
    
    var maskedDateOfBirth: String? {
        guard let dob = dateOfBirth else { return nil }
        guard hasDataProcessingConsent else { return "XX/XX/XXXX" }
        return dob.formatted(date: .long, time: .omitted)
    }

    enum CodingKeys: String, CodingKey {
        case id
        case customerID       = "customer_id"
        case firstName        = "first_name"
        case lastName         = "last_name"
        case email, phone
        case dateOfBirth      = "date_of_birth"
        case tier
        case lifetimeSpend    = "lifetime_spend"
        case preferredStore   = "preferred_store"
        case preferredAdvisor = "preferred_advisor"
        case createdAt        = "created_at"
        case updatedAt        = "updated_at"
    }
}
