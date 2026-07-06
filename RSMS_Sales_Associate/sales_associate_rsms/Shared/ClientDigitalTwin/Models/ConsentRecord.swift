// ConsentRecord.swift
// RSMS — Sales Associate Module

import Foundation

struct ConsentRecord: Codable, Sendable {
    let clientID: UUID
    var marketingEmail: Bool
    var marketingSMS: Bool
    var marketingWhatsApp: Bool
    var marketingPush: Bool
    var dataProcessing: Bool
    var profilingForRecommendations: Bool
    var consentDate: Date
    var consentVersion: String
    var withdrawnDate: Date?

    enum CodingKeys: String, CodingKey {
        case clientID = "client_id"
        case marketingEmail = "marketing_email"
        case marketingSMS = "marketing_sms"
        case marketingWhatsApp = "marketing_whatsapp"
        case marketingPush = "marketing_push"
        case dataProcessing = "data_processing"
        case profilingForRecommendations = "profiling_for_recommendations"
        case consentDate = "consent_date"
        case consentVersion = "consent_version"
        case withdrawnDate = "withdrawn_date"
    }
}

struct GDPRFlags: Codable, Sendable {
    let clientID: UUID
    var canStore: Bool
    var canProcess: Bool
    var canProfile: Bool
    var rightToErasureRequested: Bool
    var exportRequested: Bool

    enum CodingKeys: String, CodingKey {
        case clientID = "client_id"
        case canStore = "can_store"
        case canProcess = "can_process"
        case canProfile = "can_profile"
        case rightToErasureRequested = "right_to_erasure_requested"
        case exportRequested = "export_requested"
    }
}
