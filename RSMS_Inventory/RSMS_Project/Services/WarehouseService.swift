//
//  WarehouseService.swift
//  RSMS_Project
//
//  Created by Yatharth Mishra on 30/06/26.
//

import Foundation
import Supabase

final class WarehouseService {
    
    static let shared = WarehouseService()
    
    private let client = SupabaseManager.shared.client
    
    private init() {}
    
    // MARK: - Warehouses
    func fetchWarehouses() async throws -> [Warehouse] {
        try await client
            .from("warehouses")
            .select()
            .execute()
            .value
    }
    
    // MARK: - Inventory
    func fetchWarehouseInventory(warehouseId: UUID) async throws -> [InventoryItem] {
        try await client
            .from("inventory")
            .select()
            .eq("warehouse_id", value: warehouseId)
            .execute()
            .value
    }
    
    func updateInventoryQuantity(itemId: UUID, newQuantity: Int) async throws {
        struct UpdateQty: Encodable {
            let quantity: Int
            let lastVerifiedAt: Date
            enum CodingKeys: String, CodingKey {
                case quantity
                case lastVerifiedAt = "last_verified_at"
            }
        }
        try await client
            .from("inventory")
            .update(UpdateQty(quantity: newQuantity, lastVerifiedAt: Date()))
            .eq("id", value: itemId)
            .execute()
    }
    
    // MARK: - Shipments & Verification
    func fetchShipments() async throws -> [Shipment] {
        try await client
            .from("shipments")
            .select()
            .execute()
            .value
    }
    
    func fetchShipmentItems(shipmentId: UUID) async throws -> [ShipmentItem] {
        try await client
            .from("shipment_items")
            .select()
            .eq("shipment_id", value: shipmentId)
            .execute()
            .value
    }
    
    func updateShipmentStatus(shipmentId: UUID, status: String) async throws {
        struct UpdateStatus: Encodable {
            let status: String
            let receivedDate: Date?
            enum CodingKeys: String, CodingKey {
                case status
                case receivedDate = "received_date"
            }
        }
        let date = status.lowercased() == "verified" ? Date() : nil
        try await client
            .from("shipments")
            .update(UpdateStatus(status: status, receivedDate: date))
            .eq("id", value: shipmentId)
            .execute()
    }
    
    func verifyShipmentItem(itemId: UUID, receivedQty: Int, status: String) async throws {
        struct UpdateItem: Encodable {
            let receivedQuantity: Int
            let status: String
            enum CodingKeys: String, CodingKey {
                case receivedQuantity = "received_quantity"
                case status
            }
        }
        try await client
            .from("shipment_items")
            .update(UpdateItem(receivedQuantity: receivedQty, status: status))
            .eq("id", value: itemId)
            .execute()
    }
    
    // MARK: - Inventory Exceptions
    func fetchExceptions() async throws -> [InventoryException] {
        try await client
            .from("inventory_exceptions")
            .select()
            .execute()
            .value
    }
    
    func createException(
        shipmentId: UUID?,
        storeId: UUID?,
        productId: UUID,
        exceptionType: String,
        priority: String,
        remarks: String?,
        reportedBy: UUID
    ) async throws {
        struct NewException: Encodable {
            let shipmentId: UUID?
            let storeId: UUID?
            let productId: UUID
            let exceptionType: String
            let priority: String
            let status: String
            let remarks: String?
            let reportedBy: UUID
            let createdAt: Date
            enum CodingKeys: String, CodingKey {
                case shipmentId = "shipment_id"
                case storeId = "store_id"
                case productId = "product_id"
                case exceptionType = "exception_type"
                case priority
                case status
                case remarks
                case reportedBy = "reported_by"
                case createdAt = "created_at"
            }
        }
        let exception = NewException(
            shipmentId: shipmentId,
            storeId: storeId,
            productId: productId,
            exceptionType: exceptionType,
            priority: priority,
            status: "unresolved",
            remarks: remarks,
            reportedBy: reportedBy,
            createdAt: Date()
        )
        try await client
            .from("inventory_exceptions")
            .insert(exception)
            .execute()
    }
    
