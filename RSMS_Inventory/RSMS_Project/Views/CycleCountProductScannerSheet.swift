//
//  CycleCountProductScannerSheet.swift
//  RSMS_Project
//
//  Created by Yatharth Mishra on 02/07/26.
//

import SwiftUI
import AVFoundation

struct CycleCountProductScannerSheet: View {
    let item: InventoryItem
    let count: CycleCount
    @ObservedObject var viewModel: CycleCountViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var hasScanned = false
    @State private var countedQty = 0
    @State private var showErrorMessage = false
    @State private var errorMessage = ""
    @State private var cameraPermissionGranted = true

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Scanner view area
                    ZStack {
                        #if targetEnvironment(simulator)
                        VStack(spacing: 16) {
                            Image(systemName: "qrcode.viewfinder")
                                .font(.system(size: 64))
                                .foregroundColor(.blue)
                            Text("Simulator Camera View")
                                .font(.headline)
                            Text("Simulate a scan of the product box.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                            
                            if !hasScanned {
                                Button(action: {
                                    triggerScan(code: viewModel.product(for: item)?.sku ?? "")
                                }) {
                                    Text("Simulate Successful Scan")
                                        .fontWeight(.bold)
                                        .padding()
                                        .background(Color.blue)
                                        .foregroundColor(.white)
                                        .cornerRadius(12)
                                }
                                .padding(.top, 10)
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color(UIColor.secondarySystemGroupedBackground))
                        .cornerRadius(24)
                        .padding()
                        #else
                        if cameraPermissionGranted {
                            CameraScannerView(onScan: { code in
                                triggerScan(code: code)
                            })
                            .ignoresSafeArea()
                            
                            // Viewfinder Overlay
                            ZStack {
                                Color.black.opacity(0.4)
                                    .mask(
                                        ViewfinderMask(rectSize: CGSize(width: 260, height: 260))
                                            .fill(style: FillStyle(eoFill: true))
                                    )
                                
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(hasScanned ? Color.green : Color.blue, lineWidth: 3)
                                    .frame(width: 260, height: 260)
                            }
                        } else {
                            VStack(spacing: 20) {
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 60))
                                    .foregroundColor(.gray)
                                Text("Camera Access Required")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                Button("Open Settings") {
                                    if let url = URL(string: UIApplication.openSettingsURLString) {
                                        UIApplication.shared.open(url)
                                    }
                                }
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                            }
                        }
                        #endif
                    }
                    .frame(maxHeight: hasScanned ? 300 : .none) // Shrink preview area when scanned

                    // Bottom Sheet content shown only after scanning
                    if hasScanned {
                        bottomQuantityCard
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
            }
            .navigationTitle("QR Code Scanner")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.blue)
                    .fontWeight(.bold)
                }
            }
            .alert("Scan Error", isPresented: $showErrorMessage) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .onAppear {
                checkCameraPermission()
                // Initialize countedQty from the current view model state
                countedQty = viewModel.countedQty(for: item.productId)
                // If it was already scanned before, let them edit immediately
                if viewModel.scannedProductIds.contains(item.productId) {
                    hasScanned = true
                }
            }
        }
    }

    private var bottomQuantityCard: some View {
        let prod = viewModel.product(for: item)
        let variance = countedQty - item.quantity
        
        let statusBgColor: Color
        let statusStrokeColor: Color
        if variance == 0 {
            statusBgColor = Color.green.opacity(0.1)
            statusStrokeColor = Color.green.opacity(0.3)
        } else if variance < 0 {
            statusBgColor = Color.red.opacity(0.1)
            statusStrokeColor = Color.red.opacity(0.3)
        } else {
            statusBgColor = Color.orange.opacity(0.1)
            statusStrokeColor = Color.orange.opacity(0.3)
        }

        return VStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 4) {
                Text(prod?.productName ?? "Verified Product")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                Text("SKU: \(prod?.sku ?? "") · System expected: \(item.quantity) units")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Divider()

            VStack(spacing: 8) {
                Text("Physical Counted Quantity")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)

                HStack(spacing: 20) {
                    Button(action: { countedQty = max(0, countedQty - 1) }) {
                        Image(systemName: "minus.circle.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.blue)
                    }
                    .buttonStyle(.plain)

                    TextField("0", value: $countedQty, format: .number)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.center)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .frame(width: 90, height: 44)
                        .background(Color(UIColor.tertiarySystemGroupedBackground))
                        .cornerRadius(10)
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(.separator), lineWidth: 1))

                    Button(action: { countedQty += 1 }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.blue)
                    }
                    .buttonStyle(.plain)
                }
            }

            // Variance feedback
            HStack(spacing: 12) {
                if variance == 0 {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Matched — Stock matches system.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(variance < 0 ? .red : .orange)
                    Text(variance < 0 ? "Deficit of \(abs(variance)) units." : "Surplus of +\(variance) units.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
            .padding(12)
            .background(statusBgColor)
            .cornerRadius(10)
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(statusStrokeColor, lineWidth: 1))

            // Save Count Button
            Button(action: {
                viewModel.saveProductAudit(productId: item.productId, countedQuantity: countedQty)
                dismiss()
            }) {
                Text("Save Count")
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .shadow(color: Color.green.opacity(0.3), radius: 6, y: 3)
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(24)
        .shadow(color: Color.black.opacity(0.15), radius: 10, y: -5)
    }

    private func triggerScan(code: String) {
        guard !hasScanned else { return }
        
        let result = viewModel.processSingleProductScan(for: item.productId, value: code)
        switch result {
        case .match:
            withAnimation(.spring()) {
                hasScanned = true
            }
        case .mismatch(let expected, _):
            errorMessage = "Scanned barcode does not match \(expected)."
            showErrorMessage = true
        }
    }

    private func checkCameraPermission() {
        #if !targetEnvironment(simulator)
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        cameraPermissionGranted = (status == .authorized)
        #endif
    }
}
