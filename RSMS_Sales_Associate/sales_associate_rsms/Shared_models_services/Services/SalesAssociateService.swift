// SalesAssociateService.swift
// RSMS — Sales Associate Module
//
// Central Supabase query service for the Sales Associate module.
// All raw database reads/writes go through here; ViewModels and
// Services call these methods rather than hitting Supabase directly.

import Foundation
import Supabase

// MARK: - Lightweight response types for DB queries

/// Slim product row joined with its primary image URL (from product_images)
/// and aggregated store inventory quantity.
struct ProductWithInventory: Decodable {
    let id: UUID
    let sku: String
    let productName: String
    let brand: String?
    let description: String?
    let shortDescription: String?
    let price: Double
    let material: String?
    let color: String?
    let collectionName: String?
    let serialNumber: String?
    let certificateNumber: String?
    let warrantyDuration: String?
    let status: String?
    let approvalStatus: String?
    let isNewArrival: Bool?
    let isBestSeller: Bool?
    let isLimitedEdition: Bool?
    let createdAt: Date
    // Joined from categories
    let categoryName: String?
    // Joined from product_images (primary)
    let primaryImageUrl: String?
    // Aggregated from inventory for the associate's store
    let storeQuantity: Int?

    enum CodingKeys: String, CodingKey {
        case id, sku, brand, description, material, color, status
        case productName        = "product_name"
        case shortDescription   = "short_description"
        case price
        case collectionName     = "collection_name"
        case serialNumber       = "serial_number"
        case certificateNumber  = "certificate_number"
        case warrantyDuration   = "warranty_duration"
        case approvalStatus     = "approval_status"
        case isNewArrival       = "is_new_arrival"
        case isBestSeller       = "is_best_seller"
        case isLimitedEdition   = "is_limited_edition"
        case createdAt          = "created_at"
        case categoryName       = "category_name"
        case primaryImageUrl    = "primary_image_url"
        case storeQuantity      = "store_quantity"
    }
}

/// Slim struct for inserting a new sale record
struct SaleInsert: Encodable {
    let customerId: UUID
    let userId: UUID
    let storeId: UUID
    let totalAmount: Double
    let paymentMethod: String
    let discountAmount: Double
    let taxAmount: Double
    let invoiceNumber: String

    enum CodingKeys: String, CodingKey {
        case customerId     = "customer_id"
        case userId         = "user_id"
        case storeId        = "store_id"
        case totalAmount    = "total_amount"
        case paymentMethod  = "payment_method"
        case discountAmount = "discount_amount"
        case taxAmount      = "tax_amount"
        case invoiceNumber  = "invoice_number"
    }
}

/// Slim struct for inserting a sale item record
struct SaleItemInsert: Encodable {
    let saleId: UUID
    let productId: UUID
    let quantity: Int
    let unitPrice: Double

    enum CodingKeys: String, CodingKey {
        case saleId     = "sale_id"
        case productId  = "product_id"
        case quantity
        case unitPrice  = "unit_price"
    }
}

// MARK: - SalesAssociateService

@MainActor
final class SalesAssociateService {

    static let shared = SalesAssociateService()
    private let client = SupabaseManager.shared.client
    private init() {}

    // ─────────────────────────────────────────────────────────────
    // MARK: – Products
    // ─────────────────────────────────────────────────────────────

