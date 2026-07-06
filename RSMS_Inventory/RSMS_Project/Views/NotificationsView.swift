//
//  NotificationsView.swift
//  RSMS_Project
//
//  Presented as a sheet from the Dashboard bell icon.
//  Reorder logic is identical to LowStockAlertView — same Supabase inserts.
//  Status progression and tracking are handled locally via ReplenishmentTrackerView.
//

import SwiftUI

// MARK: - NotificationsView

struct NotificationsView: View {
    let warehouseId: UUID
    let userId: UUID

    @EnvironmentObject private var notificationStore: LowStockNotificationStore
    @Environment(\.dismiss) private var dismiss

    @State private var trackerTarget: LowStockNotification? = nil
    @State private var showTracker = false

    // Computed outside any @ViewBuilder closure to avoid type-inference issues
    private var activeAlerts: [LowStockNotification] {
        notificationStore.notifications.filter { $0.replenishmentStatus != .completed }
    }

    private var completedAlerts: [LowStockNotification] {
        notificationStore.notifications.filter { $0.replenishmentStatus == .completed }
    }

    private var hasCompleted: Bool {
        !completedAlerts.isEmpty
    }

    var body: some View {
        NavigationStack {
            Group {
                if notificationStore.notifications.isEmpty {
                    emptyState
                } else {
                    notificationList
                }
            }
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    if hasCompleted {
                        Button("Clear Done") {
                            notificationStore.clearCompleted()
                        }
                        .foregroundColor(.secondary)
                    }
                }
            }
            .navigationDestination(isPresented: $showTracker) {
                if let note = trackerTarget {
                    ReplenishmentTrackerView(
                        notification: note,
                        warehouseId: warehouseId,
                        userId: userId
                    )
                    .environmentObject(notificationStore)
                }
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
            Text("All stock levels are currently healthy.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .padding(.horizontal, 40)
    }

    // MARK: - Notification List

    private var notificationList: some View {
        // `let` bindings are here — outside @ViewBuilder — so the compiler
        // can resolve types before entering the List closure.
        let active    = activeAlerts
        let completed = completedAlerts

        return List {
            if !active.isEmpty {
                Section(header: activeSectionHeader) {
                    ForEach(active) { note in
                        NotificationCardRow(
                            notification: note,
                            warehouseId: warehouseId,
                            userId: userId,
                            onTrack: {
                                trackerTarget = notificationStore.notifications
                                    .first(where: { $0.id == note.id }) ?? note
                                showTracker = true
                            }
                        )
                        .environmentObject(notificationStore)
                    }
                }
            }

            if !completed.isEmpty {
                Section(header: completedSectionHeader) {
                    ForEach(completed) { note in
                        CompletedNotificationRow(notification: note)
                    }
                }

                Section {
                    Button(action: { notificationStore.clearCompleted() }) {
                        Text("Clear Completed")
                            .foregroundColor(.red)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    // MARK: - Section Headers (separate @ViewBuilder props avoid trailing-closure ambiguity)

    private var activeSectionHeader: some View {
        HStack(spacing: 6) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)
            Text("Active Alerts")
        }
    }

    private var completedSectionHeader: some View {
        HStack(spacing: 6) {
            Image(systemName: "checkmark.seal.fill")
                .foregroundColor(.green)
            Text("Fulfilled")
        }
    }
}

// MARK: - NotificationCardRow

private struct NotificationCardRow: View {
    let notification: LowStockNotification
    let warehouseId: UUID
    let userId: UUID
    let onTrack: () -> Void

    @EnvironmentObject private var notificationStore: LowStockNotificationStore
    @State private var isReordering = false
    @State private var reorderError: String? = nil
    @State private var showError = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header row
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(notification.productName)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    Text("SKU: \(notification.sku)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Text(relativeTime(notification.detectedAt))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            // Stock stats row
            HStack(spacing: 16) {
                stockStat(label: "Stock",      value: "\(notification.currentQty)",   color: .red)
                stockStat(label: "Reorder at", value: "\(notification.reorderLevel)", color: .orange)
                stockStat(label: "Reorder qty",value: "\(notification.reorderQty)",   color: .blue)
            }

            // Warehouse
            Label(notification.warehouseName, systemImage: "building.2")
                .font(.caption)
                .foregroundColor(.secondary)

            // Action
            actionRow
        }
        .padding(.vertical, 4)
        .alert(
            "Reorder Failed",
            isPresented: $showError
        ) {
            Button("OK") { reorderError = nil }
        } message: {
            Text(reorderError ?? "An unexpected error occurred.")
        }
    }

    // MARK: - Action Row

    @ViewBuilder
    private var actionRow: some View {
        switch notification.replenishmentStatus {
        case .idle:
            reorderButton

        case .pending, .inTransit, .arrived:
            HStack {
                statusPill(notification.replenishmentStatus)
                Spacer()
                Button(action: onTrack) {
                    HStack(spacing: 4) {
                        Text("Track")
                            .fontWeight(.medium)
                        Image(systemName: "chevron.right")
                    }
                    .font(.subheadline)
                    .foregroundColor(.blue)
                }
            }

        case .completed:
            statusPill(.completed)
        }
    }

    private func startReorder() {
        _Concurrency.Task { await placeReorder() }
    }

    private var reorderButton: some View {
        Button {
            startReorder()
        } label: {
            HStack(spacing: 6) {
                if isReordering {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.7)
                } else {
                    Image(systemName: "arrow.clockwise.circle.fill")
                }
                Text(isReordering ? "Requesting…" : "Reorder")
                    .fontWeight(.semibold)
            }
            .font(.subheadline)
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
            .background(isReordering ? Color.blue.opacity(0.5) : Color.blue)
            .cornerRadius(10)
        }
        .disabled(isReordering)
    }

    // MARK: - Reorder (same DB inserts as LowStockAlertView)

    private func placeReorder() async {
        isReordering = true

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
                case asnNumber    = "asn_number"
                case status
                case createdAt    = "created_at"
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
                case shipmentId       = "shipment_id"
                case productId        = "product_id"
                case expectedQuantity = "expected_quantity"
                case receivedQuantity = "received_quantity"
                case status
            }
        }

        do {
            let shipmentId = UUID()
            let asn = "ASN-DC-\(Int.random(in: 100_000...999_999))"

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
        } catch {
            reorderError = error.localizedDescription
            showError = true
        }

        isReordering = false
    }

