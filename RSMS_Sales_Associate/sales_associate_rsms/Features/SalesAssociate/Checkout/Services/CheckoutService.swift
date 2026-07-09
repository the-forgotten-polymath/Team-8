// CheckoutService.swift
// RSMS — Sales Associate Module

import Foundation

@MainActor
class CheckoutService {
    static let shared = CheckoutService()
    
    private init() {}
    
    func finalizeTransaction(cart: ActiveCart, userId: UUID? = nil) async {
        guard let userId = userId else {
            print("[CheckoutService] Error: userId required for checkout")
            return
        }
        
        print("[CheckoutService] Finalizing transaction for user: \(userId), client: \(cart.clientId)")
        
        do {
            // 1. Insert sale and sale_items into Supabase
            let items = cart.items.map { ($0.product.id, $0.quantity, Double(truncating: $0.product.price as NSNumber)) }
            let discountPercent = cart.orderLevelDiscountPercent ?? 0
            let cartTotal = cart.total ?? 0
            let discountAmount = discountPercent == 0 ? 0 : Double(truncating: (cartTotal * discountPercent / 100) as NSNumber)
            
            print("[CheckoutService] Invoking insertSale on SalesAssociateService. Items: \(items)")
            
            let sale = try await SalesAssociateService.shared.insertSale(
                customerId: cart.clientId,
                userId: userId,
                items: items,
                paymentMethod: cart.appliedTenders.first?.method.rawValue ?? "Cash",
                discountAmount: discountAmount,
                taxAmount: 0
            )
            
            print("[CheckoutService] Sales record successfully created in DB: \(sale)")
            
            // 2. Add purchase event to client digital twin
            let purchaseEvent = ClientDigitalTwinEvent(
                id: UUID(),
                clientID: cart.clientId,
                date: Date(),
                type: .purchase,
                title: "Purchase Completed",
                description: "Purchased \(cart.items.count) item(s). Total: \(AppConstants.App.currencySymbol)\(cart.total)",
                location: nil,
                performedBy: userId,
                linkedProductDigitalTwinID: cart.items.first?.product.id,
                metadata: ["total": "\(cart.total)", "item_count": "\(cart.items.count)"]
            )
            
            try await ClientDigitalTwinService.shared.addEvent(purchaseEvent)
            
            print("[CheckoutService] Successfully finalized transaction and logged to Supabase")
            
        } catch {
            print("[CheckoutService] Error finalizing transaction: \(error.localizedDescription)")
        }
    }
}