    func resolveException(exceptionId: UUID) async throws {
        struct ResolveData: Encodable {
            let status: String
            let resolvedAt: Date
            enum CodingKeys: String, CodingKey {
                case status
                case resolvedAt = "resolved_at"
            }
        }
        try await client
            .from("inventory_exceptions")
            .update(ResolveData(status: "resolved", resolvedAt: Date()))
            .eq("id", value: exceptionId)
            .execute()
    }
    
    // MARK: - Stock Requests
    func fetchStockRequests() async throws -> [StockRequest] {
        try await client
            .from("stock_requests")
            .select()
            .execute()
            .value
    }
    
    func updateStockRequestStatus(requestId: UUID, status: String) async throws {
        struct UpdateReq: Encodable {
            let status: String
            let updatedAt: Date
            enum CodingKeys: String, CodingKey {
                case status
                case updatedAt = "updated_at"
            }
        }
        try await client
            .from("stock_requests")
            .update(UpdateReq(status: status, updatedAt: Date()))
            .eq("id", value: requestId)
            .execute()
    }
    
    // MARK: - Transfers
    func fetchTransfers() async throws -> [Transfer] {
        try await client
            .from("transfers")
            .select()
            .execute()
            .value
    }
    
    func updateTransferStatus(transferId: UUID, status: String, approvedBy: UUID?) async throws {
        struct UpdateTrans: Encodable {
            let status: String
            let approvedBy: UUID?
            let completedAt: Date?
            enum CodingKeys: String, CodingKey {
                case status
                case approvedBy = "approved_by"
                case completedAt = "completed_at"
            }
        }
        let completed = status.lowercased() == "completed" ? Date() : nil
        try await client
            .from("transfers")
            .update(UpdateTrans(status: status, approvedBy: approvedBy, completedAt: completed))
            .eq("id", value: transferId)
            .execute()
    }
    
    // MARK: - Cycle Counts
    func fetchCycleCounts() async throws -> [CycleCount] {
        try await client
            .from("cycle_counts")
            .select()
            .execute()
            .value
    }
    
    func scheduleCycleCount(warehouseId: UUID, scheduledDate: Date, zone: String, userId: UUID) async throws {
        struct NewCycleCount: Encodable {
            let id: UUID
            let warehouseId: UUID
            let scheduledDate: Date
            let zone: String
            let status: String
            let createdBy: UUID
            let createdAt: Date
            enum CodingKeys: String, CodingKey {
                case id
                case warehouseId = "warehouse_id"
                case scheduledDate = "scheduled_date"
                case zone
                case status
                case createdBy = "created_by"
                case createdAt = "created_at"
            }
        }
        let count = NewCycleCount(
            id: UUID(),
            warehouseId: warehouseId,
            scheduledDate: scheduledDate,
            zone: zone,
            status: "Scheduled",
            createdBy: userId,
            createdAt: Date()
        )
        try await client
            .from("cycle_counts")
            .insert(count)
            .execute()
    }

    func fetchInventoryByZone(warehouseId: UUID, zone: String) async throws -> [InventoryItem] {
        try await client
            .from("inventory")
            .select()
            .eq("warehouse_id", value: warehouseId)
            .eq("zone", value: zone)
            .execute()
            .value
    }
    
    func completeCycleCount(countId: UUID, remarks: String?) async throws {
        struct CompleteData: Encodable {
            let status: String
            let completedDate: Date
            let remarks: String?
            enum CodingKeys: String, CodingKey {
                case status
                case completedDate = "completed_date"
                case remarks
            }
        }
        try await client
            .from("cycle_counts")
            .update(CompleteData(status: "completed", completedDate: Date(), remarks: remarks))
            .eq("id", value: countId)
            .execute()
    }
    
    // MARK: - Audit Logging
    func logAction(userId: UUID, module: String, action: String) async throws {
        struct NewLog: Encodable {
            let id: UUID
            let userId: UUID
            let module: String
            let action: String
            let createdAt: Date
            enum CodingKeys: String, CodingKey {
                case id
                case userId = "user_id"
                case module
                case action
                case createdAt = "created_at"
            }
        }
        let log = NewLog(id: UUID(), userId: userId, module: module, action: action, createdAt: Date())
        try await client
            .from("audit_logs")
            .insert(log)
            .execute()
    }
}
