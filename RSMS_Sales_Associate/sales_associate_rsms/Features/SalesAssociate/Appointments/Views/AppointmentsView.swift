// AppointmentsView.swift
// RSMS — Sales Associate Module

import SwiftUI

struct AppointmentsView: View {
    var isEmbedded: Bool = false
    @State private var showingCreateAppointment = false
    @State private var appointments = MockData.appointments
    
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
        List {
            ForEach(appointments) { appointment in
                NavigationLink(destination: AppointmentDetailView(appointment: appointment)) {
                    AppointmentRowView(appointment: appointment)
                }
            }
        }
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
            CreateAppointmentView(appointments: $appointments)
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
                Text(clientInitials(for: appointment.clientId))
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.blue)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(clientName(for: appointment.clientId))
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
    
    private func clientInitials(for id: UUID) -> String {
        guard let client = MockData.clients.first(where: { $0.id == id }) else { return "??" }
        return "\(client.firstName.prefix(1))\(client.lastName.prefix(1))"
    }
    
    private func clientName(for id: UUID) -> String {
        return MockData.clients.first(where: { $0.id == id })?.fullName ?? "Unknown Client"
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
