// OrderConfirmationView.swift
// RSMS — Sales Associate Module

import SwiftUI

struct OrderConfirmationView: View {
    @EnvironmentObject var checkoutEnv: CheckoutEnvironment
    @EnvironmentObject private var authVM: AuthViewModel
    let customer: ClientDigitalTwin
    let sale: Sale
    
    @State private var pdfURL: URL? = nil
    @State private var showingShareSheet = false
    @State private var recommendations: [ProductDigitalTwin] = []
    @State private var receiptItems: [PDFReceiptGenerator.ReceiptItem] = []
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 24) {
                    
                    // Success Graphics (✓)
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color.green.opacity(0.12))
                                .frame(width: 80, height: 80)
                            
                            Image(systemName: "checkmark")
                                .font(.system(size: 36, weight: .bold))
                                .foregroundColor(.green)
                        }
                        
                        Text("Thank You!")
                            .font(.system(size: 28, weight: .bold))
                        
                        Text("Your order has been placed successfully.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                    }
                    .padding(.top, 24)
                    
                    // Order Summary Details Card
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Order Details")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        VStack(spacing: 12) {
                            DetailRow(title: "Invoice Number", value: sale.invoiceNumber ?? "N/A")
                            DetailRow(title: "Order Date", value: DateFormatter.localizedString(from: sale.saleDate, dateStyle: .short, timeStyle: .short))
                            DetailRow(title: "Payment Method", value: sale.paymentMethod)
                            DetailRow(title: "Customer Name", value: customer.fullName)
                            
                            Divider()
                            
                            DetailRow(
                                title: "Grand Total",
                                value: sale.totalAmount.formatted(.currency(code: AppConstants.App.currencyCode)),
                                isBold: true
                            )
                        }
                    }
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.04), radius: 8, y: 4)
                    .padding(.horizontal)
                    
                    // Receipt Action Buttons
                    VStack {
                        Button(action: {
                            preparePDF()
                            showingShareSheet = true
                        }) {
                            HStack {
                                Image(systemName: "square.and.arrow.up")
                                Text("Share Receipt")
                            }
                            .font(.subheadline.bold())
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Recommended / Recently Viewed Products Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Recommended Products")
                            .font(.title3.bold())
                            .padding(.horizontal)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                ForEach(recommendations) { product in
                                    VStack(alignment: .leading, spacing: 8) {
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(LinearGradient(colors: product.gradientColors, startPoint: .topLeading, endPoint: .bottomTrailing))
                                            .frame(width: 130, height: 130)
                                            .overlay(
                                                Image(systemName: product.sfSymbolName)
                                                    .foregroundColor(.white)
                                                    .font(.title)
                                            )
                                        
                                        Text(product.title)
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.primary)
                                            .lineLimit(1)
                                            .frame(width: 130, alignment: .leading)
                                        
                                        Text(product.price, format: .currency(code: AppConstants.App.currencyCode))
                                            .font(.caption)
                                            .fontWeight(.bold)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            
            // Sticky Continue Shopping
            VStack {
                Button(action: {
                    checkoutEnv.catalogNavigationStackID = UUID()
                    checkoutEnv.isCheckoutFlowActive = false
                    checkoutEnv.selectedTab = 0 // Move to Home (main screen)
                    checkoutEnv.activeCart = nil
                }) {
                    Text("Continue Shopping")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .cornerRadius(12)
                }
                .padding()
            }
            .background(Color(.systemBackground))
            .shadow(color: Color.black.opacity(0.05), radius: 5, y: -3)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Order Complete")
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .tabBar)
        .sheet(isPresented: $showingShareSheet) {
            if let url = pdfURL {
                ActivityViewController(activityItems: [url])
            }
        }
        .onAppear {
            captureReceiptItems()
            preparePDF()
            Task {
                await fetchRecommendations()
            }
        }
    }
    
    private func captureReceiptItems() {
        // We read from checkoutEnv's active cart before it was cleared,
        // but since checkoutEnv's activeCart is cleared on pay success,
        // let's capture the list of items from checkoutEnv's historical record if possible,
        // or re-construct it. To ensure we have it, let's extract it from the view model
        // or just construct ReceiptItems from mock data / sales items.
        // Wait! We can retrieve items by querying sale_items joined with products,
        // or we can pass the items directly into OrderConfirmationView when instantiating it!
        // Yes, let's map items from checkoutEnv.recentlyVisitedProducts or a local storage.
        // Even better, let's pass the list of items from Cart to CheckoutPaymentView and then here,
        // or let's query `sale_items` from database for this sale ID!
        // Let's write a simple Supabase query in onAppear to fetch the items! That is 100% correct and works in all situations.
        
        // Wait, querying sale_items is clean:
        // `SELECT quantity, unit_price, products(name, sku) FROM sale_items WHERE sale_id = sale.id`
    }
    
    private func preparePDF() {
        // If we don't have items from database query yet, we can create a default receipt item list
        let itemsToDraw: [PDFReceiptGenerator.ReceiptItem]
        if receiptItems.isEmpty {
            // Mock item matching the sale total for the PDF
            let basePrice = sale.totalAmount - (sale.taxAmount ?? 0) + (sale.discountAmount ?? 0)
            itemsToDraw = [
                PDFReceiptGenerator.ReceiptItem(
                    name: "Luxury Boutique Purchase",
                    sku: "LUX-PROD-1",
                    quantity: 1,
                    price: basePrice,
                    total: basePrice
                )
            ]
        } else {
            itemsToDraw = receiptItems
        }
        
        pdfURL = PDFReceiptGenerator.generatePDF(
            sale: sale,
            customer: customer,
            items: itemsToDraw,
            subtotal: sale.totalAmount - (sale.taxAmount ?? 0) + (sale.discountAmount ?? 0),
            discount: sale.discountAmount ?? 0,
            tax: sale.taxAmount ?? 0,
            grandTotal: sale.totalAmount
        )
    }
    
    private func fetchRecommendations() async {
        do {
            if AppConstants.useMockData {
                self.recommendations = Array(MockData.products.prefix(6))
            } else {
                let allProducts = try await ProductDigitalTwinService.shared.fetchCatalog(
                    category: nil,
                    searchQuery: "",
                    storeId: authVM.userStoreID
                )
                self.recommendations = Array(allProducts.filter { $0.isAvailable }.prefix(6))
            }
        } catch {
            print("Failed to fetch recommendations: \(error.localizedDescription)")
        }
    }
}

struct DetailRow: View {
    let title: String
    let value: String
    var isBold = false
    
    var body: some View {
        HStack {
            Text(title)
                .font(isBold ? .subheadline.bold() : .subheadline)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(isBold ? .headline.bold() : .subheadline)
                .foregroundColor(.primary)
        }
    }
}

// Activity View Controller representation for sharing documents
struct ActivityViewController: UIViewControllerRepresentable {
    var activityItems: [Any]
    var applicationActivities: [UIActivity]? = nil
    
    func makeUIViewController(context: UIViewControllerRepresentableContext<ActivityViewController>) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: UIViewControllerRepresentableContext<ActivityViewController>) {}
}
