//
//  ShipmentDetailView.swift
//  RSMS_Project
//
//  Created by Yatharth Mishra on 30/06/26.
//

import SwiftUI

struct ShipmentDetailView: View {
    let shipment: Shipment
    let warehouseId: UUID
    let userId: UUID
    
    @StateObject private var viewModel = ShipmentVerificationViewModel()
    @State private var isShowingScanner = false
    @State private var showConfirmDialog = false
    @State private var batchCreatedCertificatesCount = 0
    
    @Environment(\.dismiss) private var dismiss
    
    private func displayStatus(for shipment: Shipment) -> String {
        let lower = shipment.status.lowercased()
        if lower == "verified" || lower == "arrived" {
            return "arrived"
        }
        return lower
    }
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // Shipment Info Header Card
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text(shipment.asnNumber ?? "No ASN Number")
                            .font(.title3)
                            .fontWeight(.bold)
                        Spacer()
                        StatusChip(status: displayStatus(for: shipment))
                    }
                    
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Label {
                            Text("Source: \(shipment.source)")
                        } icon: {
                            Image(systemName: "arrow.up.right.circle.fill").foregroundColor(.blue)
                        }
                        
                        Label {
                            Text("Destination: \(shipment.destination)")
                        } icon: {
                            Image(systemName: "arrow.down.left.circle.fill").foregroundColor(.green)
                        }
                        
                        if let ref = shipment.trackingReference {
                            Label {
                                Text("Tracking: \(ref)")
                            } icon: {
                                Image(systemName: "number.square").foregroundColor(.secondary)
                            }
                        }
                    }
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(UIColor.secondarySystemGroupedBackground))
                .cornerRadius(16)
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.appleBorder, lineWidth: 1))
                .padding()
                
                // Items List Header
                HStack {
                    Text("Shipment Items")
                        .font(.headline)
                        .foregroundColor(.primary)
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.bottom, 8)
                
                if viewModel.isLoading {
                    LoadingView(message: "Loading shipment items...")
                } else {
                    List {
                        ForEach(viewModel.shipmentItems) { item in
                            let product = viewModel.products.first { $0.id == item.productId }
                            let scanned = viewModel.scannedQuantities[item.productId] ?? 0
                            
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(product?.productName ?? "Unknown Product")
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                        Text("SKU: \(product?.sku ?? "Unknown")")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    if displayStatus(for: shipment) == "arrived" {
                                        Text("Arrived")
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(Color.green)
                                            .cornerRadius(4)
                                    } else {
                                        let status = viewModel.statusColor(for: item.productId)
                                        Text(status)
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(
                                                status == "Matched" ? Color.green :
                                                (status == "Extra Item" ? Color.red : Color.orange)
                                            )
                                            .cornerRadius(4)
                                    }
                                }
                                
                                // Progress Info
                                let expected = item.expectedQuantity
                                let received = displayStatus(for: shipment) == "arrived" ? item.receivedQuantity : scanned
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    // Custom Progress Bar
                                    GeometryReader { geo in
                                        ZStack(alignment: .leading) {
                                            Capsule()
                                                .fill(Color(.systemGray5))
                                                .frame(height: 6)
                                            
                                            let progressWidth = expected > 0 ? (CGFloat(received) / CGFloat(expected)) * geo.size.width : 0
                                            let barColor = received == expected ? Color.green : (received > expected ? Color.red : Color.orange)
                                            
                                            Capsule()
                                                .fill(barColor)
                                                .frame(width: min(progressWidth, geo.size.width), height: 6)
                                        }
                                    }
                                    .frame(height: 6)
                                    
                                    HStack {
                                        Spacer()
                                        Text("\(received) / \(expected)")
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .padding(.top, 2)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .listStyle(.plain)
                }
                
                // Bottom CTAs
                if shipment.status.lowercased() == "pending" {
                    VStack(spacing: 12) {
                        PrimaryButton("Scan QR Codes", iconName: "qrcode.viewfinder") {
                            isShowingScanner = true
                        }
                        
                        Button(action: {
                            showConfirmDialog = true
                        }) {
                            Text(viewModel.isAllMatched ? "Mark as Verified" : "Verify with Discrepancy")
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(viewModel.isAllMatched ? Color.green : Color.orange)
                                .foregroundColor(.white)
                                .fontWeight(.semibold)
                                .cornerRadius(12)
                        }
                    }
                    .padding()
                }
            }
            
            if viewModel.isLoading {
                LoadingView(message: "Submitting verification...")
            }
        }
        .navigationTitle("Shipment Details")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadShipmentItems(shipmentId: shipment.id)
        }
        .sheet(isPresented: $isShowingScanner) {
            QRScannerView(onScan: { qrCodeValue in
                return viewModel.scanQRCode(value: qrCodeValue)
            })
        }
        .alert("Verification Complete", isPresented: $viewModel.isVerifiedSuccess) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("Shipment verified. Certificates generated for \(batchCreatedCertificatesCount) products.\n\nShipment has been successfully verified, and inventory quantities have been adjusted.")
        }
        .confirmationDialog("Are you sure you want to verify this shipment?", isPresented: $showConfirmDialog, titleVisibility: .visible) {
            Button("Confirm & Update Inventory") {
                Swift.Task {
                    var count = 0
                    let details = CertificateManager.shared.getStoreDetailsAndLanguage(for: shipment.destination)
                    for serial in viewModel.scannedSerials {
                        if CertificateManager.shared.getCertificate(for: serial) == nil {
                            let normSerial = serial.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
                            if let product = viewModel.products.first(where: { prod in
                                let normalizedSKU = prod.sku.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: " ", with: "-").uppercased()
                                if let qr = prod.qrValue {
                                    let normalizedQR = qr.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: " ", with: "-").uppercased()
                                    if normalizedQR == normSerial || normalizedSKU == normSerial {
                                        return true
                                    }
                                    if normalizedQR.contains(normSerial) && !normSerial.isEmpty && normSerial.count >= 4 {
                                        return true
                                    }
                                    if normSerial.contains(normalizedQR) || normSerial.contains(normalizedSKU) {
                                        return true
                                    }
                                } else {
                                    if normalizedSKU == normSerial || normSerial.contains(normalizedSKU) {
                                        return true
                                    }
                                }
                                if let scannedURL = URL(string: serial),
                                   let lastComponent = scannedURL.pathComponents.last?.uppercased(),
                                   lastComponent == normalizedSKU {
                                    return true
                                }
                                return false
                            }) {
                                _ = CertificateManager.shared.createCertificate(
                                    serialNumber: serial,
                                    product: product,
                                    storeName: details.storeName,
                                    storeLocation: details.storeLocation,
                                    language: details.language
                                )
                                count += 1
                            }
                        }
                    }
                    batchCreatedCertificatesCount = count
                    await viewModel.submitVerification(shipment: shipment, warehouseId: warehouseId, userId: userId)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            if viewModel.isAllMatched {
                Text("All scanned quantities match the manifest exactly.")
            } else {
                Text("Warning: Discrepancies exist. Proceeding will automatically log exceptions.")
            }
        }
    }
}
