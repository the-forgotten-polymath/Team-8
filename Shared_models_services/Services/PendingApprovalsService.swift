//
//  PendingApprovalsService.swift
//  RSMS_Project
//
//  New — there is no "approvals" table. "Pending approvals" in the
//  Attention Center is derived by counting rows already sitting at
//  status = 'Pending' in stock_requests, shipments, and transfers —
//  the three tables that actually represent things awaiting sign-off
//  in this schema. No new table needed.
//

import Foundation
import Supabase

final class PendingApprovalsService {

    private let client = SupabaseManager.shared.client

    struct Breakdown {
        let stockRequests: Int
        let shipments: Int
        let transfers: Int
        var total: Int { stockRequests + shipments + transfers }
    }

    func fetchPending() async throws -> Breakdown {
        async let stockRequestsCount = countPending(table: "stock_requests")
        async let shipmentsCount = countPending(table: "shipments")
        async let transfersCount = countPending(table: "transfers")

        return Breakdown(
            stockRequests: (try? await stockRequestsCount) ?? 0,
            shipments: (try? await shipmentsCount) ?? 0,
            transfers: (try? await transfersCount) ?? 0
        )
    }

    /// Uses a head-only count query (no rows transferred) — check this
    /// against your installed supabase-swift version; the count API has
    /// shifted across SDK releases (`count:` param on .select vs a
    /// separate `.count()` call).
    private func countPending(table: String) async throws -> Int {
        let response = try await client
            .from(table)
            .select("id", head: true, count: .exact)
            .eq("status", value: "Pending")
            .execute()
        return response.count ?? 0
    }

    // MARK: - Item-level fetch (backs the Approval Center)

    struct PendingRows {
        let stockRequests: [StockRequestRow]
        let shipments: [ShipmentRow]
        let transfers: [TransferRow]
    }

    struct StockRequestRow: Decodable, Identifiable {
        let id: UUID
        let storeId: UUID?
        let productId: UUID?
        let requestedQuantity: Int?
        let priority: String?
        let createdAt: Date
        enum CodingKeys: String, CodingKey {
            case id, priority
            case storeId = "store_id"
            case productId = "product_id"
            case requestedQuantity = "requested_quantity"
            case createdAt = "created_at"
        }
    }

    struct ShipmentRow: Decodable, Identifiable {
        let id: UUID
        let shipmentNumber: String?
        let source: String?
        let destination: String?
        let createdAt: Date
        enum CodingKeys: String, CodingKey {
            case id, source, destination
            case shipmentNumber = "shipment_number"
            case createdAt = "created_at"
        }
    }

    struct TransferRow: Decodable, Identifiable {
        let id: UUID
        let sourceStoreId: UUID?
        let destinationStoreId: UUID?
        let createdAt: Date
        enum CodingKeys: String, CodingKey {
            case id
            case sourceStoreId = "source_store_id"
            case destinationStoreId = "destination_store_id"
            case createdAt = "created_at"
        }
        // NOTE: transfers has no created_at column in the schema — it uses
        // transfer_date instead. Map that here rather than adding a column.
    }

    func fetchPendingItems(limit: Int = 20) async throws -> PendingRows {
        async let stockRequests: [StockRequestRow] = client
            .from("stock_requests")
            .select("id, store_id, product_id, requested_quantity, priority, created_at")
            .eq("status", value: "Pending")
            .order("created_at", ascending: false)
            .limit(limit)
            .execute()
            .value
        async let shipments: [ShipmentRow] = client
            .from("shipments")
            .select("id, shipment_number, source, destination, created_at")
            .eq("status", value: "Pending")
            .order("created_at", ascending: false)
            .limit(limit)
            .execute()
            .value
        async let transfers: [TransferRow] = client
            .from("transfers")
            .select("id, source_store_id, destination_store_id, created_at:transfer_date")
            .eq("status", value: "Pending")
            .order("transfer_date", ascending: false)
            .limit(limit)
            .execute()
            .value

        return try await PendingRows(
            stockRequests: stockRequests,
            shipments: shipments,
            transfers: transfers
        )
    }

    // MARK: - Approve / Reject

    func setStatus(table: String, id: UUID, status: String) async throws {
        struct Update: Encodable { let status: String }
        try await client
            .from(table)
            .update(Update(status: status))
            .eq("id", value: id)
            .execute()
    }
}
