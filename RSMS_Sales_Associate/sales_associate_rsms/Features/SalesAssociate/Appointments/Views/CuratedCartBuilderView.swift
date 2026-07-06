// CuratedCartBuilderView.swift
// RSMS — Sales Associate Module

import SwiftUI

struct CuratedCartBuilderView: View {
    let appointment: Appointment
    @Environment(\.dismiss) var dismiss
    
    @State private var stylingNotes: String = ""
    @State private var selectedProducts: [ProductDigitalTwin] = []
    @State private var showingCatalogSheet = false
    @State private var showingSharePreview = false
    
    // Mock generation for the cart
    @State private var cart: CuratedCart?
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Styling Notes")) {
                    TextEditor(text: $stylingNotes)
                        .frame(height: 100)
                    Text("Add a personalized message for the client to view when they open the cart link.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Section(header: Text("Selected Items (\(selectedProducts.count))")) {
                    ForEach(selectedProducts) { product in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(product.title).font(.headline)
                                Text(product.brand).font(.caption).foregroundColor(.secondary)
                            }
                            Spacer()
                            Text(product.price, format: .currency(code: product.currency))
                        }
                    }
                    .onDelete { indexSet in
                        selectedProducts.remove(atOffsets: indexSet)
                    }
                    
                    Button(action: {
                        showingCatalogSheet = true
                    }) {
                        Label("Add Items from Catalog", systemImage: "plus")
                    }
                }
            }
            .navigationTitle("Curated Cart")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Preview & Share") {
                        generateCart()
                        showingSharePreview = true
                    }
                    .disabled(selectedProducts.isEmpty)
                }
            }
            .sheet(isPresented: $showingCatalogSheet) {
                // For simplicity in mock, just add a random item or show catalog
                // In a real flow, you'd use a variant of CatalogBrowserView with selection mode
                MockCatalogSelectionView(selectedProducts: $selectedProducts)
            }
            .sheet(isPresented: $showingSharePreview) {
                if let cart = cart {
                    CuratedCartShareView(cart: cart, products: selectedProducts)
                }
            }
        }
    }
    
    private func generateCart() {
        cart = CuratedCart(
            appointmentId: appointment.id,
            clientId: appointment.clientId,
            productIds: selectedProducts.map { $0.id },
            stylingNotes: stylingNotes,
            status: .draft
        )
    }
}

// A simple mock selection view since full Catalog selection mode is out of scope for the demo
struct MockCatalogSelectionView: View {
    @Binding var selectedProducts: [ProductDigitalTwin]
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            List(MockData.products) { product in
                HStack {
                    VStack(alignment: .leading) {
                        Text(product.title)
                        Text(product.brand).font(.caption).foregroundColor(.secondary)
                    }
                    Spacer()
                    if selectedProducts.contains(where: { $0.id == product.id }) {
                        Image(systemName: "checkmark.circle.fill").foregroundColor(.blue)
                    } else {
                        Button("Add") {
                            selectedProducts.append(product)
                            dismiss()
                        }
                    }
                }
            }
            .navigationTitle("Select Product")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
