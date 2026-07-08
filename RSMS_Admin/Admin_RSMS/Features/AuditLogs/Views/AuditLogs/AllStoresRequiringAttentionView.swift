import SwiftUI

struct AllStoresAuditView: View {
    let snapshots: [StorePerformanceSnapshot]
    let trailEntries: [AuditTrailEntry]
    let onExport: (AuditExportFormat) -> URL?

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var selectedStore: StorePerformanceSnapshot? = nil
    @State private var searchText: String = ""

    private var attentionStores: [StorePerformanceSnapshot] {
        filtered.filter { !$0.isHealthy }
    }
    private var healthyStores: [StorePerformanceSnapshot] {
        filtered.filter { $0.isHealthy }
    }
    private var filtered: [StorePerformanceSnapshot] {
        guard !searchText.isEmpty else { return snapshots }
        return snapshots.filter { $0.store.name.localizedCaseInsensitiveContains(searchText) }
    }

    private var columns: [GridItem] {
        let isIPad = UIDevice.current.userInterfaceIdiom == .pad
        return [GridItem(.adaptive(minimum: isIPad ? 280 : 160, maximum: 360), spacing: 14)]
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                if !attentionStores.isEmpty {
                    sectionHeader(
                        title: "Needs Attention",
                        count: attentionStores.count,
                        color: .auditRed
                    )
                    LazyVGrid(columns: columns, spacing: 14) {
                        ForEach(attentionStores) { snap in
                            StoreAttentionCard(snapshot: snap, onTap: { selectedStore = snap })
                        }
                    }
                }

                if !healthyStores.isEmpty {
                    sectionHeader(
                        title: "All Good",
                        count: healthyStores.count,
                        color: .auditGreen
                    )
                    LazyVGrid(columns: columns, spacing: 14) {
                        ForEach(healthyStores) { snap in
                            StoreAttentionCard(snapshot: snap, onTap: { selectedStore = snap })
                        }
                    }
                }

                if filtered.isEmpty {
                    ContentUnavailableView.search(text: searchText)
                        .padding(.top, 60)
                }
            }
            .padding(AuditDS.pagePad)
        }
        .background(Color.auditPageBG.ignoresSafeArea())
        .navigationTitle("All Stores")
        .navigationBarTitleDisplayMode(.large)
        .searchable(text: $searchText, prompt: "Search stores…")
        .sheet(item: $selectedStore) { snap in
            StoreAuditDetailsSheet(
                snapshot: snap,
                recentActivities: trailEntries,
                onExport: onExport
            )
        }
    }

    @ViewBuilder
    private func sectionHeader(title: String, count: Int, color: Color) -> some View {
        HStack(spacing: 8) {
            Text(title)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.auditLabel)
            Text("\(count)")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(color)
                .padding(.horizontal, 9)
                .padding(.vertical, 3)
                .background(color.opacity(0.12), in: Capsule())
                .overlay(Capsule().strokeBorder(color.opacity(0.25), lineWidth: 1))
        }
    }
}
