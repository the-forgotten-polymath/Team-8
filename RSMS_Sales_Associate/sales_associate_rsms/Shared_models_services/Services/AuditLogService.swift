//
//  AuditLogService.swift
//  RSMS_Project
//
//  audit_logs only stores (user_id, module, action, created_at).
//  userName/userRole are NOT columns — they come from a PostgREST
//  embed of `users` via the user_id foreign key, resolved at read time.
//

import Foundation
import Supabase

final class AuditLogService {

    private let client = SupabaseManager.shared.client

    /// Embed syntax: "*, users(full_name, designation, store_id)" pulls
    /// the related user row inline instead of a second round trip.
    private let selectWithUser = "*, users(full_name, designation, store_id)"

    /// Most recent audit entries, newest first.
    func fetchRecent(limit: Int = 100) async throws -> [AuditLog] {
        try await client
            .from("audit_logs")
            .select(selectWithUser)
            .order("created_at", ascending: false)
            .limit(limit)
            .execute()
            .value
    }

    /// Entries for users belonging to a single store — used by the Right
    /// Inspector Panel when drilling into "Related Records" for a store.
    /// audit_logs has no store_id column, so we filter on the *embedded*
    /// users.store_id, which requires an inner join (users!inner) for
    /// PostgREST to allow filtering through the embed.
    func fetchForStore(storeId: UUID, limit: Int = 50) async throws -> [AuditLog] {
        try await client
            .from("audit_logs")
            .select("*, users!inner(full_name, designation, store_id)")
            .eq("users.store_id", value: storeId)
            .order("created_at", ascending: false)
            .limit(limit)
            .execute()
            .value
    }

    /// Free-text search across module/action — backs the Record Explorer.
    /// (No entity_label column to search, since we don't store one.)
    func search(query: String, limit: Int = 50) async throws -> [AuditLog] {
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else {
            return try await fetchRecent(limit: limit)
        }
        return try await client
            .from("audit_logs")
            .select(selectWithUser)
            .or("action.ilike.%\(query)%,module.ilike.%\(query)%")
            .order("created_at", ascending: false)
            .limit(limit)
            .execute()
            .value
    }

    /// Writes a business-action entry. Call this from feature services
    /// (ProductService, InventoryService, etc.) whenever a user performs
    /// an action worth auditing. Write the description directly into
    /// `action` (e.g. "Approved shipment SHP-10245") since there's no
    /// separate entity_label column to reconstruct it from later.
    func log(userId: UUID?, module: String, action: String) async throws {
        struct NewAuditLog: Encodable {
            let user_id: UUID?
            let module: String
            let action: String
        }
        try await client
            .from("audit_logs")
            .insert(NewAuditLog(user_id: userId, module: module, action: action))
            .execute()
    }
}
