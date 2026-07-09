//
//  NotificationsView.swift
//  RSMS_Project
//
//  Presented as a sheet from the Dashboard bell icon.
//

import SwiftUI

struct NotificationsView: View {
    let warehouseId: UUID
    let userId: UUID
    @Binding var selectedTab: Int

    @EnvironmentObject private var notificationStore: LowStockNotificationStore
    @Environment(\.dismiss) private var dismiss

    private var activeAlerts: [LowStockNotification] {
        notificationStore.notifications.filter { $0.replenishmentStatus == .idle }
    }

    private var isEmpty: Bool {
        activeAlerts.isEmpty && notificationStore.pendingRequests.isEmpty
    }

    var body: some View {
        NavigationStack {
            Group {
                if isEmpty {
                    emptyState
                } else {
                    notificationList
                }
            }
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
            .task {
                await notificationStore.populate(warehouseId: warehouseId)
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "bell.slash.fill")
                .font(.system(size: 52))
                .foregroundColor(Color(UIColor.systemGray3))
            Text("No Notifications")
                .font(.title3)
                .fontWeight(.semibold)
            Text("All stock levels are healthy and there are no pending requests.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .padding(.horizontal, 40)
    }

    // MARK: - Notification List

    private var notificationList: some View {
        List {
            if !activeAlerts.isEmpty {
                Section(header: Text("Low Stock Alerts")) {
                    ForEach(activeAlerts) { note in
                        LowStockRow(
                            notification: note,
                            warehouseId: warehouseId,
                            userId: userId,
                            onReordered: {
                                selectedTab = 2 // Navigate to Shipments
                                dismiss()
                            }
                        )
                        .environmentObject(notificationStore)
                    }
                }
            }

            if !notificationStore.pendingRequests.isEmpty {
                Section(header: Text("Store Inventory Requests")) {
                    ForEach(notificationStore.pendingRequests) { request in
                        let product = notificationStore.products.first(where: { $0.id == request.productId })
                        let store = notificationStore.stores.first(where: { $0.id == request.storeId })
                        
                        let grouped = GroupedStockRequest(
                            orderId: request.orderId ?? request.id.uuidString,
                            storeId: request.storeId,
                            requestedBy: request.requestedBy,
                            priority: request.priority,
                            status: request.status,
                            remarks: request.remarks,
                            createdAt: request.createdAt,
                            items: [request]
                        )
                        
                        NavigationLink(destination: StockRequestDetailView(groupedRequest: grouped, warehouseId: warehouseId, userId: userId)) {
                            StoreRequestRow(
                                request: request,
                                storeName: store?.storeName ?? "Store",
                                productName: product?.productName ?? "Product",
                                relativeTime: relativeTime(request.createdAt)
                            )
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    private func relativeTime(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - LowStockRow

struct LowStockRow: View {
    let notification: LowStockNotification
    let warehouseId: UUID
    let userId: UUID
    let onReordered: () -> Void
    
    @EnvironmentObject private var notificationStore: LowStockNotificationStore
    @State private var isReordering = false
    @State private var reorderError: String? = nil
    @State private var showError = false

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text(notification.productName)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                HStack(spacing: 8) {
                    Text("\(notification.currentQty) Remaining")
                        .font(.subheadline)
                        .foregroundColor(.red)
                        .fontWeight(.medium)
                    
                    Text("•")
                        .foregroundColor(.secondary)
                    
                    Text("Minimum: \(notification.reorderLevel)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Text("Low Stock")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.red)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(4)
            }
            
            Spacer()
            
            Button(action: startReorder) {
                if isReordering {
                    ProgressView()
                        .scaleEffect(0.8)
                } else {
                    Text("Reorder")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue)
                        .cornerRadius(12)
                }
            }
            .disabled(isReordering)
            .buttonStyle(.borderless)
        }
        .padding(.vertical, 4)
        .alert("Reorder Failed", isPresented: $showError) {
            Button("OK") { reorderError = nil }
        } message: {
            Text(reorderError ?? "An unexpected error occurred.")
        }
    }
    
    private func startReorder() {
        _Concurrency.Task {
            isReordering = true
            do {
                let shipmentId = UUID()
                let asn = "ASN-DC-\(Int.random(in: 100_000...999_999))"
                
                struct NewShipment: Encodable {
                    let id: UUID
                    let shipmentType: String
                    let source: String
                    let destination: String
                    let asnNumber: String
                    let status: String
                    let createdAt: Date
                    enum CodingKeys: String, CodingKey {
                        case id
                        case shipmentType = "shipment_type"
                        case source
                        case destination
                        case asnNumber = "asn_number"
                        case status
                        case createdAt = "created_at"
                    }
                }
                
                struct NewShipmentItem: Encodable {
                    let id: UUID
                    let shipmentId: UUID
                    let productId: UUID
                    let expectedQuantity: Int
                    let receivedQuantity: Int
                    let status: String
                    enum CodingKeys: String, CodingKey {
                        case id
                        case shipmentId = "shipment_id"
                        case productId = "product_id"
                        case expectedQuantity = "expected_quantity"
                        case receivedQuantity = "received_quantity"
                        case status
                    }
                }
                
                let shipment = NewShipment(
                    id: shipmentId,
                    shipmentType: "inbound",
                    source: "Distribution Centre",
                    destination: notification.warehouseName,
                    asnNumber: asn,
                    status: "pending",
                    createdAt: Date()
                )
                try await DatabaseService.shared.insert(into: "shipments", value: shipment)
                
                let shipmentItem = NewShipmentItem(
                    id: UUID(),
                    shipmentId: shipmentId,
                    productId: notification.productId,
                    expectedQuantity: notification.reorderQty,
                    receivedQuantity: 0,
                    status: "pending"
                )
                try await DatabaseService.shared.insert(into: "shipment_items", value: shipmentItem)
                
                try? await WarehouseService.shared.logAction(
                    userId: userId,
                    module: "Warehouse Replenishment",
                    action: "Requested DC replenishment for \(notification.productName) (ASN: \(asn))"
                )
                
                notificationStore.markReorderPlaced(
                    for: notification.productId,
                    asnNumber: asn,
                    shipmentId: shipmentId
                )
                
                isReordering = false
                onReordered()
            } catch {
                reorderError = error.localizedDescription
                showError = true
                isReordering = false
            }
        }
    }
}

// MARK: - StoreRequestRow

struct StoreRequestRow: View {
    let request: StockRequest
    let storeName: String
    let productName: String
    let relativeTime: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(storeName)
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
                Text(relativeTime)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            HStack(spacing: 4) {
                Text("Requested")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
                    .tracking(0.5)
                
                Spacer()
            }
            
            Text(productName)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
            
            Text("Quantity: \(request.requestedQuantity)")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}