    /// Fetches all approved products with their primary image and store
    /// inventory quantity for `storeId`. Uses separate queries and joins
    /// in Swift to stay compatible with Supabase REST API limitations.
    func fetchProducts(storeId: UUID?,
                       category: String? = nil,
                       searchQuery: String = "") async throws -> [ProductWithInventory] {

        guard let storeId = storeId else { return [] }

        // 1. Fetch inventory for this store
        let inventory: [InventoryItem] = (try? await client
            .from("inventory")
            .select()
            .eq("store_id", value: storeId.uuidString)
            .execute()
            .value) ?? []

        if inventory.isEmpty { return [] }

        var inventoryMap: [UUID: Int] = [:]
        for item in inventory {
            inventoryMap[item.productId, default: 0] += item.quantity
        }
        
        let productIds = Array(inventoryMap.keys).map { $0.uuidString }

        // 2. Fetch base products (approved only) that exist in the inventory
        var productsQuery = client
            .from("products")
            .select("id, sku, product_name, brand, description, short_description, price, material, color, collection_name, serial_number, certificate_number, warranty_duration, status, approval_status, is_new_arrival, is_best_seller, is_limited_edition, created_at, category_id")
            .eq("approval_status", value: "Approved")
            .in("id", values: productIds)

        if !searchQuery.isEmpty {
            productsQuery = productsQuery.or("product_name.ilike.%\(searchQuery)%,sku.ilike.%\(searchQuery)%,brand.ilike.%\(searchQuery)%")
        }

        let dbProducts: [Product] = try await productsQuery
            .order("product_name")
            .execute()
            .value

        guard !dbProducts.isEmpty else { return [] }

        // 3. Fetch primary images for these products
        let images: [ProductImage] = (try? await client
            .from("product_images")
            .select("id, product_id, image_url, is_primary")
            .eq("is_primary", value: "true")
            .in("product_id", values: productIds)
            .execute()
            .value) ?? []
        let imageMap = Dictionary(uniqueKeysWithValues: images.compactMap { img -> (UUID, String)? in
            return (img.productId, img.imageURL)
        })

        // 4. Fetch categories
        let categories: [Category] = (try? await client
            .from("categories")
            .select("id, category_name")
            .execute()
            .value) ?? []
        let categoryMap = Dictionary(uniqueKeysWithValues: categories.map { ($0.id, $0.categoryName) })

        // 5. Filter by category name if provided (more flexible matching)
        var filteredProducts = dbProducts
        if let category = category {
            filteredProducts = dbProducts.filter { product in
                guard let catId = product.categoryId else { return false }
                guard let catName = categoryMap[catId] else { return false }
                // Flexible matching: check if DB category name contains the filter keyword
                let dbCatLower = catName.lowercased()
                let filterLower = category.lowercased()
                
                // Handle common variations
                if filterLower.contains("watch") { return dbCatLower.contains("watch") }
                if filterLower.contains("jewel") { return dbCatLower.contains("jewel") }
                if filterLower.contains("leather") { return dbCatLower.contains("leather") }
                if filterLower.contains("access") { return dbCatLower.contains("access") }
                if filterLower.contains("fragrance") { return dbCatLower.contains("fragrance") }
                if filterLower.contains("apparel") { return dbCatLower.contains("apparel") }
                if filterLower.contains("home") { return dbCatLower.contains("home") }
                if filterLower.contains("eye") { return dbCatLower.contains("eye") }
                
                return dbCatLower == filterLower
            }
        }

        // 6. Map to ProductWithInventory
        return filteredProducts.map { product in
            let catName = product.categoryId.flatMap { categoryMap[$0] }
            return ProductWithInventory(
                id: product.id,
                sku: product.sku,
                productName: product.productName,
                brand: product.brand,
                description: product.description,
                shortDescription: product.shortDescription,
                price: product.price,
                material: product.material,
                color: product.color,
                collectionName: product.collectionName,
                serialNumber: product.serialNumber,
                certificateNumber: product.certificateNumber,
                warrantyDuration: product.warrantyDuration,
                status: product.status,
                approvalStatus: product.approvalStatus,
                isNewArrival: product.isNewArrival,
                isBestSeller: product.isBestSeller,
                isLimitedEdition: product.isLimitedEdition,
                createdAt: product.createdAt,
                categoryName: catName,
                primaryImageUrl: imageMap[product.id],
                storeQuantity: inventoryMap[product.id] ?? 0
            )
        }
    }

    // ─────────────────────────────────────────────────────────────
    // MARK: – Customers
    // ─────────────────────────────────────────────────────────────

    /// Fetches customers assigned to this sales associate.
    func fetchCustomers(associateId: UUID, searchQuery: String = "") async throws -> [Customer] {
        var query = client
            .from("customers")
            .select()
            .eq("assigned_sales_associate_id", value: associateId.uuidString)
            .eq("is_active", value: "true")

        if !searchQuery.isEmpty {
            query = query.or("name.ilike.%\(searchQuery)%,email.ilike.%\(searchQuery)%,phone.ilike.%\(searchQuery)%")
        }

        return try await query
            .order("name")
            .execute()
            .value
    }

