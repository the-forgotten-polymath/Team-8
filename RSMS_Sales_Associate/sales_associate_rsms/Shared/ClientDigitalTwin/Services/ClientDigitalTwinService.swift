// ClientDigitalTwinService.swift
// RSMS — Sales Associate Module

import Foundation
@preconcurrency import Supabase

@MainActor
final class ClientDigitalTwinService: Sendable {
    static let shared = ClientDigitalTwinService()

    private init() {}

    // MARK: - Search & List

    /// Searches customers assigned to the currently authenticated associate.
    /// Falls back to MockData when `AppConstants.useMockData` is true.
    func searchClients(query: String, associateId: UUID? = nil, limit: Int? = nil) async throws -> [ClientDigitalTwin] {
        let actualLimit = limit ?? AppConstants.App.pageSize

        if AppConstants.useMockData {
            if query.isEmpty {
                return MockData.clients
            } else {
                return MockData.clients.filter { $0.fullName.localizedCaseInsensitiveContains(query) }
            }
        }

        // Fetch from `customers` table (the actual table in the DB schema)
        var customers: [Customer]
        if let associateId = associateId {
            customers = try await SalesAssociateService.shared.fetchCustomers(
                associateId: associateId,
                searchQuery: query
            )
        } else {
            // Fallback: search all active customers when no associate scoping
            var dbQuery = supabase
                .from("customers")
                .select()
                .eq("is_active", value: "true")

            if !query.isEmpty {
                dbQuery = dbQuery.or("name.ilike.%\(query)%,email.ilike.%\(query)%,phone.ilike.%\(query)%")
            }

            customers = try await dbQuery
                .order("name")
                .limit(actualLimit)
                .execute()
                .value
        }

        return customers.map { mapCustomerToTwin($0) }
    }

    // MARK: - Fetch Full Passport

    /// Fetches a full ClientDigitalTwin for a given customer UUID.
    /// Enriches the base record with their sales history as events.
    func fetchFullTwin(clientID: UUID) async throws -> ClientDigitalTwin {
        if AppConstants.useMockData {
            guard let client = MockData.clients.first(where: { $0.id == clientID }) else {
                throw AppError.notFound("Client")
            }
            return client
        }

        // Fetch base customer record from `customers` table
        let customer = try await SalesAssociateService.shared.fetchCustomer(id: clientID)
        var twin = mapCustomerToTwin(customer)

        // Concurrently enrich with sales history as events
        async let salesReq: [Sale] = (try? supabase
            .from("sales")
            .select()
            .eq("customer_id", value: clientID.uuidString)
            .order("sale_date", ascending: false)
            .limit(20)
            .execute()
            .value) ?? []

        let sales = await salesReq

        // Map past sales to ClientDigitalTwinEvent objects
        let purchaseEvents: [ClientDigitalTwinEvent] = sales.map { sale in
            ClientDigitalTwinEvent(
                id: sale.id,
                clientID: clientID,
                date: sale.saleDate,
                type: .purchase,
                title: "Purchase — \(sale.invoiceNumber ?? sale.id.uuidString.prefix(8).description)",
                description: "Total: \(AppConstants.App.currencySymbol)\(String(format: "%.2f", sale.totalAmount)) via \(sale.paymentMethod)",
                location: nil,
                performedBy: sale.userId,
                linkedProductDigitalTwinID: nil,
                metadata: [
                    "total_amount": "\(sale.totalAmount)",
                    "payment_method": sale.paymentMethod,
                    "sale_status": sale.saleStatus
                ]
            )
        }
        twin.events = purchaseEvents.isEmpty ? nil : purchaseEvents

        // Build wishlist items from the `wishlist` text field (comma-separated entries)
        if let wishlistText = customer.wishlist, !wishlistText.isEmpty {
            let wishlistEntries = wishlistText
                .split(separator: ",")
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty }

            twin.wishlistItems = wishlistEntries.enumerated().map { idx, entry in
                WishlistItem(
                    id: UUID(),
                    clientID: clientID,
                    sku: "WISH-\(idx + 1)",
                    productName: entry,
                    addedDate: customer.createdAt ?? Date(),
                    addedBy: customer.assignedSalesAssociateId ?? UUID(),
                    isAvailable: false,
                    availableStores: [],
                    notifyOnRestock: true,
                    notes: nil
                )
            }
        }

