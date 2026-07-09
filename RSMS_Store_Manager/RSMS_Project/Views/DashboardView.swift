//
//  DashboardView.swift
//  RSMS_Project
//
//  Created by Antigravity on 03/07/26.
//

import SwiftUI
import Supabase
import Charts
import Combine

// MARK: - Models

enum SalesTimeRange: String, CaseIterable {
    case week = "Week"
    case month = "Month"
    case year = "Year"
}

struct DailySale: Identifiable, Equatable {
    var id: String { dayLabel }
    let dayLabel: String
    let amount: Double
    var date: Date? = nil
}

struct StaffShiftDisplay: Identifiable, Equatable {
    let id: UUID
    let name: String
    let role: String
    let shiftTime: String
    let initials: String
    let isAbsent: Bool
    let user: User
    let roleName: String
    let storeName: String
    let shiftName: String

    static func ==(lhs: StaffShiftDisplay, rhs: StaffShiftDisplay) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - View Model

@MainActor
final class DashboardViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String? = nil
    
    @Published var lowStockCount: Int = 0
    @Published var todaySalesAmount: Double = 0.0
    @Published var salesGoal: Double = 35000.0
    @Published var chartData: [DailySale] = []
    @Published var revenueTrend: Double? = nil
    
    @Published var selectedTimeRange: SalesTimeRange = .week {
        didSet { updateChartData() }
    }
    @Published var transactions: Int = 0
    @Published var averageSaleValue: Double = 0.0
    @Published var unitsSold: Int = 0
    private var allSales: [Sale] = []
    private var allSaleItems: [SaleItem] = []
    
    @Published var upcomingTasks: [Task] = []
    @Published var staffShifts: [StaffShiftDisplay] = []
    
    @Published var currentShift: Shift? = nil
    @Published var currentShiftHeader: String = "Staff Shifts"
    
    private let client = SupabaseManager.shared.client
    private let dbService = DatabaseService.shared
    
    private func formatShiftTime(_ timeStr: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        if let date = formatter.date(from: timeStr) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateFormat = "h a"
            return displayFormatter.string(from: date).lowercased()
        }
        
