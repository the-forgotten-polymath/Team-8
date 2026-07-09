import SwiftUI

struct AuditLogsView: View {
    @StateObject private var viewModel = AuditLogsViewModel()

    // Calculated Network Summary Metrics
    private var totalStores: Int {
        viewModel.snapshots.count
    }
    private var auditedStoresCount: Int {
        viewModel.snapshots.filter { $0.isHealthy || ($0.salesAchievementPct ?? 0) >= 90 }.count
    }
    private var completionPercentage: Double {
        guard totalStores > 0 else { return 0 }
        return (Double(auditedStoresCount) / Double(totalStores)) * 100
    }
    private var openReviewsCount: Int {
        viewModel.snapshots.filter { !$0.isHealthy }.count
    }
    private var prioritiesCount: Int {
        viewModel.storesRequiringAttention.count
    }
    private var watchlistCount: Int {
        viewModel.storesRequiringAttention.filter { ($0.attentionReason?.priority ?? 99) <= 1 }.count
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AuditDS.sectionSpacing) {
                    
                    if let loadWarning = viewModel.loadWarning {
                        Text(loadWarning)
                            .font(.footnote.weight(.medium))
                            .foregroundColor(.red)
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.red.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
                            .padding(.horizontal, AuditDS.pagePad)
                    }

                    // Section 1: AI Audit Insight (Hero Card)
                    AuditInsightCard(
                        summary: viewModel.executiveSummary,
                        isGenerating: viewModel.isGeneratingInsight,
                        onViewAnalysis: { viewModel.showAnalysisDetail = true }
                    )
                    .padding(.horizontal, AuditDS.pagePad)
                    
                    Divider()
                        .opacity(0.4)
                        .padding(.horizontal, AuditDS.pagePad)

                    // Section 2: Store Performance & Reviews (Horizontal Cards)
                    StoresRequiringAttentionSection(
                        snapshots: viewModel.snapshots,
                        onViewAll: { viewModel.showAllStores = true },
                        onSelectStore: { snapshot in
                            viewModel.selectedStoreSnapshot = snapshot
                            viewModel.showStoreDetail = true
                        }
                    )
                    
                    Divider()
                        .opacity(0.4)
                        .padding(.horizontal, AuditDS.pagePad)

                    // Section 3: Audit Timeline & Activities Feed
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Audit Timeline")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.auditLabel)
                            .padding(.horizontal, AuditDS.pagePad)
                        
                        filterHeader
                        
                        AuditTrailFeed(
                            entries: viewModel.filteredTrailEntries,
                            isLoading: viewModel.isLoading,
                            onSelect: { entry in
                                viewModel.selectedEntry = entry
                            },
                            onViewFullHistory: { viewModel.showFullHistory = true }
                        )
                        .padding(.horizontal, AuditDS.pagePad)
                    }
                    
