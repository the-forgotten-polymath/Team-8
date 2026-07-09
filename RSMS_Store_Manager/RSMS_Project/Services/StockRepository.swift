//
//  StockRepository.swift
//  RSMS_Project
//
//  Created by Antigravity on 02/07/26.
//

import Foundation
import Supabase

struct InventorySummary: Equatable {
    let totalValue: Decimal
    let totalProducts: Int
    let totalUnits: Int
    let pendingRequestsCount: Int
    let lowStockCount: Int
    let outOfStockCount: Int
}

struct StockListItem: Identifiable, Equatable, Hashable {
    let id: UUID
    let productId: UUID
    let productName: String
    let sku: String
    let brand: String?
    let price: Decimal
    let quantity: Int
    let reorderLevel: Int
    let categoryName: String?
    let imageURL: String?
    let description: String?
}

protocol StockRepositoryProtocol {
    func fetchInventorySummary(forStoreId storeId: UUID) async throws -> InventorySummary
    func fetchStockList(forStoreId storeId: UUID) async throws -> [StockListItem]
    func fetchStockDashboardData(forStoreId storeId: UUID) async throws -> (InventorySummary, [StockListItem])
}

final class StockRepository: StockRepositoryProtocol {
    private let client = SupabaseManager.shared.client
    
    func fetchInventorySummary(forStoreId storeId: UUID) async throws -> InventorySummary {
        debugLog("[DEBUG] fetchInventorySummary: storeId = \(storeId.uuidString)")
        
        // Fetch all inventory items for this store
        let inventoryResponse = try await client
            .from("inventory")
            .select()
            .eq("store_id", value: storeId.uuidString)
            .execute()
        
        let inventoryItems = try JSONDecoder.supabaseDecoder.decodeSupabase([InventoryItem].self, from: inventoryResponse.data)
        debugLog("[DEBUG] fetchInventorySummary: returned \(inventoryItems.count) inventory rows from Supabase")
        
        // Fetch pending stock requests count
        var pendingRequestsCount = 0
        do {
            // Fetch unique pending orders for the logged-in user
            var query = client
                .from("stock_requests")
                .select("order_id")
                .eq("store_id", value: storeId.uuidString)
                .eq("status", value: "Pending")
            
            if let currentUserId = SessionManager.shared.currentUser?.id {
                query = query.eq("requested_by", value: currentUserId.uuidString)
            }
            
            let pendingRequestsResponse = try await query.execute()
            
            struct StockRequestOrderIdOnly: Decodable { 
                let orderId: String? 
                enum CodingKeys: String, CodingKey {
                    case orderId = "order_id"
                }
            }
            let pendingRequests = try JSONDecoder.supabaseDecoder.decodeSupabase([StockRequestOrderIdOnly].self, from: pendingRequestsResponse.data)
            
            let uniqueOrderIds = Set(pendingRequests.compactMap { $0.orderId }.filter { !$0.isEmpty })
            pendingRequestsCount = uniqueOrderIds.count
        } catch {
            debugLog("[DEBUG] fetchInventorySummary: failed to fetch pending requests count: \(error)")
        }
        
        if inventoryItems.isEmpty {
            return InventorySummary(totalValue: 0, totalProducts: 0, totalUnits: 0, pendingRequestsCount: pendingRequestsCount, lowStockCount: 0, outOfStockCount: 0)
        }
        
        // Fetch all products to join and calculate values
        let productsResponse = try await client
            .from("products")
            .select()
            .execute()
        let products = try JSONDecoder.supabaseDecoder.decodeSupabase([Product].self, from: productsResponse.data)
        let productMap = Dictionary(uniqueKeysWithValues: products.map { ($0.id, $0) })
        debugLog("[DEBUG] fetchInventorySummary: loaded \(products.count) products to join")
        
        var totalValue: Decimal = 0
        var uniqueProductIds = Set<UUID>()
        var totalUnits = 0
        var lowStockCount = 0
        var outOfStockCount = 0
        var matchedProductCount = 0
        
        for item in inventoryItems {
            totalUnits += item.quantity
            uniqueProductIds.insert(item.productId)
            
            if let product = productMap[item.productId] {
                matchedProductCount += 1
                totalValue += product.price * Decimal(item.quantity)
            }
            
            if item.quantity > 0 && item.quantity <= item.reorderLevel {
                lowStockCount += 1
            }
            if item.quantity == 0 {
                outOfStockCount += 1
            }
        }
        
        let totalProducts = uniqueProductIds.count
        
        debugLog("[DEBUG] fetchInventorySummary STATS:")
        debugLog("- Logged-in store_id: \(storeId.uuidString)")
        debugLog("- Number of inventory rows fetched: \(inventoryItems.count)")
        debugLog("- Total Units calculated: \(totalUnits)")
        debugLog("- Total Products calculated: \(totalProducts)")
        debugLog("- Inventory Value calculated: \(totalValue)")
        debugLog("- Low Stock count: \(lowStockCount)")
        debugLog("- Out of Stock count: \(outOfStockCount)")
        
        return InventorySummary(
            totalValue: totalValue,
            totalProducts: totalProducts,
            totalUnits: totalUnits,
            pendingRequestsCount: pendingRequestsCount,
            lowStockCount: lowStockCount,
            outOfStockCount: outOfStockCount
        )
    }
    
