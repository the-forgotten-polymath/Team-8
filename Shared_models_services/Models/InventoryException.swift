//
//  InventoryException.swift
//  RSMS_Project
//
//  Created by Yatharth Mishra on 30/06/26.
//



import Foundation

struct InventoryException: Identifiable, Decodable {
    let id: UUID
    let shipmentId: UUID?
    let storeId: UUID
    let productId: UUID?
    let exceptionType: String
    let priority: String
    let status: String
    let remarks: String?
    let reportedBy: UUID?
    let createdAt: Date
    let resolvedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case shipmentId = "shipment_id"
        case storeId = "store_id"
        case productId = "product_id"
        case exceptionType = "exception_type"
        case priority
        case status
        case remarks
        case reportedBy = "reported_by"
        case createdAt = "created_at"
        case resolvedAt = "resolved_at"
    }

    /// Sentence-case label for card headers, e.g. "Planogram failure".
    var displayTitle: String {
        exceptionType.replacingOccurrences(of: "_", with: " ").capitalized
    }

    /// Your real `priority` values are Low/Medium/High (from column default
    /// 'Medium') — no 'critical' value exists yet. Treat High as critical.
    /// Add a 'Critical' value to the check-free `priority` text column
    /// yourself if you want a harder tier; no migration needed either way
    /// since it's a plain text column.
    var isCritical: Bool { priority.caseInsensitiveCompare("High") == .orderedSame }
}
