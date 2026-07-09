// OmnichannelView.swift
// RSMS — Sales Associate Module
// Fulfillment screen — BOPIS orders only

import SwiftUI

struct OmnichannelView: View {
    var isEmbedded: Bool = false
    @StateObject private var viewModel = OmnichannelViewModel()
    @EnvironmentObject private var authVM: AuthViewModel

    var body: some View {
        if isEmbedded {
            mainContent
        } else {
            NavigationStack {
                mainContent
            }
        }
    }

    // MARK: – Main Content
    private var mainContent: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()

            VStack(spacing: 0) {
                // ── Header Stats Bar ──────────────────────────────
                statsBar

                // ── Orders List ───────────────────────────────────
                if viewModel.isLoadingBOPIS {
                    Spacer()
                    ProgressView("Loading BOPIS orders…")
                        .padding()
                    Spacer()
                } else if viewModel.bopisOrders.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(viewModel.bopisOrders.sorted(by: { $0.orderDate > $1.orderDate })) { order in
                                NavigationLink(destination:
                                    BOPISDetailView(order: order)
                                        .environmentObject(viewModel)
                                ) {
                                    BOPISOrderCard(order: order)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }
                    .refreshable {
                        viewModel.storeId = authVM.userStoreID
                        await viewModel.fetchBOPISOrders()
                    }
                }
            }
        }
        .navigationTitle("Fulfillment")
        .navigationBarTitleDisplayMode(.large)
        .toolbar(.hidden, for: .tabBar)
        .task {
            viewModel.storeId = authVM.userStoreID
            await viewModel.fetchBOPISOrders()
        }
    }

    // MARK: – Stats Bar
    private var statsBar: some View {
        let orders   = viewModel.bopisOrders
        let pending  = orders.filter { $0.status == .pending || $0.status == .processing }.count
        let ready    = orders.filter { $0.status == .readyForPickup }.count
        let pickedUp = orders.filter { $0.status == .pickedUp }.count

        return HStack(spacing: 0) {
            StatPill(label: "Pending",   count: pending,  color: .orange)
            Divider().frame(height: 28).padding(.horizontal, 8)
            StatPill(label: "Ready",     count: ready,    color: .blue)
            Divider().frame(height: 28).padding(.horizontal, 8)
            StatPill(label: "Picked Up", count: pickedUp, color: .green)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color(.secondarySystemGroupedBackground))
    }

    // MARK: – Empty State
    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "bag.badge.questionmark")
                .font(.system(size: 56))
                .foregroundColor(.secondary.opacity(0.4))
            Text("No BOPIS Orders")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.secondary)
            Text("New Buy-Online-Pick-Up-In-Store orders will appear here when customers place them.")
                .font(.system(size: 14))
                .foregroundColor(.secondary.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Spacer()
        }
    }
}

// MARK: – Stat Pill
private struct StatPill: View {
    let label: String
    let count: Int
    let color: Color

    var body: some View {
        VStack(spacing: 2) {
            Text("\(count)")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(color)
            Text(label)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: – BOPIS Order Card
struct BOPISOrderCard: View {
    let order: FulfillmentOrder

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Top row: order number + status badge
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Order \(order.orderNumber)")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.primary)
                    Text(getCustomerName())
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
                Spacer()
                StatusBadge(status: order.status)
            }

            Divider()

            // Items summary row
            HStack(spacing: 6) {
                Image(systemName: "shippingbox")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                Text("\(order.items.count) item\(order.items.count == 1 ? "" : "s")")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                Spacer()
                Image(systemName: "calendar")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                Text(order.orderDate, style: .date)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }

            // Item names (first 2)
            let preview = order.items.prefix(2)
            ForEach(preview) { item in
                HStack(spacing: 8) {
                    Circle()
                        .fill(Color.blue.opacity(0.12))
                        .frame(width: 6, height: 6)
                    Text(item.productTitle ?? "Unknown Product")
                        .font(.system(size: 13))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    Spacer()
                    Text("×\(item.quantity)")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.secondary)
                }
            }
            if order.items.count > 2 {
                Text("+ \(order.items.count - 2) more item\(order.items.count - 2 == 1 ? "" : "s")")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }

            // Action hint
            HStack {
                Spacer()
                HStack(spacing: 4) {
                    Text("View Details")
                        .font(.system(size: 12, weight: .semibold))
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .semibold))
                }
                .foregroundColor(.blue)
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
    }

    private func getCustomerName() -> String {
        if let name = order.clientName {
            return name
        }
        if let client = MockData.clients.first(where: { $0.id == order.clientID }) {
            return "\(client.firstName) \(client.lastName)"
        }
        return "Emma Watson"
    }
}

// MARK: – Status Badge
private struct StatusBadge: View {
    let status: FulfillmentStatus

    var body: some View {
        Text(label)
            .font(.system(size: 11, weight: .bold))
            .foregroundColor(textColor)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(bgColor)
            .cornerRadius(10)
    }

    private var label: String {
        switch status {
        case .pending:        return "Pending"
        case .processing:     return "Processing"
        case .readyForPickup: return "Ready ✓"
        case .pickedUp:       return "Picked Up"
        case .cancelled:      return "Cancelled"
        default:              return status.rawValue
        }
    }
    private var textColor: Color {
        switch status {
        case .pending, .processing:  return .orange
        case .readyForPickup:        return .blue
        case .pickedUp:              return .green
        case .cancelled:             return .red
        default:                     return .secondary
        }
    }
    private var bgColor: Color { textColor.opacity(0.12) }
}

#Preview {
    OmnichannelView()
        .environmentObject(AuthViewModel())
}
