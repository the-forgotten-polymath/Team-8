//
//  ReplenishmentTrackerView.swift
//  RSMS_Project
//
//  Timeline view for the replenishment lifecycle.
//  Status progression is handled entirely via local Task.sleep timers — no DB writes.
//  On "Arrived", the user is handed off to the existing ShipmentDetailView for
//  QR scan + verify, which uses all existing functionality unchanged.
//

import SwiftUI

// MARK: - ReplenishmentTrackerView

struct ReplenishmentTrackerView: View {
    let notification: LowStockNotification
    let warehouseId: UUID
    let userId: UUID

    @EnvironmentObject private var notificationStore: LowStockNotificationStore
    @Environment(\.dismiss) private var dismiss

    @State private var localStatus: ReplenishmentStatus
    @State private var resolvedShipment: Shipment? = nil
    @State private var isLoadingShipment = false
    @State private var showScanSheet = false

    init(notification: LowStockNotification, warehouseId: UUID, userId: UUID) {
        self.notification   = notification
        self.warehouseId    = warehouseId
        self.userId         = userId
        self._localStatus   = State(initialValue: notification.replenishmentStatus)
    }

    // Steps shown in the timeline
    private let steps: [(title: String, subtitle: String, status: ReplenishmentStatus)] = [
        ("Pending",    "Replenishment request created",    .pending),
        ("In Transit", "Inbound shipment dispatched",      .inTransit),
        ("Arrived",    "Shipment arrived at warehouse",    .arrived),
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {

                // MARK: - Product card
                productCard

                // MARK: - Progress timeline
                timelineSection

                // MARK: - CTA
                if localStatus == .arrived {
                    scanVerifyButton
                } else if localStatus == .completed {
                    completedBanner
                }

                Spacer(minLength: 40)
            }
            .padding(.horizontal)
            .padding(.top, 20)
        }
        .background(Color(UIColor.systemGroupedBackground))
        .navigationTitle("Replenishment Tracker")
        .navigationBarTitleDisplayMode(.inline)
        // Auto-advance timer — restarts each time localStatus changes
        .task(id: localStatus) {
            await advanceStatus()
        }
        // Load the linked shipment once we know the ASN
        .task {
            await loadShipment()
        }
        .sheet(isPresented: $showScanSheet, onDismiss: {
            _Concurrency.Task { await checkCompletion() }
        }) {
            if let shipment = resolvedShipment {
                NavigationStack {
                    ShipmentDetailView(shipment: shipment, warehouseId: warehouseId, userId: userId)
                }
            } else {
                loadingSheetPlaceholder
            }
        }
    }

    // MARK: - Subviews

    private var productCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.orange.opacity(0.12))
                        .frame(width: 44, height: 44)
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                        .font(.system(size: 20))
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(notification.productName)
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text("SKU: \(notification.sku)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()

                // Live status chip
                statusChip(localStatus)
            }

            Divider()

            HStack(spacing: 0) {
                statCell(label: "Current Stock", value: "\(notification.currentQty)", color: .red)
                Divider().frame(height: 36)
                statCell(label: "Reorder Level",  value: "\(notification.reorderLevel)", color: .orange)
                Divider().frame(height: 36)
                statCell(label: "Reorder Qty",    value: "\(notification.reorderQty)",   color: .blue)
            }

            if let asn = notification.linkedShipmentASN {
                HStack(spacing: 6) {
                    Image(systemName: "barcode")
                        .foregroundColor(.secondary)
                        .font(.caption)
                    Text("ASN: \(asn)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(16)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.appleBorder, lineWidth: 1))
    }

    private var timelineSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Status Timeline")
                .font(.footnote)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
                .textCase(.uppercase)
                .tracking(0.5)
                .padding(.bottom, 12)

            VStack(alignment: .leading, spacing: 0) {
                ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                    TimelineStepRow(
                        step: step,
                        isActive: isStepActive(step.status),
                        isPast: isStepPast(step.status),
                        isLast: index == steps.count - 1
                    )
                }
            }
            .padding(16)
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .cornerRadius(16)
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.appleBorder, lineWidth: 1))
        }
    }

    private var scanVerifyButton: some View {
        Button(action: {
            showScanSheet = true
        }) {
            HStack(spacing: 10) {
                if isLoadingShipment {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Image(systemName: "qrcode.viewfinder")
                        .font(.headline)
                }
                Text(isLoadingShipment ? "Loading Shipment…" : "Scan & Verify Arrival")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    colors: [Color.green.opacity(0.85), Color.green],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(14)
            .shadow(color: Color.green.opacity(0.3), radius: 8, y: 4)
        }
        .disabled(isLoadingShipment)
        .animation(.easeInOut, value: isLoadingShipment)
    }

    private var completedBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.seal.fill")
                .font(.title2)
                .foregroundColor(.green)
            VStack(alignment: .leading, spacing: 2) {
                Text("Replenishment Complete")
                    .font(.headline)
                    .foregroundColor(.primary)
                Text("Stock has been received and verified.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding(16)
        .background(Color.green.opacity(0.08))
        .cornerRadius(14)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.green.opacity(0.3), lineWidth: 1))
    }

    private var loadingSheetPlaceholder: some View {
        VStack(spacing: 16) {
            ProgressView()
            Text("Loading shipment details…")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(UIColor.systemGroupedBackground))
    }

    // MARK: - Helper Views

    private func statusChip(_ status: ReplenishmentStatus) -> some View {
        Text(status.displayName)
            .font(.caption2)
            .fontWeight(.bold)
            .foregroundColor(statusColor(status))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(statusColor(status).opacity(0.12))
            .cornerRadius(6)
    }

    private func statCell(label: String, value: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(color)
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private func statusColor(_ status: ReplenishmentStatus) -> Color {
        switch status {
        case .idle:      return .gray
        case .pending:   return .orange
        case .inTransit: return .blue
        case .arrived:   return .green
        case .completed: return .green
        }
    }

    // MARK: - Step Logic

    private func isStepActive(_ step: ReplenishmentStatus) -> Bool {
        localStatus == step
    }

    private func isStepPast(_ step: ReplenishmentStatus) -> Bool {
        stepIndex(localStatus) > stepIndex(step)
    }

    private func stepIndex(_ status: ReplenishmentStatus) -> Int {
        switch status {
        case .idle:      return -1
        case .pending:   return 0
        case .inTransit: return 1
        case .arrived:   return 2
        case .completed: return 3
        }
    }

    // MARK: - Async Helpers

    /// Advances the status using local Task.sleep timers — no DB involved.
    private func advanceStatus() async {
        switch localStatus {
        case .pending:
            try? await _Concurrency.Task.sleep(nanoseconds: 5_000_000_000)   // 5 s demo delay
            guard !_Concurrency.Task.isCancelled else { return }
            withAnimation(.easeInOut) {
                localStatus = .inTransit
            }
            notificationStore.updateStatus(for: notification.id, to: .inTransit)

        case .inTransit:
            try? await _Concurrency.Task.sleep(nanoseconds: 10_000_000_000)  // 10 s demo delay
            guard !_Concurrency.Task.isCancelled else { return }
            withAnimation(.easeInOut) {
                localStatus = .arrived
            }
            notificationStore.updateStatus(for: notification.id, to: .arrived)
            // Also refresh the shipment object so it's ready
            await loadShipment()

        default:
            break
        }
    }

    /// Fetches the linked inbound Shipment from Supabase using the stored ID.
    private func loadShipment() async {
        guard let shipmentId = notification.linkedShipmentId,
              resolvedShipment == nil else { return }
        isLoadingShipment = true
        do {
            let shipments = try await WarehouseService.shared.fetchShipments()
            resolvedShipment = shipments.first(where: { $0.id == shipmentId })
        } catch {
            print("ReplenishmentTrackerView: failed to load shipment — \(error)")
        }
        isLoadingShipment = false
    }

    /// Called when ShipmentDetailView sheet is dismissed.
    /// Re-fetches the shipment and marks notification complete if status == "verified".
    private func checkCompletion() async {
        guard let shipmentId = notification.linkedShipmentId else { return }
        do {
            let shipments = try await WarehouseService.shared.fetchShipments()
            if let shipment = shipments.first(where: { $0.id == shipmentId }),
               ["verified", "completed", "arrived"].contains(shipment.status.lowercased()) {
                withAnimation {
                    localStatus = .completed
                }
                notificationStore.markCompleted(for: notification.id)
            }
        } catch {
            print("ReplenishmentTrackerView: completion check failed — \(error)")
        }
    }
}

