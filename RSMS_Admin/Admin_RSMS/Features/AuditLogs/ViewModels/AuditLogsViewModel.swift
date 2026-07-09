//
//  AuditLogsViewModel.swift
//  RSMS_Project
//

import Foundation
import SwiftUI
import Combine

@MainActor
final class AuditLogsViewModel: ObservableObject {

    // Raw data
    @Published private(set) var stores: [AdminStore] = []
    private var sales: [Sale] = []
    private var storeTargets: [StoreTarget] = []
    private var cycleCounts: [CycleCount] = []
    private var warehouses: [Warehouse] = []
    private var inventoryExceptions: [InventoryException] = []
    private var shipments: [Shipment] = []
    private var shipmentItems: [ShipmentItem] = []
    private var stockRequests: [StockRequest] = []
    private var transfers: [Transfer] = []
    private var auditLogs: [AuditLog] = []
    private var users: [User] = []

    // Derived state
    @Published private(set) var snapshots: [StorePerformanceSnapshot] = []
    @Published private(set) var trailEntries: [AuditTrailEntry] = []
    @Published private(set) var executiveSummary: String = "Analyzing store performance…"

    // UI state
    @Published var isLoading: Bool = false
    @Published var loadWarning: String?
    @Published var selectedFilter: AuditModuleFilter = .all
    @Published var selectedStoreFilter: String = "All Stores"
    @Published var selectedDateRangeFilter: DateRangeFilter = .last30Days
    @Published var customStartDate: Date = Date().addingTimeInterval(-3600 * 24 * 30)
    @Published var customEndDate: Date = Date()
    @Published var selectedEntry: AuditTrailEntry?
    @Published var selectedStoreSnapshot: StorePerformanceSnapshot?
    @Published var showExportSheet: Bool = false
    @Published var showAllStores: Bool = false
    @Published var showFullHistory: Bool = false
    @Published var showAnalysisDetail: Bool = false
    @Published var showStoreDetail: Bool = false
    @Published var showPrioritiesDetail: Bool = false
    @Published var showReviewsDetail: Bool = false
    @Published var showCoverageDetail: Bool = false
    @Published var showWatchlistDetail: Bool = false
    @Published var isGeneratingInsight: Bool = false

    private let db = DatabaseService.shared

    var filteredSnapshots: [StorePerformanceSnapshot] {
        var result = snapshots
        if selectedStoreFilter != "All Stores" {
            result = result.filter { $0.store.name.localizedCaseInsensitiveCompare(selectedStoreFilter) == .orderedSame }
        }
        return result
    }

    var storesRequiringAttention: [StorePerformanceSnapshot] {
        filteredSnapshots.filter { !$0.isHealthy }
    }

    var filteredTrailEntries: [AuditTrailEntry] {
        var result = trailEntries
        
        // 1. Module
        if selectedFilter != .all {
            result = result.filter { $0.module == selectedFilter }
        }
        
        // 2. Store
        if selectedStoreFilter != "All Stores" {
            result = result.filter { $0.storeName.localizedCaseInsensitiveCompare(selectedStoreFilter) == .orderedSame }
        }
        
        // 3. Date Range
        let now = Date()
        let calendar = Calendar.current
        let startDate: Date? = {
            switch selectedDateRangeFilter {
            case .today:
                return calendar.startOfDay(for: now)
            case .last7Days:
                return calendar.date(byAdding: .day, value: -7, to: now)
            case .last30Days:
                return calendar.date(byAdding: .day, value: -30, to: now)
            case .thisQuarter:
                let components = calendar.dateComponents([.year], from: now)
                let currentMonth = calendar.component(.month, from: now)
                let quarterStartMonth = ((currentMonth - 1) / 3) * 3 + 1
                var startComponents = DateComponents()
                startComponents.year = components.year
                startComponents.month = quarterStartMonth
                startComponents.day = 1
                return calendar.date(from: startComponents)
            case .customRange:
                return customStartDate
            }
        }()
        
        if let startDate {
            result = result.filter { $0.timestamp >= startDate }
        }
        
        return result
    }

    func updateFilters() async {
        isGeneratingInsight = true
        if selectedStoreFilter != "All Stores", let selectedSnap = snapshots.first(where: { $0.store.name.localizedCaseInsensitiveCompare(selectedStoreFilter) == .orderedSame }) {
            executiveSummary = await AuditInsightGenerator.shared.generateStoreSummary(for: selectedSnap)
        } else {
            executiveSummary = await AuditInsightGenerator.shared.generateExecutiveSummary(from: filteredSnapshots)
        }
        isGeneratingInsight = false
    }

    var currentPeriodLabel: String {
        Date().formatted(.dateTime.month(.wide).year())
    }

