//
//  AuditLog.swift
//  RSMS_Project
//
//  Created by Yatharth Mishra on 30/06/26.
//

import Foundation

struct AuditLog: Identifiable, Decodable {
    let id: UUID
    let userId: UUID?
    let module: String
    let action: String
    let createdAt: Date

    /// Populated via the `users(full_name, designation, store_id)` embed
    /// in AuditLogService — NOT a column on audit_logs.
    let embeddedUser: EmbeddedUser?

    private enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case module
        case action
        case createdAt = "created_at"
        case users // PostgREST embed key, named after the FK's target table
    }

    struct EmbeddedUser: Decodable {
        let fullName: String
        let designation: String?
        let storeId: UUID?

        private enum CodingKeys: String, CodingKey {
            case fullName = "full_name"
            case designation
            case storeId = "store_id"
        }
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        userId = try c.decodeIfPresent(UUID.self, forKey: .userId)
        module = try c.decode(String.self, forKey: .module)
        action = try c.decode(String.self, forKey: .action)
        createdAt = try c.decode(Date.self, forKey: .createdAt)
        embeddedUser = try c.decodeIfPresent(EmbeddedUser.self, forKey: .users)
    }

    /// Falls back to "System" when the log has no user_id (e.g. automated jobs)
    /// or the caller fetched without the users embed.
    var userName: String { embeddedUser?.fullName ?? "System" }
    var userRole: String? { embeddedUser?.designation }
    var userStoreId: UUID? { embeddedUser?.storeId }

    /// Human-readable one-liner for the timeline. `action` is already
    /// written as a sentence by whatever code calls AuditLogService.log(...)
    /// (e.g. "Approved shipment SHP-10245"), so we just clean up casing —
    /// there's no separate entity_label column to append.
    var narratedAction: String {
        action.prefix(1).uppercased() + action.dropFirst()
    }
}
