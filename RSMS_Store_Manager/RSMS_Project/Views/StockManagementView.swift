//
//  StockManagementView.swift
//  RSMS_Project
//
//  Created by Antigravity on 02/07/26.
//

import SwiftUI

enum StockFilterType {
    case all
    case lowStock
    case outOfStock
    case inStock
}

struct StockManagementView: View {
    @StateObject private var viewModel = StockViewModel()
    @State private var searchText = ""
    @State private var selectedItemForDetail: StockListItem? = nil
    @State private var isShowingCart = false
    @State private var navigateToPendingOrders = false
    @State private var navigateToTotalProducts = false
    @ObservedObject private var cartManager = RestockCartManager.shared
    @Binding var selectedStockFilter: StockFilterType

    private var filterTitleString: String {
        switch selectedStockFilter {
        case .all: return "Current Stock Items"
        case .lowStock: return "Low Stock Items"
        case .outOfStock: return "Out of Stock Items"
        case .inStock: return "In Stock Items"
        }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // Custom Header Row aligning Title "Stock" and Order History
                    HStack(spacing: 12) {
                        Text("Stock")
                            .font(.system(size: 34, weight: .bold))
                            .foregroundColor(Color(.label))
                        Spacer()
                        
                        NavigationLink(destination: OrderHistoryView()) {
                            ZStack {
                                Circle()
                                    .fill(Color(.secondarySystemGroupedBackground))
                                    .frame(width: 40, height: 40)
                                    .shadow(color: Color.black.opacity(0.04), radius: 5, x: 0, y: 2)
                                Image(systemName: "clock.arrow.circlepath")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    // Search Bar and Filter at the very top
                    HStack(spacing: 12) {
                        HStack(spacing: 8) {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.secondary)
                            TextField("Search products or SKUs...", text: $searchText)
                                .font(.system(size: 15))
                                .autocorrectionDisabled()
                        }
                        .padding(.vertical, 10)
                        .padding(.horizontal, 12)
                        .background(Color(.secondarySystemGroupedBackground))
                        .cornerRadius(12)
                        
                        // Filter Menu
                        Menu {
                            Button {
                                selectedStockFilter = .all
                            } label: {
                                HStack {
                                    Text("All Stock")
                                    if selectedStockFilter == .all { Image(systemName: "checkmark") }
                                }
                            }
                            
                            Button {
                                selectedStockFilter = .inStock
                            } label: {
                                HStack {
                                    Text("In Stock")
                                    if selectedStockFilter == .inStock { Image(systemName: "checkmark") }
                                }
                            }
                            
                            Button {
                                selectedStockFilter = .lowStock
                            } label: {
                                HStack {
                                    Text("Low Stock")
                                    if selectedStockFilter == .lowStock { Image(systemName: "checkmark") }
                                }
                            }
                            
                            Button {
                                selectedStockFilter = .outOfStock
                            } label: {
                                HStack {
                                    Text("Out of Stock")
                                    if selectedStockFilter == .outOfStock { Image(systemName: "checkmark") }
                                }
                            }
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(selectedStockFilter == .all ? Color(.secondarySystemGroupedBackground) : Color.blue.opacity(0.1))
                                    .frame(width: 40, height: 40)
                                
                                Image(systemName: selectedStockFilter == .all ? "line.3.horizontal.decrease.circle" : "line.3.horizontal.decrease.circle.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(selectedStockFilter == .all ? .primary : .blue)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    
                    if searchText.isEmpty {
                        VStack(spacing: 12) {
                            // Premium Summary Card
                            InventorySummaryCard(
                                summary: viewModel.summary, 
                                isLoading: viewModel.isLoading,
                                onTotalProductsTapped: {
                                    navigateToTotalProducts = true
                                },
                                onPendingRequestsTapped: {
                                    navigateToPendingOrders = true
                                }
                            )
                            .padding(.horizontal, 20)
                            .background(
                                VStack {
                                    NavigationLink(destination: OrderHistoryView(filterStatus: "Pending"), isActive: $navigateToPendingOrders) {
                                        EmptyView()
                                    }
                                    NavigationLink(destination: StockCategoryDetailView(filterType: .all, viewModel: viewModel), isActive: $navigateToTotalProducts) {
                                        EmptyView()
                                    }
                                }
                                .hidden()
                            )
                            
                            // Horizontal status indicators
                            HStack(spacing: 16) {
                                NavigationLink(destination: StockCategoryDetailView(filterType: .lowStock, viewModel: viewModel)) {
                                    StockIndicatorCard(
                                        title: "LOW STOCK",
                                        value: viewModel.isLoading ? nil : "\(viewModel.summary?.lowStockCount ?? 0) Products",
                                        iconName: "exclamationmark.triangle.fill",
                                        iconColor: .orange,
                                        isLoading: viewModel.isLoading
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                                .disabled(viewModel.isLoading)
                                
                                NavigationLink(destination: StockCategoryDetailView(filterType: .outOfStock, viewModel: viewModel)) {
                                    StockIndicatorCard(
                                        title: "OUT OF STOCK",
                                        value: viewModel.isLoading ? nil : "\(viewModel.summary?.outOfStockCount ?? 0) Products",
                                        iconName: "xmark.circle.fill",
                                        iconColor: .red,
                                        isLoading: viewModel.isLoading
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                                .disabled(viewModel.isLoading)
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                    
                    // Section Title
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text(filterTitleString)
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.primary)
                            Spacer()
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // List of Stock Items
                    if viewModel.isLoading {
                        VStack(spacing: 12) {
                            ForEach(0..<4, id: \.self) { _ in
                                StockRowSkeleton()
                            }
                        }
                        .padding(.horizontal, 20)
                    } else if filteredStockList.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "box.trend.down")
                                .font(.system(size: 40))
                                .foregroundColor(.secondary)
                            Text("No Stock Items Found")
                                .font(.headline)
                                .foregroundColor(.secondary)
                        }
                        .frame(height: 150)
                    } else {
                        LazyVStack(spacing: 12) {
                            ForEach(filteredStockList) { item in
                                Button(action: {
                                    selectedItemForDetail = item
                                }) {
                                    StockRow(item: item)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 24)
                    }
                }
            }
            .background(Color(.systemGroupedBackground))
            
            // Floating Restock Cart Button
            if cartManager.totalUnits > 0 {
                HStack {
                    Spacer()
                    Button(action: {
                        isShowingCart = true
                    }) {
                        HStack(spacing: 10) {
                            Image(systemName: "cart.fill")
                                .font(.system(size: 16, weight: .bold))
                            
                            Text("Restock Cart")
                                .font(.system(size: 14, weight: .bold))
                            
                            Text("\(cartManager.totalUnits)")
                                .font(.system(size: 12, weight: .bold))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.white)
                                .foregroundColor(.blue)
                                .clipShape(Circle())
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal, 16)
                        .background(
                            Capsule()
                                .fill(Color.blue)
                        )
                        .foregroundColor(.white)
                        .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 5)
                    }
                    Spacer()
                }
                .padding(.bottom, 20)
                .transition(.asymmetric(
                    insertion: .scale.combined(with: .opacity),
                    removal: .scale.combined(with: .opacity)
                ))
            }
        }
        .animation(.spring(), value: cartManager.totalUnits)
        .navigationTitle("Stock")
        .navigationBarHidden(true)
        .onAppear {
            Swift.Task {
                await viewModel.loadData()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            Swift.Task {
                await viewModel.loadData()
            }
        }
        .refreshable {
            await viewModel.loadData()
        }
        .sheet(item: $selectedItemForDetail) { item in
            ProductDetailSheet(item: item)
        }
        .fullScreenCover(isPresented: $isShowingCart) {
            RestockCartView {
                Swift.Task {
                    await viewModel.loadData()
                }
            }
        }
    }
    
    private var filteredStockList: [StockListItem] {
        var list = viewModel.stockList
        
        if searchText.isEmpty {
            switch selectedStockFilter {
            case .lowStock:
                list = list.filter { $0.quantity <= $0.reorderLevel }
            case .outOfStock:
                list = list.filter { $0.quantity == 0 }
            case .inStock:
                list = list.filter { $0.quantity > $0.reorderLevel }
            case .all:
                break
            }
        } else {
            list = list.filter {
                $0.productName.localizedCaseInsensitiveContains(searchText) ||
                $0.sku.localizedCaseInsensitiveContains(searchText) ||
                ($0.brand?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
        
        return list
    }
}

struct StockRow: View {
    let item: StockListItem
    
    var stockRemainingText: String {
        if item.quantity == 0 {
            return "Out of Stock"
        } else {
            return "\(item.quantity) Units"
        }
    }
    
    var stockColor: Color {
        if item.quantity == 0 {
            return .red
        } else if item.quantity <= item.reorderLevel {
            return .orange
        } else {
            return .green
        }
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Product Image on the left
            if let imageURLString = item.imageURL, let url = URL(string: imageURLString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 50, height: 50)
                            .cornerRadius(10)
                            .clipped()
                    case .failure, .empty:
                        productPlaceholder
                    @unknown default:
                        productPlaceholder
                    }
                }
            } else {
                productPlaceholder
            }

            // Right content layout
            VStack(alignment: .leading, spacing: 6) {
                // First Row: Brand & Remaining Units
                HStack(alignment: .center) {
                    if let brand = item.brand {
                        Text(brand.uppercased())
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(Color(.systemBlue))
                            .tracking(0.8)
                    }
                    
                    Spacer()
                    
                    Text(stockRemainingText)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(stockColor)
                }
                
                // Second Row: Product Name (occupies center-left)
                Text(item.productName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                // Third Row: SKU & Price
                HStack(alignment: .center) {
                    Text("SKU: \(item.sku)")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(formatIndianCurrency(amount: item.price))
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                }
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.02), radius: 6, x: 0, y: 3)
    }
    
    private var productPlaceholder: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.systemGray6))
                .frame(width: 50, height: 50)
            
            Image(systemName: "shippingbox.fill")
                .font(.system(size: 18))
                .foregroundColor(Color(.systemGray3))
        }
    }
    
    private func formatIndianCurrency(amount: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "en_IN")
        formatter.currencySymbol = "₹"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: amount as NSDecimalNumber) ?? "₹0"
    }
}

struct StockRowSkeleton: View {
    var body: some View {
        HStack(spacing: 16) {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.systemGray5))
                .frame(width: 50, height: 50)
            
            VStack(alignment: .leading, spacing: 8) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(.systemGray5))
                    .frame(width: 80, height: 12)
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(.systemGray5))
                    .frame(width: 150, height: 16)
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(.systemGray5))
                    .frame(width: 100, height: 12)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 8) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(.systemGray5))
                    .frame(width: 80, height: 16)
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(.systemGray5))
                    .frame(width: 60, height: 12)
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .shimmering()
    }
}

struct StockIndicatorCard: View {
    let title: String
    let value: String?
    let iconName: String
    let iconColor: Color
    let isLoading: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: iconName)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(iconColor)
                
                Text(title)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(Color(.secondaryLabel))
                    .tracking(1.0)
            }
            
            if isLoading {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color(.systemGray5))
                    .frame(width: 80, height: 28)
                    .shimmering()
            } else if let value = value {
                Text(value)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(Color(.label))
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.secondarySystemGroupedBackground))
                .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 4)
        )
    }
}

