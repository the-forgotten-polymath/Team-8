//
//  StockRequestView.swift
//  RSMS_Project
//
//  Created by Yatharth Mishra on 30/06/26.
//

import SwiftUI

struct StockRequestView: View {
    let warehouseId: UUID
    let userId: UUID
    
    @StateObject private var viewModel = StockRequestViewModel()
    @State private var filterOption = RequestFilter.all
    @State private var searchText = ""
    

    enum RequestFilter {
        case all, pending, active, completed, rejected

        var displayName: String {
            switch self {
            case .all:       return "All"
            case .pending:   return "Pending"
            case .active:    return "Active"
            case .completed: return "Completed"
            case .rejected:  return "Rejected"
            }
        }
    }

    
    var filteredRequests: [GroupedStockRequest] {
        let list: [GroupedStockRequest]
        switch filterOption {
        case .all:
            list = viewModel.groupedStockRequests
        case .pending:
            list = viewModel.groupedStockRequests.filter { $0.status.lowercased() == "pending" }
        case .active:
            list = viewModel.groupedStockRequests.filter {
                let status = $0.status.lowercased()
                return status == "approved" || status == "active" || status == "in transit" || status == "preparing shipment"
            }
        case .completed:
            list = viewModel.groupedStockRequests.filter {
                let status = $0.status.lowercased()
                return status == "fulfilled" || status == "completed" || status == "delivered"
            }
        case .rejected:
            list = viewModel.groupedStockRequests.filter { $0.status.lowercased() == "rejected" }
        }
        
        if searchText.isEmpty {
            return list
        } else {
            return list.filter { group in
                group.items.contains { item in
                    guard let product = viewModel.getProduct(for: item.productId) else { return false }
                    return product.productName.localizedCaseInsensitiveContains(searchText) ||
                           product.sku.localizedCaseInsensitiveContains(searchText)
                }
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {

            // MARK: - Search + Filter row
            HStack(spacing: 8) {
                // Full-width search bar
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                        .font(.system(size: 15))

                    TextField("Search by product or SKU...", text: $searchText)
                        .font(.body)
                        .autocorrectionDisabled()
                        .autocapitalization(.none)
                        .submitLabel(.search)

                    if !searchText.isEmpty {
                        Button {
                            searchText = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 9)
                .background(Color(.systemGray6))
                .cornerRadius(10)

                // Filter button
                Menu {
                    Button(action: { filterOption = .all }) {
                        Label("All", systemImage: filterOption == .all ? "checkmark" : "")
                    }
                    Button(action: { filterOption = .pending }) {
                        Label("Pending", systemImage: filterOption == .pending ? "checkmark" : "")
                    }
                    Button(action: { filterOption = .active }) {
                        Label("Active", systemImage: filterOption == .active ? "checkmark" : "")
                    }
                    Button(action: { filterOption = .completed }) {
                        Label("Completed", systemImage: filterOption == .completed ? "checkmark" : "")
                    }
                    Button(action: { filterOption = .rejected }) {
                        Label("Rejected", systemImage: filterOption == .rejected ? "checkmark" : "")
                    }
                } label: {
                    Image(systemName: filterOption == .all
                          ? "line.3.horizontal.decrease.circle"
                          : "line.3.horizontal.decrease.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.blue)
                }
                .accessibilityLabel("Filter requests")
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color(UIColor.systemBackground))

            Divider()

            if viewModel.isLoading {
                LoadingView(message: "Loading stock requests...")
            } else if filteredRequests.isEmpty {
                EmptyStateView(
                    title: "No Stock Requests",
                    message: "There are no incoming boutique requests matching this filter.",
                    iconName: "doc.text"
                )
                .frame(maxHeight: .infinity)
            } else {
                // Scrollable custom card list with Order ID as main header title
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(filteredRequests) { request in
                            let store = viewModel.getStore(for: request.storeId)
                            let totalQty = request.items.reduce(0) { $0 + $1.requestedQuantity }
                            
                            NavigationLink(destination: StockRequestDetailView(groupedRequest: request, warehouseId: warehouseId, userId: userId)) {
                                VStack(alignment: .leading, spacing: 12) {
                                    HStack(alignment: .top) {
                                        VStack(alignment: .leading, spacing: 6) {
                                            // Order ID as the main card header
                                            Text(request.orderId)
                                                .font(.system(size: 18, weight: .bold))
                                                .foregroundColor(.primary)
                                                .multilineTextAlignment(.leading)
                                            
                                            // Bullet points of items in the request
                                            VStack(alignment: .leading, spacing: 4) {
                                                ForEach(request.items) { item in
                                                    let p = viewModel.getProduct(for: item.productId)
                                                    Text("• \(p?.productName ?? "Loading Product...")")
                                                        .font(.caption)
                                                        .foregroundColor(.secondary)
                                                        .multilineTextAlignment(.leading)
                                                }
                                            }
                                        }
                                        
                                        Spacer()
                                        
                                        StatusChip(status: getDisplayStatus(request.status))
                                    }
                                    
                                    Divider()
                                    
                                    HStack {
                                        HStack(spacing: 8) {
                                            Image(systemName: "storefront.fill")
                                                .foregroundColor(.secondary)
                                            Text(store?.storeName ?? "Store")
                                                .font(.subheadline)
                                                .foregroundColor(.secondary)
                                        }
                                        
                                        Spacer()
                                        
                                        Text("Qty: \(totalQty)")
                                            .font(.subheadline)
                                            .fontWeight(.bold)
                                            .foregroundColor(.primary)
                                    }
                                    
                                    HStack {
                                        Spacer()
                                        Text(formatRequestDate(request.createdAt))
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .padding()
                                .background(Color(UIColor.secondarySystemGroupedBackground))
                                .cornerRadius(16)
                                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.appleBorder, lineWidth: 1))
                                .shadow(color: Color.black.opacity(0.02), radius: 5, y: 2)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding()
                }
                .background(Color(UIColor.systemGroupedBackground))
            }
        }
        .navigationTitle("Stock Allocation Requests")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Error", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("OK") { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .refreshable {
            await viewModel.loadData(warehouseId: warehouseId)
        }
        .task {
            await viewModel.loadData(warehouseId: warehouseId)
        }
    }
    
    private func formatRequestDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yy, h:mm a"
        return formatter.string(from: date)
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
