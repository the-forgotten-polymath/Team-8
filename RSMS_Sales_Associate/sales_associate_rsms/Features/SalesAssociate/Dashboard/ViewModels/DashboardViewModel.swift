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
    
    func loadDashboardData() async {
        isLoading = true
        do {
            // Mock network delay
            try await Task.sleep(nanoseconds: 600_000_000)
            
            // Fetch data from MockData
            self.activeOpportunities = MockData.opportunities.filter { $0.status == .new }
            self.advisorMetrics = MockData.advisorMetrics
            self.storeMetrics = MockData.storeMetrics
            
            let today = Date()
            self.todayAppointments = MockData.appointments.filter {
                Calendar.current.isDate($0.date, inSameDayAs: today)
            }
        } catch {
            print("Failed to load dashboard data: \(error)")
        }
        isLoading = false
    }
    
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
