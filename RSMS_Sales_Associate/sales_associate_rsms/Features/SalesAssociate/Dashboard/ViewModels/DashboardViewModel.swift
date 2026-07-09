// DashboardViewModel.swift
// RSMS — Sales Associate Module

import SwiftUI
import Combine
import Supabase

struct RevenueDataPoint: Identifiable, Codable {
    let id: UUID
    let label: String
    let amount: Double
    let date: Date
    let salesCount: Int
}

@MainActor
class DashboardViewModel: ObservableObject {
    @Published var activeOpportunities: [Opportunity] = []
    @Published var advisorMetrics: AdvisorMetrics?
    @Published var storeMetrics: StoreMetrics?
    @Published var todayAppointments: [Appointment] = []

    @Published var isLoading = false
    @Published var errorMessage: String? = nil
    
    // Live Revenue analytics (Boutique Sales)
    @Published var todayRevenue: Double = 0.0
    @Published var todayOrdersCount: Int = 0
    @Published var thisWeekRevenue: Double = 0.0
    @Published var thisWeekOrdersCount: Int = 0
    @Published var thisMonthRevenue: Double = 0.0
    @Published var thisMonthOrdersCount: Int = 0
    @Published var averageOrderValue: Double = 0.0
    @Published var totalOrders: Int = 0

    @Published var weeklyChartData: [RevenueDataPoint] = []
    @Published var monthlyChartData: [RevenueDataPoint] = []

    // Advisor Live Revenue analytics (My Sales)
    @Published var advisorTodayRevenue: Double = 0.0
    @Published var advisorTodayOrdersCount: Int = 0
    @Published var advisorThisWeekRevenue: Double = 0.0
    @Published var advisorThisWeekOrdersCount: Int = 0
    @Published var advisorThisMonthRevenue: Double = 0.0
    @Published var advisorThisMonthOrdersCount: Int = 0
    @Published var advisorAverageOrderValue: Double = 0.0
    @Published var advisorTotalOrders: Int = 0

    @Published var advisorWeeklyChartData: [RevenueDataPoint] = []
    @Published var advisorMonthlyChartData: [RevenueDataPoint] = []
    
    // Attendance system state
    @Published var userShift: Shift? = nil
    @Published var todayAttendance: Attendance? = nil
    @Published var userStore: Store? = nil
    
    private var customersChannel: RealtimeChannelV2?
    private var salesChannel: RealtimeChannelV2?
    private var isSubscribed = false

    // MARK: - Load Dashboard Data
 
