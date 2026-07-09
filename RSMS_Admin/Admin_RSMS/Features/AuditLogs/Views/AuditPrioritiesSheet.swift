import SwiftUI

struct PriorityItem: Identifiable {
    let id = UUID()
    let name: String
    let description: String
    let icon: String
    let color: Color
    let severity: String
    let storesAffected: [StorePriorityDetail]
}

struct StorePriorityDetail: Identifiable {
    let id = UUID()
    let name: String
    let detail: String
    let metric: String
}

struct AuditPrioritiesSheet: View {
    let snapshots: [StorePerformanceSnapshot]
    
    @Environment(\.dismiss) private var dismiss
    @State private var expandedPriorityId: UUID? = nil
    
    private var prioritiesList: [PriorityItem] {
        // Compute dynamically
        let salesAffected = snapshots.filter { ($0.salesAchievementPct ?? 100) < 90 }.map {
            StorePriorityDetail(name: $0.store.name, detail: "Below target", metric: "\(Int($0.salesAchievementPct ?? 0))%")
        }
        
        let inventoryAffected = snapshots.filter { $0.inventoryExceptionsOpenCount > 0 }.map {
            StorePriorityDetail(name: $0.store.name, detail: "Exceptions open", metric: "\($0.inventoryExceptionsOpenCount)")
        }
        
        let shipmentAffected = snapshots.filter { $0.shipmentDiscrepancyCount > 0 }.map {
            StorePriorityDetail(name: $0.store.name, detail: "Shipment discrepancy", metric: "\($0.shipmentDiscrepancyCount)")
        }
        
        let cycleAffected = snapshots.filter { ($0.cycleCountAccuracyPct ?? 100) < 90 }.map {
            StorePriorityDetail(name: $0.store.name, detail: "Count mismatch", metric: "\(Int($0.cycleCountAccuracyPct ?? 0))%")
        }
        
        return [
            PriorityItem(
                name: "Sales Performance",
                description: "Review revenue deficits against targets.",
                icon: "chart.line.downtrend.xyaxis",
                color: .auditOrange,
                severity: "High",
                storesAffected: salesAffected
            ),
            PriorityItem(
                name: "Inventory Accuracy",
                description: "Reconcile quantity discrepancies and stock counts.",
                icon: "exclamationmark.triangle.fill",
                color: .auditRed,
                severity: "Critical",
                storesAffected: inventoryAffected
            ),
            PriorityItem(
                name: "Shipment Verification",
                description: "Resolve mismatched quantities on incoming shipments.",
                icon: "shippingbox.fill",
                color: .auditBlue,
                severity: "Medium",
                storesAffected: shipmentAffected
            ),
            PriorityItem(
                name: "Cycle Count Compliance",
                description: "Audit warehouse inventory stock levels against system database.",
                icon: "arrow.triangle.2.circlepath",
                color: .auditPurple,
                severity: "Low",
                storesAffected: cycleAffected
            )
        ].sorted { $0.storesAffected.count > $1.storesAffected.count }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("CURRENT CRITICAL PRIORITIES")
                        .font(.caption2.weight(.heavy))
                        .foregroundColor(.secondary)
                        .tracking(1.0)
                        .padding(.horizontal, 4)
                    
                    VStack(spacing: 12) {
                        ForEach(prioritiesList) { priority in
                            priorityCard(priority: priority)
                        }
                    }
                }
                .padding(24)
            }
            .background(Color.pageBG.ignoresSafeArea())
            .navigationTitle("Audit Priorities")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
        }
    }
    
    @ViewBuilder
    private func priorityCard(priority: PriorityItem) -> some View {
        let isExpanded = expandedPriorityId == priority.id
        
        VStack(alignment: .leading, spacing: 0) {
            // Header Row (Tap to expand)
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    if isExpanded {
                        expandedPriorityId = nil
                    } else {
                        expandedPriorityId = priority.id
                    }
                }
            }) {
                HStack(spacing: 16) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(priority.color.opacity(0.12))
                            .frame(width: 44, height: 44)
                        Image(systemName: priority.icon)
                            .font(.headline)
                            .foregroundColor(priority.color)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(priority.name)
                            .font(.subheadline.bold())
                            .foregroundColor(.primary)
                        Text(priority.description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("\(priority.storesAffected.count) Store(s)")
                            .font(.caption.weight(.bold))
                            .foregroundColor(priority.storesAffected.isEmpty ? .secondary : priority.color)
                        
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.secondary)
                    }
                }
                .padding(16)
            }
            .buttonStyle(.plain)
            
            // Expanded Related Stores & Details
            if isExpanded {
                Divider()
                
                VStack(alignment: .leading, spacing: 12) {
                    if priority.storesAffected.isEmpty {
                        Text("No stores are currently affected by this priority issue.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.vertical, 8)
                    } else {
                        ForEach(priority.storesAffected) { detail in
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(detail.name)
                                        .font(.caption.weight(.bold))
                                        .foregroundColor(.primary)
                                    Text(detail.detail)
                                        .font(.system(size: 11))
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Text(detail.metric)
                                    .font(.caption.weight(.bold))
                                    .foregroundColor(priority.color)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(priority.color.opacity(0.1))
                                    .clipShape(Capsule())
                            }
                            .padding(.vertical, 4)
                            
                            if detail.id != priority.storesAffected.last?.id {
                                Divider()
                            }
                        }
                    }
                }
                .padding(16)
                .background(Color.pageBG.opacity(0.4))
            }
        }
        .background(Color.cardBG, in: RoundedRectangle(cornerRadius: 16))
        .cardShadow()
    }
}

#Preview {
    AuditPrioritiesSheet(snapshots: [])
}
