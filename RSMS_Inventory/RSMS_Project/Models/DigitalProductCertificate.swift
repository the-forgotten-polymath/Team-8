//
//  DigitalProductCertificate.swift
//  RSMS_Project
//

import Foundation

struct DigitalProductCertificate: Codable, Identifiable {
    let id: UUID
    let certificateNumber: String
    let serialNumber: String
    let productId: UUID
    let productName: String
    let brand: String
    let issueDate: Date
    let storeName: String
    let storeLocation: String
    let language: String
    let printStatus: String
}
