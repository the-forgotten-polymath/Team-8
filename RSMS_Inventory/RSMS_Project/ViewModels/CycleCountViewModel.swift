//
//  CycleCountViewModel.swift
//  RSMS_Project
//
//  Created by Yatharth Mishra on 30/06/26.
//

import Foundation
import Combine

// MARK: - Cycle Count Specific Scan Result
// Separate from QRScanResult (used by Shipment Verification) — scanning identifies
// a product only; it does NOT increment the counted quantity.
enum CycleCountScanResult {
    case identified(productName: String)
    case alreadyScanned(productName: String)
    case notInZone
    case unrecognized
}

enum SingleProductScanResult {
    case match(productName: String)
    case mismatch(expectedSKU: String, scannedValue: String)
}

@MainActor
final class CycleCountViewModel: ObservableObject {

    // MARK: - List State
    @Published var cycleCounts: [CycleCount] = []
    @Published var warehouses: [Warehouse] = []

    // MARK: - Audit State (used by CycleCountDetailView)
    @Published var zoneInventory: [InventoryItem] = []
    @Published var zoneProducts: [Product] = []
    /// Maps productId → physically counted quantity (user-entered)
    @Published var countedQuantities: [UUID: Int] = [:]
    /// Tracks which products have been QR-identified during this audit session
    @Published var scannedProductIds: Set<UUID> = []
    /// Tracks which products have been audited and confirmed in this session
    @Published var auditedProductIds: Set<UUID> = []

    @Published var isLoading = false
    @Published var errorMessage: String? = nil
    @Published var isAuditSubmitted = false

    private let service = WarehouseService.shared
    private let productService = ProductService()

    // MARK: - Computed Helpers

    func product(for inventoryItem: InventoryItem) -> Product? {
        zoneProducts.first { $0.id == inventoryItem.productId }
    }

    func countedQty(for productId: UUID) -> Int {
        countedQuantities[productId] ?? 0
    }

    /// Positive = surplus, Negative = deficit, Zero = matched
    func variance(for item: InventoryItem) -> Int {
        let counted = countedQuantities[item.productId] ?? 0
        return counted - item.quantity
    }

    var auditSummary: (matched: Int, discrepancies: Int, total: Int) {
        let total = zoneInventory.count
        let discrepancies = zoneInventory.filter { variance(for: $0) != 0 }.count
        return (matched: total - discrepancies, discrepancies: discrepancies, total: total)
    }

    // MARK: - List Operations

    func loadData() async {
        isLoading = true
        errorMessage = nil
        do {
            self.cycleCounts = try await service.fetchCycleCounts()
            self.warehouses = try await service.fetchWarehouses()
        } catch {
            if let decodingError = error as? DecodingError {
                self.errorMessage = "Decoding Error: \(decodingError)"
            } else {
                self.errorMessage = error.localizedDescription
            }
        }
        isLoading = false
    }

