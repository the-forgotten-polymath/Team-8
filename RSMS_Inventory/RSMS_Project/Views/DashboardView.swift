//
//  DashboardView.swift
//  RSMS_Project
//
//  Created by Yatharth Mishra on 30/06/26.
//

import SwiftUI

struct DashboardView: View {
    @StateObject private var viewModel = DashboardViewModel()

    // Injected from ContentView via environmentObject
    @EnvironmentObject private var notificationStore: LowStockNotificationStore

    let warehouseId: UUID
    let userId: UUID

    @Binding var selectedTab: Int
    var onLogout: () -> Void = {}

    @State private var showProfile = false
    @State private var showNotifications = false
    @State private var currentUserName: String = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header Profile Info
                HStack(spacing: 12) {
                    Image(systemName: "person.crop.circle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.blue)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(currentUserName.isEmpty
                             ? "Welcome"
                             : "Welcome, \(currentUserName)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text("Central Warehouse")
                            .font(.headline)
                            .foregroundColor(.primary)
                    }
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top, 10)
                
                // Metrics grid — Overview (icon removed from card header)
                DashboardCard(title: "Overview", iconName: nil) {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        MetricCard(title: "Warehouse Stock", value: "\(viewModel.warehouseStockCount)", iconName: "shippingbox.fill", iconColor: .blue)
                        MetricCard(title: "Pending Shipments", value: "\(viewModel.pendingShipmentsCount)", iconName: "truck.box.fill", iconColor: .orange)
                        MetricCard(title: "Stock Requests", value: "\(viewModel.pendingStockRequestsCount)", iconName: "doc.text.fill", iconColor: .green)
                        MetricCard(title: "Store Transfers", value: "\(viewModel.pendingTransfersCount)", iconName: "arrow.left.arrow.right", iconColor: .purple)
                        MetricCard(title: "Low Stock Alerts", value: "\(viewModel.lowStockAlertsCount)", iconName: "exclamationmark.triangle.fill", iconColor: .red)
                        MetricCard(title: "Scheduled Cycles", value: "\(viewModel.scheduledCycleCountsCount)", iconName: "calendar.badge.clock", iconColor: .teal)
                    }
                }
                .padding(.horizontal)
                
                // Recent Activities
                DashboardCard(title: "Recent Shipments", iconName: "truck.box.fill") {
                    if viewModel.recentShipments.isEmpty {
                        Text("No recent shipments found")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.vertical, 8)
                    } else {
                        VStack(spacing: 0) {
                            ForEach(viewModel.recentShipments) { shipment in
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(shipment.asnNumber ?? "No ASN")
                                            .font(.subheadline)
                                            .fontWeight(.bold)
                                        Text("Type: \(shipment.shipmentType.capitalized) • Destination: \(shipment.destination)")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    StatusChip(status: shipment.status)
                                }
                                .padding(.vertical, 8)
                                if shipment.id != viewModel.recentShipments.last?.id {
                                    Divider()
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal)
                
                DashboardCard(title: "Recent Stock Requests", iconName: "doc.text.fill") {
                    if viewModel.recentStockRequests.isEmpty {
                        Text("No recent stock requests")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.vertical, 8)
                    } else {
                        VStack(spacing: 0) {
                            ForEach(viewModel.recentStockRequests) { request in
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Request Details")
                                            .font(.subheadline)
                                            .fontWeight(.bold)
                                        Text("Qty: \(request.requestedQuantity) • Priority: \(request.priority)")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    StatusChip(status: request.status)
                                }
                                .padding(.vertical, 8)
                                if request.id != viewModel.recentStockRequests.last?.id {
                                    Divider()
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                // Notification bell with live badge
                Button(action: {
                    showNotifications = true
                }) {
                    ZStack(alignment: .topTrailing) {
                        Image(systemName: "bell.fill")
                            .font(.title3)
                            .foregroundColor(.orange)

                        if notificationStore.activeCount > 0 {
                            Text("\(min(notificationStore.activeCount, 99))")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .background(Color.red)
                                .clipShape(Capsule())
                                .offset(x: 8, y: -8)
                        }
                    }
                }

                // Profile button
                Button(action: {
                    showProfile = true
                }) {
                    Image(systemName: "person.crop.circle")
                        .font(.title3)
                        .foregroundColor(.blue)
                }
            }
        }
        .sheet(isPresented: $showProfile) {
            ProfileView(userId: userId, warehouseId: warehouseId, onLogout: onLogout)
        }
        .sheet(isPresented: $showNotifications) {
            NotificationsView(warehouseId: warehouseId, userId: userId, selectedTab: $selectedTab)
                .environmentObject(notificationStore)
        }
        .refreshable {
            await viewModel.loadDashboardData(warehouseId: warehouseId)
            await notificationStore.populate(warehouseId: warehouseId)
        }
        .task {
            await viewModel.loadDashboardData(warehouseId: warehouseId)
            await loadCurrentUser()
            await notificationStore.populate(warehouseId: warehouseId)
        }
    }

    // MARK: - Load current user name

    private func loadCurrentUser() async {
        do {
            let users = try await UserService().fetchUsers()
            if let user = users.first(where: { $0.id == userId }) {
                currentUserName = user.fullName
            }
        } catch {
            print("DashboardView: could not load user name: \(error)")
        }
    }
}

struct QuickActionItem: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
            }
            .padding()
            .frame(width: 110, height: 110, alignment: .leading)
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.appleBorder, lineWidth: 1)
            )
        }
    }
}
