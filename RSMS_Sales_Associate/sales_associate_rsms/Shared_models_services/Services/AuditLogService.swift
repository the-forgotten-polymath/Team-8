//
//  AuditLogService.swift
//  RSMS_Project
//

import Foundation
import Supabase

struct AuditLogInsertPayload: Encodable {
    let id: UUID
    let userId: UUID?
    let module: String
    let action: String
    let createdAt: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case module
        case action
        case createdAt = "created_at"
    }
}

final class AuditLogService {

    static let shared = AuditLogService()

    private let client = SupabaseManager.shared.client

    private init() {}

    func fetchRecent(limit: Int = 100) async throws -> [AuditLog] {
        return try await client
            .from("audit_logs")
            .select("*, users(full_name, designation, store_id)")
            .order("created_at", ascending: false)
            .limit(limit)
            .execute()
            .value
    }

    func fetchForStore(storeId: UUID, limit: Int = 50) async throws -> [AuditLog] {
        return try await client
            .from("audit_logs")
            .select("*, users(full_name, designation, store_id)")
            .eq("users.store_id", value: storeId.uuidString)
            .order("created_at", ascending: false)
            .limit(limit)
            .execute()
            .value
    }

    func search(query: String, limit: Int = 50) async throws -> [AuditLog] {
        return try await client
            .from("audit_logs")
            .select("*, users(full_name, designation, store_id)")
            .ilike("action", value: "%\(query)%")
            .order("created_at", ascending: false)
            .limit(limit)
            .execute()
            .value
    }

    func log(userId: UUID?, module: String, action: String) async throws {
        let now = Date()
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let dateStr = formatter.string(from: now)
        
        let payload = AuditLogInsertPayload(
            id: UUID(),
            userId: userId,
            module: module,
            action: action,
            createdAt: dateStr
        )
        
        _ = try await client
            .from("audit_logs")
            .insert(payload)
            .execute()
    }
}
