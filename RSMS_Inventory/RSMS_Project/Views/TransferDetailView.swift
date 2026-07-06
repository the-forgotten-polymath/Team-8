//
//  TransferDetailView.swift
//  RSMS_Project
//
//  Created by Yatharth Mishra on 30/06/26.
//

import SwiftUI

struct TransferDetailView: View {
    let transfer: Transfer
    let userId: UUID
    
    @StateObject private var viewModel = TransferViewModel()
    @State private var showApproveConfirm = false
    @State private var showRejectConfirm = false
    
    var body: some View {
        ZStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Core Details
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Transfer Details")
                                .font(.headline)
                            Spacer()
                            StatusChip(status: transfer.status)
                        }
                        
                        Divider()
                        
                        let product = viewModel.getProduct(for: transfer.stockRequestId)
                        let qty = viewModel.getQuantity(for: transfer.stockRequestId)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Product:")
                                    .fontWeight(.bold)
                                Spacer()
                                Text(product?.productName ?? "Loading...")
                            }
                            
                            HStack {
                                Text("SKU:")
                                    .fontWeight(.bold)
                                Spacer()
                                Text(product?.sku ?? "")
                            }
                            
                            HStack {
                                Text("Quantity:")
                                    .fontWeight(.bold)
                                Spacer()
                                Text("\(qty) units")
                            }
                            
                            HStack {
                                Text("Transfer Date:")
                                    .fontWeight(.bold)
                                Spacer()
                                Text(transfer.transferDate, style: .date)
                            }
                        }
                        .font(.subheadline)
                    }
                    .padding()
                    .background(Color(UIColor.secondarySystemGroupedBackground))
                    .cornerRadius(16)
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.appleBorder, lineWidth: 1))
                    
                    // Routing Timeline View
                    DashboardCard(title: "Transit Path Routing", iconName: "arrow.left.arrow.right") {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: "house.fill")
                                    .foregroundColor(.blue)
                                    .font(.title3)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("SOURCE SENDER STORE")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                        .fontWeight(.bold)
                                    Text(viewModel.getStoreName(for: transfer.sourceStoreId))
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                }
                            }
                            
                            // Line Connector
                            HStack {
                                Image(systemName: "arrow.down")
                                    .foregroundColor(.secondary)
                                    .font(.subheadline)
                                    .padding(.leading, 4)
                                Spacer()
                            }
                            
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: "house.and.flag.fill")
                                    .foregroundColor(.green)
                                    .font(.title3)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("DESTINATION RECEIVER STORE")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                        .fontWeight(.bold)
                                    Text(viewModel.getStoreName(for: transfer.destinationStoreId))
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    
                    // CTA actions for manager
                    if transfer.status.lowercased() == "pending" {
                        HStack(spacing: 16) {
                            Button(action: {
                                showRejectConfirm = true
                            }) {
                                Text("Reject Transfer")
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(Color(.systemGray6))
                                    .foregroundColor(.red)
                                    .fontWeight(.semibold)
                                    .cornerRadius(12)
                            }
                            
                            Button(action: {
                                showApproveConfirm = true
                            }) {
                                Text("Approve Transfer")
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .fontWeight(.semibold)
                                    .cornerRadius(12)
                            }
                        }
                        .padding(.top, 10)
                    }
                }
                .padding()
            }
            
            if viewModel.isLoading {
                LoadingView(message: "Updating transfer...")
            }
        }
        .navigationTitle("Transfer Routing")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadData()
        }
        .confirmationDialog("Approve Transfer Request?", isPresented: $showApproveConfirm, titleVisibility: .visible) {
            Button("Confirm Approval") {
                Swift.Task {
                    await viewModel.approveTransfer(transfer: transfer, userId: userId)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will authorize the store-to-store transfer shipment route.")
        }
        .confirmationDialog("Reject Transfer Request?", isPresented: $showRejectConfirm, titleVisibility: .visible) {
            Button("Reject Transfer", role: .destructive) {
                Swift.Task {
                    await viewModel.rejectTransfer(transfer: transfer, userId: userId)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to reject this store transfer request?")
        }
    }
}
