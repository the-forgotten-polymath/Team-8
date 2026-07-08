//
//  OrderDetailView.swift
//  RSMS_Project
//
//  Created by Antigravity on 03/07/26.
//

import SwiftUI
import Supabase
import Combine

struct InventoryInsert: Encodable {
    let id: UUID
    let productId: UUID
    let storeId: UUID
    let quantity: Int
    let reorderLevel: Int
    let locationType: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case productId = "product_id"
        case storeId = "store_id"
        case quantity
        case reorderLevel = "reorder_level"
        case locationType = "location_type"
    }
}

// MARK: - View Model

@MainActor
final class OrderDetailViewModel: ObservableObject {
    @Published var items: [OrderProductItem] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    struct OrderProductItem: Identifiable {
        let id: UUID
        let productName: String
        let sku: String
        let brand: String?
        let price: Decimal
        let requestedQuantity: Int
        let status: String
        let imageURL: String?
    }
    
    func loadOrderDetails(orderId: String, isSilent: Bool = false) async {
        if !isSilent {
            isLoading = true
            errorMessage = nil
        }
        
        do {
            // Fetch all stock_requests for this order_id
            let requestResponse = try await SupabaseManager.shared.client
                .from("stock_requests")
                .select()
                .eq("order_id", value: orderId)
                .execute()
            
            let requests = try JSONDecoder.supabaseDecoder.decodeSupabase([StockRequest].self, from: requestResponse.data)
            
            guard !requests.isEmpty else {
                items = []
                if !isSilent {
                    isLoading = false
                }
                return
            }
            
            // Fetch all products to join
            let productIds = requests.map { $0.productId.uuidString }
            let productsResponse = try await SupabaseManager.shared.client
                .from("products")
                .select()
                .in("id", values: productIds)
                .execute()
            
            let products = try JSONDecoder.supabaseDecoder.decodeSupabase([Product].self, from: productsResponse.data)
            let productMap = Dictionary(uniqueKeysWithValues: products.map { ($0.id, $0) })
            
            // Fetch product images
            let imagesResponse = try await SupabaseManager.shared.client
                .from("product_images")
                .select()
                .in("product_id", values: productIds)
                .eq("is_primary", value: true)
                .execute()
            
            let images = try JSONDecoder.supabaseDecoder.decodeSupabase([ProductImage].self, from: imagesResponse.data)
            let imageMap = Dictionary(uniqueKeysWithValues: images.map { ($0.productId, $0.imageURL) })
            
            // Build display items
            var result: [OrderProductItem] = []
            for request in requests {
                let product = productMap[request.productId]
                result.append(OrderProductItem(
                    id: request.id,
                    productName: product?.productName ?? "Unknown Product",
                    sku: product?.sku ?? "N/A",
                    brand: product?.brand,
                    price: product?.price ?? 0,
                    requestedQuantity: request.requestedQuantity,
                    status: request.status,
                    imageURL: imageMap[request.productId]
                ))
            }
            
            withAnimation(.easeInOut(duration: 0.35)) {
                items = result
            }
        } catch {
            if !isSilent {
                errorMessage = error.localizedDescription
            }
            print("Failed to load order details: \(error)")
        }
        
        if !isSilent {
            isLoading = false
        }
    }
    
