//
//  RestockCartView.swift
//  RSMS_Project
//
//  Created by Antigravity on 02/07/26.
//

import SwiftUI
import Supabase

struct RestockCartView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var cartManager = RestockCartManager.shared
    
    @State private var isSubmitting = false
    @State private var showSuccess = false
    @State private var showError = false
    @State private var errorAlertMessage = ""
    
    // Submitted order tracking
    @State private var submittedOrderId = ""
    @State private var submittedProductCount = 0
    @State private var submittedTotalUnits = 0
    
    let onOrderSubmitted: () -> Void
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    if cartManager.items.isEmpty {
                        emptyView
                    } else {
                        // Cart List
                        List {
                            ForEach(cartManager.items) { item in
                                cartItemCard(item: item)
                                    .listRowBackground(Color.clear)
                                    .listRowSeparator(.hidden)
                                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                            }
                            .onDelete(perform: deleteItems)
                        }
                        .listStyle(.plain)
                        
                        // Order Summary Panel & Swipe to Order
                        summaryAndOrderPanel
                    }
                }
                
                // Success Overlay
                if showSuccess {
                    successOverlayView
                }
                
                // Processing HUD
                if isSubmitting {
                    processingHUD
                }
            }
            .navigationBarTitle("Restock Cart", displayMode: .inline)
            .navigationBarItems(leading: Button("Close") { dismiss() }
                .disabled(isSubmitting || showSuccess)
            )
            .alert(isPresented: $showError) {
                Alert(
                    title: Text("Unable to send request"),
                    message: Text(errorAlertMessage),
                    primaryButton: .default(Text("Retry"), action: {
                        Swift.Task {
                            await submitOrder()
                        }
                    }),
                    secondaryButton: .cancel(Text("Cancel"))
                )
            }
        }
    }
    
    // MARK: - Subviews
    
    private var emptyView: some View {
        VStack(spacing: 20) {
            Image(systemName: "cart.badge.minus")
                .font(.system(size: 64))
                .foregroundColor(.secondary)
            
            Text("Your Restock Cart is Empty")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.primary)
            
            Text("Add items to request restocking from the inventory manager.")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxHeight: .infinity)
    }
    
    private func cartItemCard(item: CartItem) -> some View {
        HStack(alignment: .top, spacing: 16) {
            // Product Image on the left
            if let imageURLString = item.product.imageURL, let url = URL(string: imageURLString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 70, height: 70)
                            .cornerRadius(10)
                            .clipped()
                    case .failure, .empty:
                        imagePlaceholder
                    @unknown default:
                        imagePlaceholder
                    }
                }
            } else {
                imagePlaceholder
            }
            
            // Details & Controls VStack
            VStack(alignment: .leading, spacing: 6) {
                // Brand
                if let brand = item.product.brand {
                    Text(brand.uppercased())
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.blue)
                }
                
                // Product Name
                Text(item.product.productName)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(2)
                
                // SKU | Current Stock
                Text("SKU: \(item.product.sku)  |  Stock: \(item.product.quantity) units")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                
                Spacer(minLength: 8)
                
                // Bottom row: Price and Stepper
                HStack(alignment: .center) {
                    // Total Price
                    Text(formatIndianCurrency(amount: item.product.price * Decimal(item.quantity)))
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    // Quantity controls aligned bottom-right
                    HStack(spacing: 12) {
                        Button(action: {
                            if item.quantity > 1 {
                                cartManager.updateQuantity(for: item.productId, to: item.quantity - 1)
                            } else {
                                cartManager.remove(productId: item.productId)
                            }
                        }) {
                            Image(systemName: "minus.circle.fill")
                                .font(.system(size: 22))
                                .foregroundColor(.blue)
                        }
                        .buttonStyle(BorderlessButtonStyle())
                        
                        Text("\(item.quantity)")
                            .font(.system(size: 14, weight: .bold))
                            .frame(minWidth: 24)
                            .multilineTextAlignment(.center)
                        
                        Button(action: {
                            cartManager.updateQuantity(for: item.productId, to: item.quantity + 1)
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 22))
                                .foregroundColor(.blue)
                        }
                        .buttonStyle(BorderlessButtonStyle())
                    }
                }
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.02), radius: 6, x: 0, y: 3)
    }
    
    private var imagePlaceholder: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.systemGray6))
                .frame(width: 70, height: 70)
            
            Image(systemName: "shippingbox.fill")
                .font(.system(size: 24))
                .foregroundColor(Color(.systemGray3))
        }
    }
    
    private var summaryAndOrderPanel: some View {
        VStack(spacing: 20) {
            // Sticky Summary Card
            VStack(spacing: 12) {
                HStack {
                    Text("Products")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(cartManager.uniqueProductsCount) unique")
                        .fontWeight(.semibold)
                }
                
                HStack {
                    Text("Total Units")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(cartManager.totalUnits) units")
                        .fontWeight(.semibold)
                }
                
                Divider()
                
                HStack {
                    Text("Estimated Selling Price")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.primary)
                    Spacer()
                    Text(formatIndianCurrency(amount: cartManager.estimatedCost))
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.primary)
                }
            }
            .padding(16)
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 4)
            
            // Swipe to Order Control
            VStack(spacing: 8) {
                SwipeToOrderButton(isLocked: isSubmitting || cartManager.totalUnits == 0) {
                    Swift.Task {
                        await submitOrder()
                    }
                }
                .opacity((isSubmitting || cartManager.totalUnits == 0) ? 0.6 : 1.0)
                
                if cartManager.totalUnits == 0 {
                    Text("Select at least one unit to place a restock request.")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                        .transition(.opacity)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 20)
        .background(
            VisualEffectView(effect: UIBlurEffect(style: .systemChromeMaterial))
                .cornerRadius(24)
                .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: -4)
        )
        .padding(.horizontal, 16)
        .padding(.bottom, 12)
    }
    
    private var successOverlayView: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Success Checkmark Circle
                ZStack {
                    Circle()
                        .fill(Color.green.opacity(0.12))
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.green)
                }
                
                Text("Restock Request Sent")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.primary)
                
                // Order Summary Details
                VStack(spacing: 12) {
                    orderSummaryRow(label: "Order ID", value: submittedOrderId)
                    Divider()
                    orderSummaryRow(label: "Products Requested", value: "\(submittedProductCount)")
                    Divider()
                    orderSummaryRow(label: "Total Units", value: "\(submittedTotalUnits)")
                    Divider()
                    HStack {
                        Text("Status")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("Pending")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.orange)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color.orange.opacity(0.12))
                            .cornerRadius(8)
                    }
                }
                .padding(16)
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                Button(action: {
                    cartManager.clear()
                    onOrderSubmitted()
                    dismiss()
                }) {
                    Text("Done")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.blue)
                        .cornerRadius(12)
                }
                .padding(.horizontal, 20)
            }
            .padding(24)
            .background(Color(.systemBackground))
            .cornerRadius(24)
            .shadow(radius: 20)
            .padding(.horizontal, 40)
        }
    }
    
    private func orderSummaryRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.primary)
        }
    }
    
    private var processingHUD: some View {
        ZStack {
            Color.black.opacity(0.15)
                .ignoresSafeArea()
            
            ProgressView("Sending requests...")
                .padding(24)
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(radius: 10)
        }
    }
    
    // MARK: - Operations
    
    private func deleteItems(at offsets: IndexSet) {
        for index in offsets {
            let item = cartManager.items[index]
            cartManager.remove(productId: item.productId)
        }
        checkEmptyDismiss()
    }
    
    private func checkEmptyDismiss() {
        if cartManager.items.isEmpty {
            dismiss()
        }
    }
    
    private func generateOrderId() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        formatter.timeZone = TimeZone.current
        return "ORD-\(formatter.string(from: Date()))"
    }
    
    private func submitOrder() async {
        isSubmitting = true
        
        guard let currentUser = SessionManager.shared.currentUser else {
            errorAlertMessage = "No active user session found. Please log in again."
            showError = true
            isSubmitting = false
            return
        }
        
        guard let storeId = currentUser.storeId else {
            errorAlertMessage = "Your user account is not associated with any store ID."
            showError = true
            isSubmitting = false
            return
        }
        
        // Filter items with quantity > 0
        let validItems = cartManager.items.filter { $0.quantity > 0 }
        guard !validItems.isEmpty else {
            isSubmitting = false
            return
        }
        
        // Generate ONE order ID for the entire checkout
        let orderId = generateOrderId()
        
        let dbService = DatabaseService.shared
        var failedAny = false
        var lastErrorMessage = ""
        var insertedCount = 0
        var totalUnitsSubmitted = 0
        
        for item in validItems {
            print("--- ORDER INSERT [\(orderId)] ---")
            print("Product: \(item.product.productName) | Qty: \(item.quantity)")
            print("product_id: \(item.productId.uuidString)")
            print("-------------------------------")
            
            do {
                // VALIDATION: Verify products.id exists in Supabase
                struct ProductCheck: Decodable {
                    let id: UUID
                }
                
                let checkResponse = try await SupabaseManager.shared.client
                    .from("products")
                    .select("id")
                    .eq("id", value: item.productId.uuidString)
                    .execute()
                
                let records = try JSONDecoder.supabaseDecoder.decodeSupabase([ProductCheck].self, from: checkResponse.data)
                
                guard !records.isEmpty else {
                    throw NSError(domain: "RestockCart", code: 404, userInfo: [
                        NSLocalizedDescriptionKey: "Selected product '\(item.product.productName)' with ID \(item.productId) does not exist in the database products catalog."
                    ])
                }
                
                let newRequest = StockRequest(
                    id: UUID(),
                    orderId: orderId,
                    storeId: storeId,
                    productId: item.productId,
                    requestedBy: currentUser.id,
                    requestedQuantity: item.quantity,
                    priority: "Medium",
                    status: "Pending",
                    remarks: nil,
                    createdAt: Date(),
                    updatedAt: Date()
                )
                
                try await dbService.insert(into: "stock_requests", value: newRequest)
                insertedCount += 1
                totalUnitsSubmitted += item.quantity
            } catch {
                failedAny = true
                lastErrorMessage = error.localizedDescription
                print("Failed to insert stock request: \(error)")
            }
        }
        
        if failedAny {
            errorAlertMessage = lastErrorMessage.isEmpty ? "One or more restock requests could not be saved." : lastErrorMessage
            showError = true
        } else {
            // Store submitted order details for success overlay
            submittedOrderId = orderId
            submittedProductCount = insertedCount
            submittedTotalUnits = totalUnitsSubmitted
            
            // Trigger success haptic
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
            
            withAnimation {
                showSuccess = true
            }
            
            // Clear cart, hide floating cart, and refresh parent Stock screen immediately
            cartManager.clear()
            onOrderSubmitted()
        }
        
        isSubmitting = false
    }
    
    private func formatIndianCurrency(amount: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "en_IN")
        formatter.currencySymbol = "₹"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: amount as NSDecimalNumber) ?? "₹0"
    }
}

struct VisualEffectView: UIViewRepresentable {
    var effect: UIVisualEffect?
    func makeUIView(context: Context) -> UIVisualEffectView {
        UIVisualEffectView(effect: effect)
    }
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        uiView.effect = effect
    }
}
