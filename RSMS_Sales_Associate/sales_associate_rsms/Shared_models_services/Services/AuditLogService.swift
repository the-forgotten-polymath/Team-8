//
//  AuditLogService.swift
//  RSMS_Project
//
//  NOTE: audit_logs table does not exist in the current schema.
//  This service is disabled until the table is added to the database.
//

import Foundation

final class AuditLogService {

    static let shared = AuditLogService()

    private init() {}

    /// Disabled - audit_logs table not in schema
    func fetchRecent(limit: Int = 100) async throws -> [AuditLog] {
        return []
    }

    /// Disabled - audit_logs table not in schema
    func fetchForStore(storeId: UUID, limit: Int = 50) async throws -> [AuditLog] {
        return []
    }

    /// Disabled - audit_logs table not in schema
    func search(query: String, limit: Int = 50) async throws -> [AuditLog] {
        return []
    }

    /// Disabled - audit_logs table not in schema
    func log(userId: UUID?, module: String, action: String) async throws {
        // No-op - table doesn't exist in schema
    }
}