    /// Fetches a single customer by their ID.
    func fetchCustomer(id: UUID) async throws -> Customer {
        try await client
            .from("customers")
            .select()
            .eq("id", value: id.uuidString)
            .single()
            .execute()
            .value
    }

    // ─────────────────────────────────────────────────────────────
    // MARK: – Sales / Dashboard Metrics
    // ─────────────────────────────────────────────────────────────

    /// Total revenue from sales made by this user today.
    func fetchTodaySalesTotal(userId: UUID) async throws -> Double {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        let sales: [Sale] = try await client
            .from("sales")
            .select()
            .eq("user_id", value: userId.uuidString)
            .gte("sale_date", value: ISO8601DateFormatter().string(from: startOfDay))
            .lt("sale_date", value: ISO8601DateFormatter().string(from: endOfDay))
            .execute()
            .value

        return sales.reduce(0.0) { $0 + $1.totalAmount }
    }

    /// Monthly revenue target for the store (prorated to a daily amount).
    func fetchDailyTarget(storeId: UUID) async throws -> Double {
        let now = Date()
        let calendar = Calendar.current
        // Format first day of this month as "YYYY-MM-DD"
        var comps = calendar.dateComponents([.year, .month], from: now)
        comps.day = 1
        guard let firstOfMonth = calendar.date(from: comps) else { return 10000 }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let monthString = formatter.string(from: firstOfMonth)

        let targets: [StoreTarget] = (try? await client
            .from("store_targets")
            .select()
            .eq("store_id", value: storeId.uuidString)
            .eq("target_month", value: monthString)
            .limit(1)
            .execute()
            .value) ?? []

        guard let target = targets.first else { return 10000 }

        // Prorate monthly target to a daily target
        let daysInMonth = Double(calendar.range(of: .day, in: .month, for: now)?.count ?? 30)
        return target.revenueTarget / daysInMonth
    }

    /// Counts pending and completed tasks assigned to this user.
    func fetchTaskCounts(userId: UUID) async throws -> (pending: Int, completed: Int) {
        let tasks: [AppTask] = (try? await client
            .from("tasks")
            .select()
            .eq("assigned_to", value: userId.uuidString)
            .execute()
            .value) ?? []

        let pending   = tasks.filter { $0.status.lowercased() == "pending" }.count
        let completed = tasks.filter { $0.status.lowercased() == "completed" }.count
        return (pending, completed)
    }

    /// Fetches tasks mapped to Appointments
    func fetchAppointments(userId: UUID) async throws -> [Appointment] {
        let tasks: [AppTask] = (try? await client
            .from("tasks")
            .select()
            .eq("assigned_to", value: userId.uuidString)
            .eq("task_type", value: "Appointment")
            .execute()
            .value) ?? []
            
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
            
        return tasks.compactMap { task in
            let aptStatus: AppointmentStatus
            switch task.status.lowercased() {
            case "completed": aptStatus = .completed
            case "pending": aptStatus = .scheduled
            case "cancelled": aptStatus = .cancelled
            default: aptStatus = .scheduled
            }
            
            var date = task.createdAt
            if let dateString = task.dueDate, let parsed = dateFormatter.date(from: dateString) {
                date = parsed
            }
            
            // Schema lacks a client_id on tasks, so we fallback to a mock client for now.
            // Ideally, a task_customer_link table or a customer_id column should be added to tasks.
            let mockClientId = UUID(uuidString: "11111111-1111-1111-1111-111111111111") ?? UUID()
            
            return Appointment(
                id: task.id,
                clientId: mockClientId,
                associateId: task.assignedTo ?? userId,
                date: date,
                type: .inStore,
                notes: task.description,
                status: aptStatus,
                clientName: task.title
            )
        }
    }

    /// Last 7 days of daily sales totals for a store (used for chart history).
    func fetchDailySalesTotals(storeId: UUID, days: Int = 7) async throws -> [(date: Date, total: Double)] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        guard let startDate = calendar.date(byAdding: .day, value: -days, to: today) else { return [] }

