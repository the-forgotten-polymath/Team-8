//
//  ActivityLog.swift
//  RSMS_Project
//

import Foundation
import Supabase

struct ActivityLog: Codable, Identifiable {
    let id: UUID
    let tableName: String
    let operation: String
    let recordId: UUID
    let recordName: String?
    let changedBy: String?
    let payload: AnyJSON?
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case tableName = "table_name"
        case operation
        case recordId = "record_id"
        case recordName = "record_name"
        case changedBy = "changed_by"
        case payload
        case createdAt = "created_at"
    }
}
