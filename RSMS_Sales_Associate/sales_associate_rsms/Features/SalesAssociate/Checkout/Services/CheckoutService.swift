// CheckoutService.swift
// RSMS — Sales Associate Module

import Foundation

@MainActor
class CheckoutService {
    static let shared = CheckoutService()
    
    private init() {}
    
    func finalizeTransaction(cart: ActiveCart, userId: UUID? = nil, storeId: UUID? = nil) async {
        guard let userId = userId, let storeId = storeId else {
            print("[CheckoutService] Error: userId and storeId required for checkout")
            return
        }
        
        do {
            // 1. Insert sale and sale_items into Supabase
            let items = cart.items.map { ($0.product.id, $0.quantity, Double(truncating: $0.product.price as NSNumber)) }
            let discountPercent = cart.orderLevelDiscountPercent ?? 0
            let cartTotal = cart.total ?? 0
            let discountAmount = discountPercent == 0 ? 0 : Double(truncating: (cartTotal * discountPercent / 100) as NSNumber)
            
            _ = try await SalesAssociateService.shared.insertSale(
                customerId: cart.clientId,
                userId: userId,
                storeId: storeId,
                items: items,
                paymentMethod: cart.appliedTenders.first?.method.rawValue ?? "Cash",
                discountAmount: discountAmount,
                taxAmount: 0
            )
            
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
