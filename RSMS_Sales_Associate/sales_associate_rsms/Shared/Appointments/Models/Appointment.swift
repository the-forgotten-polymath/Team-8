// Appointment.swift
// RSMS — Sales Associate Module

import Foundation

struct Appointment: Identifiable, Codable {
    let id: UUID
    let clientId: UUID
    let associateId: UUID
    let date: Date
    let type: AppointmentType
    let notes: String?
    var status: AppointmentStatus
    
    // Remote selling linkage
    var curatedCartId: UUID?
    
    init(id: UUID = UUID(), clientId: UUID, associateId: UUID, date: Date, type: AppointmentType, notes: String? = nil, status: AppointmentStatus = .scheduled, curatedCartId: UUID? = nil) {
        self.id = id
        self.clientId = clientId
        self.associateId = associateId
        self.date = date
        self.type = type
        self.notes = notes
        self.status = status
        self.curatedCartId = curatedCartId
    }
}
