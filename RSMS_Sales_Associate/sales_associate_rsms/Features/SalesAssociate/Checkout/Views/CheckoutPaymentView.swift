// CheckoutPaymentView.swift
// RSMS — Sales Associate Module

import SwiftUI

struct CheckoutPaymentView: View {
    @EnvironmentObject var checkoutEnv: CheckoutEnvironment
    @EnvironmentObject private var authVM: AuthViewModel
    let customer: ClientDigitalTwin
    @Environment(\.dismiss) var dismiss
    
    @State private var isLoadingTransaction = false
    @State private var errorMessage: String? = nil
    @State private var createdSale: Sale? = nil
    @State private var navigateToConfirmation = false
    
    // Payment UI state variables
    @State private var selectedPaymentMethod: PaymentMethod? = nil
    @State private var showingUPISheet = false
    @State private var showingApplePaySheet = false
    @State private var selectedUPIApp: String? = nil
    @State private var appLaunching = false
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 24) {
                        
                        // Amount Details Card
                        if let cart = checkoutEnv.activeCart {
                            VStack(spacing: 8) {
                                Text("Total Amount Due")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                Text(cart.total, format: .currency(code: AppConstants.App.currencyCode))
                                    .font(.system(size: 40, weight: .bold))
                                    .foregroundColor(.primary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 32)
                            .background(Color(.secondarySystemGroupedBackground))
                            .cornerRadius(16)
                            .shadow(color: Color.black.opacity(0.04), radius: 8, y: 4)
                            .padding(.horizontal)
                            .padding(.top, 16)
                        }
                        
                        // Payment Options List
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Select Payment Method")
                                .font(.headline)
                                .foregroundColor(.secondary)
                                .padding(.horizontal)
                            
                            VStack(spacing: 0) {
                                // Cash
                                PaymentOptionRow(
                                    title: "Cash",
                                    subtitle: "Accept physical cash currency",
                                    icon: "banknote",
                                    iconColor: .green,
                                    isSelected: selectedPaymentMethod == .cash
                                ) {
                                    selectedPaymentMethod = .cash
                                }
                                
                                Divider().padding(.leading, 64)
                                
                                // UPI
                                PaymentOptionRow(
                                    title: "UPI Transfer",
                                    subtitle: "Google Pay, PhonePe, Paytm, BHIM",
                                    icon: "qrcode",
                                    iconColor: .blue,
                                    isSelected: selectedPaymentMethod == .upi
                                ) {
                                    selectedPaymentMethod = .upi
                                }
                                
                                Divider().padding(.leading, 64)
                                
                                // Apple Pay
                                PaymentOptionRow(
                                    title: "Apple Pay",
                                    subtitle: "Secure payment via Apple Wallet",
                                    icon: "applelogo",
                                    iconColor: .primary,
                                    isSelected: selectedPaymentMethod == .applePay
                                ) {
                                    selectedPaymentMethod = .applePay
                                }
                            }
                            .background(Color(.secondarySystemGroupedBackground))
                            .cornerRadius(16)
                            .shadow(color: Color.black.opacity(0.04), radius: 8, y: 4)
                            .padding(.horizontal)
                        }
                        
                        if let error = errorMessage {
                            VStack(spacing: 8) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.red)
                                    .font(.title3)
                                Text(error)
                                    .font(.subheadline)
                                    .foregroundColor(.red)
                                    .multilineTextAlignment(.center)
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.red.opacity(0.08))
                            .cornerRadius(12)
                            .padding(.horizontal)
                        }
                    }
                }
                
                // Sticky Action Button
                VStack {
                    Button(action: {
                        proceedWithPayment()
                    }) {
                        Text("Pay Now")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(selectedPaymentMethod == nil ? Color.gray : Color.blue)
                            .cornerRadius(12)
                    }
                    .disabled(selectedPaymentMethod == nil || isLoadingTransaction)
                    .padding()
                }
                .background(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 5, y: -3)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Payment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .tabBar)
            .navigationDestination(isPresented: $navigateToConfirmation) {
                if let sale = createdSale {
                    OrderConfirmationView(customer: customer, sale: sale)
                }
            }
            
            // Transaction Loading Overlay
            if isLoadingTransaction {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .overlay(
                        VStack(spacing: 16) {
                            ProgressView()
                                .tint(.white)
                                .scaleEffect(1.5)
                            Text("Processing Checkout...")
                                .font(.headline)
                                .foregroundColor(.white)
                            Text("Validating inventory and creating invoice...")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.8))
                        }
                    )
            }
        }
        // UPI Selection Sheet
        .sheet(isPresented: $showingUPISheet) {
            UPISimulatorView(isPresented: $showingUPISheet) { app in
                self.selectedUPIApp = app
                self.appLaunching = true
                
                // Simulate app switch and redirect back
                Task {
                    try? await Task.sleep(nanoseconds: 1_500_000_000)
                    self.appLaunching = false
                    self.showingUPISheet = false
                    
                    // Proceed with Transaction insertion
                    await completeOrder(paymentMethod: "UPI (\(app))")
                }
            }
        }
        // Apple Pay Simulated Sheet
        .sheet(isPresented: $showingApplePaySheet) {
            ApplePaySimulatorView(
                isPresented: $showingApplePaySheet,
                amount: checkoutEnv.activeCart?.total ?? 0
            ) { success in
                self.showingApplePaySheet = false
                if success {
                    Task {
                        await completeOrder(paymentMethod: "Apple Pay")
                    }
                }
            }
        }
    }
    
    private func proceedWithPayment() {
        guard let method = selectedPaymentMethod else { return }
        errorMessage = nil
        
        switch method {
        case .cash:
            Task {
                await completeOrder(paymentMethod: "Cash")
            }
        case .upi:
            showingUPISheet = true
        case .applePay:
            showingApplePaySheet = true
        default:
            break
        }
    }
    
    private func completeOrder(paymentMethod: String) async {
        guard let cart = checkoutEnv.activeCart else { return }
        guard let userId = authVM.currentUser?.id else {
            self.errorMessage = "User session expired."
            return
        }
        
        self.isLoadingTransaction = true
        self.errorMessage = nil
        
        let items = cart.items.map { ($0.product.id, $0.quantity, Double(truncating: $0.product.price as NSNumber)) }
        let discountPercent = cart.orderLevelDiscountPercent ?? 0
        let cartTotal = (cart.total as NSDecimalNumber).doubleValue
        
        // Compute proration discount and tax
        let discountAmount = discountPercent == 0 ? 0 : (cartTotal * Double(truncating: discountPercent as NSNumber) / 100)
        let taxAmount = (cart.tax as NSDecimalNumber).doubleValue
        
        do {
            let sale = try await SalesAssociateService.shared.insertSale(
                customerId: customer.id,
                userId: userId,
                items: items,
                paymentMethod: paymentMethod,
                discountAmount: discountAmount,
                taxAmount: taxAmount
            )
            
            // Clear Cart
            checkoutEnv.activeCart = nil
            self.createdSale = sale
            self.navigateToConfirmation = true
        } catch {
            let errorMsg = error.localizedDescription
            if errorMsg.localizedCaseInsensitiveContains("Insufficient stock") || errorMsg.localizedCaseInsensitiveContains("stock level") {
                self.errorMessage = "Insufficient stock available."
            } else {
                self.errorMessage = errorMsg
            }
        }
        self.isLoadingTransaction = false
    }
}

