//
//  LeaveRequest.swift
//  RSMS_Project
//
//  Created by Yatharth Mishra on 30/06/26.
//

import Foundation

struct LeaveRequest: Codable, Identifiable {
    let id: UUID
    let employeeId: UUID
    let status: String // "pending", "approved", "rejected"
    let isUrgent: Bool
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case employeeId = "employee_id"
        case status
        case isUrgent = "is_urgent"
        case createdAt = "created_at"
    }
}
