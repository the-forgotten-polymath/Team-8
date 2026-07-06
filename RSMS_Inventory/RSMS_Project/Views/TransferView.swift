//
//  TransferView.swift
//  RSMS_Project
//
//  Created by Yatharth Mishra on 30/06/26.
//

import SwiftUI

struct TransferView: View {
    let userId: UUID
    @StateObject private var viewModel = TransferViewModel()
    
    var body: some View {
        VStack(spacing: 0) {
            if viewModel.isLoading {
                LoadingView(message: "Loading store transfers...")
            } else if viewModel.transfers.isEmpty {
                EmptyStateView(
                    title: "No Store Transfers",
                    message: "There are no inter-store stock transfers recorded.",
                    iconName: "arrow.left.arrow.right"
                )
            } else {
                List(viewModel.transfers) { transfer in
                    let product = viewModel.getProduct(for: transfer.stockRequestId)
                    let qty = viewModel.getQuantity(for: transfer.stockRequestId)
                    
                    NavigationLink(destination: TransferDetailView(transfer: transfer, userId: userId)) {
                        HStack {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(product?.productName ?? "Loading Product...")
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                
                                Text("Route: \(viewModel.getStoreName(for: transfer.sourceStoreId)) ➔ \(viewModel.getStoreName(for: transfer.destinationStoreId))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Text("Qty: \(qty) units")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            StatusChip(status: transfer.status)
                        }
                        .padding(.vertical, 4)
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("Inter-Store Transfers")
        .navigationBarTitleDisplayMode(.inline)
        .refreshable {
            await viewModel.loadData()
        }
        .task {
            await viewModel.loadData()
        }
    }
}
