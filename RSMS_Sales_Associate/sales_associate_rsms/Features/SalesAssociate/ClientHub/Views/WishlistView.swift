// WishlistView.swift
// RSMS — Sales Associate Module

import SwiftUI

struct WishlistView: View {
    let items: [WishlistItem]
    
    var body: some View {
        if items.isEmpty {
            VStack {
                Image(systemName: "heart.slash")
                    .font(.largeTitle)
                    .foregroundColor(.secondary)
                Text("Wishlist is empty.")
                    .foregroundColor(.secondary)
            }
            .padding(40)
        } else {
            VStack(spacing: 12) {
                ForEach(items) { item in
                    ProductDigitalTwinMiniCardView(
                        title: item.productName,
                        subtitle: "Added \(item.addedDate.formatted(date: .abbreviated, time: .omitted))",
                        imageURL: nil,
                        statusText: item.isAvailable ? "In Stock" : "Out of Stock",
                        statusColor: item.isAvailable ? .green : .red
                    )
                }
            }
            .padding()
        }
    }
}
