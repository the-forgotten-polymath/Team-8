// ProductDetailView.swift
// RSMS — Sales Associate Module

import SwiftUI

struct ProductDetailView: View {
    let product: ProductDigitalTwin
    
    @EnvironmentObject var checkoutEnv: CheckoutEnvironment
    @State private var showingAvailability = false
    @State private var recommendedProducts: [ProductDigitalTwin] = []
    @State private var isLoadingRecommendations = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Header Image with Category Gradient
                LinearGradient(colors: product.gradientColors, startPoint: .topLeading, endPoint: .bottomTrailing)
                    .frame(height: 350)
                    .overlay(
                        Image(systemName: product.sfSymbolName)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 80)
                            .foregroundColor(.white)
                    )
                
                VStack(alignment: .leading, spacing: 24) {
                    // Title and Price Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text(product.brand)
                            .font(.headline)
                            .foregroundColor(.secondary)
                            .textCase(.uppercase)
                        
                        Text(product.title)
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text(product.price, format: .currency(code: product.currency))
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                    }
                    
                    // Action Buttons (Add to Cart / Quantity controls + heart, Buy Now)
                    VStack(spacing: 12) {
                        HStack(spacing: 16) {
                            if let item = checkoutEnv.activeCart?.items.first(where: { $0.product.id == product.id }) {
                                HStack(spacing: 20) {
                                    Button(action: {
                                        checkoutEnv.decrementQuantity(for: item)
                                    }) {
                                        Image(systemName: "minus")
                                            .font(.headline)
                                            .foregroundColor(.blue)
                                            .frame(width: 44, height: 44)
                                            .background(Color(.systemGray6))
                                            .cornerRadius(10)
                                    }
                                    
                                    Text("\(item.quantity)")
                                        .font(.title3)
                                        .fontWeight(.bold)
                                        .frame(minWidth: 40)
                                    
                                    Button(action: {
                                        checkoutEnv.incrementQuantity(for: item)
                                    }) {
                                        Image(systemName: "plus")
                                            .font(.headline)
                                            .foregroundColor(.blue)
                                            .frame(width: 44, height: 44)
                                            .background(Color(.systemGray6))
                                            .cornerRadius(10)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                            } else {
                                Button(action: {
                                    checkoutEnv.addProductToCart(product)
                                }) {
                                    Text("Add to Cart")
                                        .fontWeight(.bold)
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(product.isAvailable ? Color.blue : Color.gray)
                                        .foregroundColor(.white)
                                        .cornerRadius(12)
                                }
                                .disabled(!product.isAvailable)
                            }
                            
                            Button(action: {
                                checkoutEnv.toggleLike(product: product)
                            }) {
                                Image(systemName: checkoutEnv.likedProducts.contains(where: { $0.id == product.id }) ? "heart.fill" : "heart")
                                    .font(.title3)
                                    .padding()
                                    .background(Color(.systemGray6))
                                    .foregroundColor(checkoutEnv.likedProducts.contains(where: { $0.id == product.id }) ? .red : .primary)
                                    .cornerRadius(12)
                            }
                        }
                        
                        NavigationLink(destination: CartReviewView(isEmbedded: true).onAppear { checkoutEnv.instantCheckout(for: product) }) {
                            Text("Buy Now")
                                .fontWeight(.bold)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(product.isAvailable ? Color.green : Color.gray)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                        .disabled(!product.isAvailable)
                    }
                    
                    // Stock Status
                    HStack {
                        Circle()
                            .fill(product.isAvailable ? Color.green : Color.red)
                            .frame(width: 10, height: 10)
                        Text(product.isAvailable ? "In Stock (\(product.stockLevel) available)" : "Out of Stock")
                            .font(.subheadline)
                            .foregroundColor(product.isAvailable ? .primary : .red)
                        
                        Spacer()
                        
                        Button(action: {
                            showingAvailability = true
                        }) {
                            Text("Check Availability")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color(.systemGray6))
                                .clipShape(Capsule())
                        }
                    }
                    .padding(.vertical, 8)
                    
                    Divider()
                    
                    // Description
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Description")
                            .font(.headline)
                        
                        Text(product.description)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineSpacing(4)
                    }
                    
                    Divider()
                    
                    // Provenance & Materials (Passport)
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Product Passport")
                            .font(.headline)
                        
                        VStack(spacing: 12) {
                            PassportDetailRow(label: "SKU", value: product.sku)
                            if let coll = product.collection {
                                PassportDetailRow(label: "Collection", value: coll)
                            }
                            PassportDetailRow(label: "Materials", value: product.materials.joined(separator: ", "))
                            if let origin = product.origin {
                                PassportDetailRow(label: "Origin", value: origin)
                            }
                            if let auth = product.authenticityCertificateID {
                                PassportDetailRow(label: "Authenticity", value: auth)
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                    
                    Divider()
                    
                    // Recommendations
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Recommended to Pair With")
                            .font(.headline)
                        
                        if isLoadingRecommendations {
                            ProgressView()
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding()
                        } else if recommendedProducts.isEmpty {
                            Text("No recommendations available.")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .center)
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                        } else {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 16) {
                                    ForEach(recommendedProducts) { recProduct in
                                        NavigationLink(destination: ProductDetailView(product: recProduct)) {
                                            CatalogProductCardView(product: recProduct)
                                                .frame(width: 160)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                }
                            }
                        }
                    }
                    .padding(.bottom, 40)
                }
                .padding()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink(destination: CartReviewView(isEmbedded: true)) {
                    ZStack {
                        Image(systemName: "cart")
                            .font(.body)
                        
                        if let cart = checkoutEnv.activeCart, !cart.items.isEmpty {
                            let totalCount = cart.items.reduce(0) { $0 + $1.quantity }
                            Text("\(totalCount)")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(.white)
                                .padding(3)
                                .background(Color.red)
                                .clipShape(Circle())
                                .offset(x: 9, y: -9)
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showingAvailability) {
            InventoryAvailabilityView(product: product)
        }
        .onAppear {
            checkoutEnv.visitProduct(product)
            if recommendedProducts.isEmpty {
                Task {
                    isLoadingRecommendations = true
                    recommendedProducts = await RecommendationEngine.shared.recommendComplementary(for: product)
                    isLoadingRecommendations = false
                }
            }
        }
    }
}

struct PassportDetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack(alignment: .top) {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(width: 100, alignment: .leading)
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
