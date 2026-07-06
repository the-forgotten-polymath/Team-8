// AppointmentsViewModel.swift
// RSMS — Sales Associate Module

import Foundation
import Combine

@MainActor
class AppointmentsViewModel: ObservableObject {
    @Published var appointments: [Appointment] = []
    @Published var isLoading = false
    @Published var errorMessage: String? = nil
    
    func fetchAppointments(userId: UUID?) async {
        guard let userId = userId else {
            errorMessage = "User not logged in."
            return
        }
        
        isLoading = true
        errorMessage = nil
        do {
            if AppConstants.useMockData {
                try await Task.sleep(nanoseconds: 500_000_000)
                self.appointments = MockData.appointments
            } else {
                self.appointments = try await SalesAssociateService.shared.fetchAppointments(userId: userId)
            }
        } catch {
            self.errorMessage = "Failed to load appointments: \(error.localizedDescription)"
        }
        isLoading = false
    }
}