    func loadDashboardData(userId: UUID? = nil, storeId: UUID? = nil) async {
        isLoading = true
        errorMessage = nil
 
        do {
            if AppConstants.useMockData {
                // Simulate network delay
                try await Task.sleep(nanoseconds: 600_000_000)
                self.activeOpportunities = MockData.opportunities.filter { $0.status == .new }
                self.advisorMetrics      = MockData.advisorMetrics
                self.storeMetrics        = MockData.storeMetrics
                let today = Date()
                self.todayAppointments   = MockData.appointments.filter {
                    Calendar.current.isDate($0.date, inSameDayAs: today)
                }
                self.userShift = Shift(
                    id: UUID(),
                    storeId: storeId ?? UUID(),
                    shiftName: "Morning Shift",
                    startTime: "09:00:00",
                    endTime: "18:00:00",
                    status: "Active",
                    createdBy: UUID(),
                    createdAt: today
                )
                self.todayAttendance = nil
                isLoading = false
                return
            }
 
            // ── Real DB path ───────────────────────────────────────────
 
            guard let userId = userId else {
                errorMessage = "User session not available."
                isLoading = false
                return
            }
 
            // 1. Fetch today's sales total for this associate
            async let todaySalesTask   = SalesAssociateService.shared.fetchTodaySalesTotal(userId: userId)
            // 2. Fetch task counts (pending = followUpsDue, completed = followUpsCompleted)
            async let taskCountsTask   = SalesAssociateService.shared.fetchTaskCounts(userId: userId)
            // 3. Fetch store-level metrics (only if storeId is known)
            async let storeMetricsTask = storeId != nil
                ? SalesAssociateService.shared.fetchStoreMetrics(storeId: storeId!)
                : nil
            // 4. Fetch daily sales totals for sparkline chart
            async let dailyTotalsTask  = storeId != nil
                ? SalesAssociateService.shared.fetchDailySalesTotals(storeId: storeId!)
                : []
            // 5. Fetch daily target for advisor gauge
            async let dailyTargetTask  = storeId != nil
                ? SalesAssociateService.shared.fetchDailyTarget(storeId: storeId!)
                : 10_000.0
            // 6. Derive opportunities from assigned customers
            async let oppsTask = SalesAssociateService.shared.fetchOpportunities(
                associateId: userId,
                storeId: storeId
            )
            // 7. Fetch Completed sales for boutique dashboard (live chart & calculations)
            async let completedSalesTask = storeId != nil
                ? SalesAssociateService.shared.fetchCompletedSales(storeId: storeId!)
                : []
            // 8. Fetch Completed sales for advisor (live chart & calculations)
            async let advisorSalesTask = SalesAssociateService.shared.fetchCompletedSalesForAdvisor(userId: userId)
 
            // Await all concurrently
            let todaySales  = try await todaySalesTask
            let taskCounts  = try await taskCountsTask
            let dailyTotals = try await dailyTotalsTask
            let dailyTarget = try await dailyTargetTask
            let opps        = try await oppsTask
            let completedSales = try await completedSalesTask
            let advisorSales = try await advisorSalesTask
 
            // Build AdvisorMetrics from real data
            self.advisorMetrics = AdvisorMetrics(
                id: userId,
                dailyGoal: dailyTarget,
                currentSales: todaySales,
                followUpsDue: taskCounts.pending,
                followUpsCompleted: taskCounts.completed
            )
 
            // Build StoreMetrics from real data
            if let storeId = storeId {
                let sm         = try await storeMetricsTask
                let dailyMetrics = dailyTotals.map {
                    DailyMetric(date: $0.date, value: $0.total)
                }
                self.storeMetrics = StoreMetrics(
                    storeID: storeId,
                    conversionRate: sm != nil && sm!.salesCount > 0
                        ? min(Double(sm!.salesCount) / 10.0 * 100, 100) // proxy: sales/10 as % capped at 100
                        : 0.0,
                    averageOrderValue: sm?.avgOrderValue ?? 0,
                    clientRetentionRate: 0, // No retention data in current schema
                    appointmentConversion: 0, // No appointment data in current schema
                    endlessAisleCaptureRate: 0,
                    dailyConversionHistory: dailyMetrics
                )
                
                // Live Revenue analytics calculations
                calculateRevenueMetrics(sales: completedSales)
            }
            
            // Live Advisor Revenue analytics calculations
            calculateAdvisorRevenueMetrics(sales: advisorSales)
 
            // Appointments come from tasks with task_type = 'Appointment' due today
            async let apptsTask = SalesAssociateService.shared.fetchAppointments(userId: userId)
            let allAppts = try await apptsTask
            self.todayAppointments = allAppts.filter { Calendar.current.isDate($0.date, inSameDayAs: Date()) }
 
            // Active opportunities
            self.activeOpportunities = opps.filter { $0.status == .new }
            
            // Fetch User details to get store_id and shift_id
            if let user = try? await SalesAssociateService.shared.fetchUser(userId: userId) {
                if let storeId = user.storeId {
                    self.userStore = try? await SalesAssociateService.shared.fetchStore(storeId: storeId)
                }
                if let shiftId = user.shiftId {
                    self.userShift = try? await SalesAssociateService.shared.fetchShift(shiftId: shiftId)
                }
            }
            
            // Fetch today's attendance record
            self.todayAttendance = try? await SalesAssociateService.shared.fetchTodayAttendance(employeeId: userId)
            
            // Setup Postgres Realtime change subscriptions (runs once)
            if !isSubscribed {
                Task {
                    await setupRealtimeSubscriptions(userId: userId, storeId: storeId)
                }
            }
 
        } catch {
            errorMessage = "Failed to load dashboard data: \(error.localizedDescription)"
            print("[DashboardViewModel] Error: \(error)")
        }
 
        isLoading = false
    }
 