    func updateOrderStatus(orderId: String, newStatus: String) async {
        do {
            // 1. Fetch current status of requests with this order_id first to prevent duplicate updates
            let checkResponse = try await SupabaseManager.shared.client
                .from("stock_requests")
                .select("status")
                .eq("order_id", value: orderId)
                .limit(1)
                .execute()
            
            struct StatusCheck: Decodable {
                let status: String
            }
            
            let statusChecks = try JSONDecoder.supabaseDecoder.decodeSupabase([StatusCheck].self, from: checkResponse.data)
            let currentStatus = statusChecks.first?.status ?? ""
            
            // If the status is already Delivered, skip to avoid duplicate stock addition
            if currentStatus.lowercased() == "delivered" {
                print("Order \(orderId) is already marked as Delivered. Skipping inventory update.")
                await loadOrderDetails(orderId: orderId, isSilent: true)
                return
            }
            
            // 2. Perform the update to the new status
            try await SupabaseManager.shared.client
                .from("stock_requests")
                .update(["status": newStatus])
                .eq("order_id", value: orderId)
                .execute()
            
            // 3. If transitioning to Delivered, perform the inventory update!
            if newStatus.lowercased() == "delivered" {
                let requestsResponse = try await SupabaseManager.shared.client
                    .from("stock_requests")
                    .select()
                    .eq("order_id", value: orderId)
                    .execute()
                let requests = try JSONDecoder.supabaseDecoder.decodeSupabase([StockRequest].self, from: requestsResponse.data)
                
                for request in requests {
                    let productId = request.productId
                    let storeId = request.storeId
                    let requestedQuantity = request.requestedQuantity
                    
                    // Fetch existing inventory row
                    let invResponse = try await SupabaseManager.shared.client
                        .from("inventory")
                        .select()
                        .eq("store_id", value: storeId.uuidString)
                        .eq("product_id", value: productId.uuidString)
                        .execute()
                    
                    let inventoryItems = try JSONDecoder.supabaseDecoder.decodeSupabase([InventoryItem].self, from: invResponse.data)
                    
                    if let existingItem = inventoryItems.first {
                        let updatedQuantity = existingItem.quantity + requestedQuantity
                        try await SupabaseManager.shared.client
                            .from("inventory")
                            .update(["quantity": updatedQuantity])
                            .eq("id", value: existingItem.id.uuidString)
                            .execute()
                        print("Updated existing inventory item \(existingItem.id) for product \(productId): \(existingItem.quantity) -> \(updatedQuantity)")
                    } else {
                        // Create a new inventory item mapping if it does not exist
                        let newInventoryItem = InventoryInsert(
                            id: UUID(),
                            productId: productId,
                            storeId: storeId,
                            quantity: requestedQuantity,
                            reorderLevel: 5,
                            locationType: "Store"
                        )
                        try await SupabaseManager.shared.client
                            .from("inventory")
                            .insert(newInventoryItem)
                            .execute()
                        print("Created new inventory item for product \(productId) with quantity \(requestedQuantity)")
                    }
                }
                
                // Broadcast that inventory was updated
                NotificationCenter.default.post(name: NSNotification.Name("InventoryDidUpdate"), object: nil)
            }
            
            await loadOrderDetails(orderId: orderId, isSilent: true)
        } catch {
            print("Failed to update order status and update inventory: \(error)")
        }
    }
}

// MARK: - Order Detail View

struct OrderDetailView: View {
    let orderId: String
    @StateObject private var viewModel = OrderDetailViewModel()
    
    private var totalUnits: Int {
        viewModel.items.reduce(0) { $0 + $1.requestedQuantity }
    }
    
    private var totalSellingPrice: Decimal {
        viewModel.items.reduce(0) { $0 + ($1.price * Decimal($1.requestedQuantity)) }
    }
    
    private var orderStatus: String {
        viewModel.items.first?.status ?? "Pending"
    }
    
    private var statusColor: Color {
        switch orderStatus.lowercased() {
        case "fulfilled": return .green
        case "rejected": return .red
        case "pending": return .orange
        default: return .secondary
        }
    }
    
    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()
            
