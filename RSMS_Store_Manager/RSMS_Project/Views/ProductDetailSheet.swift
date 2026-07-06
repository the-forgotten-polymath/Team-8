//
//  ProductDetailSheet.swift
//  RSMS_Project
//
//  Created by Antigravity on 02/07/26.
//

import SwiftUI

struct ProductDetailSheet: View {
    @Environment(\.dismiss) private var dismiss
    let item: StockListItem
    
    @State private var quantity: Int = 1
    @ObservedObject private var cartManager = RestockCartManager.shared
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Product Image Header
                    if let imageURLString = item.imageURL, let url = URL(string: imageURLString) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(maxHeight: 250)
                                    .cornerRadius(16)
                                    .clipped()
                            case .failure, .empty:
                                imagePlaceholder
                            @unknown default:
                                imagePlaceholder
                            }
                        }
                    } else {
                        imagePlaceholder
                    }
                    
                    // Product Info Card
                    VStack(alignment: .leading, spacing: 16) {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                if let brand = item.brand {
                                    Text(brand.uppercased())
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(.blue)
                                        .tracking(1.0)
                                }
                                Spacer()
                                statusBadge
                            }
                            
                            if let cat = item.categoryName {
                                Text(cat)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Text(item.productName)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.primary)
                        
                        Text("SKU: \(item.sku)")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                        
                        Divider()
                        
                        // Price & Stock Stats (2 rows of 2 columns each)
                        VStack(spacing: 16) {
                            // First Row: Selling Price
                            HStack(spacing: 16) {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Selling Price")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundColor(.secondary)
                                    Text(formatIndianCurrency(amount: item.price))
                                        .font(.system(size: 15, weight: .bold))
                                        .foregroundColor(.primary)
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.6)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                
                                Spacer()
                                    .frame(maxWidth: .infinity)
                            }
                            
                            // Second Row: Current Stock | Reorder Level
                            HStack(spacing: 16) {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Current Stock")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundColor(.secondary)
                                    Text(unitsText(for: item.quantity))
                                        .font(.system(size: 15, weight: .bold))
                                        .foregroundColor(stockColor(for: item.quantity))
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.8)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Reorder Level")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundColor(.secondary)
                                    Text("\(item.reorderLevel) Units")
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.8)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                        
                        Divider()
                        
                        // Description section
                        VStack(alignment: .leading, spacing: 8) {
                            Text("DESCRIPTION")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.secondary)
                            
                            Text(item.description ?? "No description available for this product.")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                                .lineSpacing(8)
                        }
                    }
                    .padding(20)
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(20)
                    .shadow(color: Color.black.opacity(0.02), radius: 8, x: 0, y: 4)
                    
                    // Quantity Selector & Add Button Panel
                    VStack(spacing: 16) {
                        HStack {
                            Text("Quantity to Restock:")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            HStack(spacing: 20) {
                                Button(action: {
                                    if quantity > 0 {
                                        quantity -= 1
                                    }
                                }) {
                                    Image(systemName: "minus.circle.fill")
                                        .font(.system(size: 28))
                                        .foregroundColor(quantity > 0 ? .blue : .gray.opacity(0.3))
                                }
                                .disabled(quantity <= 0)
                                
                                Text("\(quantity)")
                                    .font(.system(size: 20, weight: .bold))
                                    .frame(minWidth: 40)
                                    .multilineTextAlignment(.center)
                                
                                Button(action: {
                                    quantity += 1
                                }) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 28))
                                        .foregroundColor(.blue)
                                }
                            }
                            .padding(.vertical, 4)
                            .padding(.horizontal, 8)
                            .background(Color(.systemGray6))
                            .cornerRadius(24)
                        }
                        .padding(.horizontal, 4)
                        
                        Button(action: {
                            cartManager.add(product: item, quantity: quantity)
                            
                            let generator = UINotificationFeedbackGenerator()
                            generator.notificationOccurred(.success)
                            
                            dismiss()
                        }) {
                            Text("Add to Restock Cart")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 52)
                                .background(Color.blue)
                                .cornerRadius(16)
                                .shadow(color: Color.blue.opacity(0.2), radius: 8, x: 0, y: 4)
                        }
                    }
                    .padding(20)
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(20)
                    .shadow(color: Color.black.opacity(0.02), radius: 8, x: 0, y: 4)
                }
                .padding(20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarTitle("Product Details", displayMode: .inline)
            .navigationBarItems(leading: Button("Cancel") { dismiss() })
        }
    }
    
    private var imagePlaceholder: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemGroupedBackground))
                .frame(height: 200)
            
            Image(systemName: "shippingbox.fill")
                .font(.system(size: 48))
                .foregroundColor(Color(.systemGray4))
        }
    }
    
    private var statusBadge: some View {
        Group {
            if item.quantity == 0 {
                badgeView(text: "Out of Stock", color: .red)
            } else if item.quantity <= item.reorderLevel {
                badgeView(text: "Low Stock", color: .orange)
            } else {
                badgeView(text: "In Stock", color: .green)
            }
        }
    }
    
    private func badgeView(text: String, color: Color) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .bold))
            .foregroundColor(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(color.opacity(0.12))
            .cornerRadius(12)
    }
    
    private func statBadge(title: String, value: String) -> some View {
        HStack(spacing: 4) {
            Text("\(title):")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.secondary)
            Text(value)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.primary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color(.systemGray6))
        .cornerRadius(6)
    }
    
    private func categoryBadge(value: String) -> some View {
        HStack(spacing: 4) {
            Text("Category")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.secondary)
            Text(value)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.primary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color(.systemGray6))
        .cornerRadius(6)
        .lineLimit(1)
        .fixedSize(horizontal: true, vertical: false)
    }
    
    private func unitsText(for qty: Int) -> String {
        return "\(qty) Units"
    }
    
    private func stockColor(for qty: Int) -> Color {
        if qty == 0 {
            return .red
        } else if qty <= item.reorderLevel {
            return .orange
        } else {
            return .green
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
