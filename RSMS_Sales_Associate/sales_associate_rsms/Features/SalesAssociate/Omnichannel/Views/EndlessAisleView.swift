// EndlessAisleView.swift
// RSMS — Sales Associate Module

import SwiftUI

struct EndlessAisleView: View {
    @EnvironmentObject var viewModel: OmnichannelViewModel
    @State private var searchQuery = ""
    
    // We mock the products that can be searched for here instead of a separate service
    var searchResults: [ProductDigitalTwin] {
        if searchQuery.isEmpty {
            return MockData.products
        } else {
            return MockData.products.filter { $0.title.lowercased().contains(searchQuery.lowercased()) || $0.sku.lowercased().contains(searchQuery.lowercased()) }
        }
    }
    
    var body: some View {
        List {
            ForEach(searchResults) { product in
                NavigationLink(destination: UnifiedInventoryView(product: product).environmentObject(viewModel)) {
                    HStack {
                        if let firstImage = product.imageURLs?.first {
                            AsyncImage(url: firstImage) { phase in
                                if let image = phase.image {
                                    image.resizable()
                                         .aspectRatio(contentMode: .fill)
                                } else {
                                    Color.gray.opacity(0.3)
                                }
                            }
                            .frame(width: 50, height: 50)
                            .cornerRadius(8)
                        } else {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 50, height: 50)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(product.title)
                                .font(.headline)
                            Text(product.sku)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle("Endless Aisle")
        .searchable(text: $searchQuery, prompt: "Search by Name or SKU")
    }
}
