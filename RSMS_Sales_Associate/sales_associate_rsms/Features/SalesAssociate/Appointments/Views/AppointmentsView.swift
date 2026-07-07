// AppointmentsView.swift
// RSMS — Sales Associate Module

import SwiftUI

struct AppointmentsView: View {
    var isEmbedded: Bool = false
    @EnvironmentObject private var authVM: AuthViewModel
    @StateObject private var viewModel = AppointmentsViewModel()
    @State private var showingCreateAppointment = false
    
    var body: some View {
        if isEmbedded {
            mainContent
        } else {
            NavigationStack {
                mainContent
            }
        }
    }
    
    private var mainContent: some View {
        ScrollView {
            VStack(spacing: 16) {
                if viewModel.isLoading {
                    ProgressView("Loading...")
                        .padding()
                } else if viewModel.appointments.isEmpty {
                    Text("No appointments found.")
                        .foregroundColor(.secondary)
                        .padding()
                } else {
                    ForEach(viewModel.appointments) { appointment in
                        NavigationLink(destination: AppointmentDetailView(appointment: appointment)) {
                            AppointmentRowView(appointment: appointment)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding()
                        .liquidGlass()
                    }
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationTitle("Appointments")
        .toolbar(.hidden, for: .tabBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    showingCreateAppointment = true
                }) {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingCreateAppointment) {
            // Need to pass viewModel.appointments as binding, but better to fetch after
            CreateAppointmentView(appointments: $viewModel.appointments)
        }
        .task {
            await viewModel.fetchAppointments(userId: authVM.currentUser?.id)
        }
        .refreshable {
            await viewModel.fetchAppointments(userId: authVM.currentUser?.id)
        }
    }
}


struct AppointmentRowView: View {
    let appointment: Appointment
    
    var body: some View {
        HStack(spacing: 16) {
            // Initials avatar matching Client Hub
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 44, height: 44)
                Text(clientInitials(for: appointment))
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.blue)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(clientName(for: appointment))
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(appointment.type.displayName)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text(appointment.date, format: .dateTime.hour().minute().day().month())
                    .font(.caption)
                    .foregroundColor(.blue)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 6) {
                Text(appointment.status.rawValue)
                    .font(.system(size: 11, weight: .medium))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(statusColor(appointment.status).opacity(0.1))
                    .foregroundColor(statusColor(appointment.status))
                    .clipShape(Capsule())
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color(.systemGray4))
            }
        }
        .padding(.vertical, 6)
    }
    
    private func clientInitials(for appointment: Appointment) -> String {
        let name = appointment.clientName ?? "Unknown Client"
        let parts = name.split(separator: " ")
        if parts.count >= 2 {
            return "\(parts[0].prefix(1))\(parts[1].prefix(1))"
        }
        return "\(name.prefix(2))"
    }
    
    private func clientName(for appointment: Appointment) -> String {
        return appointment.clientName ?? "Unknown Client"
    }
    
    private func statusColor(_ status: AppointmentStatus) -> Color {
        switch status {
        case .scheduled, .confirmed: return .blue
        case .inProgress: return .orange
        case .completed: return .green
        case .cancelled, .noShow: return .red
        }
    }
}