        return twin
    }

    // MARK: - Create

    func createClient(
        _ client: ClientDigitalTwin,
        preferences: ClientPreferences?,
        sizes: SizeProfile?
    ) async throws -> ClientDigitalTwin {
        if AppConstants.useMockData {
            return client
        }

        // Insert into `customers` table using a mapped payload
        let payload = CustomerInsertPayload(from: client)
        let created: Customer = try await supabase
            .from("customers")
            .insert(payload, returning: .representation)
            .single()
            .execute()
            .value

        var twin = mapCustomerToTwin(created)

        // Add initial boutique visit event
        let initialEvent = ClientDigitalTwinEvent(
            id: UUID(),
            clientID: created.id,
            date: Date(),
            type: .boutiqueVisit,
            title: "First Boutique Visit",
            description: "Client profile created.",
            location: nil,
            performedBy: nil,
            linkedProductDigitalTwinID: nil,
            metadata: nil
        )
        twin.events = [initialEvent]

        return twin
    }

    // MARK: - Update

    func updateClient(clientID: UUID, updates: [String: AnyJSON]) async throws {
        try await supabase
            .from("customers")
            .update(updates)
            .eq("id", value: clientID.uuidString)
            .execute()
    }

    // MARK: - Add Event (stored locally on the twin; no DB table for events)

    func addEvent(_ event: ClientDigitalTwinEvent) async throws {
        // Events are derived from the `sales` table; no separate events table in the schema.
        // This is a no-op for now — future: insert into a client_events table if added.
        print("[ClientDigitalTwinService] Event logged locally: \(event.title)")
    }

    // MARK: - Wishlist (stored as text in customers.wishlist column)

    func addToWishlist(_ item: WishlistItem) async throws {
        // Fetch current wishlist, append entry, and update the text column
        let customer: Customer = try await supabase
            .from("customers")
            .select()
            .eq("id", value: item.clientID.uuidString)
            .single()
            .execute()
            .value

        let existingWishlist = customer.wishlist ?? ""
        let newEntry = item.productName
        let updated = existingWishlist.isEmpty ? newEntry : "\(existingWishlist), \(newEntry)"

        try await supabase
            .from("customers")
            .update(["wishlist": updated])
            .eq("id", value: item.clientID.uuidString)
            .execute()
    }

    func removeFromWishlist(itemID: UUID) async throws {
        // Without a dedicated wishlist table, we can't remove by UUID.
        // This method is a no-op until a wishlist table is added.
        print("[ClientDigitalTwinService] removeFromWishlist: requires dedicated wishlist table.")
    }

    // MARK: - DB → Domain Mapping

    /// Maps a `Customer` DB model to a `ClientDigitalTwin` domain model.
    func mapCustomerToTwin(_ customer: Customer) -> ClientDigitalTwin {
        // Split full name into first/last
        let parts = customer.name.split(separator: " ", maxSplits: 1)
        let firstName = parts.first.map(String.init) ?? customer.name
        let lastName  = parts.count > 1 ? String(parts[1]) : ""

        // Map customer_tier string to CustomerTier enum
        let tier = mapTier(customer.customerTier)

        // Derive lifetimeSpend from loyaltyPoints (1 point ≈ ₹500 spend)
        let loyaltyPts = customer.loyaltyPoints ?? 0
        let lifetimeSpend = Decimal(loyaltyPts) * 500

        var addressValue: String? = nil
        var notesValue: String? = customer.notes
        if let notesText = customer.notes, notesText.hasPrefix("Address: ") {
            let lines = notesText.split(separator: "\n", maxSplits: 1)
            if let firstLine = lines.first {
                addressValue = String(firstLine.dropFirst(9))
            }
            if lines.count > 1 {
                notesValue = String(lines[1])
            } else {
                notesValue = ""
            }
        }

        // Build preferences from available fields
        let prefs: ClientPreferences? = (customer.preferredBrand != nil || notesValue != nil || customer.preferredContactMethod != nil || customer.anniversaryDate != nil) ?
            ClientPreferences(
                clientID: customer.id,
                preferredBrands: customer.preferredBrand.map { [$0] } ?? [],
                preferredCategories: [],
                preferredColors: [],
                preferredMaterials: [],
                communicationChannel: mapContactMethod(customer.preferredContactMethod),
                languagePreference: "en",
                shoppingOccasions: [],
                anniversaryDate: customer.anniversaryDate,
                birthdayDate: customer.dateOfBirth,
                notes: notesValue,
                sizes: nil
            ) : nil

        // Build consent from privacy_consent flag
        let hasConsent = customer.privacyConsent ?? false
        let consent = ConsentRecord(
            clientID: customer.id,
            marketingEmail: hasConsent,
            marketingSMS: hasConsent,
            marketingWhatsApp: false,
            marketingPush: hasConsent,
            dataProcessing: hasConsent,
            profilingForRecommendations: hasConsent,
            consentDate: customer.createdAt ?? Date(),
            consentVersion: "v1.0",
            withdrawnDate: nil
        )

        let gdpr = GDPRFlags(
            clientID: customer.id,
            canStore: hasConsent,
            canProcess: hasConsent,
            canProfile: hasConsent,
            rightToErasureRequested: false,
            exportRequested: false
        )

        return ClientDigitalTwin(
            id: customer.id,
            customerID: customer.id,
            firstName: firstName,
            lastName: lastName,
            email: customer.email,
            phone: customer.phone,
            dateOfBirth: customer.dateOfBirth,
            gender: customer.gender,
            anniversaryDate: customer.anniversaryDate,
            address: addressValue,
            tier: tier,
            lifetimeSpend: lifetimeSpend,
            preferredStore: customer.assignedStoreId,
            preferredAdvisor: customer.assignedSalesAssociateId,
            createdAt: customer.createdAt ?? Date(),
            updatedAt: customer.createdAt ?? Date(),
            preferences: prefs,
            events: nil,
            ownedProducts: nil,
            wishlistItems: nil,
            consentStatus: consent,
            gdprFlags: gdpr
        )
    }

    // MARK: - Helpers

    private func mapTier(_ tier: String?) -> CustomerTier {
        switch tier?.lowercased() {
        case "vip":      return .vip
        case "vvip":     return .vip
        case "standard": return .standard
        case "regular":  return .regular
        default:         return .regular
        }
    }

    private func mapContactMethod(_ method: String?) -> CommunicationChannel {
        switch method?.lowercased() {
        case "sms":       return .sms
        case "email":     return .email
        case "whatsapp":  return .whatsapp
        case "push":      return .push
        default:          return .email
        }
    }
}

