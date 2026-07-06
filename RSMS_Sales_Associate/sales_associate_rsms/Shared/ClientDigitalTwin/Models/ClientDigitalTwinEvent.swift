// ClientDigitalTwinEvent.swift
// RSMS — Sales Associate Module

import Foundation

struct ClientDigitalTwinEvent: Codable, Identifiable, Sendable {
    let id: UUID
    let clientID: UUID
    let date: Date
    let type: ClientEventType
    let title: String
    let description: String
    let location: String?
    let performedBy: UUID?              // Staff ID
    let linkedProductDigitalTwinID: UUID?
    let metadata: [String: String]?

    enum CodingKeys: String, CodingKey {
        case id
        case clientID = "client_id"
        case date
        case type
        case title
        case description
        case location
        case performedBy = "performed_by"
        case linkedProductDigitalTwinID = "linked_product_twin_id"
        case metadata
    }
}
