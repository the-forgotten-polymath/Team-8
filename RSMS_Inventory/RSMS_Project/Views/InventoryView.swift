//
//  InventoryView.swift
//  RSMS_Project
//
//  Created by Yatharth Mishra on 30/06/26.
//

import SwiftUI

struct InventoryView: View {
    @StateObject private var viewModel = InventoryViewModel()
    let warehouseId: UUID
    
    var body: some View {
        VStack(spacing: 0) {
            // Search Bar & Filter Headers
            SearchBar(text: $viewModel.searchText, placeholder: "Search by Product Name or SKU")
                .padding(.horizontal)
                .padding(.vertical, 10)
                .background(Color(UIColor.systemBackground))
            
            // List of items
            if let error = viewModel.errorMessage {
                VStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                    Text("Error Loading Data")
                        .font(.headline)
                    Text(error)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.red.opacity(0.1))
                .cornerRadius(12)
                .padding()
            }
            
            if viewModel.isLoading {
                LoadingView(message: "Loading inventory...")
            } else if viewModel.filteredInventory.isEmpty {
                EmptyStateView(
                    title: "No Inventory Found",
                    message: "No stock matching your search query was found in this warehouse.\n(Active Warehouse ID: \(warehouseId.uuidString.lowercased()))",
                    iconName: "shippingbox"
                )
            } else {
                List(viewModel.filteredInventory) { item in
                    let product = viewModel.getProduct(for: item.productId)
                    NavigationLink(destination: ProductDetailView(item: item, product: product ?? ProductPlaceholder(id: item.productId), warehouseId: warehouseId)) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(product?.productName ?? "Unknown Product")
                                    .font(.body)
                                    .foregroundColor(.primary)
                                
                                if let sku = product?.sku {
                                    Text("SKU: \(sku)")
                                        .font(.footnote)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            Spacer()
                            
                            if item.quantity <= item.reorderLevel {
                                Text("Low Stock")
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.red)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.red.opacity(0.1))
                                    .cornerRadius(4)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle("Inventory")
        .navigationBarTitleDisplayMode(.large)
        .refreshable {
            await viewModel.loadData(warehouseId: warehouseId)
        }
        .task {
            await viewModel.loadData(warehouseId: warehouseId)
        }
    }
}

// Helper to provide a fallback Product if one is missing from the list
private func ProductPlaceholder(id: UUID) -> Product {
    struct DummyDecoder: Decoder {
        var codingPath: [CodingKey] = []
        var userInfo: [CodingUserInfoKey : Any] = [:]
        func container<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> where Key : CodingKey {
            throw DecodingError.valueNotFound(Product.self, DecodingError.Context(codingPath: [], debugDescription: ""))
        }
        func unkeyedContainer() throws -> UnkeyedDecodingContainer {
            throw DecodingError.valueNotFound(Product.self, DecodingError.Context(codingPath: [], debugDescription: ""))
        }
        func singleValueContainer() throws -> SingleValueDecodingContainer {
            throw DecodingError.valueNotFound(Product.self, DecodingError.Context(codingPath: [], debugDescription: ""))
        }
    }
    
    // We can instantiate a Product using JSONDecoder or similar if we define standard constructors,
    // but since Product is Decodable, we decode a mock JSON or create it. Let's decode from a mock string:
    let json = """
    {
        "id": "\(id.uuidString)",
        "sku": "UNKNOWN",
        "product_name": "Unknown Product",
        "brand": "Generic",
        "category_id": "00000000-0000-0000-0000-000000000000",
        "price": 0.0,
        "description": "No product details available.",
        "qr_value": null,
        "created_at": "2026-07-06T12:00:00Z"
    }
    """.data(using: .utf8)!
    
    return try! JSONDecoder().decode(Product.self, from: json)
}
