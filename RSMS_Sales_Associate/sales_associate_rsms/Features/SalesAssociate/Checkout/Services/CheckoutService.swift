// CheckoutService.swift
// RSMS — Sales Associate Module

import Foundation

class CheckoutService {
    static let shared = CheckoutService()
    
    private init() {}
    
    func finalizeTransaction(cart: ActiveCart) {
        // 1. Append purchase events to Client Digital Twin
        // Mocking the write to MockData
        
        let purchaseEvent = ClientDigitalTwinEvent(
            id: UUID(),
            clientID: cart.clientId,
            date: Date(),
            type: .purchase,
            title: "Purchase Completed",
            description: "Purchased \(cart.items.count) item(s). Total: $\(cart.total)",
            location: "Boutique",
            performedBy: UUID(),
            linkedProductDigitalTwinID: cart.items.first?.product.id,
            metadata: ["total": "\(cart.total)"]
        )
        
        if let index = MockData.clients.firstIndex(where: { $0.id == cart.clientId }) {
            var events = MockData.clients[index].events ?? []
            events.append(purchaseEvent)
            MockData.clients[index].events = events
            
            // Generate Ownership Records / Warranty
            var ownedProducts = MockData.clients[index].ownedProducts ?? []
            for item in cart.items {
                let owned = OwnedProduct(
                    id: UUID(),
                    clientID: cart.clientId,
                    twinID: item.product.id,
                    productName: item.product.title,
                    serialNumber: nil,
                    purchaseDate: Date(),
                    purchaseStore: UUID(),
                    purchasePrice: item.product.price,
                    currentWarrantyStatus: .active
                )
                ownedProducts.append(owned)
            }
            MockData.clients[index].ownedProducts = ownedProducts
        }
        
        // 2. Append sold events to Product Digital Twin
        // (Currently mocked ProductDigitalTwin does not store events in this implementation)
        for _ in cart.items {
            // In a real implementation, we would call the backend to mark the specific SKU/serial as sold.
        }
        
        print("CheckoutService: Successfully logged purchase events for Client and Products.")
    }
}
