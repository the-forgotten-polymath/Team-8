import SwiftUI
import Supabase

import Combine

@MainActor
final class SalesHistoryViewModel: ObservableObject {
    @Published var sales: [SaleSummary] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // New analytics properties
    @Published var monthlyTarget: Double = 0
    @Published var currentRevenue: Double = 0
    @Published var totalUnitsSold: Int = 0
    @Published var averageOrderValue: Double = 0
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        NotificationCenter.default.publisher(for: NSNotification.Name("InventoryDidUpdate"))
            .sink { [weak self] _ in
                Swift.Task { @MainActor [weak self] in
                    await self?.loadSales()
                }
            }
            .store(in: &cancellables)
            
        NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)
            .sink { [weak self] _ in
                Swift.Task { @MainActor [weak self] in
                    await self?.loadSales()
                }
            }
            .store(in: &cancellables)
    }
    
    struct SaleSummary: Identifiable {
        let id: UUID
        let invoiceNumber: String
        let totalAmount: Double
        let productCount: Int
        let totalUnits: Int
        let saleDate: Date
        let customerName: String
        let associateName: String
    }
    
    func loadSales() async {
        isLoading = true
        errorMessage = nil
        
        guard let currentUser = SessionManager.shared.currentUser,
              let storeId = currentUser.storeId else {
            errorMessage = "No active session."
            isLoading = false
            return
        }
        
        do {
            let client = SupabaseManager.shared.client
            let response = try await client
                .from("sales")
                .select()
                .eq("store_id", value: storeId.uuidString)
                .order("sale_date", ascending: false)
                .execute()
            
            let allSales = try JSONDecoder.supabaseDecoder.decodeSupabase([Sale].self, from: response.data)
            
            var summaries: [SaleSummary] = []
            
            if !allSales.isEmpty {
                // Fetch items for product counts (we'll fetch all items for this store for simplicity)
                // In production, we might fetch only relevant items or paginate
                let itemsResponse = try? await client.from("sale_items").select().execute()
                let allItems = (try? JSONDecoder.supabaseDecoder.decodeSupabase([SaleItem].self, from: itemsResponse?.data ?? Data())) ?? []
                
                let customersResponse = try? await client.from("customers").select("id, first_name, last_name").eq("store_id", value: storeId.uuidString).execute()
                struct MiniCustomer: Decodable { let id: UUID; let first_name: String; let last_name: String }
                let customers = (try? JSONDecoder.supabaseDecoder.decodeSupabase([MiniCustomer].self, from: customersResponse?.data ?? Data())) ?? []
                var customerMap: [UUID: String] = [:]
                for c in customers { customerMap[c.id] = "\(c.first_name) \(c.last_name)" }
                
                let usersResponse = try? await client.from("users").select("id, first_name, last_name").eq("store_id", value: storeId.uuidString).execute()
                struct MiniUser: Decodable { let id: UUID; let first_name: String; let last_name: String }
                let users = (try? JSONDecoder.supabaseDecoder.decodeSupabase([MiniUser].self, from: usersResponse?.data ?? Data())) ?? []
                var userMap: [UUID: String] = [:]
                for u in users { userMap[u.id] = "\(u.first_name) \(u.last_name)" }
                
                // Group items by sale
                var saleItemsMap: [UUID: [SaleItem]] = [:]
                for item in allItems {
                    saleItemsMap[item.saleId, default: []].append(item)
                }
                
                for sale in allSales {
                    let items = saleItemsMap[sale.id] ?? []
                    let totalUnits = items.reduce(0) { $0 + $1.quantity }
                    let productCount = Set(items.map { $0.productId }).count
                    
                    let cName = sale.customerId != nil ? (customerMap[sale.customerId!] ?? "Walk-in") : "Walk-in"
                    let aName = userMap[sale.userId] ?? "Unknown Associate"
                    
                    summaries.append(SaleSummary(
                        id: sale.id,
                        invoiceNumber: sale.invoiceNumber ?? "INV-\(String(sale.id.uuidString.prefix(8)).uppercased())",
                        totalAmount: sale.totalAmount,
                        productCount: productCount,
                        totalUnits: totalUnits,
                        saleDate: sale.saleDate,
                        customerName: cName,
                        associateName: aName
                    ))
                }
            }
            
            self.sales = summaries
            
            // Analytics logic
            var revenue: Double = 0
            var units: Int = 0
            
            for summary in summaries {
                revenue += summary.totalAmount
                units += summary.totalUnits
            }
            
            self.currentRevenue = revenue
            self.totalUnitsSold = units
            self.averageOrderValue = summaries.isEmpty ? 0 : revenue / Double(summaries.count)
            
            // Fetch target
            do {
                let currentDate = Date()
                let calendar = Calendar.current
                // Get the first day of the current month
                let components = calendar.dateComponents([.year, .month], from: currentDate)
                if let firstDayOfMonth = calendar.date(from: components),
                   let lastDayOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: firstDayOfMonth) {
                    
                    let formatter = DateFormatter()
                    formatter.dateFormat = "yyyy-MM-dd"
                    let firstDayString = formatter.string(from: firstDayOfMonth)
                    let lastDayString = formatter.string(from: lastDayOfMonth)
                    
                    let targetResponse = try await client
                        .from("store_targets")
                        .select("revenue_target")
                        .eq("store_id", value: storeId.uuidString)
                        .gte("target_month", value: firstDayString)
                        .lte("target_month", value: lastDayString)
                        .execute()
                    
                    struct StoreTargetPartial: Decodable {
                        let revenue_target: Double
                    }
                    
                    let targets = try JSONDecoder.supabaseDecoder.decodeSupabase([StoreTargetPartial].self, from: targetResponse.data)
                    self.monthlyTarget = targets.first?.revenue_target ?? 0
                }
            } catch {
                print("Failed to fetch store targets: \(error)")
                self.monthlyTarget = 0
            }
            
        } catch {
            errorMessage = error.localizedDescription
            print("Failed to load sales history: \(error)")
        }
        
        isLoading = false
    }
}

