// CreateAppointmentView.swift
// RSMS — Sales Associate Module

import SwiftUI

struct CreateAppointmentView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var appointments: [Appointment]
    
    @State private var selectedClient: UUID?
    @State private var selectedDate: Date = Date().addingTimeInterval(86400)
    @State private var selectedType: AppointmentType = .inStore
    @State private var notes: String = ""
    
    let clients = MockData.clients
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Client Details")) {
                    Picker("Client", selection: $selectedClient) {
                        Text("Select a Client").tag(UUID?.none)
                        ForEach(clients) { client in
                            Text(client.fullName).tag(UUID?.some(client.id))
                        }
                    }
                }
                
                Section(header: Text("Appointment Details")) {
                    DatePicker("Date & Time", selection: $selectedDate, in: Date()...)
                    
                    Picker("Type", selection: $selectedType) {
                        ForEach(AppointmentType.allCases, id: \.self) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                }
                
                Section(header: Text("Notes (Optional)")) {
                    TextEditor(text: $notes)
                        .frame(height: 100)
                }
            }
            .navigationTitle("New Appointment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        if let clientId = selectedClient {
                            let newAppt = Appointment(
                                clientId: clientId,
                                associateId: UUID(), // Mock associate ID
                                date: selectedDate,
                                type: selectedType,
                                notes: notes.isEmpty ? nil : notes
                            )
                            appointments.append(newAppt)
                            // In real app, sort by date and save to backend
                            appointments.sort { $0.date < $1.date }
                            dismiss()
                        }
                    }
                    .disabled(selectedClient == nil)
                }
            }
        }
    }
}
