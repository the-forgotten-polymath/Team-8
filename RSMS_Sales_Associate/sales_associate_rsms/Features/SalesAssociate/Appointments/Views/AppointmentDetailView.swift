// AppointmentDetailView.swift
// RSMS — Sales Associate Module

import SwiftUI

struct AppointmentDetailView: View {
    let appointment: Appointment
    
    @State private var customer: Customer? = nil
    @State private var isLoadingCustomer = false
    @State private var appointmentStatus: AppointmentStatus = .scheduled
    @State private var isMarkingDone = false
    @State private var alertErrorMessage: String? = nil
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Client Briefing Card
                VStack(alignment: .leading, spacing: 12) {
                    Text("Pre-Appointment Briefing")
                        .font(.headline)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text(appointment.clientName ?? "Unknown Client")
                            .font(.title3.bold())
                        
                        Divider()
                        
                        if isLoadingCustomer {
                            HStack {
                                Spacer()
                                ProgressView("Loading client info...")
                                Spacer()
                            }
                            .padding(.vertical, 8)
                        } else if let cust = customer {
                            VStack(alignment: .leading, spacing: 8) {
                                DetailRow(label: "Phone", value: cust.phone)
                                DetailRow(label: "Email", value: cust.email)
                                DetailRow(label: "Tier", value: cust.customerTier ?? "Silver Member")
                                DetailRow(label: "Status", value: cust.customerStatus ?? "Active")
                                
                                if let prefBrand = cust.preferredBrand {
                                    DetailRow(label: "Preferred Brand", value: prefBrand)
                                }
                                if let prefCat = cust.preferredCategory {
                                    DetailRow(label: "Preferred Category", value: prefCat)
                                }
                                if let notes = cust.notes {
                                    Divider()
                                    Text("Client Preferences & Notes")
                                        .font(.caption.bold())
                                        .foregroundColor(.secondary)
                                    Text(notes)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            }
                        } else {
                            Text("No additional details found in customer profile.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
                
                // Appointment Context
                VStack(alignment: .leading, spacing: 12) {
                    Text("Appointment Details")
                        .font(.headline)
                    
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Label(appointment.date.formatted(date: .abbreviated, time: .shortened), systemImage: "clock")
                            Spacer()
                            Text(appointment.type.displayName)
                                .foregroundColor(.secondary)
                        }
                        
                        Divider()
                        
                        HStack {
                            Text("Current Status")
                                .font(.subheadline.bold())
                            Spacer()
                            Text(appointmentStatus.displayName)
                                .font(.subheadline.bold())
                                .foregroundColor(appointmentStatus == .completed ? .green : .blue)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(appointmentStatus == .completed ? Color.green.opacity(0.12) : Color.blue.opacity(0.12))
                                .cornerRadius(8)
                        }
                        
                        if let notes = appointment.notes {
                            Divider()
                            Text("Notes")
                                .font(.subheadline.bold())
                            Text(notes)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
                
                // Appointment Actions
                VStack(alignment: .leading, spacing: 12) {
                    if appointmentStatus != .completed {
                        Button(action: {
                            Task {
                                await markAsDone()
                            }
                        }) {
                            if isMarkingDone {
                                HStack {
                                    ProgressView()
                                        .tint(.white)
                                    Text("Saving Status...")
                                }
                                .font(.headline.bold())
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.green.opacity(0.6))
                                .foregroundColor(.white)
                                .cornerRadius(12)
                            } else {
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                    Text("Appointment Done")
                                }
                                .font(.headline.bold())
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                                .shadow(color: Color.green.opacity(0.3), radius: 4, x: 0, y: 2)
                            }
                        }
                        .disabled(isMarkingDone)
                        .buttonStyle(.plain)
                    } else {
                        HStack {
                            Spacer()
                            VStack(spacing: 8) {
                                Image(systemName: "checkmark.seal.fill")
                                    .font(.system(size: 32))
                                    .foregroundColor(.green)
                                Text("Appointment Completed Successfully")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.green)
                            }
                            Spacer()
                        }
                        .padding()
                        .background(Color.green.opacity(0.08))
                        .cornerRadius(12)
                    }
                }
                .padding(.top, 16)
            }
            .padding()
        }
        .navigationTitle("Appointment Details")
        .navigationBarTitleDisplayMode(.inline)
        .alert(item: Binding<AlertError?>(
            get: { alertErrorMessage.map { AlertError(message: $0) } },
            set: { alertErrorMessage = $0?.message }
        )) { err in
            Alert(
                title: Text("Error"),
                message: Text(err.message),
                dismissButton: .default(Text("OK"))
            )
        }
        .task {
            appointmentStatus = appointment.status
            await loadCustomerDetails()
        }
    }
    
    struct AlertError: Identifiable {
        let id = UUID()
        let message: String
    }
    
    struct DetailRow: View {
        let label: String
        let value: String
        
        var body: some View {
            HStack(alignment: .top) {
                Text(label)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
                Text(value)
                    .font(.subheadline.bold())
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.trailing)
            }
        }
    }
    
    private func loadCustomerDetails() async {
        isLoadingCustomer = true
        do {
            self.customer = try await SalesAssociateService.shared.fetchCustomer(id: appointment.clientId)
        } catch {
            print("Failed to load customer profile details: \(error)")
        }
        isLoadingCustomer = false
    }
    
    private func markAsDone() async {
        isMarkingDone = true
        defer { isMarkingDone = false }
        
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        do {
            try await SalesAssociateService.shared.updateAppointmentStatus(appointmentId: appointment.id, status: "completed")
            appointmentStatus = .completed
        } catch {
            alertErrorMessage = "Failed to update appointment status: \(error.localizedDescription)"
        }
    }
}
