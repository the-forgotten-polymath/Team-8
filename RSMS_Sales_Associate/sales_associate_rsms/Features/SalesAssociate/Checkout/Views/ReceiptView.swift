// ReceiptView.swift
// RSMS — Sales Associate Module

import SwiftUI

struct ReceiptView: View {
    @EnvironmentObject var checkoutEnv: CheckoutEnvironment
    @EnvironmentObject var authVM: AuthViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var emailSent = false
    @State private var giftReceiptPrinted = false
    @State private var downloaded = false
    @State private var finalized = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                // Thank You Icon & Success Header
                VStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 72))
                        .foregroundColor(.green)
                    
                    Text("Transaction Complete")
                        .font(.title2.bold())
                    
                    Text("Thank you for your order!")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 24)
                
                // Transaction Details Card
                if let cart = checkoutEnv.activeCart {
                    VStack(spacing: 12) {
                        HStack {
                            Text("Client ID")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(String(cart.clientId.uuidString.prefix(8)))
                                .fontWeight(.medium)
                        }
                        
                        Divider()
                        
                        HStack {
                            Text("Total Paid")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(cart.totalPaid, format: .currency(code: AppConstants.App.currencyCode))
                                .font(.headline.bold())
                                .foregroundColor(.primary)
                        }
                    }
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.appleBorder, lineWidth: 1)
                    )
                    .padding(.horizontal)
                }
                
                // Action Options List
                if finalized {
                    VStack(spacing: 12) {
                        // Share Receipt using native ShareLink
                        if let cart = checkoutEnv.activeCart {
                            ShareLink(item: "Receipt summary:\nOrder Reference: \(String(cart.clientId.uuidString.prefix(8)))\nTotal Paid: \(cart.totalPaid.formatted(.currency(code: AppConstants.App.currencyCode)))\nThank you for shopping with us!") {
                                HStack {
                                    Image(systemName: "square.and.arrow.up")
                                    Text("Share Receipt")
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue.opacity(0.08))
                                .foregroundColor(.blue)
                                .cornerRadius(12)
                            }
                        }
                    }
                    .padding(.horizontal)
                } else {
                    VStack(spacing: 10) {
                        ProgressView()
                        Text("Placing order and generating receipt...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                }
                
                // Recommendations: Recently Visited Items
                if !checkoutEnv.recentlyVisitedProducts.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Divider()
                            .padding(.horizontal)
                            .padding(.top, 8)
                        
                        Text("Recently Visited Items")
                            .font(.system(size: 18, weight: .bold))
                            .padding(.horizontal)
                            .foregroundColor(.primary)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(checkoutEnv.recentlyVisitedProducts) { product in
                                    RecommendationProductCard(product: product)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                
                // Complete Done Button
                Button("Go Back to Home") {
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.success)
                    
                    checkoutEnv.catalogNavigationStackID = UUID() // Reset Catalog navigation stack to root!
                    checkoutEnv.selectedTab = 0 // Route back to Home tab (Tab 0)
                    checkoutEnv.isCheckoutFlowActive = false
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                        checkoutEnv.activeCart = nil
                    }
                }
                .font(.headline)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
                .padding(.horizontal)
                .padding(.bottom, 24)
            }
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            if !finalized {
                Task {
                    await checkoutEnv.finalizeTransaction(
                        userId: authVM.currentUser?.id
                    )
                    finalized = true
                }
            }
        }
    }
}

struct RecommendationProductCard: View {
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
            .frame(width: 110, alignment: .leading)
        }
        .padding(8)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.appleBorder, lineWidth: 1)
        )
    }
}
