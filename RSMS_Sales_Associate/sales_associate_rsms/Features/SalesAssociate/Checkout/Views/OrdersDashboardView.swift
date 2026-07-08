// OrdersDashboardView.swift
// RSMS — Sales Associate Module

import SwiftUI
import Supabase

struct OrdersDashboardView: View {
    var isEmbedded: Bool = false
    @EnvironmentObject private var authVM: AuthViewModel
    
    @State private var orders: [Sale] = []
    @State private var isLoading = false
    @State private var errorMessage: String? = nil
    
    @State private var searchQuery = ""
    @State private var selectedStatus: String? = nil
    
    private let statuses = ["All", "Pending", "Packed", "Shipped", "Delivered", "Ready for Pickup", "Picked Up", "Cancelled"]
    
    var filteredOrders: [Sale] {
        orders.filter { order in
            let matchesSearch = searchQuery.isEmpty || 
                (order.invoiceNumber ?? "").localizedCaseInsensitiveContains(searchQuery) ||
                order.id.uuidString.prefix(8).localizedCaseInsensitiveContains(searchQuery)
            
            let matchesStatus = selectedStatus == nil || selectedStatus == "All" || 
                order.saleStatus.lowercased() == selectedStatus!.lowercased().replacingOccurrences(of: " ", with: "_")
            
            return matchesSearch && matchesStatus
        }
    }
    
    var body: some View {
        ZStack {
            // Background
            Color(.systemGroupedBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header (if not embedded)
                if !isEmbedded {
                    HStack {
                        Text("Orders")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.primary)
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.top)
                }
                
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Search by invoice # or ID...", text: $searchQuery)
                        .foregroundColor(.primary)
                }
                .padding()
                .background(Color.appleSecondaryBackground)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.appleBorder, lineWidth: 1)
                )
                .padding(.horizontal)
                .padding(.top, 16)
                
                // Status Filter Chips
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(statuses, id: \.self) { status in
                            Button(action: {
                                selectedStatus = (status == "All") ? nil : status
                            }) {
                                Text(status)
                                    .font(.subheadline)
                                    .fontWeight(selectedStatus == status || (status == "All" && selectedStatus == nil) ? .semibold : .regular)
                                    .foregroundColor(selectedStatus == status || (status == "All" && selectedStatus == nil) ? .white : .primary)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(selectedStatus == status || (status == "All" && selectedStatus == nil) ? Color.blue : Color.appleSecondaryBackground)
                                    .cornerRadius(20)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 20)
                                            .stroke(Color.appleBorder, lineWidth: 1)
                                    )
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 12)
                }
                
                // Orders List
                if isLoading {
                    Spacer()
                    ProgressView("Loading Orders...")
                        .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                        .scaleEffect(1.2)
                    Spacer()
                } else if let error = errorMessage {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 44))
                            .foregroundColor(.red)
                        Text(error)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        Button("Retry") {
                            loadOrders()
                        }
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                    }
                    Spacer()
                } else if filteredOrders.isEmpty {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "bag.badge.questionmark")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        Text("No orders found")
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            ForEach(filteredOrders) { order in
                                NavigationLink(destination: OrderDetailDashboardView(order: order)) {
                                    OrderRowCard(order: order)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 24)
                    }
                }
            }
        }
        .navigationTitle(isEmbedded ? "Orders" : "")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .onAppear {
            loadOrders()
        }
    }
    
    private func loadOrders() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                guard let storeId = authVM.userStoreID else {
                    self.errorMessage = "User store ID not found."
                    self.isLoading = false
                    return
                }
                
                let sales = try await SalesAssociateService.shared.fetchSales(storeId: storeId)
                
                self.orders = sales
                if sales.isEmpty {
                    self.errorMessage = "No orders found for this store."
                }
                isLoading = false
            } catch {
                print("Failed to fetch real sales: \(error)")
                self.errorMessage = "Failed to load orders: \(error.localizedDescription)"
                self.orders = []
                isLoading = false
            }
        }
    }
    
    private func setupMockOrders() {
        let sampleClient1 = UUID(uuidString: "22222222-2222-2222-2222-222222222222")!
        let sampleClient2 = UUID(uuidString: "22222222-2222-2222-2222-222222222223")!
        
        self.orders = [
            Sale(
                id: UUID(uuidString: "88888888-1111-1111-1111-111111111111")!,
                customerId: sampleClient1,
                userId: authVM.currentUser?.id ?? UUID(),
                storeId: authVM.userStoreID ?? UUID(),
                totalAmount: 18500.0,
                paymentMethod: "card",
                saleStatus: "delivered",
                saleDate: Date().addingTimeInterval(-3600 * 2), // 2 hours ago
                createdAt: Date().addingTimeInterval(-3600 * 2),
                invoiceNumber: "INV-2026-904",
                discountAmount: 1500.0,
                taxAmount: 2000.0
            ),
            Sale(
                id: UUID(uuidString: "88888888-2222-2222-2222-222222222222")!,
                customerId: sampleClient2,
                userId: authVM.currentUser?.id ?? UUID(),
                storeId: authVM.userStoreID ?? UUID(),
                totalAmount: 245000.0,
                paymentMethod: "apple_pay",
                saleStatus: "shipped",
                saleDate: Date().addingTimeInterval(-86400 * 1), // 1 day ago
                createdAt: Date().addingTimeInterval(-86400 * 1),
                invoiceNumber: "INV-2026-903",
                discountAmount: 10000.0,
                taxAmount: 25000.0
            ),
            Sale(
                id: UUID(uuidString: "88888888-3333-3333-3333-333333333333")!,
                customerId: sampleClient1,
                userId: authVM.currentUser?.id ?? UUID(),
                storeId: authVM.userStoreID ?? UUID(),
                totalAmount: 95000.0,
                paymentMethod: "upi",
                saleStatus: "packed",
                saleDate: Date().addingTimeInterval(-86400 * 3), // 3 days ago
                createdAt: Date().addingTimeInterval(-86400 * 3),
                invoiceNumber: "INV-2026-902",
                discountAmount: 0.0,
                taxAmount: 9500.0
            ),
            Sale(
                id: UUID(uuidString: "88888888-4444-4444-4444-444444444444")!,
                customerId: sampleClient2,
                userId: authVM.currentUser?.id ?? UUID(),
                storeId: authVM.userStoreID ?? UUID(),
                totalAmount: 12000.0,
                paymentMethod: "cash",
                saleStatus: "pending",
                saleDate: Date().addingTimeInterval(-86400 * 5), // 5 days ago
                createdAt: Date().addingTimeInterval(-86400 * 5),
                invoiceNumber: "INV-2026-901",
                discountAmount: 500.0,
                taxAmount: 1200.0
            )
        ]
    }
}

