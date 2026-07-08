import SwiftUI

struct StoreAuditDetailsSheet: View {
    let snapshot: StorePerformanceSnapshot
    let recentActivities: [AuditTrailEntry]
    let onExport: (AuditExportFormat) -> URL?
    
    @Environment(\.dismiss) private var dismiss
    @State private var shareURL: URL?
    @State private var exportError: String?
    
    // Filter activities for this store
    private var storeActivities: [AuditTrailEntry] {
        recentActivities.filter { $0.storeName.localizedCaseInsensitiveCompare(snapshot.store.name) == .orderedSame }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header card
                    HStack(spacing: 16) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill((snapshot.attentionReason?.color ?? .auditGreen).opacity(0.12))
                                .frame(width: 52, height: 52)
                            Image(systemName: "storefront.fill")
                                .font(.title3.bold())
                                .foregroundColor(snapshot.attentionReason?.color ?? .auditGreen)
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            Text(snapshot.store.name)
                                .font(.title2.bold())
                                .foregroundColor(.primary)
                            Text(snapshot.store.address)
                                .font(.caption.weight(.medium))
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 4)
                    
                    // AI Summary Card
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 8) {
                            Image(systemName: "sparkles")
                                .foregroundColor(Color.auditTeal)
                                .font(.system(size: 16, weight: .bold))
                            Text("AI STORE SUMMARY")
                                .font(.caption.weight(.heavy))
                                .foregroundColor(Color.auditTeal)
                                .tracking(1.0)
                        }
                        
                        if let reason = snapshot.attentionReason {
                            Text(reason.description(for: snapshot.store.name) + " Operational logs indicate this discrepancy should be audited immediately to ensure inventory levels and sales alignment match records.")
                                .font(.bodyPrimary)
                                .foregroundColor(.primary)
                                .lineSpacing(4)
                                .fixedSize(horizontal: false, vertical: true)
                        } else {
                            Text("\(snapshot.store.name) is currently performing well. Sales are meeting monthly goals, inventory variance is within normal tolerances, and shipments are verified on time.")
                                .font(.bodyPrimary)
                                .foregroundColor(.primary)
                                .lineSpacing(4)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.cardBG, in: RoundedRectangle(cornerRadius: 16))
                    .cardShadow()
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(Color.auditTeal.opacity(0.15), lineWidth: 1.5)
                    )
                    
                    // Store Performance Snapshot Card
                    VStack(alignment: .leading, spacing: 14) {
                        Text("PERFORMANCE SNAPSHOT")
                            .font(.caption.weight(.heavy))
                            .foregroundColor(.secondary)
                            .tracking(1.0)
                            .padding(.horizontal, 4)
                        
                        VStack(spacing: 0) {
                            // Sales performance
                            snapshotRow(
                                title: "Sales vs Target",
                                value: snapshot.salesAchievementPct.map { "\(Int($0))% of Target" } ?? "Target not set",
                                valueColor: (snapshot.salesAchievementPct ?? 100) < 90 ? .auditOrange : .auditGreen
                            )
                            
                            Divider()
                            
                            // Inventory exception
                            snapshotRow(
                                title: "Inventory Health",
                                value: "\(snapshot.inventoryExceptionsOpenCount) Open Exception(s)",
                                valueColor: snapshot.inventoryExceptionsOpenCount > 5 ? .auditRed : .primary
                            )
                            
                            Divider()
                            
                            // Cycle counts
                            snapshotRow(
                                title: "Cycle Count Accuracy",
                                value: snapshot.cycleCountAccuracyPct.map { "\(Int($0))% Compliance" } ?? "No completed counts",
                                valueColor: (snapshot.cycleCountAccuracyPct ?? 100) < 90 ? .auditOrange : .primary
                            )
                            
                            Divider()
                            
                            // Shipment Issues
                            snapshotRow(
                                title: "Shipment Issues",
                                value: "\(snapshot.shipmentDiscrepancyCount) Discrepancies",
                                valueColor: snapshot.shipmentDiscrepancyCount > 0 ? .auditOrange : .primary
                            )
                        }
                        .background(Color.cardBG, in: RoundedRectangle(cornerRadius: 16))
                        .cardShadow()
                    }
                    
                    // Recent store activity
                    VStack(alignment: .leading, spacing: 14) {
                        Text("RECENT AUDIT ACTIVITY")
                            .font(.caption.weight(.heavy))
                            .foregroundColor(.secondary)
                            .tracking(1.0)
                            .padding(.horizontal, 4)
                        
                        if storeActivities.isEmpty {
                            HStack {
                                Spacer()
                                Text("No recent audit activities for this store.")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .padding(.vertical, 20)
                                Spacer()
                            }
                            .background(Color.cardBG, in: RoundedRectangle(cornerRadius: 16))
                            .cardShadow()
                        } else {
                            VStack(spacing: 12) {
                                ForEach(storeActivities.prefix(5)) { entry in
                                    HStack(spacing: 14) {
                                        ZStack {
                                            Circle()
                                                .fill(entry.tint.opacity(0.12))
                                                .frame(width: 36, height: 36)
                                            Image(systemName: entry.icon)
                                                .font(.system(size: 14, weight: .semibold))
                                                .foregroundColor(entry.tint)
                                        }
                                        
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(entry.title)
                                                .font(.subheadline.bold())
                                                .foregroundColor(.primary)
                                            Text(entry.subtitle)
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                                .lineLimit(1)
                                        }
                                        
                                        Spacer()
                                        
                                        Text(entry.timestamp.formatted(date: .omitted, time: .shortened))
                                            .font(.caption2.weight(.medium))
                                            .foregroundColor(.secondary)
                                    }
                                    .padding(.vertical, 4)
                                    
                                    if entry.id != storeActivities.prefix(5).last?.id {
                                        Divider()
                                    }
                                }
                            }
                            .padding(16)
                            .background(Color.cardBG, in: RoundedRectangle(cornerRadius: 16))
                            .cardShadow()
                        }
                    }
                    
                    Menu {
                        Button("Export as PDF")   { triggerExport(.pdf) }
                        Button("Export as Excel") { triggerExport(.excel) }
                        Button("Export as CSV")   { triggerExport(.csv) }
                    } label: {
                        HStack {
                            Spacer()
                            Image(systemName: "square.and.arrow.up")
                            Text("Export Store Report")
                            Spacer()
                        }
                        .font(.subheadline.bold())
                        .foregroundColor(.white)
                        .padding(.vertical, 14)
                        .background(Color.brandGreenDark, in: RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.top, 8)
                    
                    if let exportError {
                        Text(exportError)
                            .font(.caption)
                            .foregroundColor(.auditRed)
                            .padding(.top, 4)
                    }
                }
                .padding(24)
            }
            .background(Color.pageBG.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
            .navigationTitle("Store Audit Details")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(item: $shareURL) { url in
                ShareSheet(activityItems: [url])
            }
        }
    }
    
    private func triggerExport(_ format: AuditExportFormat) {
        if let url = onExport(format) {
            shareURL = url
        } else {
            exportError = "Couldn't generate the \(format.rawValue) file. Please try again."
        }
    }
    
    @ViewBuilder
    private func snapshotRow(title: String, value: String, valueColor: Color) -> some View {
        HStack {
            Text(title)
                .font(.bodyPrimary)
                .foregroundColor(.primary)
            Spacer()
            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(valueColor)
        }
        .padding(16)
    }
}

#Preview {
    let store = AdminStore(name: "London Flagship", address: "Bond Street", managerName: "A. Smith", managerInitials: "AS", status: .active)
    let snapshot = StorePerformanceSnapshot(
        id: store.id, store: store, actualRevenue: 15000, revenueTarget: 20000,
        inventoryExceptionsOpenCount: 4, shipmentDiscrepancyCount: 1, cycleCountAccuracyPct: 91,
        rejectedStockRequestCount: 2, delayedTransferCount: 1,
        attentionReason: .salesBelowTarget(achievementPct: 75)
    )
    StoreAuditDetailsSheet(snapshot: snapshot, recentActivities: [], onExport: { _ in nil })
}