            if viewModel.isLoading {
                VStack(spacing: 16) {
                    ProgressView()
                    Text("Loading order details...")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
            } else if let error = viewModel.errorMessage {
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 36))
                        .foregroundColor(.orange)
                    Text(error)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
            } else {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Order Summary Header
                        orderHeaderCard
                        
                        // Products Section Title
                        HStack {
                            Text("Requested Products")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.primary)
                            Spacer()
                            Text("\(viewModel.items.count) items")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 20)
                        
                        // Product List
                        LazyVStack(spacing: 12) {
                            ForEach(viewModel.items) { item in
                                orderProductCard(item: item)
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        // Shipment Timeline Section
                        shipmentTimeline
                    }
                    .padding(.top, 16)
                    .padding(.bottom, 24)
                }
            }
        }
        .navigationTitle("Order Details")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            Swift.Task {
                await viewModel.loadOrderDetails(orderId: orderId)
                if orderStatus.lowercased() == "approved" {
                    await viewModel.updateOrderStatus(orderId: orderId, newStatus: "Preparing Shipment")
                }
                startSimulationIfNecessary()
                startPolling()
            }
        }
        .onDisappear {
            simulationTask?.cancel()
            stopPolling()
        }
        .onChange(of: orderStatus) { _ in
            startSimulationIfNecessary()
        }
    }
    
    // MARK: - Order Header Card
    
    private var orderHeaderCard: some View {
        VStack(spacing: 16) {
            // Order ID
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("ORDER ID")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.secondary)
                        .tracking(0.8)
                    Text(orderId)
                        .font(.system(size: 16, weight: .bold, design: .monospaced))
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                Text(orderStatus)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(statusColor)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(statusColor.opacity(0.12))
                    .cornerRadius(10)
            }
            
            Divider()
            
            // Stats
            HStack(spacing: 0) {
                statColumn(label: "Products", value: "\(viewModel.items.count)")
                Spacer()
                statColumn(label: "Total Units", value: "\(totalUnits)")
                Spacer()
                statColumn(label: "Est. Selling Price", value: formatIndianCurrency(amount: totalSellingPrice))
            }
        }
        .padding(20)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.02), radius: 6, x: 0, y: 3)
        .padding(.horizontal, 20)
    }
    
    private func statColumn(label: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.primary)
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Product Card
    
    private func orderProductCard(item: OrderDetailViewModel.OrderProductItem) -> some View {
        HStack(spacing: 14) {
            // Product Image
            if let imageURLString = item.imageURL, let url = URL(string: imageURLString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 56, height: 56)
                            .cornerRadius(10)
                            .clipped()
                    case .failure, .empty:
                        productPlaceholder
                    @unknown default:
                        productPlaceholder
                    }
                }
            } else {
                productPlaceholder
            }
            
            // Product Info
            VStack(alignment: .leading, spacing: 5) {
                if let brand = item.brand {
                    Text(brand.uppercased())
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.blue)
                        .tracking(0.8)
                }
                
                Text(item.productName)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                Text("SKU: \(item.sku)")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Quantity & Price
            VStack(alignment: .trailing, spacing: 5) {
                Text("×\(item.requestedQuantity)")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.primary)
                
                Text(formatIndianCurrency(amount: item.price))
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)
            }
        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(14)
        .shadow(color: Color.black.opacity(0.02), radius: 4, x: 0, y: 2)
    }
    
    private var productPlaceholder: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.systemGray6))
                .frame(width: 56, height: 56)
            
            Image(systemName: "shippingbox.fill")
                .font(.system(size: 20))
                .foregroundColor(Color(.systemGray3))
        }
    }
    
    private func formatIndianCurrency(amount: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "en_IN")
        formatter.currencySymbol = "₹"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: amount as NSDecimalNumber) ?? "₹0"
    }
    
    // MARK: - Shipment Timeline UI & Simulation Logic
    
    @State private var simulationTask: Swift.Task<Void, Never>? = nil
    @State private var pollingTask: Swift.Task<Void, Never>? = nil
    
    private func startPolling() {
        pollingTask?.cancel()
        pollingTask = Swift.Task {
            while !Swift.Task.isCancelled {
                do {
                    try await Swift.Task.sleep(nanoseconds: 2_000_000_000)
                } catch {
                    return
                }
                
                guard !Swift.Task.isCancelled else { return }
                
                let currentStatus = orderStatus.lowercased()
                if currentStatus == "pending" || currentStatus == "approved" {
                    await viewModel.loadOrderDetails(orderId: orderId, isSilent: true)
                    
                    let newStatus = orderStatus.lowercased()
                    if newStatus == "approved" {
                        await viewModel.updateOrderStatus(orderId: orderId, newStatus: "Preparing Shipment")
                        stopPolling()
                    }
                } else {
                    stopPolling()
                }
            }
        }
    }
    
    private func stopPolling() {
        pollingTask?.cancel()
        pollingTask = nil
    }
    
    private func startSimulationIfNecessary() {
        simulationTask?.cancel()
        
        let status = orderStatus.lowercased()
        guard status == "preparing shipment" || status == "in transit" else {
            return
        }
        
        simulationTask = Swift.Task {
            if orderStatus.lowercased() == "preparing shipment" {
                do {
                    try await Swift.Task.sleep(nanoseconds: 3_000_000_000)
                } catch {
                    return
                }
                
                guard !Swift.Task.isCancelled else { return }
                
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                await viewModel.updateOrderStatus(orderId: orderId, newStatus: "In Transit")
            }
            
            if orderStatus.lowercased() == "in transit" {
                do {
                    try await Swift.Task.sleep(nanoseconds: 3_000_000_000)
                } catch {
                    return
                }
                
                guard !Swift.Task.isCancelled else { return }
                
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                await viewModel.updateOrderStatus(orderId: orderId, newStatus: "Delivered")
            }
        }
    }
    
    private func getStepStatus(for step: Int) -> TimelineStepStatus {
        let status = orderStatus.lowercased()
        
        switch step {
        case 1:
            return .completed
        case 2:
            if status == "rejected" { return .pending }
            if status == "preparing shipment" { return .active }
            if status == "in transit" || status == "delivered" { return .completed }
            return .pending
        case 3:
            if status == "rejected" { return .pending }
            if status == "in transit" { return .active }
            if status == "delivered" { return .completed }
            return .pending
        case 4:
            if status == "rejected" { return .pending }
            if status == "delivered" { return .completed }
            return .pending
        default:
            return .pending
        }
    }
    
    private func getStepDescription(for step: Int) -> String {
        let status = orderStatus.lowercased()
        
        switch step {
        case 2:
            if status == "preparing shipment" { return "Preparing your shipment..." }
            if status == "in transit" || status == "delivered" { return "Completed" }
            return "Pending"
        case 3:
            if status == "in transit" { return "On the way to your store" }
            if status == "delivered" { return "Completed" }
            return "Pending"
        case 4:
            if status == "delivered" { return "Replenishment complete" }
            return "Pending"
        default:
            return ""
        }
    }
    
    private func getLineColor(fromStep: Int) -> Color {
        let nextStepStatus = getStepStatus(for: fromStep + 1)
        if nextStepStatus == .completed || nextStepStatus == .active {
            return .green
        }
        return Color(.systemGray4)
    }
    
    private var shipmentTimeline: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Shipment Timeline")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.primary)
                .padding(.bottom, 4)
            
            VStack(alignment: .leading, spacing: 0) {
                // 1. Ordered
                TimelineStepRow(
                    status: getStepStatus(for: 1),
                    title: "Ordered",
                    description: "Request Submitted Successfully",
                    lineColor: getLineColor(fromStep: 1),
                    isLast: false
                ) {
                    if orderStatus.lowercased() == "pending" {
                        waitingStateView
                    } else if orderStatus.lowercased() == "rejected" {
                        rejectedStateView
                    }
                }
                
                // 2. Preparing Shipment
                TimelineStepRow(
                    status: getStepStatus(for: 2),
                    title: "Preparing Shipment",
                    description: getStepDescription(for: 2),
                    lineColor: getLineColor(fromStep: 2),
                    isLast: false
                )
                
                // 3. In Transit
                TimelineStepRow(
                    status: getStepStatus(for: 3),
                    title: "In Transit",
                    description: getStepDescription(for: 3),
                    lineColor: getLineColor(fromStep: 3),
                    isLast: false
                )
                
                // 4. Delivered
                TimelineStepRow(
                    status: getStepStatus(for: 4),
                    title: "Delivered",
                    description: getStepDescription(for: 4),
                    lineColor: .clear,
                    isLast: true
                )
            }
            
            if orderStatus.lowercased() == "delivered" {
                deliveryConfirmationMessage
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        .padding(20)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.02), radius: 6, x: 0, y: 3)
        .padding(.horizontal, 20)
    }
    
    private var waitingStateView: some View {
        Text("⏳ Waiting for Inventory Approval")
            .font(.system(size: 12, weight: .medium))
            .foregroundColor(.orange)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.orange.opacity(0.12))
            .cornerRadius(8)
            .padding(.top, 4)
    }
    
    private var rejectedStateView: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("This replenishment request was rejected by the Inventory Manager.")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
        }
        .padding(10)
        .background(Color.red.opacity(0.08))
        .cornerRadius(8)
        .padding(.top, 4)
    }
    
    private var deliveryConfirmationMessage: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 24))
                .foregroundColor(.green)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Order Delivered")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.primary)
                Text("Your replenishment order has been successfully delivered to your store.")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color.green.opacity(0.08))
        .cornerRadius(10)
    }
    

}

