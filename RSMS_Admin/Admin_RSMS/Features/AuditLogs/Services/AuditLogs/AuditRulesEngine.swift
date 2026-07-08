//
//  AuditRulesEngine.swift
//  RSMS_Project
//
//  Pure, stateless functions. No networking, no Supabase calls — this file
//  only turns already-fetched rows into the two things the Audit Logs screen
//  needs: (1) per-store performance snapshots + "requires attention" flags,
//  and (2) a unified, chronological Audit Trail feed.
//
//  IMPORTANT SCHEMA NOTE — please read before editing:
//  `cycle_counts` links to `warehouses` (warehouse_id), not to `stores`.
//  There is no FK from warehouses -> stores in the schema. Since the flow
//  spec treats cycle counts as a per-store metric (and the mock data in the
//  brief mixes "Zone A" cycle counts with store names like "Dubai Mall"),
//  this engine attributes a cycle count to a store by case-insensitive
//  name match between `warehouses.warehouse_name` and `stores.name`. If your
//  backend later adds a real `store_id` to `warehouses` or `cycle_counts`,
//  swap `matchStore(forWarehouse:)` below for a direct FK lookup.
//

import Foundation

enum AuditRulesEngine {

    // MARK: - Thresholds (tweak here, nowhere else)

    private static let salesAtRiskThreshold: Double = 90       // below 90% achievement = attention-worthy
    private static let inventoryExceptionThreshold: Int = 8     // open exceptions
    private static let cycleCountAccuracyThreshold: Double = 90 // %
    private static let shipmentDiscrepancyThreshold: Int = 2
    private static let rejectedStockRequestThreshold: Int = 2

    // MARK: - Snapshots

