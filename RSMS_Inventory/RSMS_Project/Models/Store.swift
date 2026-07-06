//
//  Store.swift
//  RSMS_Project
//
//  Created by Yatharth Mishra on 30/06/26.
//

import Foundation

struct Store: Codable, Identifiable {
    let id: UUID
    let storeName: String
    let pinCode: String?
    let region: String?
    let country: String?
    let city: String?
    let status: String
    let managerId: UUID?
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case storeName = "name"
        case pinCode = "pin_code"
        case region
        case country
        case city
        case status
        case managerId = "manager_id"
        case createdAt = "created_at"
    }
}
