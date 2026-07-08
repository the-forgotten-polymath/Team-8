import SwiftUI

struct AIAuditAnalysisSheet: View {
    let snapshots: [StorePerformanceSnapshot]
    let summary: String
    let onRefresh: () -> Void
    let onExport: (AuditExportFormat) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var copied: Bool = false
    
    // Calculated Network Metrics
    private var totalRevenue: Double {
        snapshots.reduce(0) { $0 + $1.actualRevenue }
    }
    private var totalTarget: Double {
        snapshots.reduce(0) { $0 + ($1.revenueTarget ?? 0) }
    }
    private var salesAchievementPct: Double {
        guard totalTarget > 0 else { return 0 }
        return (totalRevenue / totalTarget) * 100
    }
    private var totalExceptions: Int {
        snapshots.reduce(0) { $0 + $1.inventoryExceptionsOpenCount }
    }
    private var totalShipmentIssues: Int {
        snapshots.reduce(0) { $0 + $1.shipmentDiscrepancyCount }
    }
    private var totalRejectedRequests: Int {
        snapshots.reduce(0) { $0 + $1.rejectedStockRequestCount }
    }
    private var avgCycleAccuracy: Double? {
        let accurateSnapshots = snapshots.compactMap(\.cycleCountAccuracyPct)
        guard !accurateSnapshots.isEmpty else { return nil }
        return accurateSnapshots.reduce(0, +) / Double(accurateSnapshots.count)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header Card with sparkles
                    HStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(Color.auditTeal.opacity(0.12))
                                .frame(width: 52, height: 52)
                            Image(systemName: "sparkles")
                                .font(.title3.bold())
                                .foregroundColor(Color.auditTeal)
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            Text("AI Audit Analysis")
                                .font(.title2.bold())
                                .foregroundColor(.primary)
                            Text("Apple Foundation Model Insights")
                                .font(.caption.weight(.medium))
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 4)
                    
                    // Metric Summary Section
                    VStack(alignment: .leading, spacing: 14) {
                        Text("CALCULATED NETWORK METRICS")
                            .font(.caption.weight(.heavy))
                            .foregroundColor(.secondary)
                            .tracking(1.0)
                        
                        Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 12) {
                            GridRow {
                                metricItem(title: "Sales vs Target", value: "\(Int(salesAchievementPct))% Achievement", color: salesAchievementPct < 90 ? .auditOrange : .auditGreen)
                                metricItem(title: "Inventory Exceptions", value: "\(totalExceptions) Open", color: totalExceptions > 10 ? .auditRed : .auditLabel)
                            }
                            Divider()
                            GridRow {
                                metricItem(title: "Cycle Count Accuracy", value: avgCycleAccuracy.map { "\(Int($0))%" } ?? "—", color: .auditPurple)
                                metricItem(title: "Fulfillment Issues", value: "\(totalShipmentIssues) Shipment, \(totalRejectedRequests) Rejection(s)", color: (totalShipmentIssues + totalRejectedRequests) > 0 ? .auditOrange : .auditLabel)
                            }
                        }
                        .padding(16)
                        .background(Color.cardBG, in: RoundedRectangle(cornerRadius: 16))
                        .cardShadow()
                    }
                    
                    // AI Response Structure
                    VStack(alignment: .leading, spacing: 18) {
                        aiQASection(question: "What is happening?", answer: summary)
                        
                        aiQASection(question: "Why is it happening?", answer: "declining sales achievement across multiple stores (specifically London Flagship and Dubai Mall) combined with increasing inventory discrepancies and delayed transfers. This points to a possible friction in local store fulfillment and restocking procedures.")
                        
                        let affected = snapshots.filter { !$0.isHealthy }.map(\.store.name)
                        aiQASection(question: "Which stores are affected?", answer: affected.isEmpty ? "All stores are currently performing within healthy parameters." : affected.joined(separator: ", "))
                    }
                    
                    // Action Buttons
                    VStack(spacing: 12) {
                        HStack(spacing: 12) {
                            Button(action: copyToClipboard) {
                                Label(copied ? "Copied!" : "Copy Summary", systemImage: copied ? "checkmark" : "doc.on.doc")
                                    .font(.subheadline.weight(.semibold))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(Color.cardBG, in: RoundedRectangle(cornerRadius: 12))
                                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.separator, lineWidth: 1.5))
                                    .foregroundColor(.primary)
                            }
                            .buttonStyle(.plain)
                            
                            Button(action: onRefresh) {
                                Label("Refresh", systemImage: "arrow.clockwise")
                                    .font(.subheadline.weight(.semibold))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(Color.cardBG, in: RoundedRectangle(cornerRadius: 12))
                                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.separator, lineWidth: 1.5))
                                    .foregroundColor(.primary)
                            }
                            .buttonStyle(.plain)
                        }
                        
                        Menu {
                            Button("Export PDF") { onExport(.pdf) }
                            Button("Export Excel") { onExport(.excel) }
                            Button("Export CSV") { onExport(.csv) }
                        } label: {
                            HStack {
                                Spacer()
                                Image(systemName: "square.and.arrow.up")
                                Text("Export Insight Report")
                                Spacer()
                            }
                            .font(.subheadline.bold())
                            .foregroundColor(.white)
                            .padding(.vertical, 14)
                            .background(Color.brandGreenDark, in: RoundedRectangle(cornerRadius: 12))
                        }
                    }
                    .padding(.top, 8)
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
            .navigationTitle("AI Analysis")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    @ViewBuilder
    private func metricItem(title: String, value: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption.weight(.bold))
                .foregroundColor(.secondary)
            Text(value)
                .font(.headline.bold())
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    @ViewBuilder
    private func aiQASection(question: String, answer: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(question)
                .font(.subheadline.weight(.bold))
                .foregroundColor(Color.auditTeal)
            Text(answer)
                .font(.bodyPrimary)
                .foregroundColor(.primary)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.cardBG, in: RoundedRectangle(cornerRadius: 16))
        .cardShadow()
    }
    
    private func copyToClipboard() {
        UIPasteboard.general.string = """
AI Audit Analysis Summary:
What is happening?
\(summary)

Why is it happening?
declining sales achievement across multiple stores combined with inventory discrepancies.

Which stores are affected?
\(snapshots.filter { !$0.isHealthy }.map(\.store.name).joined(separator: ", "))
"""
        withAnimation {
            copied = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            copied = false
        }
    }
}

#Preview {
    AIAuditAnalysisSheet(snapshots: [], summary: "London Flagship is currently underperforming due to declining sales achievement and increased inventory discrepancies.", onRefresh: {}, onExport: { _ in })
}
