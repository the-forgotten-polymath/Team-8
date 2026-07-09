//
//  InventoryExceptionService.swift
//  RSMS_Project
//

import Foundation
import Supabase

final class InventoryExceptionService {

    private let client = SupabaseManager.shared.client

    /// Open + investigating exceptions, most urgent first — backs the
    /// "Critical Exceptions" attention card and "Active Issues" cards.
    /// Your real `status` values default to 'Open' (not 'open'), so we
    /// match case-insensitively rather than assuming a lowercase enum.
    func fetchOpen() async throws -> [InventoryException] {
        try await client
            .from("inventory_exceptions")
            .select()
            .not("status", operator: .ilike, value: "resolved")
            .order("created_at", ascending: false)
            .execute()
            .value
    }

    /// All exceptions (open + resolved) for a single store, regardless of
    /// status — backs the Inspector's "Open Findings" list and the
    /// exception-resolution-rate derivation in StoreComplianceDetailService,
    /// which needs the resolved count too, not just what fetchOpen() returns.
    func fetchAll(storeId: UUID, limit: Int = 100) async throws -> [InventoryException] {
        try await client
            .from("inventory_exceptions")
            .select()
            .eq("store_id", value: storeId)
            .order("created_at", ascending: false)
            .limit(limit)
            .execute()
            .value
    }

    func markResolved(id: UUID) async throws {
        struct Update: Encodable {
            let status: String
            let resolved_at: String
        }
        try await client
            .from("inventory_exceptions")
            .update(Update(status: "Resolved", resolved_at: ISO8601DateFormatter().string(from: Date())))
            .eq("id", value: id)
            .execute()
    }

    /// Derives "products affected" and "variance %" for a set of
    /// exceptions from `shipment_items` instead of storing those numbers
    /// redundantly on inventory_exceptions. Only exceptions that carry a
    /// shipment_id can be enriched this way (e.g. shipment_mismatch,
    /// missing_item); exceptions without one (e.g. a planogram failure)
    /// simply won't appear in the returned dictionary.
    func fetchVarianceInfo(shipmentIds: [UUID]) async throws -> [UUID: VarianceInfo] {
        guard !shipmentIds.isEmpty else { return [:] }

        let items: [ShipmentItemRow] = try await client
            .from("shipment_items")
            .select("shipment_id, expected_quantity, received_quantity, status")
            .in("shipment_id", values: shipmentIds.map { $0.uuidString })
            .execute()
            .value

        let grouped = Dictionary(grouping: items) { $0.shipmentId }
        var result: [UUID: VarianceInfo] = [:]

        for (shipmentId, rows) in grouped {
            guard let shipmentId else { continue }
            let mismatchedCount = rows.filter { row in
                guard let status = row.status?.lowercased() else { return false }
                return status != "matched"
            }.count

            let totalExpected = rows.compactMap(\.expectedQuantity).reduce(0, +)
            let totalReceived = rows.compactMap(\.receivedQuantity).reduce(0, +)
            let variancePct: Double? = totalExpected > 0
                ? (Double(abs(totalExpected - totalReceived)) / Double(totalExpected)) * 100
                : nil

            result[shipmentId] = VarianceInfo(productsAffected: mismatchedCount, variancePct: variancePct)
        }
        return result
    }

    struct VarianceInfo {
        let productsAffected: Int
        let variancePct: Double?
    }

    private struct ShipmentItemRow: Decodable {
        let shipmentId: UUID?
        let expectedQuantity: Int?
        let receivedQuantity: Int?
        let status: String?

        enum CodingKeys: String, CodingKey {
            case shipmentId = "shipment_id"
            case expectedQuantity = "expected_quantity"
            case receivedQuantity = "received_quantity"
            case status
        }
    }
}
