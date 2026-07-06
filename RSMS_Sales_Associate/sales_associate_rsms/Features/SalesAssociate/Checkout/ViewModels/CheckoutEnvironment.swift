// CheckoutEnvironment.swift
// RSMS — Sales Associate Module

import SwiftUI
import Combine

@MainActor
class CheckoutEnvironment: ObservableObject {
    @Published var activeCart: ActiveCart?
    @Published var likedProducts: [ProductDigitalTwin] = []
    @Published var showCartAnimation: Bool = false
    @Published var recentlyVisitedProducts: [ProductDigitalTwin] = []
    @Published var selectedTab: Int = 0
    
    @Published var requiresManagerApproval: Bool = false
    @Published var managerApproved: Bool = false
    @Published var isCheckoutFlowActive: Bool = false
    
    // For Sandbox integration
    @Published var paymentStatus: PaymentStatus = .pending
    
    func startCheckout(for client: ClientDigitalTwin) {
        // In a real flow, this would pull from a server or active session
        // Here we mock an active cart with some items
        
        let mockItem1 = CartItem(
            id: UUID(),
            product: MockData.products[0],
            quantity: 1
        )
        
        let mockItem2 = CartItem(
            id: UUID(),
            product: MockData.products[1],
            quantity: 2
        )
        
        self.activeCart = ActiveCart(
            clientId: client.id,
            items: [mockItem1, mockItem2]
        )
        self.paymentStatus = .pending
        self.managerApproved = false
    }
    
    func applyDiscount(_ percent: Decimal) {
        guard var cart = activeCart else { return }
        
        // Threshold logic (e.g., > 10% requires approval)
        if percent > 10.0 {
            requiresManagerApproval = true
            managerApproved = false
        } else {
            requiresManagerApproval = false
            managerApproved = true
        }
        
        cart.orderLevelDiscountPercent = percent
        self.activeCart = cart
    }
    
    func approveDiscount() {
        managerApproved = true
        requiresManagerApproval = false
    }
    
    func addTender(method: PaymentMethod, amount: Decimal) {
        guard var cart = activeCart else { return }
        
        let tender = AppliedTender(method: method, amount: amount)
        cart.appliedTenders.append(tender)
        self.activeCart = cart
        
        if cart.isFullyPaid {
            self.paymentStatus = .completed
        }
    }
    
    func finalizeTransaction() {
        // Appends events to Client and Product Passports
        guard let cart = activeCart else { return }
        
        CheckoutService.shared.finalizeTransaction(cart: cart)
    }
    
    func addProductToCart(_ product: ProductDigitalTwin) {
        if activeCart == nil {
            if let client = MockData.clients.first {
                self.activeCart = ActiveCart(clientId: client.id, items: [])
            } else {
                self.activeCart = ActiveCart(clientId: UUID(), items: [])
            }
        }
        
        guard var cart = activeCart else { return }
        
        if let idx = cart.items.firstIndex(where: { $0.product.id == product.id }) {
            cart.items[idx].quantity += 1
        } else {
            let item = CartItem(id: UUID(), product: product, quantity: 1)
            cart.items.append(item)
        }
        
        self.activeCart = cart
        
        // Trigger cart animation banner
        withAnimation {
            self.showCartAnimation = true
        }
        
        Task {
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            withAnimation {
                self.showCartAnimation = false
            }
        }
    }
    
    func toggleLike(product: ProductDigitalTwin) {
        if let idx = likedProducts.firstIndex(where: { $0.id == product.id }) {
            likedProducts.remove(at: idx)
        } else {
            likedProducts.append(product)
        }
    }
    
    func incrementQuantity(for item: CartItem) {
        guard var cart = activeCart else { return }
        if let idx = cart.items.firstIndex(where: { $0.id == item.id }) {
            cart.items[idx].quantity += 1
            self.activeCart = cart
        }
    }
    
    func decrementQuantity(for item: CartItem) {
        guard var cart = activeCart else { return }
        if let idx = cart.items.firstIndex(where: { $0.id == item.id }) {
            if cart.items[idx].quantity > 1 {
                cart.items[idx].quantity -= 1
            } else {
                cart.items.remove(at: idx)
            }
            self.activeCart = cart
        }
    }
    
    func instantCheckout(for product: ProductDigitalTwin) {
        let client = MockData.clients.first ?? ClientDigitalTwin(
            id: UUID(),
            customerID: nil,
            firstName: "Guest",
            lastName: "Customer",
            email: nil,
            phone: nil,
            dateOfBirth: nil,
            tier: .standard,
            lifetimeSpend: 0.0,
            preferredStore: nil,
            preferredAdvisor: nil,
            createdAt: Date(),
            updatedAt: Date()
        )
        let item = CartItem(id: UUID(), product: product, quantity: 1)
        self.activeCart = ActiveCart(clientId: client.id, items: [item])
        self.paymentStatus = .pending
        self.managerApproved = false
        self.isCheckoutFlowActive = true
    }
    
    func removeItem(_ item: CartItem) {
        guard var cart = activeCart else { return }
        if let idx = cart.items.firstIndex(where: { $0.id == item.id }) {
            cart.items.remove(at: idx)
            self.activeCart = cart
        }
    }
    
    func visitProduct(_ product: ProductDigitalTwin) {
        if !recentlyVisitedProducts.contains(where: { $0.id == product.id }) {
            recentlyVisitedProducts.insert(product, at: 0)
            if recentlyVisitedProducts.count > 5 {
                recentlyVisitedProducts.removeLast()
            }
        }
    }
}
