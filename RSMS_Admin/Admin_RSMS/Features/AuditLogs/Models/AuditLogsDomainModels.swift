//
//  AuditLogsDomainModels.swift
//  RSMS_Project
//
//  These are NOT Supabase tables — they're computed/derived view models that
//  the Audit Logs module builds in memory from the real tables (sales,
//  store_targets, cycle_counts, inventory_exceptions, shipments,
//  stock_requests, transfers, audit_logs). Kept in Models/ (rather than
//  ViewModels/) since they're pure data, reused by both the rules engine and
//  the views.
//

import Foundation
import SwiftUI

// MARK: - Why a store needs attention

enum AttentionReason: Equatable {
    case salesBelowTarget(achievementPct: Double)
    case inventoryAccuracyIssue(exceptionCount: Int)
    case fulfillmentDelays(issueCount: Int)
    case operationalDelays(overdueCount: Int)

    /// Only one reason is ever surfaced per store card — this is the
    /// priority order used to pick it (matches "Only one primary reason is
    /// displayed to keep the UI clean" from the flow doc).
    var priority: Int {
        switch self {
        case .salesBelowTarget:          return 0
        case .inventoryAccuracyIssue:    return 1
        case .fulfillmentDelays:         return 2
        case .operationalDelays:         return 3
        }
    }

    var title: String {
        switch self {
        case .salesBelowTarget:        return "Sales Below Target"
        case .inventoryAccuracyIssue:  return "Inventory Accuracy Issue"
        case .fulfillmentDelays:       return "Fulfillment Delays"
        case .operationalDelays:       return "Operational Delays"
        }
    }

    var metricValue: String {
        switch self {
        case .salesBelowTarget(let pct):          return "\(Int(pct.rounded()))%"
        case .inventoryAccuracyIssue(let count):  return "\(count)"
        case .fulfillmentDelays(let count):       return "\(count)"
        case .operationalDelays(let count):       return "\(count)"
        }
    }

    var metricLabel: String {
        switch self {
        case .salesBelowTarget:         return "Achievement"
        case .inventoryAccuracyIssue:   return "Exceptions"
        case .fulfillmentDelays:        return "Shipment Issues"
        case .operationalDelays:        return "Overdue Tasks"
        }
    }

    var severity: AuditSeverity {
        switch self {
        case .salesBelowTarget(let pct):
            return pct < 70 ? .critical : .warning
        case .inventoryAccuracyIssue(let count):
            return count >= 10 ? .critical : .warning
        case .fulfillmentDelays:
            return .warning
        case .operationalDelays:
            return .caution
        }
    }

    var color: Color { severity.color }

    var icon: String {
        switch self {
        case .salesBelowTarget:        return "chart.line.downtrend.xyaxis"
        case .inventoryAccuracyIssue:  return "exclamationmark.triangle.fill"
        case .fulfillmentDelays:       return "shippingbox.fill"
        case .operationalDelays:       return "clock.badge.exclamationmark.fill"
        }
    }

    var categoryLabel: String {
        switch self {
        case .salesBelowTarget:        return "SALES PERFORMANCE"
        case .inventoryAccuracyIssue:  return "INVENTORY ACCURACY"
        case .fulfillmentDelays:       return "FULFILLMENT"
        case .operationalDelays:       return "OPERATIONAL"
        }
    }

    func description(for storeName: String) -> String {
        switch self {
        case .salesBelowTarget(let pct):
            return "\(storeName) is currently below monthly target (\(Int(pct.rounded()))% achievement)."
        case .inventoryAccuracyIssue(let count):
            return "\(storeName) reported \(count) inventory count discrepancies this period."
        case .fulfillmentDelays(let count):
            return "\(storeName) has \(count) unresolved shipment issues affecting fulfillment."
        case .operationalDelays(let count):
            return "\(storeName) has \(count) overdue operational tasks requiring attention."
        }
    }
}

// MARK: - Per-store performance snapshot (rules-engine output)

struct StorePerformanceSnapshot: Identifiable {
    let id: UUID                 // store id
    let store: AdminStore

    let actualRevenue: Double
    let revenueTarget: Double?
    var salesAchievementPct: Double? {
        guard let target = revenueTarget, target > 0 else { return nil }
        return (actualRevenue / target) * 100
    }

    let inventoryExceptionsOpenCount: Int
    let shipmentDiscrepancyCount: Int
    let cycleCountAccuracyPct: Double?
    let rejectedStockRequestCount: Int
    let delayedTransferCount: Int

    let attentionReason: AttentionReason?

    var isHealthy: Bool { attentionReason == nil }
}

// MARK: - Unified Audit Trail entry (feeds the "Audit Trail Feed" list)

enum AuditModuleFilter: String, CaseIterable, Identifiable {
    case all               = "All"
    case sales             = "Sales"
    case inventory         = "Inventory"
    case shipments         = "Shipments"
    case stockRequests     = "Stock Requests"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .all:                  return "line.3.horizontal.decrease.circle"
        case .sales:                return "chart.line.uptrend.xyaxis"
        case .inventory:            return "cube.box"
        case .shipments:            return "shippingbox"
        case .stockRequests:        return "clipboard"
        }
    }

    var accentColor: Color {
        switch self {
        case .all:                  return .auditBlue
        case .sales:                return .auditBlue
        case .inventory:            return .auditGreen
        case .shipments:            return .auditOrange
        case .stockRequests:        return .auditIndigo
        }
    }
}

enum DateRangeFilter: String, CaseIterable, Identifiable {
    case today = "Today"
    case last7Days = "Last 7 Days"
    case last30Days = "Last 30 Days"
    case thisQuarter = "This Quarter"
    case customRange = "Custom Range"
    
    var id: String { rawValue }
}

struct AuditTrailDetailField: Identifiable {
    let id = UUID()
    let label: String
    let value: String

    init(_ label: String, _ value: String) {
        self.label = label
        self.value = value
    }
}

struct AuditTrailEntry: Identifiable {
    let id: UUID
    let module: AuditModuleFilter
    let title: String            // e.g. "Shipment Verified"
    let subtitle: String         // e.g. "ASN-DC-810574 • Fully Verified"
    let storeName: String
    let timestamp: Date
    let icon: String
    let tint: Color
    let statusDotColor: Color?   // small live-status dot, nil = none
    let detailFields: [AuditTrailDetailField]
}
