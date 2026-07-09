// BillSummaryView.swift
// RSMS — Sales Associate Module

import SwiftUI

struct BillSummaryView: View {
    @EnvironmentObject var checkoutEnv: CheckoutEnvironment
    let customer: ClientDigitalTwin
    @Environment(\.dismiss) var dismiss
    @State private var navigateToPayment = false
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 20) {
                    
                    // Customer Information Card
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Customer Information")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Text(customer.fullName)
                                .font(.title3.bold())
                            
                            HStack(spacing: 8) {
                                Image(systemName: "phone.fill")
                                    .foregroundColor(.secondary)
                                    .font(.caption)
                                Text(customer.phone ?? "No Phone")
                                    .font(.subheadline)
                            }
                            
                            HStack(spacing: 8) {
                                Image(systemName: "mappin.and.ellipse")
                                    .foregroundColor(.secondary)
                                    .font(.caption)
                                Text(customer.address ?? "Address not set")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.04), radius: 8, y: 4)
                    .padding(.horizontal)
                    .padding(.top, 16)
                    
                    // Items Section
                    if let cart = checkoutEnv.activeCart {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Product Summary")
                                .font(.headline)
                                .foregroundColor(.secondary)
                                .padding(.horizontal)
                            
                            VStack(spacing: 0) {
                                ForEach(cart.items) { item in
                                    HStack(spacing: 12) {
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(LinearGradient(colors: item.product.gradientColors, startPoint: .topLeading, endPoint: .bottomTrailing))
                                            .frame(width: 50, height: 50)
                                            .overlay(
                                                Image(systemName: item.product.sfSymbolName)
                                                    .foregroundColor(.white)
                                                    .font(.caption)
                                            )
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(item.product.title)
                                                .font(.subheadline.bold())
                                                .lineLimit(1)
                                            
                                            Text("SKU: \(item.product.sku ?? "N/A")")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                            
                                            Text("Qty: \(item.quantity) × \(item.product.price.formatted(.currency(code: AppConstants.App.currencyCode)))")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                        
                                        Spacer()
                                        
                                        Text(item.subtotal, format: .currency(code: AppConstants.App.currencyCode))
                                            .font(.subheadline.bold())
                                    }
                                    .padding(.vertical, 12)
                                    .padding(.horizontal)
                                    
                                    if item.id != cart.items.last?.id {
                                        Divider().padding(.leading, 78)
                                    }
                                }
                            }
                            .background(Color(.secondarySystemGroupedBackground))
                            .cornerRadius(16)
                            .shadow(color: Color.black.opacity(0.04), radius: 8, y: 4)
                            .padding(.horizontal)
                        }
                        
                        // Totals Summary
                        VStack(spacing: 12) {
                            HStack {
                                Text("Subtotal")
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(cart.subtotal, format: .currency(code: AppConstants.App.currencyCode))
                            }
                            
                            let discountAmount = cart.subtotal - cart.discountedSubtotal
                            if discountAmount > 0 {
                                HStack {
                                    Text("Discount")
                                        .foregroundColor(.green)
                                    Spacer()
                                    Text("-\(discountAmount.formatted(.currency(code: AppConstants.App.currencyCode)))")
                                        .foregroundColor(.green)
                                }
                            }
                            
                            HStack {
                                Text("Tax (8.875%)")
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(cart.tax, format: .currency(code: AppConstants.App.currencyCode))
                            }
                            
                            Divider()
                            
                            HStack {
                                Text("Grand Total")
                                    .font(.headline.bold())
                                Spacer()
                                Text(cart.total, format: .currency(code: AppConstants.App.currencyCode))
                                    .font(.title3.bold())
                                    .foregroundColor(.primary)
                            }
                        }
                        .padding()
                        .background(Color(.secondarySystemGroupedBackground))
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.04), radius: 8, y: 4)
                        .padding(.horizontal)
                    }
                }
            }
            
            // Sticky Bottom Panel
            VStack {
                HStack(spacing: 16) {
                    Button(action: {
                        dismiss()
                    }) {
                        Text("Back")
                            .font(.headline)
                            .foregroundColor(.primary)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(.systemGray5))
                            .cornerRadius(12)
                    }
                    
                    Button(action: {
                        navigateToPayment = true
                    }) {
                        Text("Payment")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(12)
                    }
                }
                .padding()
            }
            .background(Color(.systemBackground))
            .shadow(color: Color.black.opacity(0.05), radius: 5, y: -3)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Bill Summary")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .navigationDestination(isPresented: $navigateToPayment) {
            CheckoutPaymentView(customer: customer)
        }
    }
}