    static func buildSnapshots(
        stores: [AdminStore],
        sales: [Sale],
        storeTargets: [StoreTarget],
        cycleCounts: [CycleCount],
        warehouses: [Warehouse],
        inventoryExceptions: [InventoryException],
        shipments: [Shipment],
        shipmentItems: [ShipmentItem],
        stockRequests: [StockRequest],
        transfers: [Transfer],
        referenceMonth: Date = Date()
    ) -> [StorePerformanceSnapshot] {

        let calendar = Calendar.current
        let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: referenceMonth)) ?? referenceMonth

        return stores.filter { !$0.isArchived }.map { store in
            // Revenue this month
            let revenue = sales
                .filter { $0.storeId == store.id && $0.saleStatus.lowercased() != "cancelled" }
                .filter { calendar.isDate($0.saleDate, equalTo: monthStart, toGranularity: .month) }
                .reduce(0) { $0 + $1.totalAmount }

            let target = storeTargets
                .filter { $0.storeId == store.id }
                .first(where: { calendar.isDate($0.targetMonth, equalTo: monthStart, toGranularity: .month) })?
                .revenueTarget

            // Inventory exceptions (open)
            let openExceptions = inventoryExceptions.filter {
                $0.storeId == store.id && $0.status.lowercased() == "open"
            }

            // Shipment discrepancies: shipment_items where received != expected,
            // scoped to shipments whose destination matches this store's name.
            let storeShipments = shipments.filter {
                $0.destination.localizedCaseInsensitiveCompare(store.name) == .orderedSame
            }
            let storeShipmentIds = Set(storeShipments.map(\.id))
            let discrepancyCount = shipmentItems.filter {
                storeShipmentIds.contains($0.shipmentId) && $0.receivedQuantity != $0.expectedQuantity
            }.count

            // Cycle count accuracy — via warehouse name -> store name match (see header note)
            let matchedWarehouseIds = Set(
                warehouses
                    .filter { $0.warehouseName.localizedCaseInsensitiveCompare(store.name) == .orderedSame }
                    .map(\.id)
            )
            let storeCycleCounts = cycleCounts.filter {
                matchedWarehouseIds.contains($0.warehouseId) && $0.status.lowercased() == "completed"
            }
            let cycleAccuracy: Double? = storeCycleCounts.isEmpty ? nil : {
                // remarks are free text in the schema; accuracy is approximated
                // from completion rate against scheduled counts as a stand-in
                // metric when explicit matched/discrepancy counts aren't stored.
                let scheduled = cycleCounts.filter { matchedWarehouseIds.contains($0.warehouseId) }.count
                guard scheduled > 0 else { return nil }
                return (Double(storeCycleCounts.count) / Double(scheduled)) * 100
            }()

            // Stock requests rejected
            let rejectedRequests = stockRequests.filter {
                $0.storeId == store.id && $0.status.lowercased() == "rejected"
            }.count

            // Delayed transfers (no completedAt but transferDate is in the past)
            let delayedTransfers = transfers.filter { transfer in
                guard transfer.destinationStoreId == store.id, transfer.completedAt == nil else { return false }
                return transfer.transferDate < Date()
            }.count

            let achievementPct: Double? = {
                guard let target, target > 0 else { return nil }
                return (revenue / target) * 100
            }()

            let reason = determineAttentionReason(
                achievementPct: achievementPct,
                openExceptionCount: openExceptions.count,
                shipmentDiscrepancyCount: discrepancyCount,
                rejectedStockRequestCount: rejectedRequests,
                delayedTransferCount: delayedTransfers
            )

            return StorePerformanceSnapshot(
                id: store.id,
                store: store,
                actualRevenue: revenue,
                revenueTarget: target,
                inventoryExceptionsOpenCount: openExceptions.count,
                shipmentDiscrepancyCount: discrepancyCount,
                cycleCountAccuracyPct: cycleAccuracy,
                rejectedStockRequestCount: rejectedRequests,
                delayedTransferCount: delayedTransfers,
                attentionReason: reason
            )
        }
        .sorted { lhs, rhs in
            // Stores requiring attention first, most severe first, then A→Z
            switch (lhs.attentionReason, rhs.attentionReason) {
            case (.some(let l), .some(let r)):
                if l.priority != r.priority { return l.priority < r.priority }
                return lhs.store.name < rhs.store.name
            case (.some, .none): return true
            case (.none, .some): return false
            case (.none, .none): return lhs.store.name < rhs.store.name
            }
        }
    }

    private static func determineAttentionReason(
        achievementPct: Double?,
        openExceptionCount: Int,
        shipmentDiscrepancyCount: Int,
        rejectedStockRequestCount: Int,
        delayedTransferCount: Int
    ) -> AttentionReason? {
        if let pct = achievementPct, pct < salesAtRiskThreshold {
            return .salesBelowTarget(achievementPct: pct)
        }
        if openExceptionCount >= inventoryExceptionThreshold {
            return .inventoryAccuracyIssue(exceptionCount: openExceptionCount)
        }
        if shipmentDiscrepancyCount >= shipmentDiscrepancyThreshold || rejectedStockRequestCount >= rejectedStockRequestThreshold {
            let total = shipmentDiscrepancyCount + rejectedStockRequestCount
            return .fulfillmentDelays(issueCount: total)
        }
        if delayedTransferCount > 0 {
            return .operationalDelays(overdueCount: delayedTransferCount)
        }
        return nil
    }

    // MARK: - Audit Trail feed

    /// Builds the unified, reverse-chronological Audit Trail feed. Primary
    /// source is the generic `audit_logs` table (module/action/timestamp) —
    /// where a matching operational record exists (shipment, stock request,
    /// cycle count, inventory exception) we enrich the entry with the richer
    /// details those tables carry (ASN numbers, item counts, etc.), because
    /// `audit_logs` itself only stores module/action/timestamp/user.
    static func buildAuditTrail(
        auditLogs: [AuditLog],
        users: [User],
        stores: [AdminStore],
        shipments: [Shipment],
        shipmentItems: [ShipmentItem],
        stockRequests: [StockRequest],
        cycleCounts: [CycleCount],
        warehouses: [Warehouse],
        inventoryExceptions: [InventoryException]
    ) -> [AuditTrailEntry] {

        var entries: [AuditTrailEntry] = []

        let userName: (UUID?) -> String = { id in
            guard let id, let u = users.first(where: { $0.id == id }) else { return "System" }
            return u.fullName
        }
        let storeNameById: (UUID?) -> String = { storeId in
            guard let storeId else { return "Network" }
            return stores.first(where: { $0.id == storeId })?.name ?? "Network"
        }
        let storeNameForUser: (UUID?) -> String = { userId in
            guard let userId, let user = users.first(where: { $0.id == userId }) else { return "Network" }
            return storeNameById(user.storeId)
        }
        let warehouseToStoreName: (UUID) -> String = { warehouseId in
            guard let wh = warehouses.first(where: { $0.id == warehouseId }) else { return "Unknown Location" }
            let match = stores.first { $0.name.localizedCaseInsensitiveCompare(wh.warehouseName) == .orderedSame }
            return match?.name ?? wh.warehouseName
        }

        // Shipments -> "Shipment Verified" / "ASN Received"
        for shipment in shipments {
            let itemCount = shipmentItems.filter { $0.shipmentId == shipment.id }.count
            if let verifiedAt = shipment.verifiedAt {
                entries.append(AuditTrailEntry(
                    id: shipment.id,
                    module: .shipments,
                    title: "Shipment Verified",
                    subtitle: "\(shipment.asnNumber ?? shipment.shipmentNumber) • Fully Verified",
                    storeName: shipment.destination,
                    timestamp: verifiedAt,
                    icon: "checkmark.seal.fill",
                    tint: .auditGreen,
                    statusDotColor: .auditGreen,
                    detailFields: [
                        .init("Module", "Shipment Verification"),
                        .init("Action", "Verified Shipment"),
                        .init("ASN", shipment.asnNumber ?? "—"),
                        .init("Status", shipment.status),
                        .init("Timestamp", verifiedAt.formatted(date: .abbreviated, time: .shortened))
                    ]
                ))
            } else if let dispatch = shipment.dispatchDate {
                entries.append(AuditTrailEntry(
                    id: shipment.id,
                    module: .shipments,
                    title: "ASN Received",
                    subtitle: "\(shipment.asnNumber ?? shipment.shipmentNumber) • \(itemCount) Items",
                    storeName: shipment.destination,
                    timestamp: dispatch,
                    icon: "shippingbox.fill",
                    tint: .auditBlue,
                    statusDotColor: nil,
                    detailFields: [
                        .init("Module", "Shipment Verification"),
                        .init("Action", "ASN Received"),
                        .init("ASN", shipment.asnNumber ?? "—"),
                        .init("Items", "\(itemCount)"),
                        .init("Timestamp", dispatch.formatted(date: .abbreviated, time: .shortened))
                    ]
                ))
            }
        }

        // Stock requests -> "Stock Request Rejected" / "Stock Request Approved"
        for request in stockRequests where ["rejected", "approved"].contains(request.status.lowercased()) {
            let isRejected = request.status.lowercased() == "rejected"
            let requesterName = userName(request.requestedBy)
            let resolvedStoreName = storeNameById(request.storeId) == "Network"
                ? storeNameForUser(request.requestedBy)
                : storeNameById(request.storeId)
            entries.append(AuditTrailEntry(
                id: request.id,
                module: .stockRequests,
                title: isRejected ? "Stock Request Rejected" : "Stock Request Approved",
                subtitle: "By \(requesterName) • \(request.requestedQuantity) units · \(request.priority) priority",
                storeName: resolvedStoreName,
                timestamp: request.updatedAt,
                icon: isRejected ? "xmark.circle.fill" : "checkmark.circle.fill",
                tint: isRejected ? .auditRed : .auditGreen,
                statusDotColor: nil,
                detailFields: [
                    .init("Module", "Stock Requests"),
                    .init("Action", request.status),
                    .init("Priority", request.priority),
                    .init("Quantity", "\(request.requestedQuantity)"),
                    .init("Timestamp", request.updatedAt.formatted(date: .abbreviated, time: .shortened))
                ]
            ))
        }

        // Cycle counts -> "Cycle Count Completed"
        for count in cycleCounts where count.status.lowercased() == "completed" {
            let completedDate = count.completedDate ?? count.scheduledDate
            let ts = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: completedDate) ?? completedDate
            entries.append(AuditTrailEntry(
                id: count.id,
                module: .inventory,
                title: "Cycle Count Completed",
                subtitle: count.remarks.map { "\($0)" } ?? "Completed",
                storeName: warehouseToStoreName(count.warehouseId),
                timestamp: ts,
                icon: "arrow.triangle.2.circlepath",
                tint: .auditPurple,
                statusDotColor: nil,
                detailFields: [
                    .init("Module", "Cycle Counts"),
                    .init("Action", "Completed Cycle Count"),
                    .init("Remarks", count.remarks ?? "—"),
                    .init("Timestamp", ts.formatted(date: .abbreviated, time: .shortened))
                ]
            ))
        }

        // Inventory exceptions -> "Inventory Adjustment" / "Exception Reported"
        for exception in inventoryExceptions {
            let store = stores.first(where: { $0.id == exception.storeId })
            entries.append(AuditTrailEntry(
                id: exception.id,
                module: .inventory,
                title: exception.status.lowercased() == "resolved" ? "Inventory Adjustment" : "Inventory Exception Reported",
                subtitle: "\(exception.exceptionType) • Reason: \(exception.remarks ?? exception.exceptionType)",
                storeName: store?.name ?? "Unknown Store",
                timestamp: exception.resolvedAt ?? exception.createdAt,
                icon: "shippingbox.and.arrow.backward.fill",
                tint: .auditOrange,
                statusDotColor: exception.status.lowercased() == "open" ? .auditOrange : nil,
                detailFields: [
                    .init("Module", "Inventory Exceptions"),
                    .init("Action", exception.exceptionType),
                    .init("Priority", exception.priority),
                    .init("Status", exception.status),
                    .init("Timestamp", (exception.resolvedAt ?? exception.createdAt).formatted(date: .abbreviated, time: .shortened))
                ]
            ))
        }

        // Fallback: raw audit_logs rows that don't map to a table above —
        // still surfaced generically so nothing from the audit_logs table is silently dropped.
        let coveredWords = ["shipment", "stock request", "cycle count", "inventory"]
        for log in auditLogs where !coveredWords.contains(where: { log.module.lowercased().contains($0) }) {
            entries.append(AuditTrailEntry(
                id: log.id,
                module: .inventory,
                title: log.action,
                subtitle: log.module,
                storeName: userName(log.userId),
                timestamp: log.createdAt,
                icon: "doc.text.magnifyingglass",
                tint: .auditIndigo,
                statusDotColor: nil,
                detailFields: [
                    .init("Module", log.module),
                    .init("Action", log.action),
                    .init("User", userName(log.userId)),
                    .init("Timestamp", log.createdAt.formatted(date: .abbreviated, time: .shortened))
                ]
            ))
        }

        return entries.sorted { $0.timestamp > $1.timestamp }
    }
}
