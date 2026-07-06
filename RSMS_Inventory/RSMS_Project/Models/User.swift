//
//  User.swift
//  RSMS_Project
//
//  Created by Yatharth Mishra on 30/06/26.
//

import Foundation

struct User: Codable, Identifiable {
    let id: UUID
    let fullName: String
    let username: String
    let email: String?
    let roleId: UUID
    let storeId: UUID?
    let shiftId: UUID?
    let isVerified: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case fullName = "full_name"
        case username
        case email
        case roleId = "role_id"
        case storeId = "store_id"
        case shiftId = "shift_id"
        case isVerified = "is_verified"
    }
}
