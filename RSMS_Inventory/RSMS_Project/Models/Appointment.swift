//
//  Appointment.swift
//  RSMS_Project
//
//  Created by Yatharth Mishra on 30/06/26.
//

import Foundation

struct Appointment: Codable, Identifiable {
    let id: UUID
    let customerId: UUID?
    let storeId: UUID
    let salesAssociateId: UUID?
    let appointmentDatetime: Date
    let description: String?
    let status: String
    let createdBy: UUID
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case customerId = "customer_id"
        case storeId = "store_id"
        case salesAssociateId = "sales_associate_id"
        case appointmentDatetime = "appointment_datetime"
        case description
        case status
        case createdBy = "created_by"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}
