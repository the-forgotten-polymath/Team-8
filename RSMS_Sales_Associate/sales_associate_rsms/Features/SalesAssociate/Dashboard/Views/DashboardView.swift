// DashboardView.swift
// RSMS — Sales Associate Module

import SwiftUI

enum DashboardRole: String, CaseIterable {
    case advisor = "My Sales"
    case manager = "Boutique Sales"
}

struct DashboardView: View {
    @EnvironmentObject private var authVM: AuthViewModel
    @EnvironmentObject var checkoutEnv: CheckoutEnvironment
    @StateObject private var viewModel = DashboardViewModel()
    @State private var selectedRole: DashboardRole = .advisor
    @State private var showingProfileSheet = false
    @State private var showingLikedSheet = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Role", selection: $selectedRole) {
                    ForEach(DashboardRole.allCases, id: \.self) { role in
                        Text(role.rawValue).tag(role)
                    }
                }
                .pickerStyle(.segmented)
                .padding()
                

                
                if viewModel.isLoading {
                    Spacer()
                    ProgressView("Loading Intelligence Data...")
                    Spacer()
                } else {
                    if selectedRole == .advisor {
                        AdvisorDashboardView()
                            .environmentObject(viewModel)
                    } else {
                        ManagerDashboardView()
                            .environmentObject(viewModel)
                    }
                }
            }
            .navigationTitle("Home")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 12) {
                        Button(action: {
                            showingLikedSheet = true
                        }) {
                            Image(systemName: "heart.fill")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.red)
                                .frame(width: 36, height: 36)
                                .background(Color.red.opacity(0.1))
                                .clipShape(Circle())
                        }
                        
                        Button(action: {
                            showingProfileSheet = true
                        }) {
                            ZStack {
                                Circle()
                                    .fill(Color.blue.opacity(0.12))
                                    .frame(width: 36, height: 36)
                                Text(authVM.userFullName.initials)
                                    .font(.system(size: 13, weight: .bold, design: .serif))
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
            }
            .sheet(isPresented: $showingProfileSheet) {
                ProfileView()
                    .environmentObject(authVM)
            }
            .sheet(isPresented: $showingLikedSheet) {
                LikedProductsSheet()
                    .environmentObject(checkoutEnv)
            }
            .task {
                await viewModel.loadDashboardData()
            }
            .refreshable {
                await viewModel.loadDashboardData()
            }
        }
    }
}

struct LikedProductCard: View {
    let product: ProductDigitalTwin
    
    var body: some View {
        HStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 8)
                .fill(LinearGradient(colors: product.gradientColors, startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 50, height: 50)
                .overlay(
                    Image(systemName: product.sfSymbolName)
                        .foregroundColor(.white)
                        .font(.body)
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text(product.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                Text(product.brand)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                Text(product.price, format: .currency(code: product.currency))
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
            }
            .frame(width: 100, alignment: .leading)
        }
        .padding(8)
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.appleBorder, lineWidth: 1)
        )
    }
}

struct LikedProductsSheet: View {
    @EnvironmentObject var checkoutEnv: CheckoutEnvironment
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                if checkoutEnv.likedProducts.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "heart.slash")
                            .font(.largeTitle)
                            .foregroundColor(.secondary)
                        Text("No liked products yet.")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, minHeight: 200)
                    .listRowBackground(Color.clear)
                } else {
                    ForEach(checkoutEnv.likedProducts) { product in
                        NavigationLink(destination: ProductDetailView(product: product)) {
                            HStack(spacing: 12) {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(LinearGradient(colors: product.gradientColors, startPoint: .topLeading, endPoint: .bottomTrailing))
                                    .frame(width: 50, height: 50)
                                    .overlay(
                                        Image(systemName: product.sfSymbolName)
                                            .foregroundColor(.white)
                                            .font(.caption)
                                    )
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(product.title)
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.primary)
                                    Text(product.brand)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Text(product.price, format: .currency(code: product.currency))
                                    .font(.subheadline.bold())
                                    .foregroundColor(.primary)
                            }
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                checkoutEnv.toggleLike(product: product)
                            } label: {
                                Label("Unlike", systemImage: "heart.slash")
                            }
                        }
                        .swipeActions(edge: .leading, allowsFullSwipe: true) {
                            Button {
                                checkoutEnv.addProductToCart(product)
                            } label: {
                                Label("Add to Cart", systemImage: "cart.badge.plus")
                            }
                            .tint(.blue)
                        }
                    }
                }
            }
            .navigationTitle("Liked Products")
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

extension ProductDigitalTwin {
    var sfSymbolName: String { category.icon }
    
    var gradientColors: [Color] {
        switch category {
        case .apparel: return [Color(hex: "4A90E2"), Color(hex: "50E3C2")]
        case .leather: return [Color(hex: "F5A623"), Color(hex: "F8E71C")]
        case .watches: return [Color(hex: "BD10E0"), Color(hex: "9013FE")]
        case .jewellery: return [Color(hex: "D0021B"), Color(hex: "F5A623")]
        case .fragrance: return [Color(hex: "B8E986"), Color(hex: "417505")]
        default: return [Color(hex: "4A90E2"), Color(hex: "BD10E0")]
        }
    }
}

