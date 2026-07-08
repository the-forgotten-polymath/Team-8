//
//  StoresRequiringAttentionSection.swift
//  RSMS_Project
//
//  Horizontal scroll cards for stores requiring attention
//  Large cards (280-320pt), no percentages, just store name + one reason
//

import SwiftUI

struct StoresRequiringAttentionSection: View {
    let snapshots: [StorePerformanceSnapshot]
    let onViewAll: () -> Void
    let onSelectStore: (StorePerformanceSnapshot) -> Void

    private var displaySnapshots: [StorePerformanceSnapshot] {
        let limit = UIDevice.current.userInterfaceIdiom == .pad ? 4 : 2
        return Array(snapshots.prefix(limit))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Store Performance & Reviews")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.auditLabel)
                Spacer()
                if !snapshots.isEmpty {
                    Button(action: onViewAll) {
                        Text("View All")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(Color.auditBlue)
                    }
                }
            }
            .padding(.horizontal, AuditDS.pagePad)

            if snapshots.isEmpty {
                emptyState
                    .padding(.horizontal, AuditDS.pagePad)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: AuditDS.cardSpacing) {
                        ForEach(displaySnapshots) { snap in
                            StoreAttentionCard(snapshot: snap, onTap: { onSelectStore(snap) })
                                .frame(width: 300)
                        }
                    }
                    .padding(.horizontal, AuditDS.pagePad)
                }
            }
        }
    }

    private var emptyState: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.seal.fill")
                .foregroundColor(.auditGreen)
                .font(.system(size: 24))
            Text("All stores are performing within expected range.")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.auditLabel2)
            Spacer()
        }
        .padding(AuditDS.cardPad)
        .glassCard(material: .secondary, tint: .auditGreen)
    }
}

struct StoreAttentionCard: View {
    let snapshot: StorePerformanceSnapshot
    var onTap: (() -> Void)? = nil

    private var cardAccentColor: Color {
        snapshot.attentionReason?.color ?? .auditGreen
    }

    private var statusLabel: String {
        if let reason = snapshot.attentionReason {
            return reason.title
        }
        if let pct = snapshot.salesAchievementPct {
            if pct >= 100.0 { return "Target Met" }
            else if pct >= 90.0 { return "On Track" }
        }
        return "Fully Compliant"
    }

    private var metricValue: String {
        if let reason = snapshot.attentionReason {
            return reason.metricValue
        }
        return snapshot.salesAchievementPct.map { "\(Int($0.rounded()))%" } ?? "100%"
    }

    private var metricLabel: String {
        if let reason = snapshot.attentionReason {
            return reason.metricLabel
        }
        return "Sales Achievement"
    }

    var body: some View {
        Button(action: { onTap?() }) {
            VStack(alignment: .leading, spacing: 0) {
                // — Top row: icon + name + chevron
                HStack(alignment: .center, spacing: 10) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(cardAccentColor.opacity(0.12))
                            .frame(width: 40, height: 40)
                        Image(systemName: "storefront.fill")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(cardAccentColor)
                    }

                    Text(snapshot.store.name)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.auditLabel)
                        .lineLimit(1)
                        .truncationMode(.tail)

                    Spacer(minLength: 4)

                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.auditLabel3)
                }

                Spacer().frame(height: 10)

                // — Status pill badge
                Text(statusLabel)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(cardAccentColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(cardAccentColor.opacity(0.10), in: Capsule())
                    .overlay(Capsule().strokeBorder(cardAccentColor.opacity(0.25), lineWidth: 1))

                Spacer().frame(height: 14)

                // — Big metric value
                Text(metricValue)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.auditLabel)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                Spacer().frame(height: 2)

                // — Metric label
                Text(metricLabel)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.auditLabel2)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .glassCard()
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    let store1 = AdminStore(name: "London Flagship", address: "Bond Street", managerName: "A. Smith", managerInitials: "AS", status: .active)
    let store2 = AdminStore(name: "Dubai Mall", address: "Downtown Dubai", managerName: "B. Jones", managerInitials: "BJ", status: .active)
    let store3 = AdminStore(name: "NY Midtown", address: "Fifth Avenue", managerName: "C. Chen", managerInitials: "CC", status: .active)
    
    let snapshot1 = StorePerformanceSnapshot(
        id: store1.id, store: store1, actualRevenue: 12000, revenueTarget: 18000,
        inventoryExceptionsOpenCount: 14, shipmentDiscrepancyCount: 3, cycleCountAccuracyPct: 82,
        rejectedStockRequestCount: 1, delayedTransferCount: 0,
        attentionReason: .salesBelowTarget(achievementPct: 68)
    )
    let snapshot2 = StorePerformanceSnapshot(
        id: store2.id, store: store2, actualRevenue: 25000, revenueTarget: 22000,
        inventoryExceptionsOpenCount: 28, shipmentDiscrepancyCount: 1, cycleCountAccuracyPct: 75,
        rejectedStockRequestCount: 0, delayedTransferCount: 2,
        attentionReason: .inventoryAccuracyIssue(exceptionCount: 28)
    )
    let snapshot3 = StorePerformanceSnapshot(
        id: store3.id, store: store3, actualRevenue: 19000, revenueTarget: 20000,
        inventoryExceptionsOpenCount: 5, shipmentDiscrepancyCount: 8, cycleCountAccuracyPct: 92,
        rejectedStockRequestCount: 3, delayedTransferCount: 5,
        attentionReason: .fulfillmentDelays(issueCount: 8)
    )
    
    StoresRequiringAttentionSection(
        snapshots: [snapshot1, snapshot2, snapshot3],
        onViewAll: {},
        onSelectStore: { _ in }
    )
    .padding()
    .background(Color.auditPageBG)
}