// MARK: - CustomerInsertPayload

/// Encodable payload for inserting into the `customers` table.
struct CustomerInsertPayload: Encodable {
    let name: String
    let email: String?
    let phone: String?
    let gender: String?
    let dateOfBirth: String?
    let anniversaryDate: String?
    let preferredBrand: String?
    let preferredCategory: String?
    let preferredContactMethod: String?
    let notes: String?
    let assignedSalesAssociateId: UUID?
    let assignedStoreId: UUID?
    let customerTier: String
    let customerStatus: String
    let isVip: Bool
    let isActive: Bool
    let privacyConsent: Bool
    let loyaltyPoints: Int

    enum CodingKeys: String, CodingKey {
        case name, email, phone, gender, notes
        case dateOfBirth             = "date_of_birth"
        case anniversaryDate         = "anniversary_date"
        case preferredBrand          = "preferred_brand"
        case preferredCategory       = "preferred_category"
        case preferredContactMethod  = "preferred_contact_method"
        case assignedSalesAssociateId = "assigned_sales_associate_id"
        case assignedStoreId         = "assigned_store_id"
        case customerTier            = "customer_tier"
        case customerStatus          = "customer_status"
        case isVip                   = "is_vip"
        case isActive                = "is_active"
        case privacyConsent          = "privacy_consent"
        case loyaltyPoints           = "loyalty_points"
    }

    init(from twin: ClientDigitalTwin) {
        self.name          = twin.fullName
        self.email         = twin.email
        self.phone         = twin.phone
        self.gender        = twin.gender
        
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        
        if let dob = twin.dateOfBirth {
            self.dateOfBirth = fmt.string(from: dob)
        } else {
            self.dateOfBirth = nil
        }
        
        if let anniv = twin.anniversaryDate {
            self.anniversaryDate = fmt.string(from: anniv)
        } else {
            self.anniversaryDate = nil
        }
        
        self.preferredBrand         = twin.preferences?.preferredBrands.first
        self.preferredCategory      = twin.preferences?.preferredCategories.first?.rawValue
        
        switch twin.preferences?.communicationChannel {
        case .sms:      self.preferredContactMethod = "SMS"
        case .email:    self.preferredContactMethod = "Email"
        case .whatsapp: self.preferredContactMethod = "WhatsApp"
        case .push:     self.preferredContactMethod = "Push"
        case .inApp:    self.preferredContactMethod = "Push"
        case .none:     self.preferredContactMethod = "Email"
        }
        
        if let addr = twin.address {
            self.notes = "Address: \(addr)\n\(twin.preferences?.notes ?? "")"
        } else {
            self.notes = twin.preferences?.notes
        }
        
        self.assignedSalesAssociateId = twin.preferredAdvisor
        self.assignedStoreId         = twin.preferredStore
        
        switch twin.tier {
        case .regular:  self.customerTier = "Regular"
        case .standard: self.customerTier = "Standard"
        case .vip:      self.customerTier = "VIP"
        }
        
        self.customerStatus = "Active"
        self.isVip          = twin.tier == .vip
        self.isActive       = true
        self.privacyConsent = twin.consentStatus?.dataProcessing ?? true
        
        let spendDouble = (twin.lifetimeSpend as NSDecimalNumber).doubleValue
        self.loyaltyPoints  = Int(spendDouble / 500.0)
    }
}
