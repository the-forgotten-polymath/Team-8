// CuratedCartShareView.swift
// RSMS — Sales Associate Module

import SwiftUI

struct CuratedCartShareView: View {
    let cart: CuratedCart
    let products: [ProductDigitalTwin]
    @Environment(\.dismiss) var dismiss
    
    @State private var linkGenerated = false
    @State private var generatedLink = ""
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Preview of the client experience
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Preview: Client View")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .textCase(.uppercase)
                        
                        VStack(alignment: .leading, spacing: 16) {
                            Text("A personal selection for you")
                                .font(.title2.bold())
                            
                            if !cart.stylingNotes.isEmpty {
                                Text(cart.stylingNotes)
                                    .font(.body)
                                    .italic()
                                    .padding()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(8)
                            }
                            
                            ForEach(products) { product in
                                HStack {
                                    Rectangle()
                                        .fill(Color.gray.opacity(0.2))
                                        .frame(width: 60, height: 60)
                                        .cornerRadius(8)
                                        .overlay(Image(systemName: "bag").foregroundColor(.gray))
                                    
                                    VStack(alignment: .leading) {
                                        Text(product.title).font(.headline)
                                        Text(product.price, format: .currency(code: product.currency)).font(.subheadline)
                                    }
                                    Spacer()
                                }
                                .padding(.vertical, 4)
                            }
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(12)
                        .shadow(radius: 2)
                    }
                    .padding()
                    
                    // Share Actions
                    VStack(spacing: 16) {
                        if linkGenerated {
                            Text("Link Generated!")
                                .foregroundColor(.green)
                                .fontWeight(.bold)
                            
                            Text(generatedLink)
                                .font(.footnote)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                            
                            Button(action: {
                                // Simulate Client viewing the cart
                                dismiss()
                                NotificationCenter.default.post(name: NSNotification.Name("ClientViewedCart"), object: nil)
                            }) {
                                Text("Simulate Client Opening Link")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.black)
                                    .foregroundColor(.white)
                                    .cornerRadius(12)
                            }
                        } else {
                            Button(action: {
                                // Mock link generation
                                generatedLink = "https://brand.com/curated/\(UUID().uuidString.prefix(8).lowercased())"
                                linkGenerated = true
                            }) {
                                Text("Generate Share Link")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(12)
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Share Cart")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
