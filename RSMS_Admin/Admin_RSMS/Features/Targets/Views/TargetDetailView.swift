import SwiftUI

struct TargetDetailView: View {
    let target: RevenueTarget
    @ObservedObject private var dataManager = RSMSDataManager.shared
    
    // We will generate deterministic mock progress for the assigned stores.
    // In a real app this would come from a backend query matching target period + store sales.
    
    private var assignedStoreModels: [AdminStore] {
        dataManager.stores.filter { target.assignedStoreIDs.contains($0.id) }
    }
    
    private func mockProgress(for target: RevenueTarget, storeID: UUID) -> Double {
        // Deterministic mock generation based on target id string and store id
        let hash = abs((target.id.uuidString + storeID.uuidString).hashValue)
        let percent = Double(hash % 120) / 100.0 // from 0.0 to 1.19 (0% to 119%)
        return percent * target.amount
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                targetHeroSection
                
                if !assignedStoreModels.isEmpty {
                    metricsSummarySection
                }
                
                storesListSection
            }
            .padding(.top, 24)
            .padding(.horizontal, 24)
            .padding(.bottom, 60)
        }
        .background(Color.pageBG.ignoresSafeArea())
        .navigationTitle(target.name)
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - Sections
    
    private var targetHeroSection: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.brandGreenDark, Color.brandGreenDark.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 88, height: 88)
                    .shadow(color: Color.brandGreenDark.opacity(0.3), radius: 10, y: 5)
                
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 40, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .padding(.bottom, 8)
            
            VStack(spacing: 8) {
                Text(target.name)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
                
                Text(target.period.rawValue.uppercased() + " TARGET")
                    .font(.system(size: 13, weight: .bold))
                    .tracking(1.0)
                    .foregroundStyle(.secondary)
            }
            
            Text("₹\(target.amount, specifier: "%.2f")")
                .font(.system(size: 44, weight: .heavy, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.primary, Color.primary.opacity(0.8)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                
            HStack(spacing: 24) {
                VStack(spacing: 4) {
                    Image(systemName: "building.2.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(.blue)
                    Text("\(assignedStoreModels.count) Stores")
                        .font(.system(size: 13, weight: .medium))
                }
                
                Divider().frame(height: 30)
                
                VStack(spacing: 4) {
                    Image(systemName: "calendar.badge.clock")
                        .font(.system(size: 14))
                        .foregroundStyle(.orange)
                    Text("\(target.startDate.formatted(date: .abbreviated, time: .omitted)) - \(target.endDate.formatted(date: .abbreviated, time: .omitted))")
                        .font(.system(size: 13, weight: .medium))
                }
            }
            .padding(.top, 12)
            .foregroundStyle(.secondary)
        }
        .padding(32)
        .frame(maxWidth: .infinity)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: Color.black.opacity(0.04), radius: 10, y: 4)
    }
    
    private var metricsSummarySection: some View {
        let totalCurrent = assignedStoreModels.reduce(0.0) { $0 + mockProgress(for: target, storeID: $1.id) }
        let totalTarget = target.amount * Double(assignedStoreModels.count)
        let percent = totalTarget > 0 ? (totalCurrent / totalTarget) : 0
        let reachedCount = assignedStoreModels.filter { mockProgress(for: target, storeID: $0.id) >= target.amount }.count
        
        return HStack(spacing: 16) {
            metricCard(
                title: "Aggregated Progress",
                value: String(format: "%.1f%%", percent * 100),
                icon: "percent",
                iconColor: .purple
            )
            metricCard(
                title: "Stores Reached",
                value: "\(reachedCount) / \(assignedStoreModels.count)",
                icon: "checkmark.seal.fill",
                iconColor: .green
            )
        }
    }
    
    private func metricCard(title: String, value: String, icon: String, iconColor: Color) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(iconColor)
                    .font(.system(size: 16, weight: .bold))
                Spacer()
            }
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: Color.black.opacity(0.03), radius: 8, y: 3)
    }
    
    private var storesListSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Store Progress Breakdown")
                .font(.title3)
                .fontWeight(.bold)
                .padding(.top, 8)
                .padding(.horizontal, 4)
            
            if assignedStoreModels.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "building.slash.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(.secondary.opacity(0.5))
                    Text("No stores assigned to this target.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(40)
                .background(Color(uiColor: .secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 20))
            } else {
                VStack(spacing: 16) {
                    ForEach(assignedStoreModels) { store in
                        storeProgressCard(store: store)
                    }
                }
            }
        }
    }
    
    // MARK: - Subviews
    
    private func getProgressColor(percent: Double) -> Color {
        if percent < 0.3 {
            return .red
        } else if percent < 0.8 {
            return .orange
        } else {
            return .green
        }
    }
    
    private func storeProgressCard(store: AdminStore) -> some View {
        let current = mockProgress(for: target, storeID: store.id)
        let percent = current / max(target.amount, 1)
        let isReached = current >= target.amount
        let themeColor = getProgressColor(percent: percent)
        
        return VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 16) {
                // Store Avatar
                Circle()
                    .fill(Color(uiColor: .systemGray5))
                    .frame(width: 44, height: 44)
                    .overlay(
                        Text(store.managerInitials)
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(.primary)
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(store.name)
                        .font(.system(size: 16, weight: .semibold))
                    Text("Manager: \(store.managerName)")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("₹\(current, specifier: "%.0f")")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(isReached ? .green : .primary)
                    Text("Target: ₹\(target.amount, specifier: "%.0f")")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
            }
            
            // Progress Bar Area
            VStack(spacing: 8) {
                HStack {
                    if isReached {
                        Label("Target Reached!", systemImage: "star.fill")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.green)
                    } else {
                        Text("\(Int(percent * 100))% completed")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(themeColor)
                    }
                    Spacer()
                }
                
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color(uiColor: .systemGray5))
                            .frame(height: 10)
                        
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [themeColor.opacity(0.7), themeColor],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: min(CGFloat(percent) * geo.size.width, geo.size.width), height: 10)
                            .shadow(color: themeColor.opacity(0.3), radius: 4, y: 2)
                    }
                }
                .frame(height: 10)
            }
        }
        .padding(20)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: Color.black.opacity(0.03), radius: 8, y: 3)
    }
}
