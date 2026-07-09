//
//  InventoryView.swift
//  RSMS_Project
//
//  Created by Yatharth Mishra on 30/06/26.
//

import SwiftUI

struct InventoryView: View {
    @StateObject private var viewModel = InventoryViewModel()
    @ObservedObject private var certificateManager = CertificateManager.shared
    let warehouseId: UUID
    
    var body: some View {
        VStack(spacing: 0) {
            // Search Bar & Filter Headers
            HStack(spacing: 12) {
                SearchBar(text: $viewModel.searchText, placeholder: "Search by Product Name or SKU")
                
                // Filter Button Menu
                Menu {
                    // 1. "Low Stock Only" Toggle
                    Button(action: {
                        viewModel.lowStockOnly.toggle()
                    }) {
                        Label(
                            "Low Stock Only",
                            systemImage: viewModel.lowStockOnly ? "checkmark.circle.fill" : "circle"
                        )
                    }
                    
                    Divider()
                    
                    // 2. Categories
                    if !viewModel.categories.isEmpty {
                        Text("Categories")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        ForEach(viewModel.categories) { category in
                            Button(action: {
                                if viewModel.selectedCategoryIds.contains(category.id) {
                                    viewModel.selectedCategoryIds.remove(category.id)
                                } else {
                                    viewModel.selectedCategoryIds.insert(category.id)
                                }
                            }) {
                                Label(
                                    category.categoryName,
                                    systemImage: viewModel.selectedCategoryIds.contains(category.id)
                                        ? "checkmark.circle.fill"
                                        : "circle"
                                )
                            }
                        }
                        
                        Divider()
                    }
                    
                    // 3. Clear Filters
                    if viewModel.lowStockOnly || !viewModel.selectedCategoryIds.isEmpty {
                        Button(role: .destructive, action: {
                            viewModel.lowStockOnly = false
                            viewModel.selectedCategoryIds.removeAll()
                        }) {
                            Label("Clear Filters", systemImage: "trash")
                        }
                    }
                } label: {
                    ZStack(alignment: .topTrailing) {
                        Image(systemName: "line.3.horizontal.decrease.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(
                                (viewModel.lowStockOnly || !viewModel.selectedCategoryIds.isEmpty)
                                ? .orange
                                : .blue
                            )
                        
                        // Active-filter indicator badge
                        let activeCount = (viewModel.lowStockOnly ? 1 : 0) + viewModel.selectedCategoryIds.count
                        if activeCount > 0 {
                            Text("\(activeCount)")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 14, height: 14)
                                .background(Color.orange)
                                .clipShape(Circle())
                                .offset(x: 6, y: -6)
                        }
                    }
                    .padding(8)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
            }
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
                    message: "No stock matching your search query or filters was found in this warehouse.\n(Active Warehouse ID: \(warehouseId.uuidString.lowercased()))",
                    iconName: "shippingbox"
                )
            } else {
<<<<<<< HEAD
                List(viewModel.filteredInventory) { item in
                    let product = viewModel.getProduct(for: item.productId)
                    NavigationLink(destination: ProductDetailView(item: item, product: product ?? ProductPlaceholder(id: item.productId), warehouseId: warehouseId)) {
                        HStack(alignment: .center, spacing: 12) {
                            Image(systemName: "shippingbox.fill")
                                .font(.title3)
                                .foregroundColor(item.quantity <= item.reorderLevel ? .orange : .blue)
                                .opacity(0.8)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(product?.productName ?? "Unknown Product")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                    .lineLimit(1)
                                
                                if let sku = product?.sku {
                                    Text("SKU: \(sku) • \(item.quantity) units")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
                                } else {
                                    Text("\(item.quantity) units")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
=======
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(viewModel.filteredInventory) { item in
                            let product = viewModel.getProduct(for: item.productId)
                            NavigationLink(destination: ProductDetailView(item: item, product: product ?? ProductPlaceholder(id: item.productId), warehouseId: warehouseId)) {
                                VStack(alignment: .leading, spacing: 12) {
                                    HStack(alignment: .top) {
                                        VStack(alignment: .leading, spacing: 6) {
                                            // Product Name
                                            Text(product?.productName ?? "Unknown Product")
                                                .font(.system(size: 18, weight: .bold))
                                                .foregroundColor(.primary)
                                                .multilineTextAlignment(.leading)
                                            
                                            // SKU Subtitle
                                            Text("SKU: \(product?.sku ?? "Unknown")")
                                                .font(.footnote)
                                                .foregroundColor(.secondary)
                                        }
                                        
                                        Spacer()
                                        
                                        // Stock status badge
                                        Text(item.quantity <= item.reorderLevel ? "LOW STOCK" : "IN STOCK")
                                            .font(.caption2)
                                            .fontWeight(.bold)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(item.quantity <= item.reorderLevel ? Color.red.opacity(0.15) : Color.green.opacity(0.15))
                                            .foregroundColor(item.quantity <= item.reorderLevel ? .red : .green)
                                            .cornerRadius(8)
                                    }
                                    
                                    Divider()
                                    
                                    HStack {
                                        // Brand info
                                        HStack(spacing: 6) {
                                            Image(systemName: "tag.fill")
                                                .font(.system(size: 14))
                                                .foregroundColor(.secondary)
                                            Text(product?.brand ?? "Generic")
                                                .font(.subheadline)
                                                .foregroundColor(.secondary)
                                        }
                                        
                                        Spacer()
                                        
                                        // Quantity count
                                        HStack(spacing: 4) {
                                            Text("Qty:")
                                                .font(.subheadline)
                                                .foregroundColor(.secondary)
                                            Text("\(item.quantity)")
                                                .font(.subheadline)
                                                .fontWeight(.bold)
                                                .foregroundColor(item.quantity <= item.reorderLevel ? .red : .primary)
                                        }
                                    }
>>>>>>> inventory
                                }
                                .padding()
                                .background(Color(UIColor.secondarySystemGroupedBackground))
                                .cornerRadius(16)
                                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.appleBorder, lineWidth: 1))
                                .shadow(color: Color.black.opacity(0.02), radius: 5, y: 2)
                            }
<<<<<<< HEAD
                            
                            Spacer()
                            
                            if item.quantity <= item.reorderLevel {
                                Label("Low Stock", systemImage: "exclamationmark.triangle.fill")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.orange)
                            }
                        }
                        .padding(.vertical, 4)
                        .listRowBackground(
                            Color(.secondarySystemGroupedBackground)
                                .opacity(0.6)
                                .background(.ultraThinMaterial)
                        )
=======
                            .buttonStyle(.plain)
                        }
>>>>>>> inventory
                    }
                    .padding()
                }
                .background(Color(UIColor.systemGroupedBackground))
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
