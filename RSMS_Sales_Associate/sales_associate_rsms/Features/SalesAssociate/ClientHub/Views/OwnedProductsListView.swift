// OwnedProductsListView.swift
// RSMS — Sales Associate Module

import SwiftUI

struct OwnedProductsListView: View {
    let products: [OwnedProduct]
    
    var body: some View {
        if products.isEmpty {
            VStack {
                Image(systemName: "bag.badge.minus")
                    .font(.largeTitle)
                    .foregroundColor(.secondary)
                Text("No products owned yet.")
                    .foregroundColor(.secondary)
            }
            .padding(40)
        } else {
            VStack(spacing: 12) {
                ForEach(products) { product in
                    ProductDigitalTwinMiniCardView(
                        title: product.productName,
                        subtitle: "Purchased \(product.purchaseDate.formatted(date: .abbreviated, time: .omitted))",
                        imageURL: nil,
                        statusText: product.currentWarrantyStatus.rawValue.capitalized,
                        statusColor: statusColor(for: product.currentWarrantyStatus)
                    )
                }
            }
            .padding()
        }
    }
    
    private func statusColor(for status: WarrantyStatus) -> Color {
        switch status {
        case .active: return .green
        case .expiring: return .orange
        case .expired: return .red
        case .voided: return .gray
        }
    }
}