struct SalesHistoryView: View {
    @StateObject private var viewModel = SalesHistoryViewModel()
    
    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()
            
            if viewModel.isLoading {
                VStack(spacing: 16) {
                    ProgressView()
                    Text("Loading sales...")
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
            } else if viewModel.sales.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "tray")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text("No Sales Yet")
                        .font(.system(size: 18, weight: .bold))
                    Text("Your sales history will appear here.")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
            } else {
                ScrollView(showsIndicators: false) {
                    SalesAnalyticsHeaderView(viewModel: viewModel)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Sales History")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(Color(.secondaryLabel))
                            .padding(.horizontal, 20)
                            .padding(.top, 6)
                        
                        LazyVStack(spacing: 12) {
                            ForEach(viewModel.sales) { sale in
                                NavigationLink(destination: SaleDetailsView(saleId: sale.id)) {
                                    SalesHistoryCard(sale: sale)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
                .refreshable {
                    await viewModel.loadSales()
                }
            }
        }
        .navigationTitle("Sales History")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            Swift.Task {
                await viewModel.loadSales()
            }
        }
    }
}

struct SalesHistoryCard: View {
    let sale: SalesHistoryViewModel.SaleSummary
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Row 1: Invoice Number & Total Sale Amount
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "doc.text.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.blue)
                    Text(sale.invoiceNumber)
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                Text(formatIndianCurrency(amount: sale.totalAmount))
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.primary)
            }
            
            Divider()
            
            // Row 2: Product Count & Total Units
            HStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(sale.productCount)")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.primary)
                    Text("Products")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(sale.totalUnits)")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.primary)
                    Text("Units")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
            
            Divider()
            
            // Row 3: Date & Time
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(.secondary)
                    .font(.system(size: 12))
                Text(formattedDate(sale.saleDate))
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.primary)
                
                Spacer()
                
                Image(systemName: "clock")
                    .foregroundColor(.secondary)
                    .font(.system(size: 12))
                Text(formattedTime(sale.saleDate))
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.primary)
            }
            
            Divider()
            
            // Row 4: Customer Name & Sales Associate Name
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "person.fill")
                        .foregroundColor(.secondary)
                        .font(.system(size: 12))
                    Text(sale.customerName)
                        .font(.system(size: 13))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                HStack(spacing: 6) {
                    Image(systemName: "briefcase.fill")
                        .foregroundColor(.secondary)
                        .font(.system(size: 12))
                    Text(sale.associateName)
                        .font(.system(size: 13))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                }
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.secondary)
                    .padding(.leading, 4)
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 3)
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMMM yyyy"
        return formatter.string(from: date)
    }
    
    private func formattedTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date).lowercased()
    }
    
    private func formatIndianCurrency(amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "en_IN")
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "₹0"
    }
}


fileprivate func formatIndianCurrency(amount: Double) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .currency
    formatter.locale = Locale(identifier: "en_IN")
    formatter.maximumFractionDigits = 0
    return formatter.string(from: NSNumber(value: amount)) ?? "₹0"
}

// MARK: - Analytics Header UI

struct SalesKPICardView: View {
    let symbol: String
    let title: String
    let value: String
    let subtitle: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: symbol)
                .font(.system(size: 20))
                .foregroundColor(.blue)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(Color(.label))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Color(.secondaryLabel))
                Text(subtitle)
                    .font(.system(size: 11))
                    .foregroundColor(Color(.tertiaryLabel))
                    .lineLimit(2)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .cornerRadius(18)
        .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 4)
    }
}