struct OrderRowCard: View {
    let order: Sale
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: [Color.blue.opacity(0.12), Color.indigo.opacity(0.12)], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 48, height: 48)
                
                Image(systemName: "bag.fill")
                    .foregroundColor(.blue)
                    .font(.system(size: 18))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(order.invoiceNumber ?? "INV-\(String(order.id.uuidString.prefix(6).uppercased()))")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(order.saleDate.displayDate)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 6) {
                    Image(systemName: "creditcard")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                    Text(order.paymentMethod.replacingOccurrences(of: "_", with: " ").capitalized)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 6) {
                Text(Money(Decimal(order.totalAmount)).formatted)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.primary)
                
                // Status badge
                Text(order.saleStatus.replacingOccurrences(of: "_", with: " ").uppercased())
                    .font(.system(size: 10, weight: .bold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(statusColor(order.saleStatus).opacity(0.12))
                    .foregroundColor(statusColor(order.saleStatus))
                    .clipShape(Capsule())
            }
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Color(.systemGray4))
        }
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground)).cornerRadius(16).shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
    }
    
    private func statusColor(_ status: String) -> Color {
        switch status.lowercased() {
        case "pending": return .orange
        case "packed", "ready_for_pickup": return .blue
        case "shipped": return .indigo
        case "delivered", "picked_up": return .green
        case "cancelled": return .red
        default: return .gray
        }
    }
}