        formatter.dateFormat = "HH:mm"
        if let date = formatter.date(from: timeStr) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateFormat = "h a"
            return displayFormatter.string(from: date).lowercased()
        }
        return timeStr
    }
    
    func loadDashboardData() async {
        isLoading = true
        errorMessage = nil
        
        // Ensure session is resolved
        if SessionManager.shared.currentUser == nil {
            await SessionManager.shared.resolveSession()
        }
        
        guard let currentUser = SessionManager.shared.currentUser,
              let storeId = currentUser.storeId else {
            isLoading = false
            return
        }
        
        do {
            // 1. Fetch Inventory for Low Stock count
            let inventoryResponse = try await client
                .from("inventory")
                .select()
                .eq("store_id", value: storeId.uuidString)
                .execute()
            let inventoryItems = try JSONDecoder.supabaseDecoder.decodeSupabase([InventoryItem].self, from: inventoryResponse.data)
            
            // Count items requiring attention (quantity <= reorder_level)
            self.lowStockCount = inventoryItems.filter { $0.quantity <= $0.reorderLevel }.count
            
            // 2. Fetch Sales for the current year
            let calendar = Calendar.current
            let oneYearAgo = calendar.date(byAdding: .year, value: -1, to: calendar.startOfDay(for: Date())) ?? Date()
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            let dateString = formatter.string(from: oneYearAgo)
            
            let salesResponse = try await client
                .from("sales")
                .select()
                .eq("store_id", value: storeId.uuidString)
                .gte("sale_date", value: dateString)
                .execute()
            self.allSales = try JSONDecoder.supabaseDecoder.decodeSupabase([Sale].self, from: salesResponse.data)
            
            if !self.allSales.isEmpty {
                if let itemsResponse = try? await client.from("sale_items").select().execute() {
                    self.allSaleItems = (try? JSONDecoder.supabaseDecoder.decodeSupabase([SaleItem].self, from: itemsResponse.data)) ?? []
                }
            }
            
            updateChartData()
            
            // 3. Fetch top 5 upcoming tasks
            let tasksResponse = try await client
                .from("tasks")
                .select()
                .eq("store_id", value: storeId.uuidString)
                .neq("status", value: "done")
                .order("due_date", ascending: true)
                .limit(5)
                .execute()
            self.upcomingTasks = try JSONDecoder.supabaseDecoder.decodeSupabase([Task].self, from: tasksResponse.data)
            
            // 4. Fetch Shifts, Staff and Roles
            let shiftsResponse = try await client
                .from("shifts")
                .select()
                .eq("store_id", value: storeId.uuidString)
                .eq("status", value: "active")
                .execute()
            let shifts = try JSONDecoder.supabaseDecoder.decodeSupabase([Shift].self, from: shiftsResponse.data)
            
            let usersResponse = try await client
                .from("users")
                .select()
                .eq("store_id", value: storeId.uuidString)
                .execute()
            let users = try JSONDecoder.supabaseDecoder.decodeSupabase([User].self, from: usersResponse.data)
            
            let rolesResponse = try await client
                .from("roles")
                .select()
                .execute()
            let roles = try JSONDecoder.supabaseDecoder.decodeSupabase([Role].self, from: rolesResponse.data)
            let roleMap = Dictionary(uniqueKeysWithValues: roles.map { ($0.id, $0.roleName) })
            
            let fetchedStores: [Store] = try await dbService.fetch(from: "stores", as: Store.self)
            
            // Resolve current shift based on current hour (8 AM to 10 PM)
            let currentHour = calendar.component(.hour, from: Date())
            
            if currentHour >= 8 && currentHour < 22 {
                let timeFormatter = DateFormatter()
                timeFormatter.dateFormat = "HH:mm:ss"
                
                let matchingShift = shifts.first { shift in
                    guard let startDate = timeFormatter.date(from: shift.startTime),
                          let endDate = timeFormatter.date(from: shift.endTime) else {
                        return false
                    }
                    let startHour = calendar.component(.hour, from: startDate)
                    let endHour = calendar.component(.hour, from: endDate)
                    return currentHour >= startHour && currentHour < endHour
                }
                
                if let shift = matchingShift {
                    self.currentShift = shift
                    
                    let startStr = formatShiftTime(shift.startTime)
                    let endStr = formatShiftTime(shift.endTime)
                    self.currentShiftHeader = "\(shift.shiftName) (\(startStr) - \(endStr))"
                    
                    // Filter users assigned to this shift
                    var tempStaffShifts: [StaffShiftDisplay] = []
                    let shiftUsers = users.filter { $0.shiftId == shift.id }
                    
                    for user in shiftUsers {
                        let roleName = roleMap[user.roleId] ?? "Staff"
                        let initials = String(user.fullName.split(separator: " ").compactMap { $0.first }.prefix(2)).uppercased()
                        let initialsString = initials.isEmpty ? String(user.fullName.prefix(2)).uppercased() : initials
                        
                        let timeRange = "\(shift.startTime) - \(shift.endTime)"
                        let isAbsent = (user.employeeStatus?.lowercased() == "absent")
                        let storeName = fetchedStores.first(where: { $0.id == storeId })?.storeName ?? "Store"
                        
                        tempStaffShifts.append(StaffShiftDisplay(
                            id: user.id,
                            name: user.fullName,
                            role: roleName,
                            shiftTime: timeRange,
                            initials: initialsString,
                            isAbsent: isAbsent,
                            user: user,
                            roleName: roleName,
                            storeName: storeName,
                            shiftName: shift.shiftName
                        ))
                    }
                    self.staffShifts = tempStaffShifts
                } else {
                    self.currentShift = nil
                    self.currentShiftHeader = ""
                    self.staffShifts = []
                }
            } else {
                self.currentShift = nil
                self.currentShiftHeader = ""
                self.staffShifts = []
            }
            
        } catch {
            print("Failed to load dashboard data: \(error)")
            self.errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func updateChartData() {
        let calendar = Calendar.current
        var tempChartData: [DailySale] = []
        var filteredSales: [Sale] = []
        let today = calendar.startOfDay(for: Date())
        
        switch selectedTimeRange {
        case .week:
            let weekdaySymbols = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
            for i in 0..<7 {
                let targetDate = calendar.date(byAdding: .day, value: -6 + i, to: today) ?? Date()
                let weekdayIndex = calendar.component(.weekday, from: targetDate) - 1
                let label = weekdaySymbols[weekdayIndex]
                
                let daySales = allSales.filter { calendar.isDate($0.saleDate, inSameDayAs: targetDate) }
                let total = daySales.reduce(0.0) { $0 + $1.totalAmount }
                tempChartData.append(DailySale(dayLabel: label, amount: total, date: targetDate))
                filteredSales.append(contentsOf: daySales)
            }
        case .month:
            // Group by 4 weeks (last 28 days)
            for i in 0..<4 {
                let startDate = calendar.date(byAdding: .day, value: -28 + (i * 7), to: today) ?? Date()
                let endDate = calendar.date(byAdding: .day, value: 7, to: startDate) ?? Date()
                let label = "W\(i+1)"
                
                let weekSales = allSales.filter { $0.saleDate >= startDate && $0.saleDate < endDate }
                let total = weekSales.reduce(0.0) { $0 + $1.totalAmount }
                tempChartData.append(DailySale(dayLabel: label, amount: total, date: startDate))
                filteredSales.append(contentsOf: weekSales)
            }
        case .year:
            let monthSymbols = calendar.shortMonthSymbols
            for i in 0..<12 {
                let targetMonthDate = calendar.date(byAdding: .month, value: -11 + i, to: today) ?? Date()
                let monthIndex = calendar.component(.month, from: targetMonthDate) - 1
                let label = monthSymbols[monthIndex]
                
                let monthSales = allSales.filter { 
                    calendar.component(.month, from: $0.saleDate) == monthIndex + 1 &&
                    calendar.component(.year, from: $0.saleDate) == calendar.component(.year, from: targetMonthDate)
                }
                let total = monthSales.reduce(0.0) { $0 + $1.totalAmount }
                tempChartData.append(DailySale(dayLabel: label, amount: total, date: targetMonthDate))
                filteredSales.append(contentsOf: monthSales)
            }
        }
        
        self.chartData = tempChartData
        self.todaySalesAmount = tempChartData.last?.amount ?? 0.0
        
        // Update stats
        self.transactions = filteredSales.count
        let totalRevenue = filteredSales.reduce(0.0) { $0 + $1.totalAmount }
        self.averageSaleValue = self.transactions > 0 ? totalRevenue / Double(self.transactions) : 0.0
        
        let filteredSaleIds = Set(filteredSales.map { $0.id })
        let relevantItems = allSaleItems.filter { filteredSaleIds.contains($0.saleId) }
        self.unitsSold = relevantItems.reduce(0) { $0 + $1.quantity }
        
        // Calculate Trend
        var previousRevenue = 0.0
        switch selectedTimeRange {
        case .week:
            let lastWeekStart = calendar.date(byAdding: .day, value: -13, to: today) ?? Date()
            let lastWeekEnd = calendar.date(byAdding: .day, value: -7, to: today) ?? Date()
            previousRevenue = allSales.filter { $0.saleDate >= lastWeekStart && $0.saleDate <= lastWeekEnd }.reduce(0.0) { $0 + $1.totalAmount }
        case .month:
            let lastMonthStart = calendar.date(byAdding: .day, value: -56, to: today) ?? Date()
            let lastMonthEnd = calendar.date(byAdding: .day, value: -28, to: today) ?? Date()
            previousRevenue = allSales.filter { $0.saleDate >= lastMonthStart && $0.saleDate < lastMonthEnd }.reduce(0.0) { $0 + $1.totalAmount }
        case .year:
            let lastYearStart = calendar.date(byAdding: .month, value: -23, to: today) ?? Date()
            let lastYearEnd = calendar.date(byAdding: .month, value: -11, to: today) ?? Date()
            previousRevenue = allSales.filter { $0.saleDate >= lastYearStart && $0.saleDate < lastYearEnd }.reduce(0.0) { $0 + $1.totalAmount }
        }
        
        if previousRevenue > 0 {
            self.revenueTrend = ((totalRevenue - previousRevenue) / previousRevenue) * 100.0
        } else if previousRevenue == 0 && totalRevenue > 0 {
            self.revenueTrend = 100.0 // 100% increase if previous was 0 and now we have sales
        } else {
            self.revenueTrend = nil
        }
    }
}

// MARK: - View

struct DashboardView: View {
    @Binding var selectedTab: Int
    @Binding var selectedStockFilter: StockFilterType
    @StateObject private var viewModel = DashboardViewModel()
    
    @State private var selectedDay: String? = nil
    @State private var showBars = false
    
    @State private var navigateToShifts = false
    @State private var selectedEmployeeDetail: StaffShiftDisplay? = nil
    @State private var showingNotifications = false
    @State private var showingProfile = false
    
    private var currentDayString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: Date())
    }
    
    private var headerSubtitle: String {
        if let day = selectedDay, let sale = viewModel.chartData.first(where: { $0.dayLabel == day }) {
            return formatIndianCurrency(amount: sale.amount)
        }
        return "\(formatIndianCurrency(amount: viewModel.todaySalesAmount)) / \(formatIndianCurrency(amount: viewModel.salesGoal))"
    }
    
    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.chartData.isEmpty {
                VStack(spacing: 12) {
                    ProgressView()
                        .scaleEffect(1.2)
                    Text("Loading Dashboard...")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Custom Header Row aligning Title and Notification Button
                        HStack(spacing: 12) {
                            Text("Dashboard")
                                .font(.system(size: 34, weight: .bold))
                                .foregroundColor(Color(.label))
                            Spacer()
                            Button {
                                showingNotifications = true
                            } label: {
                                ZStack {
                                    Circle()
                                        .fill(Color(.secondarySystemGroupedBackground))
                                        .frame(width: 40, height: 40)
                                        .shadow(color: Color.black.opacity(0.04), radius: 5, x: 0, y: 2)
                                    Image(systemName: "bell.fill")
                                        .font(.system(size: 18, weight: .medium))
                                        .foregroundColor(.blue)
                                }
                            }
                            Button {
                                showingProfile = true
                            } label: {
                                ZStack {
                                    Circle()
                                        .fill(Color(.secondarySystemGroupedBackground))
                                        .frame(width: 40, height: 40)
                                        .shadow(color: Color.black.opacity(0.04), radius: 5, x: 0, y: 2)
                                    Image(systemName: "person.fill")
                                        .font(.system(size: 18, weight: .medium))
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 16)

                        // Hidden navigation link to shift page
                        NavigationLink(destination: ShiftManagementView(), isActive: $navigateToShifts) {
                            EmptyView()
                        }
                        .frame(width: 0, height: 0)
                        .opacity(0)
                        
                        // 1. Interactive Sales Chart Card
                        salesProgressChartCard
                        
                        // 2. Low Stock Banner/Card
                        lowStockBannerCard
                        
                        // 3. Upcoming Appointments Card (Carousel)
                        upcomingAppointmentsCard
                        
                        // 4. Staff Shifts Card (Conditional)
                        if viewModel.currentShift != nil {
                            staffShiftsCard
                        }
                    }
                    .padding(.vertical)
                }
            }
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationBarHidden(true)
        .sheet(item: $selectedEmployeeDetail) { staff in
            NavigationStack {
                EmployeeDetailView(
                    employee: staff.user,
                    roleName: staff.roleName,
                    storeName: staff.storeName,
                    shiftName: staff.shiftName,
                    onUpdate: { updatedUser in
                        Swift.Task {
                            await viewModel.loadDashboardData()
                        }
                    },
                    onDelete: { deletedUser in
                        Swift.Task {
                            await viewModel.loadDashboardData()
                        }
                    }
                )
            }
        }
        .sheet(isPresented: $showingNotifications) {
            NotificationsOrdersView()
        }
        .sheet(isPresented: $showingProfile) {
            if let user = SessionManager.shared.currentUser {
                StoreManagerProfileSheet(user: user, onLogout: {
                    SessionManager.shared.currentUser = nil
                })
            }
        }
        .onAppear {
            Swift.Task {
                await viewModel.loadDashboardData()
                showBars = true
            }
        }
        .refreshable {
            await viewModel.loadDashboardData()
        }
    }
    
    // MARK: - Cards
    
    @ViewBuilder
    private var lowStockBannerCard: some View {
        if viewModel.lowStockCount > 0 {
            Button {
            selectedStockFilter = .lowStock
            withAnimation {
                selectedTab = 2 // Navigate to Stock Tab
            }
        } label: {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color.orange.opacity(0.2))
                        .frame(width: 40, height: 40)
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.headline).fontWeight(.bold)
                        .foregroundColor(.orange)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(viewModel.lowStockCount) items Low Stock")
                        .font(.subheadline).fontWeight(.bold)
                        .foregroundColor(Color(.label))
                    
                    Text("Keep an eye on this")
                        .font(.caption).fontWeight(.medium)
                        .foregroundColor(Color(.secondaryLabel))
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.footnote).fontWeight(.bold)
                    .foregroundColor(Color.orange.opacity(0.5))
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.orange.opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.orange.opacity(0.3), lineWidth: 1)
            )
            .padding(.horizontal, 20)
        }
        .buttonStyle(PlainButtonStyle())
        }
    }
    
    private var formattedSelectedDate: String {
        if let selected = selectedDay, let sale = viewModel.chartData.first(where: { $0.dayLabel == selected }), let date = sale.date {
            let formatter = DateFormatter()
            formatter.dateFormat = "d MMM yyyy"
            let dateString = formatter.string(from: date)
            return Calendar.current.isDateInToday(date) ? "Today • \(dateString)" : dateString
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM yyyy"
        return "Today • \(formatter.string(from: Date()))"
    }
    
    private var isChartEmpty: Bool {
        viewModel.chartData.isEmpty || viewModel.chartData.allSatisfy { $0.amount == 0 }
    }
    
    @ViewBuilder
    private var headerRevenueView: some View {
        if let day = selectedDay, let sale = viewModel.chartData.first(where: { $0.dayLabel == day }) {
            Text(formatIndianCurrency(amount: sale.amount))
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(Color(.label))
        } else {
            Text(formatIndianCurrency(amount: viewModel.todaySalesAmount))
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(Color(.label))
        }
    }
    
    private var salesProgressChartCard: some View {
        VStack(alignment: .leading, spacing: 16) {
                    // Header & Picker
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 4) {
                            NavigationLink(destination: SalesHistoryView()) {
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack(spacing: 4) {
                                        Text("TOTAL REVENUE")
                                            .font(.caption)
                                            .fontWeight(.bold)
                                            .foregroundColor(Color(.systemGray))
                                            .textCase(.uppercase)
                                        
                                        Image(systemName: "chevron.right")
                                            .font(.caption)
                                            .fontWeight(.bold)
                                            .foregroundColor(Color(.systemGray))
                                    }
                                    
                                    headerRevenueView
                                        .animation(.spring(), value: viewModel.todaySalesAmount)
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            if let trend = viewModel.revenueTrend {
                                let isPositive = trend >= 0
                                let trendText = String(format: "%.1f%%", abs(trend))
                                let periodText = viewModel.selectedTimeRange == .week ? "last week" : (viewModel.selectedTimeRange == .month ? "last month" : "last year")
                                
                                Text("\(isPositive ? "↑" : "↓") \(trendText) vs \(periodText)")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(isPositive ? .green : .red)
                                    .padding(.top, 2)
                            }
                        }
                        
                        Spacer()
                        
                        Picker("Time Range", selection: $viewModel.selectedTimeRange) {
                            ForEach([SalesTimeRange.week, SalesTimeRange.month], id: \.self) { range in
                                Text(range.rawValue).tag(range)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .frame(width: 140)
                        .padding(.top, 16)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 8)
                    
                    // Line Chart
                    ZStack {
                        if isChartEmpty {
                            VStack {
                                Spacer()
                                Text("No sales recorded for this period.")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Spacer()
                            }
                            .frame(height: 150)
                        }
                        
                        Chart {
                            if !isChartEmpty {
                                ForEach(viewModel.chartData) { day in
                                    LineMark(
                                        x: .value("Time", day.dayLabel),
                                        y: .value("Sales", day.amount)
                                    )
                                    .foregroundStyle(Color.blue)
                                    .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                                    .interpolationMethod(.catmullRom)
                                    
                                    AreaMark(
                                        x: .value("Time", day.dayLabel),
                                        y: .value("Sales", day.amount)
                                    )
                                    .foregroundStyle(
                                        LinearGradient(
                                            gradient: Gradient(colors: [Color.blue.opacity(0.15), Color.blue.opacity(0.0)]),
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                                    .interpolationMethod(.catmullRom)
                                    
                                    if let selected = selectedDay, day.dayLabel == selected {
                                        PointMark(
                                            x: .value("Time", day.dayLabel),
                                            y: .value("Sales", day.amount)
                                        )
                                        .foregroundStyle(Color.blue)
                                        .symbolSize(80)
                                        .annotation(position: .top, spacing: 8) {
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(day.dayLabel)
                                                    .font(.system(size: 10, weight: .regular))
                                                    .foregroundColor(.white.opacity(0.9))
                                                Text("Revenue")
                                                    .font(.system(size: 8, weight: .regular))
                                                    .foregroundColor(.white.opacity(0.7))
                                                Text(formatIndianCurrency(amount: day.amount))
                                                    .font(.system(size: 14, weight: .bold))
                                                    .foregroundColor(.white)
                                            }
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 6)
                                            .background(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .fill(Color.blue)
                                            )
                                            .shadow(radius: 3, y: 2)
                                        }
                                    }
                                }
                            }
                            
                            // Horizontal target line (only if not empty)
                            if viewModel.salesGoal > 0 && !isChartEmpty {
                                RuleMark(
                                    y: .value("Target", viewModel.salesGoal)
                                )
                                .foregroundStyle(Color.green.opacity(0.5))
                                .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [4, 4]))
                                .annotation(position: .top, alignment: .leading) {
                                    Text("TARGET")
                                        .font(.system(size: 8, weight: .bold))
                                        .foregroundColor(.green)
                                        .padding(.leading, 4)
                                }
                            }
                            
                            if let selected = selectedDay, !isChartEmpty {
                                RuleMark(
                                    x: .value("Time", selected)
                                )
                                .foregroundStyle(Color.blue.opacity(0.3))
                                .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [4]))
                            }
                        }
                        .chartXAxis {
                            AxisMarks { value in
                                AxisValueLabel {
                                    if let text = value.as(String.self) {
                                        Text(text)
                                            .font(.system(size: 9))
                                            .foregroundColor(Color(.systemGray2))
                                    }
                                }
                            }
                        }
                        .chartYAxis {
                            AxisMarks(position: .leading, values: .automatic(desiredCount: 4)) { value in
                                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [2]))
                                    .foregroundStyle(Color(.systemGray5))
                                AxisValueLabel {
                                    if let doubleValue = value.as(Double.self) {
                                        Text("₹\(Int(doubleValue/1000))k")
                                            .font(.system(size: 9))
                                            .foregroundColor(Color(.systemGray2))
                                    }
                                }
                            }
                        }
                        .frame(height: 140)
                        .padding(.horizontal, 8)
                        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: viewModel.chartData)
                        .chartOverlay { proxy in
                            GeometryReader { geometry in
                                Rectangle().fill(.clear).contentShape(Rectangle())
                                    .onTapGesture { location in
                                        if isChartEmpty { return }
                                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                        let origin = geometry[proxy.plotAreaFrame].origin
                                        let x = location.x - origin.x
                                        if let dayLabel: String = proxy.value(atX: x) {
                                            if selectedDay == dayLabel {
                                                selectedDay = nil
                                            } else {
                                                selectedDay = dayLabel
                                            }
                                        }
                                    }
                            }
                        }
                    }
                    .padding(.bottom, 20)
                }
                .background(Color(.systemBackground))
                .cornerRadius(24)
                .shadow(color: Color.black.opacity(0.04), radius: 15, x: 0, y: 8)
                .padding(.horizontal)
    }
    
    private var upcomingAppointmentsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            NavigationLink(destination: TaskManagementView()) {
                HStack {
                    Image(systemName: "calendar")
                        .foregroundColor(Color(.label))
                    Text("UPCOMING APPOINTMENTS")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(Color(.label))
                        .tracking(1)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.footnote).fontWeight(.bold)
                        .foregroundColor(Color(.label))
                }
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.horizontal, 20)
            
            // Horizontal Carousel
            if viewModel.upcomingTasks.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "calendar.badge.clock")
                        .font(.largeTitle).fontWeight(.bold)
                        .foregroundColor(Color(.secondaryLabel))
                    Text("No upcoming appointments or tasks.")
                        .foregroundColor(Color(.label))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
                .background(Color(.secondaryLabel).opacity(0.05))
                .cornerRadius(16)
                .padding(.horizontal, 20)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(viewModel.upcomingTasks) { task in
                            NavigationLink(destination: TaskManagementView()) {
                                VStack(alignment: .leading, spacing: 12) {
                                    // Time & Icon
                                    HStack {
                                        Text(formatTime(task.dueDate))
                                            .font(.subheadline)
                                            .fontWeight(.bold)
                                            .foregroundColor(Color(.label))
                                        Spacer()
                                        Image(systemName: "star.fill")
                                            .foregroundColor(.orange)
                                    }
                                    
                                    // Title & Priority/Type
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(task.title)
                                            .font(.body)
                                            .fontWeight(.semibold)
                                            .foregroundColor(Color(.label))
                                            .lineLimit(1)
                                        
                                        Text(task.description ?? "\(task.priority.capitalized) Priority")
                                            .font(.caption2)
                                            .foregroundColor(Color(.secondaryLabel))
                                            .lineLimit(1)
                                    }
                                }
                                .padding(16)
                                .frame(width: 180, height: 100)
                                .background(Color(.secondaryLabel).opacity(0.05))
                                .cornerRadius(16)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color(.secondaryLabel).opacity(0.1), lineWidth: 1)
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 8)
                }
            }
        }
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.secondarySystemGroupedBackground))
        )
        .shadow(color: Color.black.opacity(0.04), radius: 15, x: 0, y: 8)
        .padding(.horizontal)
    }
    
    private var staffShiftsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Image(systemName: "person.3.sequence.fill")
                    .foregroundColor(Color(.label))
                Text(viewModel.currentShiftHeader.uppercased())
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(Color(.label))
                    .tracking(1)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.footnote).fontWeight(.bold)
                    .foregroundColor(Color(.label))
            }
            .padding(.horizontal, 20)
            
            if viewModel.staffShifts.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "moon.zzz")
                        .font(.largeTitle).fontWeight(.bold)
                        .foregroundColor(Color(.secondaryLabel))
                    Text("No staff scheduled for today.")
                        .foregroundColor(Color(.label))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
                .background(Color(.secondaryLabel).opacity(0.05))
                .cornerRadius(16)
                .padding(.horizontal, 20)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(viewModel.staffShifts) { staff in
                            activeStaffCard(for: staff)
                                .onTapGesture {
                                    selectedEmployeeDetail = staff
                                }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 8)
                }
                .onTapGesture {
                    // Swallow tap gesture to prevent outer navigation trigger
                }
            }
        }
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.secondarySystemGroupedBackground))
        )
        .shadow(color: Color.black.opacity(0.04), radius: 15, x: 0, y: 8)
        .padding(.horizontal)
        .contentShape(Rectangle())
        .onTapGesture {
            navigateToShifts = true
        }
    }
    
    @ViewBuilder
    private func activeStaffCard(for staff: StaffShiftDisplay) -> some View {
        VStack(spacing: 12) {
            ZStack(alignment: .bottomTrailing) {
                Circle()
                    .fill(Color(.secondaryLabel).opacity(0.1))
                    .frame(width: 60, height: 60)
                    .overlay(
                        Text(String(staff.initials.prefix(1)))
                            .font(.title)
                            .foregroundColor(Color(.label))
                    )
                
                Circle()
                    .fill(staff.isAbsent ? Color.red : Color.green)
                    .frame(width: 14, height: 14)
                    .overlay(Circle().stroke(Color(.secondarySystemGroupedBackground), lineWidth: 2))
            }
            
            VStack(spacing: 2) {
                Text(staff.name.components(separatedBy: " ").first ?? "Unknown")
                    .font(.body)
                    .fontWeight(.bold)
                    .foregroundColor(Color(.label))
                    .lineLimit(1)
                
                Text(staff.role)
                    .font(.caption2)
                    .foregroundColor(Color(.secondaryLabel))
                    .lineLimit(1)
            }
        }
        .padding(16)
        .frame(width: 160, height: 130)
        .background(Color(.secondaryLabel).opacity(0.05))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(.secondaryLabel).opacity(0.1), lineWidth: 1)
        )
    }
    
    // MARK: - Formatting Helpers
    
    private func formatK(_ amount: Double) -> String {
        if amount == 0 { return "0K" }
        if amount >= 1000 {
            return "\(Int(amount / 1000))K"
        }
        return "\(Int(amount))"
    }
    
    private func formatTime(_ date: Date?) -> String {
        guard let d = date else { return "--:--" }
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: d)
    }
    
    private func formatIndianCurrency(amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "en_IN")
        formatter.currencySymbol = "₹"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "₹0"
    }
}

