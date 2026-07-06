// InventoryAvailabilityView.swift
// RSMS — Sales Associate Module

import SwiftUI

struct InventoryAvailabilityView: View {
    let product: ProductDigitalTwin
    @Environment(\.dismiss) var dismiss
    
    @State private var locations: [(storeName: String, quantity: Int)] = []
    @State private var isLoading = true
    
    var body: some View {
        NavigationStack {
            List {
                if isLoading {
                    ProgressView("Loading inventory...")
                        .frame(maxWidth: .infinity, alignment: .center)
                } else if locations.isEmpty {
                    Text("No inventory data available")
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                } else {
                    Section(header: Text("Global Availability")) {
                        ForEach(locations, id: \.storeName) { location in
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(location.storeName)
                                        .font(.body)
                                        .fontWeight(.medium)
                                    if location.quantity == 0 {
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
                                Text("\(location.quantity)")
                                    .font(.title3)
                                    .fontWeight(.bold)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    
                    Section(header: Text("Actions")) {
                        Button(action: {
                            // Request transfer functionality
                            dismiss()
                        }) {
                            Label("Request Transfer", systemImage: "arrow.left.arrow.right")
                        }
                        .disabled(locations.allSatisfy { $0.quantity == 0 })
                    }
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
            .task {
                await loadInventory()
            }
        }
    }
    
    private func loadInventory() async {
        isLoading = true
        locations = (try? await SalesAssociateService.shared.fetchInventoryForProduct(productId: product.id)) ?? []
        isLoading = false
    }
}
