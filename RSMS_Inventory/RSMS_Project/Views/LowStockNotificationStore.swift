//
//  LowStockNotificationStore.swift
//  RSMS_Project
//
//  Pure in-memory @EnvironmentObject — no Supabase, no DB, no schema changes.
//  Populated from the same WarehouseService + ProductService calls already used
//  throughout the app.
//

import Foundation
import Combine

// MARK: - Replenishment Status

enum ReplenishmentStatus: String {
    case idle       = "idle"
    case pending    = "pending"
    case inTransit  = "in_transit"
    case arrived    = "arrived"
    case completed  = "completed"

    var displayName: String {
        switch self {
        case .idle:      return "Not Started"
        case .pending:   return "Pending"
        case .inTransit: return "In Transit"
        case .arrived:   return "Arrived"
        case .completed: return "Completed"
        }
    }

    var sfSymbol: String {
        switch self {
        case .idle:      return "circle"
        case .pending:   return "clock.fill"
        case .inTransit: return "truck.box.fill"
        case .arrived:   return "checkmark.circle.fill"
        case .completed: return "checkmark.seal.fill"
        }
    }

    var color: String {
        switch self {
        case .idle:      return "gray"
        case .pending:   return "orange"
        case .inTransit: return "blue"
        case .arrived:   return "green"
        case .completed: return "green"
        }
    }
}

// MARK: - LowStockNotification

struct LowStockNotification: Identifiable {
    let id: UUID
    let productId: UUID
    let productName: String
    let sku: String
    let currentQty: Int
    let reorderLevel: Int
    let reorderQty: Int           // = reorderLevel * 3, same formula as LowStockAlertView
    let warehouseName: String
    let detectedAt: Date
    var replenishmentStatus: ReplenishmentStatus = .idle
    var linkedShipmentASN: String? = nil
    var linkedShipmentId: UUID? = nil
}

// MARK: - LowStockNotificationStore

@MainActor
final class LowStockNotificationStore: ObservableObject {

    @Published var notifications: [LowStockNotification] = []

    // Services — same ones used by InventoryViewModel / LowStockAlertView
    private let warehouseService = WarehouseService.shared
    private let productService   = ProductService()

    // MARK: - Computed

    var activeNotifications: [LowStockNotification] {
        notifications.filter { $0.replenishmentStatus != .completed }
    }

    var activeCount: Int { activeNotifications.count }

    // MARK: - Populate

    /// Fetches warehouse inventory using the existing WarehouseService and builds
    /// notifications for items at or below reorder level. Skips items already tracked.
    func populate(warehouseId: UUID) async {
        do {
            let products  = try await productService.fetchProducts()
            let inventory = try await warehouseService.fetchWarehouseInventory(warehouseId: warehouseId)
            let warehouses = try await warehouseService.fetchWarehouses()
            let warehouseName = warehouses.first(where: { $0.id == warehouseId })?.warehouseName
                             ?? warehouses.first?.warehouseName
                             ?? "Central Warehouse"

            let lowStock = inventory.filter { $0.quantity <= $0.reorderLevel }
            for item in lowStock {
                // Don't duplicate already-tracked products
                guard !notifications.contains(where: { $0.productId == item.productId }) else { continue }
                let product = products.first(where: { $0.id == item.productId })
                let note = LowStockNotification(
                    id: UUID(),
                    productId: item.productId,
                    productName: product?.productName ?? "Unknown Product",
                    sku: product?.sku ?? "",
                    currentQty: item.quantity,
                    reorderLevel: item.reorderLevel,
                    reorderQty: item.reorderLevel * 3,
                    warehouseName: warehouseName,
                    detectedAt: Date()
                )
                notifications.append(note)
            }
        } catch {
            print("LowStockNotificationStore: populate failed — \(error)")
        }
    }

    // MARK: - Status Mutations

    func markReorderPlaced(
        for productId: UUID,
        asnNumber: String,
        shipmentId: UUID
    ) {
        guard let idx = notifications.firstIndex(where: { $0.productId == productId })
        else { return }
        notifications[idx].linkedShipmentASN = asnNumber
        notifications[idx].linkedShipmentId  = shipmentId
        notifications[idx].replenishmentStatus = .pending
    }

    func updateStatus(for notificationId: UUID, to status: ReplenishmentStatus) {
        guard let idx = notifications.firstIndex(where: { $0.id == notificationId })
        else { return }
        notifications[idx].replenishmentStatus = status
    }

    func markCompleted(for notificationId: UUID) {
        guard let idx = notifications.firstIndex(where: { $0.id == notificationId })
        else { return }
        notifications[idx].replenishmentStatus = .completed
    }

    func clearCompleted() {
        notifications.removeAll { $0.replenishmentStatus == .completed }
    }
}