struct SalesDoughnutChartView: View {
    let currentRevenue: Double
    let monthlyTarget: Double
    @State private var animatedPercentage: Double = 0
    
    var completionPercentage: Double {
        if monthlyTarget == 0 { return 0 }
        return min((currentRevenue / monthlyTarget) * 100, 100.0)
    }
    
    var isTargetSet: Bool {
        return monthlyTarget > 0
    }
    
    var body: some View {
        VStack(spacing: 24) {
            ZStack {
                // Background Track
                Circle()
                    .stroke(Color(.systemGray5), lineWidth: 16)
                
                // Progress
                if isTargetSet {
                    Circle()
                        .trim(from: 0, to: CGFloat(animatedPercentage / 100.0))
                        .stroke(Color.blue, style: StrokeStyle(lineWidth: 16, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                }
                
                // Center text
                VStack(spacing: 2) {
                    Text(formatIndianCurrency(amount: currentRevenue))
                        .font(.system(size: 26, weight: .bold))
                        .foregroundColor(Color(.label))
                        .minimumScaleFactor(0.7)
                        .lineLimit(1)
                    
                    Text("Current Revenue")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(Color(.secondaryLabel))
                    
                    if isTargetSet {
                        Text(String(format: "%.0f%% Complete", animatedPercentage))
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.green)
                            .padding(.top, 4)
                    } else {
                        Text("Target Not Available")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(Color(.tertiaryLabel))
                            .padding(.top, 4)
                    }
                }
                .padding(24)
            }
            .frame(width: 176, height: 176)
            .onAppear {
                withAnimation(.spring(response: 1.0, dampingFraction: 0.8)) {
                    animatedPercentage = completionPercentage
                }
            }
            .onChange(of: currentRevenue) { _ in
                withAnimation(.spring(response: 1.0, dampingFraction: 0.8)) {
                    animatedPercentage = completionPercentage
                }
            }
            
            // Native Info List
            if isTargetSet {
                VStack(spacing: 12) {
                    Divider()
                    
                    HStack {
                        Text("Target")
                            .font(.system(size: 15))
                            .foregroundColor(Color(.secondaryLabel))
                        Spacer()
                        Text(formatIndianCurrency(amount: monthlyTarget))
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(Color(.label))
                    }
                    
                    Divider()
                    
                    HStack {
                        Text("Remaining")
                            .font(.system(size: 15))
                            .foregroundColor(Color(.secondaryLabel))
                        Spacer()
                        let remaining = max(monthlyTarget - currentRevenue, 0)
                        Text(formatIndianCurrency(amount: remaining))
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(Color(.label))
                    }
                }
                .padding(.top, 4)
                .padding(.horizontal, 4)
            } else {
                VStack(spacing: 12) {
                    Divider()
                    Text("No Monthly Target Set")
                        .font(.system(size: 15))
                        .foregroundColor(Color(.secondaryLabel))
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                .padding(.top, 4)
            }
        }
        .padding(24)
        .background(Color(.systemBackground))
        .cornerRadius(24)
        .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 4)
    }
}

struct SalesAnalyticsHeaderView: View {
    @ObservedObject var viewModel: SalesHistoryViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            
            // Sales Progress Header
            Text("Sales Progress")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(Color(.secondaryLabel))
                .padding(.top, 22)
                .padding(.bottom, 12)
            
            // 1. Chart Card
            if viewModel.isLoading && viewModel.currentRevenue == 0 {
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color(.systemBackground))
                    .frame(height: 280)
                    .shimmering()
            } else {
                SalesDoughnutChartView(currentRevenue: viewModel.currentRevenue, monthlyTarget: viewModel.monthlyTarget)
            }
            
            // Key Metrics Header
            Text("Key Metrics")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(Color(.secondaryLabel))
                .padding(.top, 22)
                .padding(.bottom, 12)
            
            // 2. KPI Cards
            HStack(spacing: 12) {
                if viewModel.isLoading && viewModel.currentRevenue == 0 {
                    RoundedRectangle(cornerRadius: 18)
                        .fill(Color(.systemBackground))
                        .frame(height: 110)
                        .shimmering()
                    RoundedRectangle(cornerRadius: 18)
                        .fill(Color(.systemBackground))
                        .frame(height: 110)
                        .shimmering()
                } else {
                    SalesKPICardView(
                        symbol: "cube.box.fill",
                        title: "Units Sold",
                        value: "\(viewModel.totalUnitsSold)",
                        subtitle: "Units sold this period"
                    )
                    
                    SalesKPICardView(
                        symbol: "indianrupeesign.circle.fill",
                        title: "Average Order Value",
                        value: formatIndianCurrency(amount: viewModel.averageOrderValue),
                        subtitle: "Average revenue per sale"
                    )
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
    }
}