// MARK: - TimelineStepRow

private struct TimelineStepRow: View {
    let step: (title: String, subtitle: String, status: ReplenishmentStatus)
    let isActive: Bool
    let isPast: Bool
    let isLast: Bool

    private var dotColor: Color {
        if isPast || isActive {
            switch step.status {
            case .pending:   return .orange
            case .inTransit: return .blue
            case .arrived:   return .green
            default:         return .gray
            }
        }
        return Color(UIColor.systemGray4)
    }

    private var lineColor: Color {
        isPast ? dotColor : Color(UIColor.systemGray4)
    }

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Dot + connector line
            VStack(spacing: 0) {
                ZStack {
                    Circle()
                        .fill(dotColor.opacity(isActive ? 0.15 : 0))
                        .frame(width: 28, height: 28)
                    Circle()
                        .fill(isPast ? dotColor : (isActive ? dotColor : Color(UIColor.systemGray4)))
                        .frame(width: 14, height: 14)
                    if isActive {
                        Circle()
                            .stroke(dotColor, lineWidth: 2)
                            .frame(width: 22, height: 22)
                    }
                }
                .animation(.easeInOut(duration: 0.4), value: isActive)

                if !isLast {
                    Rectangle()
                        .fill(lineColor)
                        .frame(width: 2, height: 40)
                        .animation(.easeInOut(duration: 0.4), value: isPast)
                }
            }

            // Text content
            VStack(alignment: .leading, spacing: 3) {
                Text(step.title)
                    .font(.subheadline)
                    .fontWeight(isActive ? .semibold : .regular)
                    .foregroundColor(isActive || isPast ? .primary : .secondary)
                Text(step.subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 4)
            .padding(.bottom, isLast ? 0 : 20)

            Spacer()

            if isPast {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(dotColor)
                    .padding(.top, 6)
                    .transition(.scale.combined(with: .opacity))
            }
        }
    }
}
