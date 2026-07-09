//
//  StaffMember.swift
//  RSMS_Project
//

import Foundation

struct StaffMember: Codable, Identifiable {
    let id: UUID
    let name: String
    let email: String
    let role: String
    let location: String
    let shift: String
    let imageName: String?
    let initials: String
    let isArchived: Bool
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case email
        case role
        case location
        case shift
        case imageName = "image_name"
        case initials
        case isArchived = "is_archived"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}
