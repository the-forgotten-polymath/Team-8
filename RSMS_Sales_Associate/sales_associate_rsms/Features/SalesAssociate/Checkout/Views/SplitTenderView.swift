// SplitTenderView.swift
// RSMS — Sales Associate Module

import SwiftUI
import Razorpay

struct SplitTenderView: View {
    @EnvironmentObject var checkoutEnv: CheckoutEnvironment
    
    @State private var showingCardPayment = false
    @State private var showingCashPayment = false
    @State private var cashAmountString: String = ""
    
    var body: some View {
        Form {
            if let cart = checkoutEnv.activeCart {
                Section(header: Text("Bill Summary")) {
                    HStack {
                        Text("Subtotal")
                        Spacer()
                        Text(cart.subtotal, format: .currency(code: "USD"))
                    }
                    if let discount = cart.orderLevelDiscountPercent {
                        HStack {
                            Text("Discount (\(discount, format: .number)%)")
                            Spacer()
                            Text("-\(cart.subtotal - cart.discountedSubtotal, format: .currency(code: "USD"))")
                                .foregroundColor(.green)
                        }
                    }
                    if cart.giftWrap {
                        HStack {
                            Text("Gift Wrapping Services")
                            Spacer()
                            Text("Included")
                                .foregroundColor(.secondary)
                        }
                    }
                    HStack {
                        Text("Tax (8.875%)")
                        Spacer()
                        Text(cart.tax, format: .currency(code: "USD"))
                    }
                    Divider()
                    HStack {
                        Text("Total Due").bold()
                        Spacer()
                        Text(cart.total, format: .currency(code: "USD")).bold()
                    }
                }
                
                Section(header: Text("Applied Payments")) {
                    ForEach(cart.appliedTenders) { tender in
                        HStack {
                            Text(tender.method.rawValue.capitalized)
                            Spacer()
                            Text("-\(tender.amount, format: .currency(code: "USD"))")
                        }
                        .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Remaining Balance").bold()
                        Spacer()
                        Text(cart.remainingBalance, format: .currency(code: "USD")).bold()
                    }
                }
                
                if !cart.isFullyPaid {
                    Section(header: Text("Add Payment")) {
                        Button(action: {
                            showingCardPayment = true
                        }) {
                            Label("Credit Card (Razorpay)", systemImage: "creditcard")
                        }
                        
                        Button(action: {
                            showingCashPayment = true
                        }) {
                            Label("Cash", systemImage: "banknote")
                        }
                        
                        Button(action: {
                            // Mocking external payment methods
                            checkoutEnv.addTender(method: .applePay, amount: cart.remainingBalance)
                        }) {
                            Label("Apple Pay", systemImage: "applelogo")
                        }
                    }
                } else {
                    Section {
                        VStack(spacing: 16) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.green)
                            
                            Text("Payment Successful")
                                .font(.title3.bold())
                            
                            Text("The remaining balance has been fully paid. Tap the button below to generate the order invoice and view the transaction receipt.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                            
                            NavigationLink(destination: ReceiptView()) {
                                Text("Complete & View Receipt")
                                    .font(.headline)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.green)
                                    .cornerRadius(12)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .padding(.vertical)
                    }
                }
            }
        }
        .navigationTitle("Payment")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Cancel Order", role: .destructive) {
                    checkoutEnv.activeCart = nil
                    checkoutEnv.selectedTab = 1 // Catalog screen
                    checkoutEnv.isCheckoutFlowActive = false
                }
                .foregroundColor(.red)
            }
        }
        .sheet(isPresented: $showingCardPayment) {
            RazorpayPaymentSheetMockView(amount: checkoutEnv.activeCart?.remainingBalance ?? 0) {
                checkoutEnv.addTender(method: .card, amount: checkoutEnv.activeCart?.remainingBalance ?? 0)
                showingCardPayment = false
            }
        }
        .sheet(isPresented: $showingCashPayment) {
            NavigationStack {
                Form {
                    Section(header: Text("Enter Cash Amount")) {
                        TextField("Amount", text: $cashAmountString)
                            .keyboardType(.decimalPad)
                    }
                }
                .navigationTitle("Cash Payment")
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") { showingCashPayment = false }
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Apply") {
                            if let val = Decimal(string: cashAmountString) {
                                checkoutEnv.addTender(method: .cash, amount: val)
                                showingCashPayment = false
                            }
                        }
                    }
                }
            }
        }
    }
}

// A simple mock for Razorpay payment collection
struct RazorpayPaymentSheetMockView: View {
    let amount: Decimal
    let onComplete: () -> Void
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text("Razorpay Sandbox")
                    .font(.largeTitle.bold())
                
                Text("Paying: \(amount, format: .currency(code: "USD"))")
                    .font(.title2)
                
                // In a real app, we'd use Razorpay's Checkout UI here.
                // However, without a backend to generate a Razorpay order ID,
                // we'll just mock the visual representation.
                
                HStack {
                    Image(systemName: "creditcard")
                    Text("•••• •••• •••• 4242")
                    Spacer()
                    Text("12/26")
                    Text("123")
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .padding(.horizontal)
                
                Button(action: {
                    onComplete()
                }) {
                    Text("Process Payment")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .padding(.top, 40)
            .navigationTitle("Card Payment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}