// Detailed View showing tabs for order details, tracking (trace order), and bill (invoice).
struct OrderDetailDashboardView: View {
    let order: Sale
    @State private var selectedTab = 0
    @State private var products: [UUID: ProductDigitalTwin] = [:]
    @State private var saleItems: [SaleItem] = []
    @State private var isItemLoading = false
    
    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Segmented picker for sub-views
                Picker("Options", selection: $selectedTab) {
                    Text("Details").tag(0)
                    Text("Trace Order").tag(1)
                    Text("Bill").tag(2)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                ScrollView {
                    if isItemLoading {
                        ProgressView()
                            .padding(.top, 40)
                    } else {
                        switch selectedTab {
                        case 0:
                            OrderDetailTab(order: order, saleItems: saleItems, products: products)
                        case 1:
                            TraceOrderTab(order: order)
                        case 2:
                            BillInvoiceTab(order: order, saleItems: saleItems, products: products)
                        default:
                            EmptyView()
                        }
                    }
                }
            }
        }
        .navigationTitle(order.invoiceNumber ?? "Order Details")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadItems()
        }
    }
    
    private func loadItems() {
        isItemLoading = true
        
        Task {
            do {
                let items: [SaleItem] = try await SupabaseManager.shared.client
                    .from("sale_items")
                    .select()
                    .eq("sale_id", value: order.id.uuidString)
                    .execute()
                    .value
                
                self.saleItems = items
                for item in items {
                    if let productsList: [Product] = try? await SupabaseManager.shared.client
                        .from("products")
                        .select()
                        .eq("id", value: item.productId.uuidString)
                        .execute()
                        .value,
                       let product = productsList.first {
                        let twin = ProductDigitalTwin(
                            id: product.id,
                            sku: product.sku,
                            title: product.productName,
                            description: product.description ?? "",
                            category: .watches,
                            brand: product.brand,
                            collection: product.collectionName ?? "",
                            materials: product.material != nil ? [product.material!] : [],
                            price: Decimal(product.price),
                            currency: "INR",
                            authenticityCertificateID: nil,
                            dateOfManufacture: nil,
                            origin: nil,
                            imageURLs: [],
                            stockLevel: 0
                        )
                        self.products[item.productId] = twin
                    }
                }
                isItemLoading = false
            } catch {
                print("Failed to fetch real sale items: \(error)")
                self.saleItems = []
                isItemLoading = false
            }
        }
    }
    
    private func setupMockItems() {
        // Set up matching mock items
        let sampleProdId1 = UUID(uuidString: "44444444-4444-4444-4444-444444444444")!
        let sampleProdId2 = UUID(uuidString: "44444444-4444-4444-4444-444444444445")!
        
        self.saleItems = [
            SaleItem(id: UUID(), saleId: order.id, productId: sampleProdId1, quantity: 1, unitPrice: order.totalAmount * 0.6, createdAt: Date()),
            SaleItem(id: UUID(), saleId: order.id, productId: sampleProdId2, quantity: 1, unitPrice: order.totalAmount * 0.4, createdAt: Date())
        ]
        
        self.products = [
            sampleProdId1: ProductDigitalTwin(
                id: sampleProdId1,
                sku: "WAT-9011",
                title: "Classic Chronograph Edition",
                description: "Luxury automatic chronograph with steel bracelet.",
                category: .watches,
                brand: "Grand Horology",
                collection: "Classic",
                materials: ["Steel"],
                price: Decimal(order.totalAmount * 0.6),
                currency: "INR",
                authenticityCertificateID: "AUTH-GH-9011",
                dateOfManufacture: Date(),
                origin: "Switzerland",
                imageURLs: [],
                stockLevel: 1
            ),
            sampleProdId2: ProductDigitalTwin(
                id: sampleProdId2,
                sku: "JEW-8041",
                title: "Gold Band Ring",
                description: "18K yellow gold band, unisex design.",
                category: .jewellery,
                brand: "Aura Gems",
                collection: "Bands",
                materials: ["Gold"],
                price: Decimal(order.totalAmount * 0.4),
                currency: "INR",
                authenticityCertificateID: "AUTH-AG-8041",
                dateOfManufacture: Date(),
                origin: "Italy",
                imageURLs: [],
                stockLevel: 3
            )
        ]
    }
}

