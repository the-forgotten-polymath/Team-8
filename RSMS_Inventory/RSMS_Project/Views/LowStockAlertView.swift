//
//  LowStockAlertView.swift
//  RSMS_Project
//
//  Created by Yatharth Mishra on 30/06/26.
//

import SwiftUI

struct LowStockAlertView: View {
    let warehouseId: UUID
    let userId: UUID

    @EnvironmentObject private var notificationStore: LowStockNotificationStore
    @StateObject private var viewModel = InventoryViewModel()
    @State private var replenishmentSuccessAlert = false
    @State private var selectedProduct: Product? = nil

    var lowStockItems: [InventoryItem] {
        viewModel.inventoryItems.filter { $0.quantity <= $0.reorderLevel }
    }
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                if viewModel.isLoading {
                    LoadingView(message: "Scanning warehouse stock levels...")
                } else if lowStockItems.isEmpty {
                    EmptyStateView(
                        title: "All Stock Levels Healthy",
                        message: "There are currently no items matching or below the specified reorder trigger levels.",
                        iconName: "checkmark.shield"
                    )
                } else {
                    List(lowStockItems) { item in
                        let product = viewModel.getProduct(for: item.productId)
                        
                        HStack {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(product?.productName ?? "Loading Product...")
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                
                                Text("SKU: \(product?.sku ?? "")")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                HStack(spacing: 12) {
                                    Text("Stock: \(item.quantity)")
                                        .font(.caption)
                                        .foregroundColor(.red)
                                        .fontWeight(.bold)
                                    
                                    Text("Reorder Trigger: \(item.reorderLevel)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            Spacer()
                            
                            Button(action: {
                                selectedProduct = product
                                Swift.Task {
                                    // Simulate sending DC replenishment request
                                    // 1. Create a shipment of type inbound
                                    struct NewShipment: Encodable {
                                        let id: UUID
                                        let shipmentType: String
                                        let source: String
                                        let destination: String
                                        let asnNumber: String
                                        let status: String
                                        let createdAt: Date
                                        enum CodingKeys: String, CodingKey {
                                            case id
                                            case shipmentType = "shipment_type"
                                            case source
                                            case destination
                                            case asnNumber = "asn_number"
                                            case status
                                            case createdAt = "created_at"
                                        }
                                    }
                                    let shipmentId = UUID()
                                    let asn = "ASN-DC-\(Int.random(in: 100000...999999))"
                                    let shipment = NewShipment(
                                        id: shipmentId,
                                        shipmentType: "inbound",
                                        source: "Distribution Centre",
                                        destination: "Central Warehouse",
                                        asnNumber: asn,
                                        status: "pending",
                                        createdAt: Date()
                                    )
                                    try? await DatabaseService.shared.insert(into: "shipments", value: shipment)
                                    
                                    // Create shipment item
                                    struct NewShipmentItem: Encodable {
                                        let id: UUID
                                        let shipmentId: UUID
                                        let productId: UUID
                                        let expectedQuantity: Int
                                        let receivedQuantity: Int
                                        let status: String
                                        enum CodingKeys: String, CodingKey {
                                            case id
                                            case shipmentId = "shipment_id"
                                            case productId = "product_id"
                                            case expectedQuantity = "expected_quantity"
                                            case receivedQuantity = "received_quantity"
                                            case status
                                        }
                                    }
                                    let shipmentItem = NewShipmentItem(
                                        id: UUID(),
                                        shipmentId: shipmentId,
                                        productId: item.productId,
                                        expectedQuantity: item.reorderLevel * 3, // Order bulk quantity
                                        receivedQuantity: 0,
                                        status: "pending"
                                    )
                                    try? await DatabaseService.shared.insert(into: "shipment_items", value: shipmentItem)
                                    
                                    // Log action
                                    try? await WarehouseService.shared.logAction(
                                        userId: userId,
                                        module: "Warehouse Replenishment",
                                        action: "Requested DC replenishment for \(product?.productName ?? "") (ASN: \(asn))"
                                    )

                                    // Notify the shared store so the Dashboard bell updates
                                    notificationStore.markReorderPlaced(
                                        for: item.productId,
                                        asnNumber: asn,
                                        shipmentId: shipmentId
                                    )

                                    replenishmentSuccessAlert = true
                                    await viewModel.loadData(warehouseId: warehouseId)
                                }
                            }) {
                                Text("Reorder")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(Color.blue)
                                    .cornerRadius(8)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .listStyle(.plain)
                }
            }
            
            if viewModel.isLoading {
                LoadingView(message: "Submitting reorder request...")
            }
        }
        .navigationTitle("Low Stock Alerts")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Replenishment Requested", isPresented: $replenishmentSuccessAlert) {
            Button("OK") {}
        } message: {
            if let prod = selectedProduct {
                Text("An inbound shipment from the Distribution Centre has been requested for \(prod.productName).")
            } else {
                Text("Replenishment request successfully sent to the Distribution Centre.")
            }
        }
        .refreshable {
            await viewModel.loadData(warehouseId: warehouseId)
        }
        .task {
            await viewModel.loadData(warehouseId: warehouseId)
        }
    }
}
