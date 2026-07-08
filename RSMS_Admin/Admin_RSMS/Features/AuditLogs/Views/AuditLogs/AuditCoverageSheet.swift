import SwiftUI

struct AuditCoverageSheet: View {
    let snapshots: [StorePerformanceSnapshot]
    
    @Environment(\.dismiss) private var dismiss
    
    private var totalStores: Int {
        snapshots.count
    }
    private var auditedStoresCount: Int {
        // A store is "audited" if it's healthy or has complete metrics
        snapshots.filter { $0.isHealthy || ($0.salesAchievementPct ?? 0) >= 90 }.count
    }
    private var pendingStoresCount: Int {
        totalStores - auditedStoresCount
    }
    private var completionPercentage: Double {
        guard totalStores > 0 else { return 0 }
        return (Double(auditedStoresCount) / Double(totalStores)) * 100
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Ring Progress
                    HStack {
                        Spacer()
                        ZStack {
                            Circle()
                                .stroke(Color.brandGreenLight, lineWidth: 16)
                                .frame(width: 140, height: 140)
                            
                            Circle()
                                .trim(from: 0, to: CGFloat(completionPercentage / 100))
                                .stroke(Color.brandGreenDark, style: StrokeStyle(lineWidth: 16, lineCap: .round))
                                .frame(width: 140, height: 140)
                                .rotationEffect(.degrees(-90))
                            
                            VStack(spacing: 2) {
                                Text("\(Int(completionPercentage))%")
                                    .font(.system(size: 32, weight: .bold, design: .rounded))
                                    .foregroundColor(.primary)
                                Text("COMPLETED")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.secondary)
                            }
                        }
                        Spacer()
                    }
                    .padding(.vertical, 16)
                    
                    // Stats grid
                    HStack(spacing: 16) {
                        statCard(title: "Stores Audited", value: "\(auditedStoresCount)", subtitle: "This Month", icon: "checkmark.shield.fill", color: .brandGreenDark)
                        statCard(title: "Stores Pending", value: "\(pendingStoresCount)", subtitle: "Awaiting Review", icon: "clock.badge.exclamationmark.fill", color: .auditOrange)
                    }
                    
                    // Audited stores list
                    VStack(alignment: .leading, spacing: 14) {
                        Text("STORE REVIEW STATUS")
                            .font(.caption.weight(.heavy))
                            .foregroundColor(.secondary)
                            .tracking(1.0)
                        
                        VStack(spacing: 0) {
                            ForEach(snapshots) { snap in
                                let isAudited = snap.isHealthy || (snap.salesAchievementPct ?? 0) >= 90
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(snap.store.name)
                                            .font(.bodyPrimary)
                                            .foregroundColor(.primary)
                                        Text("Manager: \(snap.store.managerName)")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    
                                    HStack(spacing: 6) {
                                        Circle()
                                            .fill(isAudited ? Color.auditGreen : Color.auditOrange)
                                            .frame(width: 8, height: 8)
                                        Text(isAudited ? "Audited" : "Pending")
                                            .font(.caption.weight(.bold))
                                            .foregroundColor(isAudited ? Color.auditGreen : Color.auditOrange)
                                    }
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background((isAudited ? Color.auditGreen : Color.auditOrange).opacity(0.12))
                                    .clipShape(Capsule())
                                }
                                .padding(.vertical, 12)
                                .padding(.horizontal, 16)
                                
                                if snap.id != snapshots.last?.id {
                                    Divider().padding(.leading, 16)
                                }
                            }
                        }
                        .background(Color.cardBG, in: RoundedRectangle(cornerRadius: 16))
                        .cardShadow()
                    }
                }
                .padding(24)
            }
            .background(Color.pageBG.ignoresSafeArea())
            .navigationTitle("Audit Coverage")
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
    private func statCard(title: String, value: String, subtitle: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.headline)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.title.bold())
                    .foregroundColor(.primary)
                Text(title)
                    .font(.caption.weight(.bold))
                    .foregroundColor(.secondary)
                Text(subtitle)
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.cardBG, in: RoundedRectangle(cornerRadius: 16))
        .cardShadow()
    }
}

#Preview {
    AuditCoverageSheet(snapshots: [])
}
