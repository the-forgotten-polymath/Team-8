//
//  CertificateManager.swift
//  RSMS_Project
//

import Foundation
import Combine

@MainActor
final class CertificateManager: ObservableObject {
    static let shared = CertificateManager()
    
    @Published var certificates: [DigitalProductCertificate] = []
    
    private init() {
        loadCertificates()
    }
    
    // Save to UserDefaults for persistence without db schema changes
    private func saveCertificates() {
        do {
            let data = try JSONEncoder().encode(certificates)
            UserDefaults.standard.set(data, forKey: "rsms_digital_product_certificates")
        } catch {
            print("Failed to save certificates: \(error)")
        }
    }
    
    private func loadCertificates() {
        if let data = UserDefaults.standard.data(forKey: "rsms_digital_product_certificates") {
            do {
                let decoded = try JSONDecoder().decode([DigitalProductCertificate].self, from: data)
                self.certificates = decoded
            } catch {
                print("Failed to load certificates: \(error)")
                self.certificates = []
            }
        }
    }
    
    func getCertificate(for serialNumber: String) -> DigitalProductCertificate? {
        let norm = serialNumber.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        return certificates.first { $0.serialNumber.trimmingCharacters(in: .whitespacesAndNewlines).uppercased() == norm }
    }
    
    func createCertificate(
        serialNumber: String,
        product: Product,
        storeName: String,
        storeLocation: String,
        language: String
    ) -> DigitalProductCertificate {
        // Retrieve certificate number count
        let certNumber = String(format: "CERT-%06d", certificates.count + 1 + 344)
        
        let newCert = DigitalProductCertificate(
            id: UUID(),
            certificateNumber: certNumber,
            serialNumber: serialNumber,
            productId: product.id,
            productName: product.productName,
            brand: product.brand,
            issueDate: Date(),
            storeName: storeName,
            storeLocation: storeLocation,
            language: language,
            printStatus: "Printed"
        )
        
        certificates.append(newCert)
        saveCertificates()
        return newCert
    }
    
    // Map destination string to appropriate Store details and Language
    func getStoreDetailsAndLanguage(for destination: String) -> (storeName: String, storeLocation: String, language: String) {
        let lower = destination.lowercased()
        if lower.contains("paris") || lower.contains("france") || lower.contains("store002") {
            return ("Boutique Paris", "Paris, France", "French")
        } else if lower.contains("tokyo") || lower.contains("japan") || lower.contains("store003") {
            return ("Boutique Tokyo", "Tokyo, Japan", "Japanese")
        } else if lower.contains("dubai") || lower.contains("uae") || lower.contains("store004") {
            return ("Boutique Dubai", "Dubai, UAE", "Arabic")
        } else {
            return ("Boutique New York", "New York, USA", "English")
        }
    }
}
