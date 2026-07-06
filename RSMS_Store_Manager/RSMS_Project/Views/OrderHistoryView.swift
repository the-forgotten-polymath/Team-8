//
//  OrderHistoryView.swift
//  RSMS_Project
//
//  Created by Antigravity on 03/07/26.
//

import SwiftUI
import Supabase
import Combine

// MARK: - View Model

@MainActor
final class OrderHistoryViewModel: ObservableObject {
    @Published var orders: [OrderSummary] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    struct OrderSummary: Identifiable {
        let id: String // order_id
        let orderId: String
        let productCount: Int
        let totalUnits: Int
        let status: String
        let createdAt: Date
    }
    
    func loadOrders() async {
        isLoading = true
        errorMessage = nil
        
        guard let currentUser = SessionManager.shared.currentUser,
              let storeId = currentUser.storeId else {
            errorMessage = "No active session."
            isLoading = false
            return
        }
        
        do {
            let response = try await SupabaseManager.shared.client
                .from("stock_requests")
                .select()
                .eq("store_id", value: storeId.uuidString)
                .eq("requested_by", value: currentUser.id.uuidString)
                .order("created_at", ascending: false)
                .execute()
            
            let allRequests = try JSONDecoder.supabaseDecoder.decodeSupabase([StockRequest].self, from: response.data)
            
            // Group by order_id
            var grouped: [String: [StockRequest]] = [:]
            for request in allRequests {
                guard let orderId = request.orderId, !orderId.isEmpty else { continue }
                grouped[orderId, default: []].append(request)
            }
            
            // Build order summaries
            var summaries: [OrderSummary] = []
            for (orderId, requests) in grouped {
                let totalUnits = requests.reduce(0) { $0 + $1.requestedQuantity }
                let status = requests.first?.status ?? "Pending"
                let createdAt = requests.min(by: { $0.createdAt < $1.createdAt })?.createdAt ?? Date()
                
                summaries.append(OrderSummary(
                    id: orderId,
                    orderId: orderId,
                    productCount: requests.count,
                    totalUnits: totalUnits,
                    status: status,
                    createdAt: createdAt
                ))
            }
            
            // Sort by date descending
            orders = summaries.sorted { $0.createdAt > $1.createdAt }
        } catch {
            errorMessage = error.localizedDescription
            print("Failed to load order history: \(error)")
        }
        
        isLoading = false
    }
}

// MARK: - Order History View

struct OrderHistoryView: View {
    @StateObject private var viewModel = OrderHistoryViewModel()
    
    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()
            
            if viewModel.isLoading {
                VStack(spacing: 16) {
                    ProgressView()
                    Text("Loading orders...")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
            } else if let error = viewModel.errorMessage {
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 36))
                        .foregroundColor(.orange)
                    Text(error)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
            } else if viewModel.orders.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "tray")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text("No Orders Yet")
                        .font(.system(size: 18, weight: .bold))
                    Text("Your restock order history will appear here.")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
            } else {
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.orders) { order in
                            NavigationLink(destination: OrderDetailView(orderId: order.orderId)) {
                                OrderHistoryCard(order: order)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
                .refreshable {
                    await viewModel.loadOrders()
                }
            }
        }
        .navigationTitle("Order History")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            Swift.Task {
                await viewModel.loadOrders()
            }
        }
    }
}

// MARK: - Order History Card

struct OrderHistoryCard: View {
    let order: OrderHistoryViewModel.OrderSummary
    
    var statusColor: Color {
        switch order.status.lowercased() {
        case "approved": return .green
        case "rejected": return .red
        case "pending": return .orange
        default: return .secondary
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Top Row: Order ID & Status
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "number.square.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.blue)
                    Text(order.orderId)
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                Text(order.status)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(statusColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(statusColor.opacity(0.12))
                    .cornerRadius(8)
            }
            
            Divider()
            
            // Stats Row
            HStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(order.productCount)")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.primary)
                    Text("Products")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(order.totalUnits)")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.primary)
                    Text("Units")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(formattedDate(order.createdAt))
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.primary)
                    Text(formattedTime(order.createdAt))
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
            }
            
            // Chevron hint
            HStack {
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.secondary)
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.02), radius: 6, x: 0, y: 3)
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMMM yyyy"
        return formatter.string(from: date)
    }
    
    private func formattedTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
}
