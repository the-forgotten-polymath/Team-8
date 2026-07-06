//
//  CycleCountProductAuditView.swift
//  RSMS_Project
//
//  Created by Yatharth Mishra on 02/07/26.
//

import SwiftUI

struct CycleCountProductAuditView: View {
    let item: InventoryItem
    let count: CycleCount
    @ObservedObject var viewModel: CycleCountViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var isShowingScanner = false

    var body: some View {
        let isAudited = viewModel.auditedProductIds.contains(item.productId)
        let counted = viewModel.countedQty(for: item.productId)
        let variance = viewModel.variance(for: item)

        ScrollView {
            VStack(spacing: 20) {
                productInfoCard
                
                // Scan QR Button
                scanQRButton
                
                // Summary of audit count (shown if audited)
                if isAudited {
                    auditSummaryCard(counted: counted, variance: variance)
                }
            }
            .padding()
        }
        .background(Color(UIColor.systemGroupedBackground).ignoresSafeArea())
        .navigationTitle("Product Audit")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $isShowingScanner) {
            CycleCountProductScannerSheet(
                item: item,
                count: count,
                viewModel: viewModel
            )
        }
    }

    // MARK: - Product Info Card

    private var productInfoCard: some View {
        let prod = viewModel.product(for: item)
        let isVerified = viewModel.scannedProductIds.contains(item.productId)

        return VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(prod?.productName ?? "Unknown Product")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)

                    Text("\(prod?.brand ?? "No Brand") · SKU: \(prod?.sku ?? "–")")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
                if isVerified {
                    Label("Verified", systemImage: "checkmark.seal.fill")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(Color.green.opacity(0.15))
                        .foregroundColor(.green)
                        .cornerRadius(8)
                } else {
                    Label("Unverified", systemImage: "qrcode.viewfinder")
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(Color.secondary.opacity(0.15))
                        .foregroundColor(.secondary)
                        .cornerRadius(8)
                }
            }

            Divider()

            HStack {
                Label("Zone: \(count.zone ?? item.zone ?? "–")", systemImage: "map.fill")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text("Item ID: \(item.productId.uuidString.prefix(8))...")
                    .font(.caption2)
                    .foregroundColor(Color(.tertiaryLabel))
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 2)
    }

    // MARK: - Scan QR Button

    private var scanQRButton: some View {
        Button(action: { isShowingScanner = true }) {
            HStack(spacing: 12) {
                Image(systemName: "qrcode.viewfinder")
                    .font(.title2)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Scan QR Code")
                        .font(.headline)
                        .fontWeight(.semibold)
                    Text("Scan to verify and enter counted quantity.")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(16)
            .shadow(color: Color.blue.opacity(0.3), radius: 8, x: 0, y: 4)
        }
    }

    // MARK: - Audit Summary Card

    private func auditSummaryCard(counted: Int, variance: Int) -> some View {
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

        return VStack(alignment: .leading, spacing: 12) {
            Text("Audit Summary")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .fontWeight(.semibold)

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Physical Counted")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(counted) units")
                        .font(.headline)
                        .fontWeight(.bold)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("System Expected")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(item.quantity) units")
                        .font(.subheadline)
                }
            }

            Divider()

            HStack(spacing: 8) {
                if variance == 0 {
                    Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
                    Text("Matched").font(.subheadline).fontWeight(.bold).foregroundColor(.green)
                } else if variance < 0 {
                    Image(systemName: "exclamationmark.triangle.fill").foregroundColor(.red)
                    Text("Deficit of \(abs(variance)) units").font(.subheadline).fontWeight(.bold).foregroundColor(.red)
                } else {
                    Image(systemName: "plus.circle.fill").foregroundColor(.orange)
                    Text("Surplus of +\(variance) units").font(.subheadline).fontWeight(.bold).foregroundColor(.orange)
                }
                Spacer()
            }
            .padding(10)
            .background(statusBgColor)
            .cornerRadius(8)
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(statusStrokeColor, lineWidth: 1))
        }
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 2)
    }
}