    func fetchStockList(forStoreId storeId: UUID) async throws -> [StockListItem] {
        debugLog("[DEBUG] fetchStockList: storeId = \(storeId.uuidString)")
        
        // Fetch all inventory items for this store
        let inventoryResponse = try await client
            .from("inventory")
            .select()
            .eq("store_id", value: storeId.uuidString)
            .execute()
        let inventoryItems = try JSONDecoder.supabaseDecoder.decodeSupabase([InventoryItem].self, from: inventoryResponse.data)
        debugLog("[DEBUG] fetchStockList: returned \(inventoryItems.count) inventory rows from Supabase")
        
        if inventoryItems.isEmpty {
            return []
        }
        
        // Fetch all products
        let productsResponse = try await client
            .from("products")
            .select()
            .execute()
        let products = try JSONDecoder.supabaseDecoder.decodeSupabase([Product].self, from: productsResponse.data)
        let productMap = Dictionary(uniqueKeysWithValues: products.map { ($0.id, $0) })
        
        // Fetch all categories
        let categoriesResponse = try await client
            .from("categories")
            .select()
            .execute()
        let categories = try JSONDecoder.supabaseDecoder.decodeSupabase([Category].self, from: categoriesResponse.data)
        let categoryMap = Dictionary(uniqueKeysWithValues: categories.map { ($0.id, $0) })
        
        // Fetch all product images
        let imagesResponse = try await client
            .from("product_images")
            .select()
            .execute()
        let productImages = try JSONDecoder.supabaseDecoder.decodeSupabase([ProductImage].self, from: imagesResponse.data)
        debugLog("[DEBUG] fetchStockList: loaded \(productImages.count) images from product_images")
        if !productImages.isEmpty {
            debugLog("[DEBUG] fetchStockList: sample image URL = \(productImages[0].imageURL)")
        }
        
        var imageMap = [UUID: String]()
        for image in productImages {
            if image.isPrimary {
                imageMap[image.productId] = image.imageURL
            } else if imageMap[image.productId] == nil {
                imageMap[image.productId] = image.imageURL
            }
        }
        
        let items = inventoryItems.compactMap { item -> StockListItem? in
            guard let product = productMap[item.productId] else { return nil }
            let categoryName = product.categoryId.flatMap { categoryMap[$0]?.categoryName }
            let imgURL = imageMap[product.id]
            return StockListItem(
                id: item.id,
                productId: product.id,
                productName: product.productName,
                sku: product.sku,
                brand: product.brand,
                price: product.price,
                quantity: item.quantity,
                reorderLevel: item.reorderLevel,
                categoryName: categoryName,
                imageURL: imgURL,
                description: product.description
            )
        }
        
        debugLog("[DEBUG] fetchStockList: matched \(items.count) products out of \(inventoryItems.count) inventory items for list")
        return items
    }
    