                    // Bottom padding
                    Spacer().frame(height: 32)
                }
                .padding(.vertical, 16)
            }
            .background(Color.pageBG.ignoresSafeArea())
            .navigationTitle("Audit Logs")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        viewModel.showExportSheet = true
                    } label: {
                        Label("Export", systemImage: "square.and.arrow.up")
                            .font(.system(size: 15, weight: .semibold))
                    }
                }
            }
            .refreshable { await viewModel.refresh() }
            .task { await viewModel.load() }
            .sheet(item: $viewModel.selectedEntry) { entry in
                AuditDetailSheet(entry: entry)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $viewModel.showExportSheet) {
                ExportSheet(
                    period: viewModel.currentPeriodLabel,
                    activeFilter: viewModel.selectedFilter,
                    onExport: { format in viewModel.performExport(format: format) }
                )
                .presentationDetents([.height(360)])
                .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $viewModel.showAnalysisDetail) {
                AIAuditAnalysisSheet(
                    snapshots: viewModel.snapshots,
                    summary: viewModel.executiveSummary,
                    onRefresh: { Task { await viewModel.refresh() } },
                    onExport: { format in viewModel.performExport(format: format) }
                )
            }
            .sheet(isPresented: $viewModel.showStoreDetail) {
                if let snap = viewModel.selectedStoreSnapshot {
                    StoreAuditDetailsSheet(
                        snapshot: snap,
                        recentActivities: viewModel.trailEntries,
                        onExport: { format in viewModel.performExport(format: format) }
                    )
                }
            }
            .sheet(isPresented: $viewModel.showPrioritiesDetail) {
                AuditPrioritiesSheet(snapshots: viewModel.snapshots)
            }
            .sheet(isPresented: $viewModel.showReviewsDetail) {
                OpenAuditReviewsSheet(snapshots: viewModel.snapshots, recentActivities: viewModel.trailEntries)
            }
            .sheet(isPresented: $viewModel.showCoverageDetail) {
                AuditCoverageSheet(snapshots: viewModel.snapshots)
            }
            .sheet(isPresented: $viewModel.showWatchlistDetail) {
                WatchlistSheet(snapshots: viewModel.storesRequiringAttention) { snapshot in
                    viewModel.selectedStoreSnapshot = snapshot
                    viewModel.showStoreDetail = true
                }
            }
            .navigationDestination(isPresented: $viewModel.showFullHistory) {
                AuditHistoryView(
                    entries: viewModel.trailEntries,
                    stores: viewModel.stores,
                    onExport: { format in viewModel.performExport(format: format) }
                )
            }
            .navigationDestination(isPresented: $viewModel.showAllStores) {
                AllStoresAuditView(
                    snapshots: viewModel.snapshots,
                    trailEntries: viewModel.trailEntries,
                    onExport: { format in viewModel.performExport(format: format) }
                )
            }
        }
    }
    
    // MARK: - Filters Bar
    
    @ViewBuilder
    private var filterHeader: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                // Store Filter Dropdown
                Menu {
                    Button("All Stores") {
                        viewModel.selectedStoreFilter = "All Stores"
                        Task { await viewModel.updateFilters() }
                    }
                    ForEach(viewModel.stores) { store in
                        Button(store.name) {
                            viewModel.selectedStoreFilter = store.name
                            Task { await viewModel.updateFilters() }
                        }
                    }
                } label: {
                    HStack(spacing: 6) {
                        Text("Store: \(viewModel.selectedStoreFilter)")
                            .font(.caption.weight(.bold))
                        Image(systemName: "chevron.down")
                            .font(.system(size: 10, weight: .bold))
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .glassChip(isSelected: false)
                    .foregroundColor(.primary)
                }
                
                // Date Range Filter Dropdown
                Menu {
                    ForEach(DateRangeFilter.allCases) { filter in
                        Button(filter.rawValue) {
                            viewModel.selectedDateRangeFilter = filter
                            Task { await viewModel.updateFilters() }
                        }
                    }
                } label: {
                    HStack(spacing: 6) {
                        Text("Date: \(viewModel.selectedDateRangeFilter.rawValue)")
                            .font(.caption.weight(.bold))
                        Image(systemName: "chevron.down")
                            .font(.system(size: 10, weight: .bold))
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .glassChip(isSelected: false)
                    .foregroundColor(.primary)
                }
                
                // Divider
                Color.secondary.opacity(0.3)
                    .frame(width: 1, height: 16)
                
                // Focus area chips
                ForEach(AuditModuleFilter.allCases) { filter in
                    let isSelected = viewModel.selectedFilter == filter
                    let tint = filter.accentColor
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                            viewModel.selectedFilter = filter
                        }
                    }) {
                        Text(filter.rawValue)
                            .font(.caption.weight(.bold))
                            .foregroundColor(isSelected ? tint : .primary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                    }
                    .glassChip(isSelected: isSelected, tint: tint)
                }
            }
            .padding(.horizontal, AuditDS.pagePad)
            .padding(.vertical, 4)
        }
    }
    
    // MARK: - Grid summary cards
    
    @ViewBuilder
    private var summaryGridItems: some View {
        // 1. Audit Coverage Card
        Button(action: { viewModel.showCoverageDetail = true }) {
            StatisticCard(
                category: "Coverage",
                title: "Network Audited",
                value: "\(Int(completionPercentage))%",
                footnoteLeft: "\(auditedStoresCount) of \(totalStores)",
                footnoteRight: "Stores",
                iconName: "checkmark.shield.fill",
                iconColor: .brandGreenDark,
                iconBackground: Color.brandGreenLight
            )
        }
        .buttonStyle(.plain)
        
        // 2. Open Audit Reviews Card
        Button(action: { viewModel.showReviewsDetail = true }) {
            StatisticCard(
                category: "Reviews",
                title: "Open Reviews",
                value: "\(openReviewsCount)",
                footnoteLeft: "\(openReviewsCount) Unresolved",
                footnoteRight: "Cases",
                iconName: "exclamationmark.triangle.fill",
                iconColor: .auditOrange,
                iconBackground: Color.auditOrange.opacity(0.15)
            )
        }
        .buttonStyle(.plain)
        
        // 3. Current Audit Priorities Card
        Button(action: { viewModel.showPrioritiesDetail = true }) {
            StatisticCard(
                category: "Priorities",
                title: "Audit Priorities",
                value: "\(prioritiesCount)",
                footnoteLeft: "\(prioritiesCount) Active",
                footnoteRight: "Priorities",
                iconName: "list.bullet.clipboard.fill",
                iconColor: .auditRed,
                iconBackground: Color.auditRed.opacity(0.15)
            )
        }
        .buttonStyle(.plain)
        
        // 4. Attention Watchlist Card
        Button(action: { viewModel.showWatchlistDetail = true }) {
            StatisticCard(
                category: "Watchlist",
                title: "Watchlist Stores",
                value: "\(watchlistCount)",
                footnoteLeft: "\(watchlistCount) Critical",
                footnoteRight: "Stores",
                iconName: "eye.fill",
                iconColor: .auditPurple,
                iconBackground: Color.auditPurple.opacity(0.15)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    AuditLogsView()
}
