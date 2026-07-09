// CatalogBrowserView.swift
// RSMS — Sales Associate Module

import SwiftUI

struct CatalogBrowserView: View {
    @EnvironmentObject var checkoutEnv: CheckoutEnvironment
    @EnvironmentObject private var authVM: AuthViewModel
    @StateObject private var viewModel = CatalogViewModel()
    
    // Responsive grid layout that adapts to iPhone and iPad
    let columns = [
        GridItem(.adaptive(minimum: 160), spacing: 12)
    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                VStack(spacing: 0) {
                    
                    // Custom Header (Apple Store Inspired)
                    HStack {
                        Text("Catalog")
                            .font(.system(size: 34, weight: .bold))
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        NavigationLink(destination: CartReviewView(isEmbedded: true)) {
                            ZStack {
                                Circle()
                                    .fill(Color(.systemGray6))
                                    .frame(width: 40, height: 40)
                                
                                Image(systemName: "cart")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.blue)
                                
                                if let cart = checkoutEnv.activeCart, !cart.items.isEmpty {
                                    let totalCount = cart.items.reduce(0) { $0 + $1.quantity }
                                    Text("\(totalCount)")
                                        .font(.system(size: 9, weight: .bold))
                                        .foregroundColor(.white)
                                        .frame(width: 16, height: 16)
                                        .background(Color.red)
                                        .clipShape(Circle())
                                        .offset(x: 12, y: -12)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 12)
                    
                    // Custom Search Bar (visible inline)
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        
                        TextField("Search products by name, SKU, brand...", text: $viewModel.searchQuery)
                            .font(.system(size: 15))
                            .foregroundColor(.primary)
                        
                        if !viewModel.searchQuery.isEmpty {
                            Button(action: {
                                viewModel.searchQuery = ""
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 12)
                    
                    // Category Filter Scroll (36pt height, 16pt bottom margin)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            CatalogFilterChip(title: "All", isSelected: viewModel.selectedCategory == nil) {
                                viewModel.selectedCategory = nil
                            }
                            
                            ForEach(ProductCategory.allCases, id: \.self) { category in
                                CatalogFilterChip(title: category.rawValue, isSelected: viewModel.selectedCategory == category) {
                                    viewModel.selectedCategory = category
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    .frame(height: 36)
                    .padding(.bottom, 16)
                    
                    // Product Scroll Grid
                    ScrollView {
                        if viewModel.isLoading {
                            ProgressView()
                                .padding(.top, 50)
                        } else if viewModel.products.isEmpty {
                            VStack(spacing: 16) {
                                Image(systemName: "magnifyingglass")
                                    .font(.largeTitle)
                                    .foregroundColor(.gray)
                                Text("No products found.")
                                    .foregroundColor(.gray)
                            }
                            .padding(.top, 100)
                        } else {
                            LazyVGrid(columns: columns, spacing: 12) {
                                ForEach(viewModel.products) { product in
                                    NavigationLink(destination: ProductDetailView(product: product)) {
                                        CatalogProductCardView(product: product)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 4)
                        }
                    }
                    .background(Color(.systemGroupedBackground))
                    .safeAreaInset(edge: .bottom) {
                        Color.clear.frame(height: 40) // Bottom safe area breathing space
                    }
                }
                
                // Toast Animation
                if checkoutEnv.showCartAnimation {
                    VStack {
                        HStack(spacing: 10) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.white)
                                .font(.headline)
                            Text("Added to Cart!")
                                .foregroundColor(.white)
                                .fontWeight(.bold)
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal, 24)
                        .background(Color.blue)
                        .clipShape(Capsule())
                        .shadow(color: Color.black.opacity(0.2), radius: 10, y: 5)
                        .transition(.asymmetric(insertion: .move(edge: .top).combined(with: .opacity), removal: .opacity))
                        .padding(.top, 16)
                        
                        Spacer()
                    }
                    .zIndex(10)
                }
            }
            .toolbar(.hidden, for: .navigationBar) // Hide native nav bar on root Catalog tab
            .onAppear {
                viewModel.storeId = authVM.userStoreID
                viewModel.searchQuery = ""
                viewModel.selectedCategory = nil
                Task {
                    await viewModel.fetchCatalog()
                }
            }
            .id(checkoutEnv.catalogNavigationStackID)
        }
    }
}

struct CatalogFilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 16)
                .frame(height: 36)
                .background(isSelected ? Color.blue : Color(.systemGray6))
                .cornerRadius(18)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
