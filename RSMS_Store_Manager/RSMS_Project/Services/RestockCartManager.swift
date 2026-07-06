//
//  RestockCartManager.swift
//  RSMS_Project
//
//  Created by Antigravity on 02/07/26.
//

import Foundation
import Combine

struct CartItem: Identifiable, Equatable, Hashable {
    var id: UUID { productId }
    let inventoryId: UUID
    let productId: UUID
    let product: StockListItem
    var quantity: Int
}

final class RestockCartManager: ObservableObject {
    static let shared = RestockCartManager()
    
    @Published var items: [CartItem] = []
    
    private init() {}
    
    var totalUnits: Int {
        items.reduce(0) { $0 + $1.quantity }
    }
    
    var uniqueProductsCount: Int {
        items.count
    }
    
    var estimatedCost: Decimal {
        items.reduce(0) { $0 + ($1.product.price * Decimal($1.quantity)) }
    }
    
    func add(product: StockListItem, quantity: Int) {
        if let index = items.firstIndex(where: { $0.productId == product.productId }) {
            items[index].quantity += quantity
        } else {
            let newItem = CartItem(
                inventoryId: product.id,
                productId: product.productId,
                product: product,
                quantity: quantity
            )
            items.append(newItem)
        }
    }
    
    func updateQuantity(for productId: UUID, to newQuantity: Int) {
        guard newQuantity >= 0 else { return }
        if let index = items.firstIndex(where: { $0.productId == productId }) {
            items[index].quantity = newQuantity
        }
    }
    
    func remove(productId: UUID) {
        items.removeAll(where: { $0.productId == productId })
    }
    
    func clear() {
        items = []
    }
}
