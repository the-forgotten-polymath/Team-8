//
//  CurrentAuditPrioritiesSection.swift
//  RSMS_Project
//
//  Current Audit Priorities - list-style section showing context
//  without requiring users to open each store
//

import SwiftUI

struct CurrentAuditPrioritiesSection: View {
    let snapshots: [StorePerformanceSnapshot]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Current Audit Priorities")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.auditLabel)

            if snapshots.isEmpty {
                emptyState
            } else {
                VStack(spacing: 12) {
                    ForEach(prioritizedSnapshots.prefix(3)) { snapshot in
                        if let reason = snapshot.attentionReason {
                            PriorityRow(
                                category: reason.categoryLabel,
                                storeName: snapshot.store.name,
                                description: reason.description(for: snapshot.store.name)
                            )
                        }
                    }
                }
            }
        }
    }

    private var prioritizedSnapshots: [StorePerformanceSnapshot] {
        snapshots
            .filter { $0.attentionReason != nil }
            .sorted { ($0.attentionReason?.priority ?? 999) < ($1.attentionReason?.priority ?? 999) }
    }

    private var emptyState: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.auditGreen)
                .font(.system(size: 20))
            Text("No audit priorities at this time.")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.auditLabel2)
            Spacer()
        }
        .padding(AuditDS.cardPad)
        .glassCard(material: .secondary, tint: .auditGreen)
    }
}

struct PriorityRow: View {
    let category: String
    let storeName: String
    let description: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Text(category)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.auditLabel2)
                    .tracking(0.5)
                Spacer()
            }
            Text(description)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.auditLabel)
                .lineSpacing(2)
        }
        .padding(AuditDS.cardPad)
        .glassCard(material: .secondary)
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
    
    return CurrentAuditPrioritiesSection(snapshots: [snapshot1, snapshot2, snapshot3])
        .padding()
        .background(Color.auditPageBG)
}
