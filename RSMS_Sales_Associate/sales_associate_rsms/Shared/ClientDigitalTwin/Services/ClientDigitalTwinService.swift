// ClientDigitalTwinService.swift
// RSMS — Sales Associate Module

import Foundation
@preconcurrency import Supabase

@MainActor
final class ClientDigitalTwinService: Sendable {
    static let shared = ClientDigitalTwinService()

    private init() {}

    // MARK: - Search & List

    func searchClients(query: String, limit: Int? = nil) async throws -> [ClientDigitalTwin] {
        let actualLimit = limit ?? AppConstants.App.pageSize
        if AppConstants.useMockData {
            if query.isEmpty {
                return MockData.clients
            } else {
                return MockData.clients.filter { $0.fullName.localizedCaseInsensitiveContains(query) }
            }
        }
        
        var request = supabase.from("clients").select()
        
        if !query.isEmpty {
            // Assuming pg_trgm and a generated column or searching across multiple fields
            // For simplicity, we use ilike on first_name, last_name, email, phone
            request = request.or("first_name.ilike.%\(query)%,last_name.ilike.%\(query)%,email.ilike.%\(query)%,phone.ilike.%\(query)%")
        }
        
        return try await request
            .order("last_name", ascending: true)
            .limit(actualLimit)
            .execute()
            .value
    }

    // MARK: - Fetch Full Passport

    func fetchFullTwin(clientID: UUID) async throws -> ClientDigitalTwin {
        if AppConstants.useMockData {
            guard let client = MockData.clients.first(where: { $0.id == clientID }) else {
                throw URLError(.badURL) // arbitrary error for mock failure
            }
            return client
        }
        
        // Fetch base client
        var client: ClientDigitalTwin = try await supabase
            .from("clients")
            .select()
            .eq("id", value: clientID.uuidString)
            .single()
            .execute()
            .value

        // Fetch relationships concurrently
        async let prefReq: ClientPreferences? = try? supabase.from("client_preferences").select().eq("client_id", value: clientID.uuidString).single().execute().value
        async let sizesReq: SizeProfile? = try? supabase.from("client_sizes").select().eq("client_id", value: clientID.uuidString).single().execute().value
        async let eventsReq: [ClientDigitalTwinEvent] = (try? supabase.from("client_events").select().eq("client_id", value: clientID.uuidString).order("date", ascending: false).execute().value) ?? []
        async let wishlistReq: [WishlistItem] = (try? supabase.from("wishlist_items").select().eq("client_id", value: clientID.uuidString).order("added_date", ascending: false).execute().value) ?? []
        async let consentReq: ConsentRecord? = try? supabase.from("consent_records").select().eq("client_id", value: clientID.uuidString).single().execute().value
        async let gdprReq: GDPRFlags? = try? supabase.from("gdpr_flags").select().eq("client_id", value: clientID.uuidString).single().execute().value
        async let ownedReq: [OwnedProduct] = (try? supabase.from("owned_products").select().eq("client_id", value: clientID.uuidString).order("purchase_date", ascending: false).execute().value) ?? []

        client.preferences = await prefReq
        client.preferences?.sizes = await sizesReq
        client.events = await eventsReq
        client.wishlistItems = await wishlistReq
        client.consentStatus = await consentReq
        client.gdprFlags = await gdprReq
        client.ownedProducts = await ownedReq

        return client
    }

    // MARK: - Create

    func createClient(_ client: ClientDigitalTwin, preferences: ClientPreferences?, sizes: SizeProfile?) async throws -> ClientDigitalTwin {
        if AppConstants.useMockData {
            // For now, in mock mode, just return the passed client.
            // In a more complex mock, we could append this to MockData.clients.
            return client
        }
        
        // Create base client
        let created: ClientDigitalTwin = try await supabase
            .from("clients")
            .insert(client, returning: .representation)
            .single()
            .execute()
            .value

        if let pref = preferences {
            _ = try? await supabase.from("client_preferences").insert(pref).execute()
        }
        if let sz = sizes {
            _ = try? await supabase.from("client_sizes").insert(sz).execute()
        }
        
        // Add initial event
        let initialEvent = ClientDigitalTwinEvent(
            id: UUID(),
            clientID: created.id,
            date: Date(),
            type: .boutiqueVisit,
            title: "First Boutique Visit",
            description: "Client profile created.",
            location: nil,
            performedBy: nil, // Will be set by RLS or auth context if available
            linkedProductDigitalTwinID: nil,
            metadata: nil
        )
        _ = try? await addEvent(initialEvent)

        return created
    }

    // MARK: - Update

    func updateClient(clientID: UUID, updates: [String: AnyJSON]) async throws {
        try await supabase
            .from("clients")
            .update(updates)
            .eq("id", value: clientID.uuidString)
            .execute()
    }

    // MARK: - Add Event

    func addEvent(_ event: ClientDigitalTwinEvent) async throws {
        try await supabase
            .from("client_events")
            .insert(event)
            .execute()
    }

    // MARK: - Wishlist

    func addToWishlist(_ item: WishlistItem) async throws {
        try await supabase
            .from("wishlist_items")
            .insert(item)
            .execute()
    }
    
    func removeFromWishlist(itemID: UUID) async throws {
        try await supabase
            .from("wishlist_items")
            .delete()
            .eq("id", value: itemID.uuidString)
            .execute()
    }
}
