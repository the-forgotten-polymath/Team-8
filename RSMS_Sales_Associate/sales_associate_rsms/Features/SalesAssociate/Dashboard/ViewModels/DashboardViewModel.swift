// DashboardViewModel.swift
// RSMS — Sales Associate Module

import SwiftUI
import Combine

@MainActor
class DashboardViewModel: ObservableObject {
    @Published var activeOpportunities: [Opportunity] = []
    @Published var advisorMetrics: AdvisorMetrics?
    @Published var storeMetrics: StoreMetrics?
    @Published var todayAppointments: [Appointment] = []

    @Published var isLoading = false
    @Published var errorMessage: String? = nil

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

            // Await all concurrently
            let todaySales  = try await todaySalesTask
            let taskCounts  = try await taskCountsTask
            let dailyTotals = try await dailyTotalsTask
            let dailyTarget = try await dailyTargetTask
            let opps        = try await oppsTask

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
            }

            // Appointments come from tasks with task_type = 'Appointment' due today
            async let apptsTask = SalesAssociateService.shared.fetchAppointments(userId: userId)
            let allAppts = try await apptsTask
            self.todayAppointments = allAppts.filter { Calendar.current.isDate($0.date, inSameDayAs: Date()) }

            // Active opportunities
            self.activeOpportunities = opps.filter { $0.status == .new }

        } catch {
            errorMessage = "Failed to load dashboard data: \(error.localizedDescription)"
            print("[DashboardViewModel] Error: \(error)")
        }

        isLoading = false
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