    func scheduleCount(warehouseId: UUID, date: Date, zone: String, userId: UUID) async {
        isLoading = true
        errorMessage = nil
        do {
            try await service.scheduleCycleCount(
                warehouseId: warehouseId,
                scheduledDate: date,
                zone: zone,
                userId: userId
            )
            try await service.logAction(
                userId: userId,
                module: "Cycle Counts",
                action: "Scheduled cycle count for \(zone) in warehouse: \(warehouseId.uuidString)"
            )
            await loadData()
        } catch {
            self.errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    // MARK: - Audit Operations (used by CycleCountDetailView)

    func loadAuditData(warehouseId: UUID, zone: String) async {
        isLoading = true
        errorMessage = nil
        scannedProductIds = []
        auditedProductIds = []
        countedQuantities = [:]
        do {
            let allProducts = try await productService.fetchProducts()
            let inventoryForZone = try await service.fetchInventoryByZone(warehouseId: warehouseId, zone: zone)

            let productIds = Set(inventoryForZone.map { $0.productId })
            self.zoneProducts = allProducts.filter { productIds.contains($0.id) }
            self.zoneInventory = inventoryForZone

            // Seed counted quantities to 0 as the starting baseline
            for item in inventoryForZone {
                countedQuantities[item.productId] = 0
            }
        } catch {
            guard !Swift.Task.isCancelled else { return }
            self.errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    // MARK: - Quantity Controls

    func setCountedQuantity(productId: UUID, quantity: Int) {
        countedQuantities[productId] = max(0, quantity)
    }

    func incrementCount(productId: UUID) {
        let current = countedQuantities[productId] ?? 0
        countedQuantities[productId] = current + 1
    }

    func decrementCount(productId: UUID) {
        let current = countedQuantities[productId] ?? 0
        countedQuantities[productId] = max(0, current - 1)
    }

    func setAllToExpected() {
        for item in zoneInventory {
            countedQuantities[item.productId] = item.quantity
        }
    }

    func markAsAudited(productId: UUID) {
        auditedProductIds.insert(productId)
    }

    /// Single atomic save: updates count, marks as QR-verified, and marks as audited.
    /// Call this from the Save button in CycleCountProductScannerSheet to guarantee
    /// @Published mutations fire together and SwiftUI refreshes the parent list.
    func saveProductAudit(productId: UUID, countedQuantity: Int) {
        countedQuantities[productId] = max(0, countedQuantity)
        scannedProductIds.insert(productId)
        auditedProductIds.insert(productId)
    }

    // MARK: - Per-Product QR Scan (used by CycleCountProductAuditView)
    func processSingleProductScan(for productId: UUID, value: String) -> SingleProductScanResult {
        let normalizedScanned = value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: " ", with: "-")
            .uppercased()

        guard let p = zoneProducts.first(where: { $0.id == productId }) else {
            return .mismatch(expectedSKU: "Unknown", scannedValue: value)
        }

        let normalizedSKU = p.sku
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: " ", with: "-")
            .uppercased()

        var matches = (normalizedSKU == normalizedScanned || normalizedScanned.contains(normalizedSKU))
        if let qr = p.qrValue {
            let normalizedQR = qr
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .replacingOccurrences(of: " ", with: "-")
                .uppercased()
            if normalizedQR == normalizedScanned || normalizedScanned.contains(normalizedQR) {
                matches = true
            }
        }

        if matches {
            scannedProductIds.insert(productId)
            return .match(productName: p.productName)
        } else {
            return .mismatch(expectedSKU: p.sku, scannedValue: value)
        }
    }

    // MARK: - QR Scan (Identify-Only)
    // Unlike Shipment Verification (which increments qty per scan), cycle count QR
    // scanning only identifies which product is being counted. The controller then
    // manually enters or adjusts the physical quantity.

    func processCycleCountScan(value: String) -> CycleCountScanResult {
        let normalizedScanned = value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: " ", with: "-")
            .uppercased()

        guard let product = zoneProducts.first(where: { p in
            let normalizedSKU = p.sku
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .replacingOccurrences(of: " ", with: "-")
                .uppercased()
            // qrValue is optional — skip QR match if not assigned
            if let qr = p.qrValue {
                let normalizedQR = qr
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                    .replacingOccurrences(of: " ", with: "-")
                    .uppercased()
                if normalizedQR == normalizedScanned || normalizedScanned.contains(normalizedQR) {
                    return true
                }
            }
            return normalizedSKU == normalizedScanned || normalizedScanned.contains(normalizedSKU)
        }) else {
            return .notInZone
        }

        if scannedProductIds.contains(product.id) {
            return .alreadyScanned(productName: product.productName)
        }

        // Mark as identified — quantity is deliberately NOT changed here
        scannedProductIds.insert(product.id)
        return .identified(productName: product.productName)
    }

    // MARK: - Submit Audit

    func submitAudit(countId: UUID, warehouseId: UUID, remarks: String?, userId: UUID) async {
        isLoading = true
        errorMessage = nil
        do {
            // 1. Mark cycle count as completed in DB
            try await service.completeCycleCount(countId: countId, remarks: remarks)

            // 2. Reconcile inventory and log discrepancy exceptions
            for item in zoneInventory {
                let counted = countedQuantities[item.productId] ?? item.quantity

                // Update inventory to the physically counted quantity
                try await service.updateInventoryQuantity(itemId: item.id, newQuantity: counted)

                // Log exception for any discrepancy
                let diff = counted - item.quantity
                if diff != 0 {
                    let exceptionType = diff < 0 ? "Missing Item" : "Extra Item"
                    let productName = product(for: item)?.productName ?? "Unknown Product"
                    try await service.createException(
                        shipmentId: nil,
                        storeId: nil,       // warehouse-level, no store
                        productId: item.productId,
                        exceptionType: exceptionType,
                        priority: "Medium",
                        remarks: "Cycle count variance: \(abs(diff)) unit(s) \(diff < 0 ? "short" : "over") for \(productName) in \(item.zone ?? "zone").",
                        reportedBy: userId
                    )
                }
            }

            // 3. Write audit log entry
            let summary = auditSummary
            try await service.logAction(
                userId: userId,
                module: "Cycle Counts",
                action: "Completed audit \(countId.uuidString) — \(summary.matched)/\(summary.total) matched, \(summary.discrepancies) discrepancy(ies)."
            )

            isAuditSubmitted = true
        } catch {
            self.errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func getWarehouseName(for warehouseId: UUID) -> String {
        warehouses.first(where: { $0.id == warehouseId })?.warehouseName ?? "Warehouse"
    }
}
