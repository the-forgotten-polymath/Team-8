//
//  Customer.swift
//  RSMS_Project
//
//  Created by Yatharth Mishra on 30/06/26.
//

import Foundation

struct Customer: Codable, Identifiable {
    let id: UUID
    let name: String
    let phone: String
    let email: String
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case phone
        case email
        case createdAt = "created_at"
    }
}
