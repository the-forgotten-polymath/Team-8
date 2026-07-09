//
//  CertificateView.swift
//  RSMS_Project
//

import SwiftUI

struct CertificatePresentationInfo: Identifiable {
    let id = UUID()
    let serialNumber: String
    let product: Product
    let destination: String
}

struct CertificateView: View {
    let info: CertificatePresentationInfo
    var onPrintCompleted: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    @StateObject private var certificateManager = CertificateManager.shared
    
    @State private var isPrinting = false
    @State private var printSuccess = false
    
    // Check if certificate already exists
    private var existingCertificate: DigitalProductCertificate? {
        certificateManager.getCertificate(for: info.serialNumber)
    }
    
    // Store configurations mapped from shipment destination
    private var storeDetails: (storeName: String, storeLocation: String, language: String) {
        certificateManager.getStoreDetailsAndLanguage(for: info.destination)
    }
    
    // Selected language for certificate localization
    private var activeLanguage: String {
        existingCertificate?.language ?? storeDetails.language
    }
    
    // Localized labels structure
    private var labels: LocalizedLabels {
        LocalizedLabels.get(for: activeLanguage)
    }
    
    // Formatted Issue Date
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: existingCertificate?.issueDate ?? Date())
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        
                        // --- THE LUXURY CERTIFICATE CARD PREVIEW ---
                        VStack(spacing: 20) {
                            // Header: Brand & Title
                            VStack(spacing: 8) {
                                Text(info.product.brand.uppercased())
                                    .font(.system(.title3, design: .serif))
                                    .fontWeight(.bold)
                                    .tracking(4)
                                    .foregroundColor(.primary)
                                
                                Text(labels.title)
                                    .font(.system(.caption, design: .serif))
                                    .fontWeight(.medium)
                                    .tracking(2)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.top, 10)
                            
                            Divider()
                                .background(Color.secondary.opacity(0.3))
                            
                            // Certificate details grid
                            VStack(spacing: 14) {
                                detailRow(label: labels.model, value: info.product.productName)
                                detailRow(label: labels.brand, value: info.product.brand)
                                detailRow(label: labels.serial, value: info.serialNumber)
                                
                                detailRow(
                                    label: labels.certNo,
                                    value: existingCertificate?.certificateNumber ?? "Auto-Generated Upon Print"
                                )
                                
                                detailRow(label: labels.issueDate, value: formattedDate)
                                
                                detailRow(
                                    label: labels.store,
                                    value: existingCertificate?.storeName ?? storeDetails.storeName
                                )
                                
                                detailRow(
                                    label: labels.location,
                                    value: existingCertificate?.storeLocation ?? storeDetails.storeLocation
                                )
                            }
                            
                            Divider()
                                .background(Color.secondary.opacity(0.3))
                            
                            // Authenticity Statement & Seal
                            VStack(spacing: 12) {
                                Text(labels.statement)
                                    .font(.system(.subheadline, design: .serif))
                                    .italic()
                                    .multilineTextAlignment(.center)
                                    .foregroundColor(.primary)
                                    .padding(.horizontal, 10)
                                
                                // Fake Luxury Seal Graphic
                                Image(systemName: "seal.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(existingCertificate != nil ? .green : .blue)
                                    .overlay(
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundColor(.white)
                                    )
                            }
                            .padding(.bottom, 10)
                        }
                        .padding(24)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(UIColor.secondarySystemGroupedBackground))
                                .shadow(color: Color.black.opacity(0.08), radius: 15, x: 0, y: 10)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.secondary.opacity(0.2), lineWidth: 1.5)
                        )
                        .padding(.horizontal)
                        
                        // Print/Link Button
                        if existingCertificate == nil {
                            Button(action: startPrintProcess) {
                                HStack {
                                    Image(systemName: "link")
                                    Text(labels.linkCertificate)
                                        .fontWeight(.bold)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                                .padding(.horizontal)
                            }
                            .disabled(isPrinting)
                        } else {
                            Button(action: { dismiss() }) {
                                Text("Close")
                                    .fontWeight(.bold)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(Color(.systemGray5))
                                    .foregroundColor(.primary)
                                    .cornerRadius(12)
                                    .padding(.horizontal)
                            }
                        }
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("Product Certificate")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(existingCertificate != nil ? "Done" : "Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.blue)
                }
            }
            .overlay {
                if isPrinting {
                    ZStack {
                        Color.black.opacity(0.4)
                            .ignoresSafeArea()
                        
                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.5)
                                .tint(.white)
                            
                            Text("Linking Product Certificate...")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            Text("Language: \(activeLanguage)")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.8))
                        }
                        .padding(24)
                        .background(Color(.systemBackground).opacity(0.2))
                        .cornerRadius(16)
                    }
                }
            }
        }
    }
    
    private func detailRow(label: String, value: String) -> some View {
        HStack(alignment: .top) {
            Text(label)
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.secondary)
                .frame(width: 120, alignment: .leading)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .foregroundColor(.primary)
                .multilineTextAlignment(.trailing)
        }
    }
    
    private func startPrintProcess() {
        isPrinting = true
        
        // Simulate printer sending delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            isPrinting = false
            
            // Create certificate in CertificateManager
            _ = CertificateManager.shared.createCertificate(
                serialNumber: info.serialNumber,
                product: info.product,
                storeName: storeDetails.storeName,
                storeLocation: storeDetails.storeLocation,
                language: storeDetails.language
            )
            
            // Call verification completed callback to switch back or proceed
            onPrintCompleted()
            dismiss()
        }
    }
}

// Localized Labels Mapping
struct LocalizedLabels {
    let title: String
    let model: String
    let brand: String
    let serial: String
    let certNo: String
    let issueDate: String
    let store: String
    let location: String
    let statement: String
    let linkCertificate: String
    
    static func get(for language: String) -> LocalizedLabels {
        switch language {
        case "French":
            return LocalizedLabels(
                title: "CERTIFICAT D'AUTHENTICITÉ",
                model: "Modèle",
                brand: "Marque",
                serial: "Numéro de Série",
                certNo: "N° de Certificat",
                issueDate: "Date d'Émission",
                store: "Boutique",
                location: "Emplacement",
                statement: "Ce certificat garantit l'authenticité de ce produit de luxe.",
                linkCertificate: "Lier le certificat"
            )
        case "Japanese":
            return LocalizedLabels(
                title: "真正性証明書",
                model: "モデル",
                brand: "ブランド",
                serial: "シリアル番号",
                certNo: "証明書番号",
                issueDate: "発行日",
                store: "ブティック",
                location: "場所",
                statement: "この証明書は、この高級製品の真正性を保証するものです。",
                linkCertificate: "証明書をリンク"
            )
        case "Arabic":
            return LocalizedLabels(
                title: "شهادة الأصالة",
                model: "الموديل",
                brand: "العلامة التجارية",
                serial: "الرقم التسلسلي",
                certNo: "رقم الشهادة",
                issueDate: "تاريخ الإصدار",
                store: "البوتيك",
                location: "الموقع",
                statement: "هذه الشهادة تضمن أصالة هذا المنتج الفاخر.",
                linkCertificate: "ربط الشهادة"
            )
        default:
            return LocalizedLabels(
                title: "AUTHENTICITY CERTIFICATE",
                model: "Model",
                brand: "Brand",
                serial: "Serial Number",
                certNo: "Certificate No.",
                issueDate: "Issue Date",
                store: "Boutique",
                location: "Location",
                statement: "This certificate guarantees the authenticity of this luxury product.",
                linkCertificate: "Link Certificate"
            )
        }
    }
}
