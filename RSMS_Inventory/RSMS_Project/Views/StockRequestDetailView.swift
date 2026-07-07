//
//  StockRequestDetailView.swift
//  RSMS_Project
//
//  Created by Yatharth Mishra on 30/06/26.
//

import SwiftUI

struct StockRequestDetailView: View {
    let groupedRequest: GroupedStockRequest
    let warehouseId: UUID
    let userId: UUID
    
    @StateObject private var viewModel = StockRequestViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        let items = viewModel.groupedStockRequests.first(where: { $0.orderId == groupedRequest.orderId })?.items ?? groupedRequest.items
        let overallStatus = viewModel.groupedStockRequests.first(where: { $0.orderId == groupedRequest.orderId })?.status ?? groupedRequest.status
        
        let pendingItems = items.filter { $0.status.lowercased() == "pending" }
        let hasPendingItems = !pendingItems.isEmpty
        
        // Check if all pending items have sufficient stock
        let allPendingStockAvailable = pendingItems.allSatisfy { item in
            let whStock = viewModel.getWarehouseStock(for: item.productId)
            return whStock >= item.requestedQuantity
        }
        
        return ZStack(alignment: .bottom) {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header card
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Stock Request Details")
                                .font(.headline)
                            Spacer()
                             StatusChip(status: getDisplayStatus(overallStatus))
                        }
                        
                        Divider()
                        
                        let store = viewModel.getStore(for: groupedRequest.storeId)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Order ID:")
                                    .fontWeight(.bold)
                                Spacer()
                                Text(groupedRequest.orderId)
                            }
                            
                            HStack {
                                Text("Requested By:")
                                    .fontWeight(.bold)
                                Spacer()
                                Text(store?.storeName ?? "Loading...")
                            }
                            
                            HStack {
                                Text("Priority:")
                                    .fontWeight(.bold)
                                Spacer()
                                Text(groupedRequest.priority.uppercased())
                                    .foregroundColor(groupedRequest.priority.lowercased() == "high" ? .red : .primary)
                            }
                            
                            if let remarks = groupedRequest.remarks, !remarks.isEmpty {
                                HStack {
                                    Text("Remarks:")
                                        .fontWeight(.bold)
                                    Spacer()
                                    Text(remarks)
                                }
                            }
                        }
                        .font(.subheadline)
                    }
                    .padding()
                    .background(Color(UIColor.secondarySystemGroupedBackground))
                    .cornerRadius(16)
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.appleBorder, lineWidth: 1))
                    
                    Text("Requested Items")
                        .font(.headline)
                        .padding(.top, 10)
                    
                    // List of items in the grouped request
                    ForEach(items) { item in
                        let product = viewModel.getProduct(for: item.productId)
                        let whStock = viewModel.getWarehouseStock(for: item.productId)
                        let isSufficient = whStock >= item.requestedQuantity
                        
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(product?.productName ?? "Loading Product...")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                    Text("SKU: \(product?.sku ?? "")")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                 StatusChip(status: getDisplayStatus(item.status))
                            }
                            
                            Divider()
                            
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Requested Qty")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                    Text("\(item.requestedQuantity) units")
                                        .font(.subheadline)
                                        .fontWeight(.bold)
                                }
                                Spacer()
                                VStack(alignment: .trailing, spacing: 2) {
                                    Text("Warehouse Available")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                    Text("\(whStock) units")
                                        .font(.subheadline)
                                        .fontWeight(.bold)
                                        .foregroundColor(isSufficient ? .green : .red)
                                }
                            }
                            
                            HStack {
                                Text("Stock Status:")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(isSufficient ? "Available" : "Insufficient Stock")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(isSufficient ? .green : .red)
                                Spacer()
                            }
                        }
                        .padding()
                        .background(Color(UIColor.secondarySystemGroupedBackground))
                        .cornerRadius(16)
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.appleBorder, lineWidth: 1))
                    }
                    
                    // Spacer at the bottom to avoid overlapping with bottom buttons
                    if hasPendingItems {
                        Spacer().frame(height: 150)
                    }
                }
                .padding()
            }
            
            // Bottom Action: Fulfill and Reject buttons for entire order
            if hasPendingItems {
                VStack {
                    Divider()
                        .padding(.bottom, 8)
                    
                    VStack(spacing: 12) {
                        Button(action: {
                            if let refreshedGroup = viewModel.groupedStockRequests.first(where: { $0.orderId == groupedRequest.orderId }) {
                                Swift.Task {
                                    await viewModel.fulfillGroupedRequest(
                                        groupedRequest: refreshedGroup,
                                        warehouseId: warehouseId,
                                        userId: userId
                                    )
                                }
                            }
                        }) {
                            Text(allPendingStockAvailable ? "Fulfill Order" : "Stock Shortage — Cannot Fulfill")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 52)
                                .background(allPendingStockAvailable ? Color.blue : Color.gray)
                                .cornerRadius(12)
                        }
                        .disabled(!allPendingStockAvailable)
                        
                        Button(action: {
                            if let refreshedGroup = viewModel.groupedStockRequests.first(where: { $0.orderId == groupedRequest.orderId }) {
                                Swift.Task {
                                    await viewModel.rejectGroupedRequest(
                                        groupedRequest: refreshedGroup,
                                        warehouseId: warehouseId,
                                        userId: userId
                                    )
                                }
                            }
                        }) {
                            Text("Reject Request")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity)
                                .frame(height: 52)
                                .background(Color.red.opacity(0.1))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.red, lineWidth: 1.5)
                                )
                                .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 24)
                }
                .background(Color(UIColor.systemBackground).ignoresSafeArea(edges: .bottom))
            }
            
            if viewModel.isLoading {
                LoadingView(message: "Processing allocation...")
            }
        }
        .navigationTitle("Fulfillment Operations")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Error", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("OK") { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .task {
            await viewModel.loadData(warehouseId: warehouseId)
        }
    }
    
    private func getDisplayStatus(_ status: String) -> String {
        let lower = status.lowercased()
        if lower == "approved" || lower == "preparing shipment" || lower == "in transit" {
            return "fulfilled"
        } else if lower == "delivered" {
            return "delivered"
        } else {
            return lower
        }
    }
}