// Payment Row Components
struct PaymentOptionRow: View {
    let title: String
    let subtitle: String
    let icon: String
    let iconColor: Color
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(iconColor)
                    .frame(width: 32, height: 32)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Circle()
                    .fill(isSelected ? Color.blue : Color.clear)
                    .frame(width: 20, height: 20)
                    .overlay(
                        Circle()
                            .stroke(isSelected ? Color.blue : Color(.systemGray4), lineWidth: 2)
                    )
            }
            .padding()
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// UPI Apps Picker Sheet
struct UPISimulatorView: View {
    @Binding var isPresented: Bool
    let onSelect: (String) -> Void
    
    let apps = ["Google Pay", "PhonePe", "Paytm", "BHIM"]
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(apps, id: \.self) { app in
                    Button(action: {
                        onSelect(app)
                    }) {
                        HStack {
                            Text(app)
                                .font(.headline)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Select UPI Application")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
            }
        }
    }
}

// Apple Pay Sheet Simulation
struct ApplePaySimulatorView: View {
    @Binding var isPresented: Bool
    let amount: Decimal
    let onComplete: (Bool) -> Void
    
    @State private var progressText = "Confirm Payment"
    @State private var isProcessing = false
    
    var body: some View {
        VStack(spacing: 24) {
            Capsule()
                .fill(Color(.systemGray4))
                .frame(width: 40, height: 6)
                .padding(.top, 8)
            
            Text("Apple Pay Sandbox")
                .font(.title3.bold())
            
            Image(systemName: "applelogo")
                .font(.system(size: 60))
                .padding()
            
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("CARD")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(" Pay Card (•••• 1234)")
                        .font(.body.bold())
                }
                
                HStack {
                    Text("TOTAL DUE")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(amount, format: .currency(code: AppConstants.App.currencyCode))
                        .font(.body.bold())
                }
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(12)
            .padding(.horizontal)
            
            if isProcessing {
                ProgressView()
                    .padding()
            } else {
                Button(action: {
                    isProcessing = true
                    progressText = "Processing with Face ID..."
                    Task {
                        try? await Task.sleep(nanoseconds: 1_500_000_000)
                        onComplete(true)
                    }
                }) {
                    Text("Double-Click to Pay")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.black)
                        .cornerRadius(12)
                }
                .padding(.horizontal)
            }
            
            Button("Cancel") {
                onComplete(false)
            }
            .font(.subheadline)
            .foregroundColor(.secondary)
        }
        .padding(.bottom, 32)
        .background(Color(.systemGroupedBackground))
    }
}
