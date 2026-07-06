// InventoryAvailabilityView.swift
// RSMS — Sales Associate Module

import SwiftUI

struct InventoryAvailabilityView: View {
    let product: ProductDigitalTwin
    @Environment(\.dismiss) var dismiss
    
    // Mock locations and stock
    private let locations = [
        ("Current Store (London)", 2),
        ("Warehouse (UK)", 15),
        ("Paris Flagship", 4),
        ("New York 5th Ave", 0)
    ]
    
    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("Global Availability")) {
                    ForEach(locations, id: \.0) { location in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(location.0)
                                    .font(.body)
                                    .fontWeight(.medium)
                                if location.1 == 0 {
                                    Text("Out of stock")
                                        .font(.caption)
                                        .foregroundColor(.red)
                                } else {
                                    Text("Available")
                                        .font(.caption)
                                        .foregroundColor(.green)
                                }
                            }
                            Spacer()
                            Text("\(location.1)")
                                .font(.title3)
                                .fontWeight(.bold)
                        }
                        .padding(.vertical, 4)
                    }
                }
                
                Section(header: Text("Actions")) {
                    Button(action: {
                        // Request transfer functionality mock
                        dismiss()
                    }) {
                        Label("Request Transfer from Warehouse", systemImage: "arrow.left.arrow.right")
                    }
                    .disabled(locations[1].1 == 0) // disabled if warehouse is out of stock
                }
            }
            .navigationTitle("Stock: \(product.title)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}
