//
//  CycleCount.swift
//  RSMS_Project
//
//  Created by Yatharth Mishra on 30/06/26.
//

import Foundation

struct CycleCount: Identifiable, Codable {
    let id: UUID
    let warehouseId: UUID
    let scheduledDate: Date
    let completedDate: Date?
    let status: String
    let createdBy: UUID
    let remarks: String?
    let createdAt: Date
    let zone: String?

    enum CodingKeys: String, CodingKey {
        case id
        case warehouseId = "warehouse_id"
        case scheduledDate = "scheduled_date"
        case completedDate = "completed_date"
        case status
        case createdBy = "created_by"
        case remarks
        case createdAt = "created_at"
        case zone
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        warehouseId = try container.decode(UUID.self, forKey: .warehouseId)
        
        // Flexible decoding for scheduledDate
        scheduledDate = try Self.decodeFlexibleDate(from: container, key: .scheduledDate)
        
        // Flexible decoding for completedDate
        completedDate = try Self.decodeFlexibleDateIfPresent(from: container, key: .completedDate)
        
        status = try container.decode(String.self, forKey: .status)
        createdBy = try container.decode(UUID.self, forKey: .createdBy)
        remarks = try container.decodeIfPresent(String.self, forKey: .remarks)
        
        // Flexible decoding for createdAt
        createdAt = try Self.decodeFlexibleDate(from: container, key: .createdAt)
        
        // Safety: If zone is not present in the JSON payload (e.g. database schema not updated yet), default to nil
        if container.contains(.zone) {
            zone = try container.decodeIfPresent(String.self, forKey: .zone)
        } else {
            zone = nil
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(warehouseId, forKey: .warehouseId)
        try container.encode(scheduledDate, forKey: .scheduledDate)
        try container.encodeIfPresent(completedDate, forKey: .completedDate)
        try container.encode(status, forKey: .status)
        try container.encode(createdBy, forKey: .createdBy)
        try container.encodeIfPresent(remarks, forKey: .remarks)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encodeIfPresent(zone, forKey: .zone)
    }

    // MARK: - Date Decoding Helpers

    private static func decodeFlexibleDate(from container: KeyedDecodingContainer<CodingKeys>, key: CodingKeys) throws -> Date {
        if let dateStr = try? container.decode(String.self, forKey: key) {
            if let date = parseDateString(dateStr) {
                return date
            }
        }
        return try container.decode(Date.self, forKey: key)
    }

    private static func decodeFlexibleDateIfPresent(from container: KeyedDecodingContainer<CodingKeys>, key: CodingKeys) throws -> Date? {
        guard container.contains(key) else { return nil }
        if let dateStr = try? container.decodeIfPresent(String.self, forKey: key) {
            if let date = parseDateString(dateStr) {
                return date
            }
        }
        return try container.decodeIfPresent(Date.self, forKey: key)
    }

    private static func parseDateString(_ string: String) -> Date? {
        let formats = [
            "yyyy-MM-dd",
            "yyyy-MM-dd'T'HH:mm:ss",
            "yyyy-MM-dd'T'HH:mm:ss.SSS",
            "yyyy-MM-dd'T'HH:mm:ss.SSSSSS",
            "yyyy-MM-dd'T'HH:mm:ssZ",
            "yyyy-MM-dd HH:mm:ss"
        ]
        
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        
        for format in formats {
            formatter.dateFormat = format
            if let date = formatter.date(from: string) {
                return date
            }
        }
        return nil
    }
}