    private func calculateRevenueMetrics(sales: [Sale]) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // Today's Revenue & Orders Count
        let todaySales = sales.filter { calendar.isDate($0.saleDate, inSameDayAs: today) }
        self.todayRevenue = todaySales.reduce(0.0) { $0 + $1.totalAmount }
        self.todayOrdersCount = todaySales.count
        
        // This Week Revenue & Orders Count (Monday-Sunday)
        var components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today)
        components.weekday = 2 // Monday
        let startOfWeek = calendar.date(from: components)!
        let endOfWeek = calendar.date(byAdding: .day, value: 7, to: startOfWeek)!
        let thisWeekSales = sales.filter { $0.saleDate >= startOfWeek && $0.saleDate < endOfWeek }
        self.thisWeekRevenue = thisWeekSales.reduce(0.0) { $0 + $1.totalAmount }
        self.thisWeekOrdersCount = thisWeekSales.count
        
        // This Month Revenue & Orders Count
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: today))!
        let nextMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth)!
        let thisMonthSales = sales.filter { $0.saleDate >= startOfMonth && $0.saleDate < nextMonth }
        self.thisMonthRevenue = thisMonthSales.reduce(0.0) { $0 + $1.totalAmount }
        self.thisMonthOrdersCount = thisMonthSales.count
        
        // Overall boutique order statistics
        self.totalOrders = sales.count
        self.averageOrderValue = sales.isEmpty ? 0.0 : (sales.reduce(0.0) { $0 + $1.totalAmount } / Double(sales.count))
        
        // Generate Weekly Chart Data (Mon - Sun)
        let weekdays = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
        var tempWeekly: [RevenueDataPoint] = []
        for i in 0..<7 {
            let targetDate = calendar.date(byAdding: .day, value: i, to: startOfWeek)!
            let label = weekdays[i]
            let daySales = sales.filter { calendar.isDate($0.saleDate, inSameDayAs: targetDate) }
            let dayAmount = daySales.reduce(0.0) { $0 + $1.totalAmount }
            tempWeekly.append(RevenueDataPoint(id: UUID(), label: label, amount: dayAmount, date: targetDate, salesCount: daySales.count))
        }
        self.weeklyChartData = tempWeekly
        
        // Generate Monthly Chart Data (Week 1 - Week 4)
        let currentMonthDays = calendar.range(of: .day, in: .month, for: today)?.count ?? 30
        let monthYearComponents = calendar.dateComponents([.year, .month], from: today)
        
        let week1Sales = sales.filter {
            let day = calendar.component(.day, from: $0.saleDate)
            let sameMonth = calendar.component(.month, from: $0.saleDate) == monthYearComponents.month &&
                            calendar.component(.year, from: $0.saleDate) == monthYearComponents.year
            return sameMonth && day >= 1 && day <= 7
        }
        let week2Sales = sales.filter {
            let day = calendar.component(.day, from: $0.saleDate)
            let sameMonth = calendar.component(.month, from: $0.saleDate) == monthYearComponents.month &&
                            calendar.component(.year, from: $0.saleDate) == monthYearComponents.year
            return sameMonth && day >= 8 && day <= 14
        }
        let week3Sales = sales.filter {
            let day = calendar.component(.day, from: $0.saleDate)
            let sameMonth = calendar.component(.month, from: $0.saleDate) == monthYearComponents.month &&
                            calendar.component(.year, from: $0.saleDate) == monthYearComponents.year
            return sameMonth && day >= 15 && day <= 21
        }
        let week4Sales = sales.filter {
            let day = calendar.component(.day, from: $0.saleDate)
            let sameMonth = calendar.component(.month, from: $0.saleDate) == monthYearComponents.month &&
                            calendar.component(.year, from: $0.saleDate) == monthYearComponents.year
            return sameMonth && day >= 22 && day <= currentMonthDays
        }
        
        var tempMonthly: [RevenueDataPoint] = []
        tempMonthly.append(RevenueDataPoint(id: UUID(), label: "Week 1", amount: week1Sales.reduce(0.0) { $0 + $1.totalAmount }, date: startOfMonth, salesCount: week1Sales.count))
        tempMonthly.append(RevenueDataPoint(id: UUID(), label: "Week 2", amount: week2Sales.reduce(0.0) { $0 + $1.totalAmount }, date: calendar.date(byAdding: .day, value: 7, to: startOfMonth)!, salesCount: week2Sales.count))
        tempMonthly.append(RevenueDataPoint(id: UUID(), label: "Week 3", amount: week3Sales.reduce(0.0) { $0 + $1.totalAmount }, date: calendar.date(byAdding: .day, value: 14, to: startOfMonth)!, salesCount: week3Sales.count))
        tempMonthly.append(RevenueDataPoint(id: UUID(), label: "Week 4", amount: week4Sales.reduce(0.0) { $0 + $1.totalAmount }, date: calendar.date(byAdding: .day, value: 21, to: startOfMonth)!, salesCount: week4Sales.count))
        self.monthlyChartData = tempMonthly
    }

    private func calculateAdvisorRevenueMetrics(sales: [Sale]) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // Today's Revenue & Orders Count
        let todaySales = sales.filter { calendar.isDate($0.saleDate, inSameDayAs: today) }
        self.advisorTodayRevenue = todaySales.reduce(0.0) { $0 + $1.totalAmount }
        self.advisorTodayOrdersCount = todaySales.count
        
        // This Week Revenue & Orders Count (Monday-Sunday)
        var components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today)
        components.weekday = 2 // Monday
        let startOfWeek = calendar.date(from: components)!
        let endOfWeek = calendar.date(byAdding: .day, value: 7, to: startOfWeek)!
        let thisWeekSales = sales.filter { $0.saleDate >= startOfWeek && $0.saleDate < endOfWeek }
        self.advisorThisWeekRevenue = thisWeekSales.reduce(0.0) { $0 + $1.totalAmount }
        self.advisorThisWeekOrdersCount = thisWeekSales.count
        
        // This Month Revenue & Orders Count
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: today))!
        let nextMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth)!
        let thisMonthSales = sales.filter { $0.saleDate >= startOfMonth && $0.saleDate < nextMonth }
        self.advisorThisMonthRevenue = thisMonthSales.reduce(0.0) { $0 + $1.totalAmount }
        self.advisorThisMonthOrdersCount = thisMonthSales.count
        
        // Overall advisor order statistics
        self.advisorTotalOrders = sales.count
        self.advisorAverageOrderValue = sales.isEmpty ? 0.0 : (sales.reduce(0.0) { $0 + $1.totalAmount } / Double(sales.count))
        
        // Generate Weekly Chart Data (Mon - Sun)
        let weekdays = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
        var tempWeekly: [RevenueDataPoint] = []
        for i in 0..<7 {
            let targetDate = calendar.date(byAdding: .day, value: i, to: startOfWeek)!
            let label = weekdays[i]
            let daySales = sales.filter { calendar.isDate($0.saleDate, inSameDayAs: targetDate) }
            let dayAmount = daySales.reduce(0.0) { $0 + $1.totalAmount }
            tempWeekly.append(RevenueDataPoint(id: UUID(), label: label, amount: dayAmount, date: targetDate, salesCount: daySales.count))
        }
        self.advisorWeeklyChartData = tempWeekly
        
        // Generate Monthly Chart Data (Week 1 - Week 4)
        let currentMonthDays = calendar.range(of: .day, in: .month, for: today)?.count ?? 30
        let monthYearComponents = calendar.dateComponents([.year, .month], from: today)
        
        let week1Sales = sales.filter {
            let day = calendar.component(.day, from: $0.saleDate)
            let sameMonth = calendar.component(.month, from: $0.saleDate) == monthYearComponents.month &&
                            calendar.component(.year, from: $0.saleDate) == monthYearComponents.year
            return sameMonth && day >= 1 && day <= 7
        }
        let week2Sales = sales.filter {
            let day = calendar.component(.day, from: $0.saleDate)
            let sameMonth = calendar.component(.month, from: $0.saleDate) == monthYearComponents.month &&
                            calendar.component(.year, from: $0.saleDate) == monthYearComponents.year
            return sameMonth && day >= 8 && day <= 14
        }
        let week3Sales = sales.filter {
            let day = calendar.component(.day, from: $0.saleDate)
            let sameMonth = calendar.component(.month, from: $0.saleDate) == monthYearComponents.month &&
                            calendar.component(.year, from: $0.saleDate) == monthYearComponents.year
            return sameMonth && day >= 15 && day <= 21
        }
        let week4Sales = sales.filter {
            let day = calendar.component(.day, from: $0.saleDate)
            let sameMonth = calendar.component(.month, from: $0.saleDate) == monthYearComponents.month &&
                            calendar.component(.year, from: $0.saleDate) == monthYearComponents.year
            return sameMonth && day >= 22 && day <= currentMonthDays
        }
        
        var tempMonthly: [RevenueDataPoint] = []
        tempMonthly.append(RevenueDataPoint(id: UUID(), label: "Week 1", amount: week1Sales.reduce(0.0) { $0 + $1.totalAmount }, date: startOfMonth, salesCount: week1Sales.count))
        tempMonthly.append(RevenueDataPoint(id: UUID(), label: "Week 2", amount: week2Sales.reduce(0.0) { $0 + $1.totalAmount }, date: calendar.date(byAdding: .day, value: 7, to: startOfMonth)!, salesCount: week2Sales.count))
        tempMonthly.append(RevenueDataPoint(id: UUID(), label: "Week 3", amount: week3Sales.reduce(0.0) { $0 + $1.totalAmount }, date: calendar.date(byAdding: .day, value: 14, to: startOfMonth)!, salesCount: week3Sales.count))
        tempMonthly.append(RevenueDataPoint(id: UUID(), label: "Week 4", amount: week4Sales.reduce(0.0) { $0 + $1.totalAmount }, date: calendar.date(byAdding: .day, value: 21, to: startOfMonth)!, salesCount: week4Sales.count))
        self.advisorMonthlyChartData = tempMonthly
    }

    func setupRealtimeSubscriptions(userId: UUID, storeId: UUID?) async {
        guard !isSubscribed else { return }
        isSubscribed = true
        
        do {
            let custCh = await supabase.realtimeV2.channel("customers-dashboard-changes")
            let custChanges = await custCh.postgresChange(
                AnyAction.self,
                schema: "public",
                table: "customers"
            )
            await custCh.subscribe()
            self.customersChannel = custCh
            
            let salesCh = await supabase.realtimeV2.channel("sales-dashboard-changes")
            let salesChanges = await salesCh.postgresChange(
                AnyAction.self,
                schema: "public",
                table: "sales"
            )
            await salesCh.subscribe()
            self.salesChannel = salesCh
            
            Task { [weak self] in
                for await _ in custChanges {
                    print("[DashboardViewModel] Realtime: customers table updated, reloading dashboard...")
                    guard let self = self else { return }
                    await self.loadDashboardData(userId: userId, storeId: storeId)
                }
            }
            
            Task { [weak self] in
                for await _ in salesChanges {
                    print("[DashboardViewModel] Realtime: sales table updated, reloading dashboard...")
                    guard let self = self else { return }
                    await self.loadDashboardData(userId: userId, storeId: storeId)
                }
            }
        } catch {
            print("[DashboardViewModel] Realtime subscription error: \(error)")
        }
    }

    // MARK: - Opportunity Actions

    func dismissOpportunity(_ id: UUID) {
        if let index = activeOpportunities.firstIndex(where: { $0.id == id }) {
            activeOpportunities[index].status = .dismissed
            activeOpportunities.remove(at: index)
        }
    }

    func convertOpportunity(_ id: UUID) {
        if let index = activeOpportunities.firstIndex(where: { $0.id == id }) {
            activeOpportunities[index].status = .converted
            activeOpportunities.remove(at: index)
        }
    }
}
