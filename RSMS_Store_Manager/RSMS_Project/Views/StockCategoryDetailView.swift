import SwiftUI

struct StockCategoryDetailView: View {
    let filterType: StockFilterType
    @ObservedObject var viewModel: StockViewModel
    @ObservedObject private var cartManager = RestockCartManager.shared
    @State private var selectedItemForDetail: StockListItem? = nil
    @State private var isShowingCart = false
    @Environment(\.dismiss) private var dismiss
    
    private var filteredItems: [StockListItem] {
        switch filterType {
        case .lowStock:
            return viewModel.stockList.filter { $0.quantity <= $0.reorderLevel }
        case .outOfStock:
            return viewModel.stockList.filter { $0.quantity == 0 }
        default:
            return viewModel.stockList
        }
    }
    
    private var titleString: String {
        switch filterType {
        case .lowStock: return "Low Stock Items"
        case .outOfStock: return "Out of Stock Items"
        default: return "Stock Items"
        }
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 12) {
                    if filteredItems.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 48))
                                .foregroundColor(.green)
                            Text("All items are well stocked!")
                                .font(.headline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 100)
                    } else {
                        ForEach(filteredItems) { item in
                            StockDetailRow(item: item, onSelect: {
                                selectedItemForDetail = item
                            })
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 80) // Spacing for floating cart
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
        .navigationTitle(titleString)
        .navigationBarTitleDisplayMode(.inline)
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
}

struct StockDetailRow: View {
    let item: StockListItem
    var onSelect: () -> Void
    @ObservedObject private var cartManager = RestockCartManager.shared
    
    private var cartQuantity: Int {
        cartManager.items.first(where: { $0.productId == item.productId })?.quantity ?? 0
    }
    
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
        HStack(spacing: 12) {
            // Product Image or placeholder
            Button(action: onSelect) {
                HStack(spacing: 12) {
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
                    
                    VStack(alignment: .leading, spacing: 4) {
                        if let brand = item.brand {
                            Text(brand.uppercased())
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(.blue)
                                .tracking(0.8)
                        }
                        
                        Text(item.productName)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.primary)
                            .lineLimit(1)
                        
                        HStack(spacing: 8) {
                            Text(stockRemainingText)
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(stockColor)
                            
                            Text("•")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            
                            Text(formatIndianCurrency(amount: item.price))
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            Spacer()
            
            // Add / Stepper UI
            if cartQuantity > 0 {
                HStack(spacing: 8) {
                    Button(action: {
                        cartManager.updateQuantity(for: item.productId, to: cartQuantity - 1)
                        if cartQuantity == 1 {
                            cartManager.remove(productId: item.productId)
                        }
                    }) {
                        Image(systemName: "minus.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.blue)
                    }
                    
                    Text("\(cartQuantity)")
                        .font(.system(size: 14, weight: .bold))
                        .frame(minWidth: 20)
                        .foregroundColor(.primary)
                    
                    Button(action: {
                        cartManager.updateQuantity(for: item.productId, to: cartQuantity + 1)
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.blue)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color(.systemGray6))
                .cornerRadius(12)
            } else {
                Button(action: {
                    cartManager.add(product: item, quantity: 1)
                }) {
                    Text("Add")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.blue)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(12)
                }
            }
        }
        .padding(12)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.01), radius: 4, x: 0, y: 2)
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
