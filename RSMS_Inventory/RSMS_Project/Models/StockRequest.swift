//
//  StockRequest.swift
//  RSMS_Project
//
//  Created by Yatharth Mishra on 30/06/26.
//

import Foundation

struct StockRequest: Codable, Identifiable {
    let id: UUID
    let storeId: UUID
    let productId: UUID
    let requestedBy: UUID
    let requestedQuantity: Int
    let priority: String
    let status: String
    let remarks: String?
    let orderId: String?
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case storeId = "store_id"
        case productId = "product_id"
        case requestedBy = "requested_by"
        case requestedQuantity = "requested_quantity"
        case priority
        case status
        case remarks
        case orderId = "order_id"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct GroupedStockRequest: Identifiable, Codable {
    var id: String { orderId }
    let orderId: String
    let storeId: UUID
    let requestedBy: UUID
    let priority: String
    let status: String
    let remarks: String?
    let createdAt: Date
    let items: [StockRequest]
}
