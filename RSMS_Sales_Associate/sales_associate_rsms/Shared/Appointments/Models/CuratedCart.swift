// CuratedCart.swift
// RSMS — Sales Associate Module

import Foundation

struct CuratedCart: Identifiable, Codable {
    let id: UUID
    let appointmentId: UUID
    let clientId: UUID
    
    var productIds: [UUID]
    var stylingNotes: String
    var status: CartStatus
    var shareableLink: String?
    
    init(id: UUID = UUID(), appointmentId: UUID, clientId: UUID, productIds: [UUID] = [], stylingNotes: String = "", status: CartStatus = .draft, shareableLink: String? = nil) {
        self.id = id
        self.appointmentId = appointmentId
        self.clientId = clientId
        self.productIds = productIds
        self.stylingNotes = stylingNotes
        self.status = status
        self.shareableLink = shareableLink
    }
}