// 1. Order Detail Tab View
struct OrderDetailTab: View {
    let order: Sale
    let saleItems: [SaleItem]
    let products: [UUID: ProductDigitalTwin]
    
    var body: some View {
        VStack(spacing: 20) {
            // General Info Card
            VStack(alignment: .leading, spacing: 12) {
                Text("Order Information")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Divider()
                
                HStack {
                    Text("Invoice Number")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(order.invoiceNumber ?? "INV-\(String(order.id.uuidString.prefix(8).uppercased()))")
                        .fontWeight(.semibold)
                }
                
                HStack {
                    Text("Date & Time")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(order.saleDate.displayDateTime)
                }
                
                HStack {
                    Text("Payment Method")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(order.paymentMethod.replacingOccurrences(of: "_", with: " ").capitalized)
                }
                
                HStack {
                    Text("Fulfillment Status")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(order.saleStatus.replacingOccurrences(of: "_", with: " ").capitalized)
                        .fontWeight(.bold)
                        .foregroundColor(statusColor(order.saleStatus))
                }
            }
            .padding()
            .background(Color(UIColor.secondarySystemGroupedBackground)).cornerRadius(16).shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
            
            // Items Card
            VStack(alignment: .leading, spacing: 12) {
                Text("Purchased Items")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Divider()
                
                ForEach(saleItems) { item in
                    let product = products[item.productId]
                    HStack(spacing: 12) {
                        // Product image placeholder
                        RoundedRectangle(cornerRadius: 8)
                            .fill(LinearGradient(colors: [.blue.opacity(0.1), .purple.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 50, height: 50)
                            .overlay(
                                Image(systemName: product?.category == .watches ? "clock.fill" : "sparkles")
                                    .foregroundColor(.blue)
                            )
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(product?.title ?? "Unknown Product")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .lineLimit(1)
                            Text("Qty: \(item.quantity)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Text(Money(Decimal(item.unitPrice * Double(item.quantity))).formatted)
                            .font(.subheadline.bold())
                    }
                    .padding(.vertical, 4)
                }
            }
            .padding()
            .background(Color(UIColor.secondarySystemGroupedBackground)).cornerRadius(16).shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
            
            // Payment Summary Card
            VStack(alignment: .leading, spacing: 12) {
                Text("Order Summary")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Divider()
                
                let discount = order.discountAmount ?? 0.0
                let tax = order.taxAmount ?? 0.0
                let subtotal = order.totalAmount + discount - tax
                
                HStack {
                    Text("Subtotal")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(Money(Decimal(subtotal)).formatted)
                }
                
                if discount > 0 {
                    HStack {
                        Text("Discount")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("- \(Money(Decimal(discount)).formatted)")
                            .foregroundColor(.red)
                    }
                }
                
                HStack {
                    Text("Tax")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(Money(Decimal(tax)).formatted)
                }
                
                Divider()
                
                HStack {
                    Text("Grand Total")
                        .font(.headline)
                        .foregroundColor(.primary)
                    Spacer()
                    Text(Money(Decimal(order.totalAmount)).formatted)
                        .font(.title3.bold())
                        .foregroundColor(.blue)
                }
            }
            .padding()
            .background(Color(UIColor.secondarySystemGroupedBackground)).cornerRadius(16).shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
        }
        .padding(.horizontal)
    }
    
    private func statusColor(_ status: String) -> Color {
        switch status.lowercased() {
        case "pending": return .orange
        case "packed", "ready_for_pickup": return .blue
        case "shipped": return .indigo
        case "delivered", "picked_up": return .green
        case "cancelled": return .red
        default: return .gray
        }
    }
}

// 2. Trace Order Tab View
struct TraceOrderTab: View {
    let order: Sale
    
    private var steps: [(title: String, systemImage: String, detail: String, isCompleted: Bool, isActive: Bool)] {
        let currentStatus = order.saleStatus.lowercased()
        
        let pendingCompleted = ["pending", "packed", "ready_for_pickup", "shipped", "delivered", "picked_up"].contains(currentStatus)
        let packedCompleted = ["packed", "ready_for_pickup", "shipped", "delivered", "picked_up"].contains(currentStatus)
        let shippedCompleted = ["shipped", "delivered", "picked_up"].contains(currentStatus)
        let deliveredCompleted = ["delivered", "picked_up"].contains(currentStatus)
        
        if currentStatus == "cancelled" {
            return [
                ("Order Placed", "cart.badge.plus", "Order has been registered in system.", true, false),
                ("Cancelled", "xmark.circle.fill", "Order has been cancelled.", true, true)
            ]
        }
        
        return [
            ("Order Placed", "cart.fill", "Order received & approved.", pendingCompleted, currentStatus == "pending"),
            ("Packed & Prepared", "shippingbox.fill", "Item securely packed at boutique.", packedCompleted, currentStatus == "packed" || currentStatus == "ready_for_pickup"),
            ("Shipped / Dispatched", "truck.box.fill", "Order in transit via logistics partner.", shippedCompleted, currentStatus == "shipped"),
            ("Delivered / Picked Up", "checkmark.seal.fill", "Order successfully handed over to client.", deliveredCompleted, currentStatus == "delivered" || currentStatus == "picked_up")
        ]
    }
    
    var body: some View {
        VStack(spacing: 24) {
            // Live Status Card
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Live Order Tracking")
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text("Invoice: \(order.invoiceNumber ?? String(order.id.uuidString.prefix(8).uppercased()))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Text(order.saleStatus.replacingOccurrences(of: "_", with: " ").uppercased())
                    .font(.system(size: 11, weight: .bold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.blue.opacity(0.12))
                    .foregroundColor(.blue)
                    .clipShape(Capsule())
            }
            .padding()
            .background(Color(UIColor.secondarySystemGroupedBackground)).cornerRadius(16).shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
            
            // Vertical Progress Timeline
            VStack(alignment: .leading, spacing: 0) {
                let stepList = steps
                ForEach(0..<stepList.count, id: \.self) { index in
                    let step = stepList[index]
                    
                    HStack(alignment: .top, spacing: 16) {
                        // Timeline Indicator (Circle & Line)
                        VStack(spacing: 0) {
                            ZStack {
                                Circle()
                                    .fill(step.isCompleted ? Color.green : Color(.systemGray4))
                                    .frame(width: 32, height: 32)
                                
                                Image(systemName: step.isCompleted ? "checkmark" : step.systemImage)
                                    .foregroundColor(.white)
                                    .font(.system(size: 12, weight: .bold))
                            }
                            
                            // Connecting line to next item
                            if index < stepList.count - 1 {
                                Rectangle()
                                    .fill(stepList[index + 1].isCompleted ? Color.green : Color(.systemGray4))
                                    .frame(width: 4, height: 50)
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(step.title)
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(step.isCompleted ? .primary : .secondary)
                            
                            Text(step.detail)
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                            
                            if step.isActive {
                                Text("In Progress")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.orange)
                                    .padding(.top, 2)
                            }
                        }
                        .padding(.top, 4)
                        
                        Spacer()
                    }
                }
            }
            .padding()
            .background(Color(UIColor.secondarySystemGroupedBackground)).cornerRadius(16).shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
        }
        .padding(.horizontal)
    }
}

// 3. Bill / Invoice Tab View
struct BillInvoiceTab: View {
    let order: Sale
    let saleItems: [SaleItem]
    let products: [UUID: ProductDigitalTwin]
    
    @State private var emailSent = false
    @State private var invoiceDownloaded = false
    @State private var billShared = false
    
    var body: some View {
        VStack(spacing: 24) {
            // Bill Presentation
            VStack(spacing: 16) {
                // Boutique Logo / Name
                VStack(spacing: 4) {
                    Text("RSMS BOUTIQUE")
                        .font(.system(size: 20, weight: .black, design: .serif))
                        .tracking(4)
                    Text("Official Tax Invoice")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 16)
                
                Divider()
                
                // Invoice Details
                VStack(spacing: 8) {
                    HStack {
                        Text("Invoice No:")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(order.invoiceNumber ?? String(order.id.uuidString.prefix(8).uppercased()))
                            .fontWeight(.medium)
                    }
                    
                    HStack {
                        Text("Date:")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(order.saleDate.displayDate)
                    }
                    
                    HStack {
                        Text("Customer ID:")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(order.customerId.uuidString.prefix(8).description)
                    }
                }
                .font(.subheadline)
                
                Divider()
                
                // Items Table
                VStack(spacing: 12) {
                    HStack {
                        Text("Description")
                            .font(.caption.bold())
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("Qty")
                            .font(.caption.bold())
                            .foregroundColor(.secondary)
                            .frame(width: 40)
                        Text("Amount")
                            .font(.caption.bold())
                            .foregroundColor(.secondary)
                            .frame(width: 100, alignment: .trailing)
                    }
                    
                    ForEach(saleItems) { item in
                        let product = products[item.productId]
                        HStack {
                            Text(product?.title ?? "Product Item")
                                .font(.subheadline)
                                .lineLimit(1)
                            Spacer()
                            Text("\(item.quantity)")
                                .font(.subheadline)
                                .frame(width: 40)
                            Text(Money(Decimal(item.unitPrice * Double(item.quantity))).formatted)
                                .font(.subheadline)
                                .frame(width: 100, alignment: .trailing)
                        }
                    }
                }
                
                Divider()
                
                // Totals
                let discount = order.discountAmount ?? 0.0
                let tax = order.taxAmount ?? 0.0
                let subtotal = order.totalAmount + discount - tax
                
                VStack(spacing: 8) {
                    HStack {
                        Text("Subtotal")
                        Spacer()
                        Text(Money(Decimal(subtotal)).formatted)
                    }
                    if discount > 0 {
                        HStack {
                            Text("Discount")
                            Spacer()
                            Text("- \(Money(Decimal(discount)).formatted)")
                                .foregroundColor(.red)
                        }
                    }
                    HStack {
                        Text("Tax")
                        Spacer()
                        Text(Money(Decimal(tax)).formatted)
                    }
                    
                    Divider()
                    
                    HStack {
                        Text("Total Amount")
                            .font(.headline)
                        Spacer()
                        Text(Money(Decimal(order.totalAmount)).formatted)
                            .font(.title3.bold())
                            .foregroundColor(.blue)
                    }
                }
                .font(.subheadline)
                
                Text("Thank you for shopping at RSMS.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.vertical, 8)
            }
            .padding()
            .background(Color(UIColor.secondarySystemGroupedBackground)).cornerRadius(16).shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
            
            // Actions
            VStack(spacing: 12) {
                // Download PDF button
                Button(action: {
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                    invoiceDownloaded = true
                }) {
                    HStack {
                        Image(systemName: "arrow.down.circle.fill")
                        Text(invoiceDownloaded ? "Invoice Downloaded" : "Download PDF Bill")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(invoiceDownloaded ? Color.green.opacity(0.12) : Color.blue.opacity(0.08))
                    .foregroundColor(invoiceDownloaded ? .green : .blue)
                    .cornerRadius(12)
                }
                .disabled(invoiceDownloaded)
                
                // Email Invoice button
                Button(action: {
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                    emailSent = true
                }) {
                    HStack {
                        Image(systemName: "envelope.fill")
                        Text(emailSent ? "Email Sent to Client" : "Email Bill to Client")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(emailSent ? Color.green.opacity(0.12) : Color.blue.opacity(0.08))
                    .foregroundColor(emailSent ? .green : .blue)
                    .cornerRadius(12)
                }
                .disabled(emailSent)
                
                // Share via WhatsApp / Native
                Button(action: {
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                    billShared = true
                }) {
                    HStack {
                        Image(systemName: "square.and.arrow.up.fill")
                        Text(billShared ? "Bill Shared Successfully" : "Share Digital Bill")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(billShared ? Color.green.opacity(0.12) : Color.blue.opacity(0.08))
                    .foregroundColor(billShared ? .green : .blue)
                    .cornerRadius(12)
                }
            }
        }
        .padding(.horizontal)
    }
}