        let sales: [Sale] = (try? await client
            .from("sales")
            .select()
            .eq("store_id", value: storeId.uuidString)
            .gte("sale_date", value: ISO8601DateFormatter().string(from: startDate))
            .execute()
            .value) ?? []

        // Group sales by day
        var dailyTotals: [Date: Double] = [:]
        for sale in sales {
            let day = calendar.startOfDay(for: sale.saleDate)
            dailyTotals[day, default: 0] += sale.totalAmount
        }

        // Fill in zero values for days with no sales
        var result: [(date: Date, total: Double)] = []
        for dayOffset in 0..<days {
            if let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) {
                result.append((date: date, total: dailyTotals[date] ?? 0))
            }
        }
        return result.sorted { $0.date < $1.date }
    }

    /// Computes store-level metrics: average order value, total sales for store.
    func fetchStoreMetrics(storeId: UUID) async throws -> (avgOrderValue: Double, totalSales: Double, salesCount: Int) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        guard let weekAgo = calendar.date(byAdding: .day, value: -7, to: today) else {
            return (0, 0, 0)
        }

        let sales: [Sale] = (try? await client
            .from("sales")
            .select()
            .eq("store_id", value: storeId.uuidString)
            .gte("sale_date", value: ISO8601DateFormatter().string(from: weekAgo))
            .execute()
            .value) ?? []

        let total = sales.reduce(0.0) { $0 + $1.totalAmount }
        let avg   = sales.isEmpty ? 0 : total / Double(sales.count)
        return (avgOrderValue: avg, totalSales: total, salesCount: sales.count)
    }

    // ─────────────────────────────────────────────────────────────
    // MARK: – Opportunities (derived from customers)
    // ─────────────────────────────────────────────────────────────

    /// Derives active opportunities from customers assigned to this associate.
    /// Generates Birthday, Anniversary, and Wishlist opportunities.
    func fetchOpportunities(associateId: UUID, storeId: UUID?) async throws -> [Opportunity] {
        let customers = try await fetchCustomers(associateId: associateId)
        let calendar  = Calendar.current
        let today     = Date()
        var opportunities: [Opportunity] = []

        for customer in customers {
            let nameParts = customer.name.split(separator: " ", maxSplits: 1)
            let clientName = customer.name

            // Birthday opportunity: if birthday is within next 14 days
            if let dob = customer.dateOfBirth {
                var birthdayComponents = calendar.dateComponents([.month, .day], from: dob)
                birthdayComponents.year = calendar.component(.year, from: today)
                if let birthdayThisYear = calendar.date(from: birthdayComponents) {
                    let daysUntil = calendar.dateComponents([.day], from: today, to: birthdayThisYear).day ?? 0
                    if daysUntil >= 0 && daysUntil <= 14 {
                        opportunities.append(Opportunity(
                            id: UUID(),
                            clientID: customer.id,
                            associateID: associateId,
                            type: .birthday,
                            title: "Upcoming Birthday",
                            description: "\(clientName)'s birthday is in \(daysUntil) day(s). Consider reaching out with a personalized offer.",
                            dateGenerated: today,
                            status: .new,
                            clientName: clientName
                        ))
                    }
                }
            }

            // Anniversary opportunity: if anniversary is within next 14 days
            if let anniv = customer.anniversaryDate {
                var anniversaryComponents = calendar.dateComponents([.month, .day], from: anniv)
                anniversaryComponents.year = calendar.component(.year, from: today)
                if let anniversaryThisYear = calendar.date(from: anniversaryComponents) {
                    let daysUntil = calendar.dateComponents([.day], from: today, to: anniversaryThisYear).day ?? 0
                    if daysUntil >= 0 && daysUntil <= 14 {
                        opportunities.append(Opportunity(
                            id: UUID(),
                            clientID: customer.id,
                            associateID: associateId,
                            type: .anniversary,
                            title: "Upcoming Anniversary",
                            description: "\(clientName)'s anniversary is in \(daysUntil) day(s). A great time to suggest a gift.",
                            dateGenerated: today,
                            status: .new,
                            clientName: clientName
                        ))
                    }
                }
            }

            // Wishlist opportunity: if customer has a wishlist entry and has been inactive
            if let wishlist = customer.wishlist, !wishlist.isEmpty {
                if let lastVisit = customer.lastVisitDate {
                    let daysSinceVisit = calendar.dateComponents([.day], from: lastVisit, to: today).day ?? 0
                    if daysSinceVisit > 30 {
                        opportunities.append(Opportunity(
                            id: UUID(),
                            clientID: customer.id,
                            associateID: associateId,
                            type: .wishlistInStock,
                            title: "Wishlist Follow-up",
                            description: "\(clientName) has wishlist items and hasn't visited in \(daysSinceVisit) days.",
                            dateGenerated: today,
                            status: .new,
                            clientName: clientName
                        ))
                    }
                }
            }
        }

        return opportunities
    }

    // ─────────────────────────────────────────────────────────────
    // MARK: – Inventory Availability
    // ─────────────────────────────────────────────────────────────

    /// Fetches inventory levels for a product across all stores.
    func fetchInventoryForProduct(productId: UUID) async throws -> [(storeName: String, quantity: Int)] {
        let inventory: [InventoryItem] = try await client
            .from("inventory")
            .select("product_id, quantity, store_id, location_type")
            .eq("product_id", value: productId.uuidString)
            .execute()
            .value

        guard !inventory.isEmpty else { return [] }

        // Fetch store names
        let storeIds = inventory.compactMap { $0.storeId?.uuidString }
        let stores: [AdminStore] = (storeIds.isEmpty ? [] : (try? await client
            .from("stores")
            .select("id, name")
            .in("id", values: storeIds)
            .execute()
            .value) ?? [])
        let storeMap = Dictionary(uniqueKeysWithValues: stores.map { ($0.id, $0.name) })

        return inventory.map { item in
            let name = item.storeId.flatMap { storeMap[$0] } ?? item.locationType ?? "Unknown"
            return (storeName: name, quantity: item.quantity)
        }.sorted { $0.quantity > $1.quantity }
    }

    // ─────────────────────────────────────────────────────────────
    // MARK: – Checkout / Sale Insert
    // ─────────────────────────────────────────────────────────────

    /// Inserts a completed sale and its line items into Supabase.
    /// Returns the created Sale record.
    @discardableResult
    func insertSale(
        customerId: UUID,
        userId: UUID,
        storeId: UUID,
        items: [(productId: UUID, quantity: Int, unitPrice: Double)],
        paymentMethod: String,
        discountAmount: Double = 0,
        taxAmount: Double = 0
    ) async throws -> Sale {

        let total = items.reduce(0.0) { $0 + ($1.unitPrice * Double($1.quantity)) }
        let invoiceNumber = "INV-\(Int(Date().timeIntervalSince1970))"

        let saleInsert = SaleInsert(
            customerId: customerId,
            userId: userId,
            storeId: storeId,
            totalAmount: total - discountAmount + taxAmount,
            paymentMethod: paymentMethod,
            discountAmount: discountAmount,
            taxAmount: taxAmount,
            invoiceNumber: invoiceNumber
        )

        let created: Sale = try await client
            .from("sales")
            .insert(saleInsert, returning: .representation)
            .single()
            .execute()
            .value

        // Insert sale items
        let saleItems = items.map { item in
            SaleItemInsert(
                saleId: created.id,
                productId: item.productId,
                quantity: item.quantity,
                unitPrice: item.unitPrice
            )
        }

        _ = try? await client
            .from("sale_items")
            .insert(saleItems)
            .execute()

        return created
    }
    
    /// Fetches all sales for a given store
    func fetchSales(storeId: UUID) async throws -> [Sale] {
        let sales: [Sale] = try await client
            .from("sales")
            .select()
            .eq("store_id", value: storeId.uuidString)
            .order("created_at", ascending: false)
            .execute()
            .value
        
        return sales
    }
}

// MARK: - AppTask (lightweight decode of tasks table)
// Named AppTask to avoid conflict with Swift's Task type.
struct AppTask: Decodable, Identifiable {
    let id: UUID
    let title: String
    let description: String?
    let status: String
    let assignedTo: UUID?
    let dueDate: String?
    let taskType: String?
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id, title, description, status
        case assignedTo = "assigned_to"
        case dueDate    = "due_date"
        case taskType   = "task_type"
        case createdAt  = "created_at"
    }
}