// MARK: - Timeline Step Row Helper

enum TimelineStepStatus {
    case completed
    case active
    case pending
    case rejected
}

struct TimelineStepRow<Content: View>: View {
    let status: TimelineStepStatus
    let title: String
    let description: String
    let lineColor: Color
    let isLast: Bool
    let extraContent: () -> Content
    
    init(
        status: TimelineStepStatus,
        title: String,
        description: String,
        lineColor: Color,
        isLast: Bool,
        @ViewBuilder extraContent: @escaping () -> Content = { EmptyView() }
    ) {
        self.status = status
        self.title = title
        self.description = description
        self.lineColor = lineColor
        self.isLast = isLast
        self.extraContent = extraContent
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(spacing: 0) {
                indicatorIcon
                
                if !isLast {
                    Rectangle()
                        .fill(lineColor)
                        .frame(width: 2.5)
                        .frame(minHeight: 40)
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 15, weight: isStepActive ? .bold : .semibold))
                    .foregroundColor(isStepActive ? .primary : (isStepPending ? .secondary : .primary))
                
                if !description.isEmpty {
                    Text(description)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                
                extraContent()
            }
            .padding(.bottom, isLast ? 0 : 20)
            
            Spacer()
        }
    }
    
    private var isStepActive: Bool {
        status == .active
    }
    
    private var isStepPending: Bool {
        status == .pending
    }
    
    private var indicatorIcon: some View {
        Group {
            switch status {
            case .completed:
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.green)
            case .active:
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.blue)
            case .pending:
                Circle()
                    .fill(Color(.systemGray4))
                    .frame(width: 20, height: 20)
            case .rejected:
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.red)
            }
        }
        .frame(width: 20, height: 20)
    }
}