    func load() async {
        isLoading = true
        loadWarning = nil

        async let storesR = db.fetchResilient(from: "stores", as: AdminStore.self)
        async let salesR = db.fetchResilient(from: "sales", as: Sale.self)
        async let targetsR = db.fetchResilient(from: "store_targets", as: StoreTarget.self)
        async let cycleR = db.fetchResilient(from: "cycle_counts", as: CycleCount.self)
        async let warehousesR = db.fetchResilient(from: "warehouses", as: Warehouse.self)
        async let exceptionsR = db.fetchResilient(from: "inventory_exceptions", as: InventoryException.self)
        async let shipmentsR = db.fetchResilient(from: "shipments", as: Shipment.self)
        async let shipmentItemsR = db.fetchResilient(from: "shipment_items", as: ShipmentItem.self)
        async let stockRequestsR = db.fetchResilient(from: "stock_requests", as: StockRequest.self)
        async let transfersR = db.fetchResilient(from: "transfers", as: Transfer.self)
        async let auditLogsR = db.fetchResilient(from: "audit_logs", as: AuditLog.self)
        async let usersR = db.fetchResilient(from: "users", as: User.self)

        let (
            storesRes, salesRes, targetsRes, cycleRes, warehousesRes,
            exceptionsRes, shipmentsRes, shipmentItemsRes, stockRequestsRes,
            transfersRes, auditLogsRes, usersRes
        ) = await (
            storesR, salesR, targetsR, cycleR, warehousesR,
            exceptionsR, shipmentsR, shipmentItemsR, stockRequestsR,
            transfersR, auditLogsR, usersR
        )

        stores = storesRes.values
        sales = salesRes.values
        storeTargets = targetsRes.values
        cycleCounts = cycleRes.values
        warehouses = warehousesRes.values
        inventoryExceptions = exceptionsRes.values
        shipments = shipmentsRes.values
        shipmentItems = shipmentItemsRes.values
        stockRequests = stockRequestsRes.values
        transfers = transfersRes.values
        auditLogs = auditLogsRes.values
        users = usersRes.values

        loadWarning = nil
        if stores.isEmpty && storesRes.failureReason != nil {
            loadWarning = storesRes.failureReason
        } else if sales.isEmpty && salesRes.failureReason != nil {
            loadWarning = salesRes.failureReason
        } else if storeTargets.isEmpty && targetsRes.failureReason != nil {
            loadWarning = targetsRes.failureReason
        } else if cycleCounts.isEmpty && cycleRes.failureReason != nil {
            loadWarning = cycleRes.failureReason
        } else if warehouses.isEmpty && warehousesRes.failureReason != nil {
            loadWarning = warehousesRes.failureReason
        } else if inventoryExceptions.isEmpty && exceptionsRes.failureReason != nil {
            loadWarning = exceptionsRes.failureReason
        } else if shipments.isEmpty && shipmentsRes.failureReason != nil {
            loadWarning = shipmentsRes.failureReason
        } else if shipmentItems.isEmpty && shipmentItemsRes.failureReason != nil {
            loadWarning = shipmentItemsRes.failureReason
        } else if stockRequests.isEmpty && stockRequestsRes.failureReason != nil {
            loadWarning = stockRequestsRes.failureReason
        } else if transfers.isEmpty && transfersRes.failureReason != nil {
            loadWarning = transfersRes.failureReason
        } else if auditLogs.isEmpty && auditLogsRes.failureReason != nil {
            loadWarning = auditLogsRes.failureReason
        } else if users.isEmpty && usersRes.failureReason != nil {
            loadWarning = usersRes.failureReason
        }

        recompute()
        isLoading = false

        isGeneratingInsight = true
        executiveSummary = await AuditInsightGenerator.shared.generateExecutiveSummary(from: snapshots)
        isGeneratingInsight = false
    }

    func refresh() async {
        await load()
    }

    private func recompute() {
        snapshots = AuditRulesEngine.buildSnapshots(
            stores: stores,
            sales: sales,
            storeTargets: storeTargets,
            cycleCounts: cycleCounts,
            warehouses: warehouses,
            inventoryExceptions: inventoryExceptions,
            shipments: shipments,
            shipmentItems: shipmentItems,
            stockRequests: stockRequests,
            transfers: transfers
        )

        trailEntries = AuditRulesEngine.buildAuditTrail(
            auditLogs: auditLogs,
            users: users,
            stores: stores,
            shipments: shipments,
            shipmentItems: shipmentItems,
            stockRequests: stockRequests,
            cycleCounts: cycleCounts,
            warehouses: warehouses,
            inventoryExceptions: inventoryExceptions
        )
    }

    // MARK: - Export

    func performExport(format: AuditExportFormat) -> URL? {
        try? AuditExportService.export(
            format: format,
            period: currentPeriodLabel,
            activeFilter: selectedFilter,
            snapshots: snapshots,
            entries: filteredTrailEntries,
            executiveSummary: executiveSummary
        )
    }
}