// MARK: - Notifications View for Delivered or Approved Orders

struct NotificationsOrdersView: View {
    @StateObject private var viewModel = OrderHistoryViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                if viewModel.isLoading {
                    ProgressView("Loading updates...")
                } else {
                    let filtered = viewModel.orders.filter {
                        let s = $0.status.lowercased()
                        return s == "delivered" || s == "approved"
                    }
                    
                    if filtered.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "bell.slash")
                                .font(.system(size: 48))
                                .foregroundColor(.secondary)
                            Text("No Notifications")
                                .font(.system(size: 18, weight: .bold))
                            Text("Orders approved or delivered will show here.")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                        }
                    } else {
                        ScrollView(showsIndicators: false) {
                            LazyVStack(spacing: 12) {
                                ForEach(filtered) { order in
                                    NavigationLink(destination: OrderDetailView(orderId: order.orderId)) {
                                        OrderHistoryCard(order: order)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 16)
                        }
                    }
                }
            }
            .navigationTitle("Updates")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Dismiss") {
                        dismiss()
                    }
                }
            }
            .task {
                await viewModel.loadOrders()
            }
        }
    }
}

struct StoreManagerProfileSheet: View {
    let user: User
    var onLogout: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var storeName: String = "Loading..."
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Profile Avatar/Header
                VStack(spacing: 12) {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.blue)
                    
