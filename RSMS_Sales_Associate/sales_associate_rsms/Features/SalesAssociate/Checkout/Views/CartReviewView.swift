// CartReviewView.swift
// RSMS — Sales Associate Module

import SwiftUI

struct CartReviewView: View {
    var isEmbedded: Bool = false
    @EnvironmentObject var checkoutEnv: CheckoutEnvironment
    @State private var discountString: String = ""
    @State private var showingManagerApproval = false
    
    var body: some View {
        if isEmbedded {
            mainContent
        } else {
            NavigationStack {
                mainContent
            }
        }
    }
    
    private var mainContent: some View {
        Group {
            if let cart = checkoutEnv.activeCart {
                VStack(spacing: 0) {
                    List {
                        Section(header: Text("Items (\(cart.items.count))")) {
                            ForEach(cart.items) { item in
                                HStack(spacing: 12) {
                                    // Product category image / gradient
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
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                            .lineLimit(1)
                                        
                                        // Quantity selector controls
                                        HStack(spacing: 10) {
                                            Button(action: {
                                                checkoutEnv.decrementQuantity(for: item)
                                            }) {
                                                Image(systemName: "minus")
                                                    .font(.system(size: 10, weight: .bold))
                                                    .foregroundColor(.primary)
                                                    .frame(width: 24, height: 24)
                                                    .background(Color(.systemGray5))
                                                    .clipShape(Circle())
                                            }
                                            .buttonStyle(PlainButtonStyle())
                                            
                                            Text("\(item.quantity)")
                                                .font(.subheadline)
                                                .fontWeight(.bold)
                                                .frame(minWidth: 16)
                                            
                                            Button(action: {
                                                checkoutEnv.incrementQuantity(for: item)
                                            }) {
                                                Image(systemName: "plus")
                                                    .font(.system(size: 10, weight: .bold))
                                                    .foregroundColor(.primary)
                                                    .frame(width: 24, height: 24)
                                                    .background(Color(.systemGray5))
                                                    .clipShape(Circle())
                                            }
                                            .buttonStyle(PlainButtonStyle())
                                        }
                                    }
                                    
                                    Spacer()
                                    
                                    Text(item.subtotal, format: .currency(code: item.product.currency))
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                }
                                .padding(.vertical, 4)
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button(role: .destructive) {
                                        checkoutEnv.removeItem(item)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                    
                                    Button {
                                        if !checkoutEnv.likedProducts.contains(where: { $0.id == item.product.id }) {
                                            checkoutEnv.toggleLike(product: item.product)
                                        }
                                        checkoutEnv.removeItem(item)
                                    } label: {
                                        Label("Like", systemImage: "heart.fill")
                                    }
                                    .tint(.orange)
                                }
                            }
                        }
                        
                        Section(header: Text("Discount")) {
                            HStack {
                                TextField("Discount %", text: $discountString)
                                    .keyboardType(.decimalPad)
                                Button("Apply") {
                                    if let val = Decimal(string: discountString) {
                                        checkoutEnv.applyDiscount(val)
                                        if checkoutEnv.requiresManagerApproval {
                                            showingManagerApproval = true
                                        }
                                    }
                                }
                            }
                            
                            if let discount = cart.orderLevelDiscountPercent {
                                HStack {
                                    Text("Applied Discount:")
                                    Spacer()
                                    Text("\(discount, format: .number)%")
                                        .foregroundColor(.green)
                                }
                            }
                        }
                        
                        Section(header: Text("Services")) {
                            Toggle("Gift Wrapping", isOn: Binding(
                                get: { checkoutEnv.activeCart?.giftWrap ?? false },
                                set: { checkoutEnv.activeCart?.giftWrap = $0 }
                            ))
                            
                            if checkoutEnv.activeCart?.giftWrap == true {
                                TextField("Gift Note (Optional)", text: Binding(
                                    get: { checkoutEnv.activeCart?.giftNote ?? "" },
                                    set: { checkoutEnv.activeCart?.giftNote = $0 }
                                ))
                            }
                        }
                        
                        Section(header: Text("Summary")) {
                            HStack {
                                Text("Subtotal")
                                Spacer()
                                Text(cart.subtotal, format: .currency(code: AppConstants.App.currencyCode))
                            }
                            if cart.orderLevelDiscountPercent != nil {
                                HStack {
                                    Text("Discounted Subtotal")
                                    Spacer()
                                    Text(cart.discountedSubtotal, format: .currency(code: AppConstants.App.currencyCode))
                                }
                                .foregroundColor(.green)
                            }
                            HStack {
                                Text("Tax (8.875%)")
                                Spacer()
                                Text(cart.tax, format: .currency(code: AppConstants.App.currencyCode))
                            }
                            HStack {
                                Text("Total").bold()
                                Spacer()
                                Text(cart.total, format: .currency(code: AppConstants.App.currencyCode)).bold()
                            }
                        }
                    }
                    
                    // Sticky Bottom Panel with Proceed to Buy Button
                    VStack {
                        NavigationLink(destination: CustomerVerificationView()) {
                            Text("Proceed to Checkout")
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(((checkoutEnv.activeCart?.items.isEmpty ?? true) || (checkoutEnv.requiresManagerApproval && !checkoutEnv.managerApproved)) ? Color.gray : Color.blue)
                                .cornerRadius(12)
                        }
                        .disabled((checkoutEnv.activeCart?.items.isEmpty ?? true) || (checkoutEnv.requiresManagerApproval && !checkoutEnv.managerApproved))
                        .padding()
                    }
                    .background(Color(.systemBackground))
                    .shadow(color: Color.black.opacity(0.05), radius: 5, y: -3)
                }
                .navigationTitle("Review Cart")
                .toolbar(.hidden, for: .tabBar)
                .alert("Manager Approval Required", isPresented: $showingManagerApproval) {
                    Button("Approve (Mock)", role: .none) {
                        checkoutEnv.approveDiscount()
                    }
                    Button("Cancel", role: .cancel) {
                        checkoutEnv.applyDiscount(0)
                        discountString = ""
                    }
                } message: {
                    Text("Discounts over 10% require manager override.")
                }
            } else {
                VStack {
                    Text("No Active Cart")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Button("Start Mock Checkout") {
                        if let client = MockData.clients.first {
                            checkoutEnv.startCheckout(for: client)
                        }
                    }
                    .padding()
                }
            }
        }
    }
}