// MARK: - Custom Swipe To Fulfill Component
struct SwipeToFulfillButton: View {
    let isEnabled: Bool
    var onSwipeSuccess: () -> Void
    
    @State private var dragOffset: CGFloat = 0
    private let buttonWidth: CGFloat = 340
    private let thumbSize: CGFloat = 52
    
    var body: some View {
        ZStack(alignment: .leading) {
            // Track background
            Capsule()
                .fill(isEnabled ? Color(.systemGray6) : Color(.systemGray5))
                .frame(width: buttonWidth, height: 60)
                .overlay(
                    Capsule()
                        .stroke(Color(.separator), lineWidth: 1)
                )
            
            // Status track text
            Text(isEnabled ? "Swipe to Fulfill" : "Stock Shortage — Cannot Fulfill")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(isEnabled ? .primary : .secondary)
                .frame(width: buttonWidth, height: 60, alignment: .center)
            
            if isEnabled {
                // Slid overlay capsule to show swipe progress
                Capsule()
                    .fill(Color.green.opacity(0.15))
                    .frame(width: max(thumbSize, dragOffset + thumbSize), height: 60)
                
                // Draggable handle matching the screenshot (blue outline circle, white background, chevrons)
                Circle()
                    .fill(Color.white)
                    .frame(width: thumbSize, height: thumbSize)
                    .overlay(
                        Circle()
                            .stroke(Color.blue, lineWidth: 3)
                    )
                    .overlay(
                        Image(systemName: "chevron.right.2")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.blue)
                    )
                    .padding(.horizontal, 4)
                    .offset(x: dragOffset)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                let maxDrag = buttonWidth - thumbSize - 8
                                if value.translation.width > 0 {
                                    dragOffset = min(maxDrag, value.translation.width)
                                }
                            }
                            .onEnded { value in
                                let maxDrag = buttonWidth - thumbSize - 8
                                if dragOffset > maxDrag * 0.85 {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        dragOffset = maxDrag
                                    }
                                    onSwipeSuccess()
                                } else {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        dragOffset = 0
                                    }
                                }
                            }
                    )
            } else {
                // Disabled lock icon handle
                Circle()
                    .fill(Color(.systemGray4))
                    .frame(width: thumbSize, height: thumbSize)
                    .overlay(
                        Image(systemName: "lock.fill")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.secondary)
                    )
                    .padding(.horizontal, 4)
            }
        }
        .frame(width: buttonWidth, height: 60)
    }
}