                    Text(user.fullName)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text(user.designation ?? "Store Manager")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 24)
                
                // Details List
                List {
                    Section(header: Text("Account Details")) {
                        HStack {
                            Text("Username")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(user.username)
                                .foregroundColor(.primary)
                        }
                        
                        HStack {
                            Text("Email")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(user.email)
                                .foregroundColor(.primary)
                        }
                        
                        HStack {
                            Text("Phone")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(user.phone ?? "Not Provided")
                                .foregroundColor(.primary)
                        }
                        
                        HStack {
                            Text("Store")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(storeName)
                                .foregroundColor(.primary)
                        }
                    }
                }
                .listStyle(InsetGroupedListStyle())
                
                Spacer()
                
                // Logout Button
                Button(action: {
                    dismiss()
                    onLogout()
                }) {
                    Text("Log Out")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.red)
                        .cornerRadius(12)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 24)
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                fetchStoreName()
            }
        }
        .preferredColorScheme(.light)
    }
    
    private func fetchStoreName() {
        guard let storeId = user.storeId else {
            self.storeName = "No Store Assigned"
            return
        }
        
        Swift.Task {
            do {
                let client = SupabaseManager.shared.client
                struct StoreNameResponse: Codable {
                    let name: String
                }
                let store: StoreNameResponse = try await client
                    .from("stores")
                    .select("name")
                    .eq("id", value: storeId.uuidString)
                    .single()
                    .execute()
                    .value
                await MainActor.run {
                    self.storeName = store.name
                }
            } catch {
                print("Failed to fetch store name: \(error)")
                await MainActor.run {
                    self.storeName = "Unknown Store"
                }
            }
        }
    }
}