    // MARK: - Helper Views

    private func stockStat(label: String, value: String, color: Color) -> some View {
        VStack(spacing: 1) {
            Text(value)
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(color)
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }

    private func statusPill(_ status: ReplenishmentStatus) -> some View {
        HStack(spacing: 5) {
            Image(systemName: status.sfSymbol)
                .font(.caption2)
            Text(status.displayName)
                .font(.caption)
                .fontWeight(.medium)
        }
        .foregroundColor(pillColor(status))
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(pillColor(status).opacity(0.1))
        .cornerRadius(20)
    }

    private func pillColor(_ status: ReplenishmentStatus) -> Color {
        switch status {
        case .idle:      return .gray
        case .pending:   return .orange
        case .inTransit: return .blue
        case .arrived:   return .green
        case .completed: return .green
        }
    }

    private func relativeTime(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - CompletedNotificationRow

private struct CompletedNotificationRow: View {
    let notification: LowStockNotification

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text(notification.productName)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text("Replenishment completed • \(notification.reorderQty) units")
                    .font(.caption)
                    .foregroundColor(Color(UIColor.tertiaryLabel))
            }
            Spacer()
            Image(systemName: "checkmark.seal.fill")
                .foregroundColor(.green)
        }
        .padding(.vertical, 2)
    }
}
