// CatalogProductCardView.swift
// RSMS — Sales Associate Module

import SwiftUI

struct CatalogProductCardView: View {
    let product: ProductDigitalTwin
    @EnvironmentObject var checkoutEnv: CheckoutEnvironment
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Product Image Container (Strict 1:1 Ratio)
            Color.clear
                .aspectRatio(1, contentMode: .fit)
                .overlay(
                    ZStack(alignment: .topTrailing) {
                        // Category Specific Digital Gradient or Image
                if let firstImageURL = product.imageURLs?.first {
                    AsyncImage(url: firstImageURL) { phase in
                        switch phase {
                        case .empty:
                            ZStack {
                                LinearGradient(colors: product.gradientColors, startPoint: .topLeading, endPoint: .bottomTrailing)
                                    .overlay(
                                        Image(systemName: product.sfSymbolName)
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 44)
                                            .foregroundColor(.white.opacity(0.5))
                                    )
                                ProgressView()
                            }
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                        case .failure:
                            LinearGradient(colors: product.gradientColors, startPoint: .topLeading, endPoint: .bottomTrailing)
                                .overlay(
                                    Image(systemName: product.sfSymbolName)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 44)
                                        .foregroundColor(.white)
                                )
                        @unknown default:
                            EmptyView()
                        }
                    }
                } else {
                    LinearGradient(colors: product.gradientColors, startPoint: .topLeading, endPoint: .bottomTrailing)
                        .overlay(
                            Image(systemName: product.sfSymbolName)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 44)
                                .foregroundColor(.white)
                        )
                }
                
                // Wishlist overlay icon
                Button(action: {
                    checkoutEnv.toggleLike(product: product)
                }) {
                    Image(systemName: checkoutEnv.likedProducts.contains(where: { $0.id == product.id }) ? "heart.fill" : "heart")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(checkoutEnv.likedProducts.contains(where: { $0.id == product.id }) ? .red : .gray)
                        .padding(8)
                        .background(Color.white.opacity(0.85))
                        .clipShape(Circle())
                        .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 1.5)
                }
                .padding(8)
                    }
                )
                .clipped()
                .clipShape(UnevenRoundedRectangle(topLeadingRadius: 16, bottomLeadingRadius: 0, bottomTrailingRadius: 0, topTrailingRadius: 16))
            
            // Card Info Content
            VStack(alignment: .leading, spacing: 6) {
                Text(product.brand)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
                
                Text(product.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .frame(height: 40, alignment: .topLeading) // Equal-height lock ensures cards align perfectly!
                
                Text(product.price, format: .currency(code: product.currency))
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.primary)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.appleBorder, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.03), radius: 6, x: 0, y: 3)
    }
}