    func fetchStockDashboardData(forStoreId storeId: UUID) async throws -> (InventorySummary, [StockListItem]) {
        debugLog("[DEBUG] fetchStockDashboardData: storeId = \(storeId.uuidString)")
        
        let inventoryResponse = try await client
            .from("inventory")
            .select()
            .eq("store_id", value: storeId.uuidString)
            .execute()
            
        let inventoryItems = try JSONDecoder.supabaseDecoder.decodeSupabase([InventoryItem].self, from: inventoryResponse.data)
        
        var pendingRequestsCount = 0
        do {
            var query = client
                .from("stock_requests")
                .select("order_id")
                .eq("store_id", value: storeId.uuidString)
                .eq("status", value: "Pending")
            
            if let currentUserId = SessionManager.shared.currentUser?.id {
                query = query.eq("requested_by", value: currentUserId.uuidString)
            }
            
            let pendingRequestsResponse = try await query.execute()
            
            struct StockRequestOrderIdOnly: Decodable { 
                let orderId: String? 
                enum CodingKeys: String, CodingKey {
                    case orderId = "order_id"
                }
            }
            let pendingRequests = try JSONDecoder.supabaseDecoder.decodeSupabase([StockRequestOrderIdOnly].self, from: pendingRequestsResponse.data)
            let uniqueOrderIds = Set(pendingRequests.compactMap { $0.orderId }.filter { !$0.isEmpty })
            pendingRequestsCount = uniqueOrderIds.count
        } catch {
            debugLog("[DEBUG] fetchStockDashboardData: failed to fetch pending requests count: \(error)")
        }
        
        if inventoryItems.isEmpty {
            return (InventorySummary(totalValue: 0, totalProducts: 0, totalUnits: 0, pendingRequestsCount: pendingRequestsCount, lowStockCount: 0, outOfStockCount: 0), [])
        }
        
        let productsResponse = try await client
            .from("products")
            .select()
            .execute()
        let products = try JSONDecoder.supabaseDecoder.decodeSupabase([Product].self, from: productsResponse.data)
        let productMap = Dictionary(uniqueKeysWithValues: products.map { ($0.id, $0) })
        
        let categoriesResponse = try await client
            .from("categories")
            .select()
            .execute()
        let categories = try JSONDecoder.supabaseDecoder.decodeSupabase([Category].self, from: categoriesResponse.data)
        let categoryMap = Dictionary(uniqueKeysWithValues: categories.map { ($0.id, $0) })
        
        let imagesResponse = try await client
            .from("product_images")
            .select()
            .execute()
        let productImages = try JSONDecoder.supabaseDecoder.decodeSupabase([ProductImage].self, from: imagesResponse.data)
        
        var imageMap = [UUID: String]()
        for image in productImages {
            if image.isPrimary {
                imageMap[image.productId] = image.imageURL
            } else if imageMap[image.productId] == nil {
                imageMap[image.productId] = image.imageURL
            }
        }
        
        var totalValue: Decimal = 0
        var uniqueProductIds = Set<UUID>()
        var totalUnits = 0
        var lowStockCount = 0
        var outOfStockCount = 0
        
        let items = inventoryItems.compactMap { item -> StockListItem? in
            guard let product = productMap[item.productId] else { return nil }
            
            totalUnits += item.quantity
            uniqueProductIds.insert(item.productId)
            totalValue += product.price * Decimal(item.quantity)
            
            if item.quantity > 0 && item.quantity <= item.reorderLevel {
                lowStockCount += 1
            }
            if item.quantity == 0 {
                outOfStockCount += 1
            }
            
            let categoryName = product.categoryId.flatMap { categoryMap[$0]?.categoryName }
            let imgURL = imageMap[product.id]
            return StockListItem(
                id: item.id,
                productId: product.id,
                productName: product.productName,
                sku: product.sku,
                brand: product.brand,
                price: product.price,
                quantity: item.quantity,
                reorderLevel: item.reorderLevel,
                categoryName: categoryName,
                imageURL: imgURL,
                description: product.description
            )
        }
        
        let summary = InventorySummary(
            totalValue: totalValue,
            totalProducts: uniqueProductIds.count,
            totalUnits: totalUnits,
            pendingRequestsCount: pendingRequestsCount,
            lowStockCount: lowStockCount,
            outOfStockCount: outOfStockCount
        )
        
        return (summary, items)
    }
}
