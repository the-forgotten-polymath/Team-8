import SwiftUI

struct AuditReviewItem: Identifiable {
    let id = UUID()
    let type: String       // e.g. "Inventory Exception Review"
    let storeName: String
    let reference: String  // e.g. "Item: SKU-10298"
    let status: ReviewStatus
    let timestamp: Date
}

enum ReviewStatus: String, CaseIterable {
    case open = "Open"
    case inProgress = "In Progress"
    case resolved = "Resolved"
    
    var color: Color {
        switch self {
        case .open: return .auditOrange
        case .inProgress: return .auditBlue
        case .resolved: return .auditGreen
        }
    }
}

struct OpenAuditReviewsSheet: View {
    let snapshots: [StorePerformanceSnapshot]
    let recentActivities: [AuditTrailEntry]
    
    @Environment(\.dismiss) private var dismiss
    @State private var selectedStatusFilter: ReviewStatus? = nil
    
    // Generate reviews in memory from database exceptions & shipment discrepancies
    private var reviewItems: [AuditReviewItem] {
        var items: [AuditReviewItem] = []
        
        // 1. Map open exceptions
        for snapshot in snapshots {
            // We can simulate exception reviews based on inventoryExceptionsOpenCount
            if snapshot.inventoryExceptionsOpenCount > 0 {
                items.append(AuditReviewItem(
                    type: "Inventory Exception Review",
                    storeName: snapshot.store.name,
                    reference: "Discrepancy count: \(snapshot.inventoryExceptionsOpenCount) items",
                    status: .open,
                    timestamp: Date().addingTimeInterval(-3600 * 4)
                ))
            }
            if snapshot.shipmentDiscrepancyCount > 0 {
                items.append(AuditReviewItem(
                    type: "Shipment Discrepancy Review",
                    storeName: snapshot.store.name,
                    reference: "ASN Discrepancy count: \(snapshot.shipmentDiscrepancyCount)",
                    status: .inProgress,
                    timestamp: Date().addingTimeInterval(-3600 * 24)
                ))
            }
            if let cycleAcc = snapshot.cycleCountAccuracyPct, cycleAcc < 90 {
                items.append(AuditReviewItem(
                    type: "Cycle Count Variance Review",
                    storeName: snapshot.store.name,
                    reference: "Accuracy: \(Int(cycleAcc))%",
                    status: .open,
                    timestamp: Date().addingTimeInterval(-3600 * 48)
                ))
            }
        }
        
        // Mock a couple resolved ones for illustration
        items.append(AuditReviewItem(
            type: "Inventory Exception Review",
            storeName: "Singapore Marina",
            reference: "SKU-99201 Resolved",
            status: .resolved,
            timestamp: Date().addingTimeInterval(-3600 * 72)
        ))
        
        items.append(AuditReviewItem(
            type: "Shipment Discrepancy Review",
            storeName: "New York Midtown",
            reference: "ASN-DC-237980 Match",
            status: .resolved,
            timestamp: Date().addingTimeInterval(-3600 * 96)
        ))
        
        if let filter = selectedStatusFilter {
            return items.filter { $0.status == filter }
        }
        return items
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Status Filter Chips
                HStack(spacing: 8) {
                    Button(action: { selectedStatusFilter = nil }) {
                        Text("All")
                            .font(.caption.weight(.bold))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(selectedStatusFilter == nil ? Color.brandGreenLight : Color.clear)
                            .clipShape(Capsule())
                            .foregroundColor(selectedStatusFilter == nil ? Color.brandGreenDark : .secondary)
                            .overlay(Capsule().stroke(selectedStatusFilter == nil ? Color.brandGreenDark.opacity(0.3) : Color.separator, lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                    
                    ForEach(ReviewStatus.allCases, id: \.self) { status in
                        Button(action: { selectedStatusFilter = status }) {
                            Text(status.rawValue)
                                .font(.caption.weight(.bold))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(selectedStatusFilter == status ? status.color.opacity(0.12) : Color.clear)
                                .clipShape(Capsule())
                                .foregroundColor(selectedStatusFilter == status ? status.color : .secondary)
                                .overlay(Capsule().stroke(selectedStatusFilter == status ? status.color.opacity(0.3) : Color.separator, lineWidth: 1))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        if reviewItems.isEmpty {
                            HStack {
                                Spacer()
                                Text("No reviews found for this filter.")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .padding(.top, 40)
                                Spacer()
                            }
                        } else {
                            ForEach(reviewItems) { item in
                                reviewRow(item: item)
                            }
                        }
                    }
                    .padding(24)
                }
            }
            .background(Color.pageBG.ignoresSafeArea())
            .navigationTitle("Open Audit Reviews")
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
    private func reviewRow(item: AuditReviewItem) -> some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(item.status.color.opacity(0.12))
                    .frame(width: 44, height: 44)
                Image(systemName: item.status == .resolved ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(item.status.color)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(item.type)
                    .font(.subheadline.bold())
                    .foregroundColor(.primary)
                
                HStack(spacing: 6) {
                    Text(item.storeName)
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.secondary)
                    
                    Circle()
                        .fill(Color.secondary.opacity(0.5))
                        .frame(width: 4, height: 4)
                    
                    Text(item.reference)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Status Badge
            Text(item.status.rawValue)
                .font(.caption2.weight(.bold))
                .foregroundColor(item.status.color)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(item.status.color.opacity(0.12))
                .clipShape(Capsule())
        }
        .padding(16)
        .background(Color.cardBG, in: RoundedRectangle(cornerRadius: 16))
        .cardShadow()
    }
}

#Preview {
    OpenAuditReviewsSheet(snapshots: [], recentActivities: [])
}
