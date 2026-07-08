import sys

def main():
    repo_file = '/Users/abhistro/Desktop/Team-8/RSMS_Store_Manager/RSMS_Project/Services/StockRepository.swift'
    with open(repo_file, 'r') as f:
        repo_content = f.read()

    new_method = """    
    func fetchStockDashboardData(forStoreId storeId: UUID) async throws -> (InventorySummary, [StockListItem]) {
        debugLog("[DEBUG] fetchStockDashboardData: storeId = \\(storeId.uuidString)")
        
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
            debugLog("[DEBUG] fetchStockDashboardData: failed to fetch pending requests count: \\(error)")
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
"""
    if "let summary = InventorySummary(" not in repo_content:
        last_brace = repo_content.rfind('}')
        repo_content = repo_content[:last_brace] + new_method + repo_content[last_brace:]
        with open(repo_file, 'w') as f:
            f.write(repo_content)
        print("Method inserted.")
    else:
        print("Already inserted.")

if __name__ == "__main__":
    main()
