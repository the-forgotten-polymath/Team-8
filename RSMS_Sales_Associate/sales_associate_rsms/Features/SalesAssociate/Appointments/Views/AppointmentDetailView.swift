// AppointmentDetailView.swift
// RSMS — Sales Associate Module

import SwiftUI

struct AppointmentDetailView: View {
    let appointment: Appointment
    @State private var showingCuratedCartBuilder = false
    
    // client property removed since we're using appointment.clientName
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Client Briefing Card
                VStack(alignment: .leading, spacing: 12) {
                    Text("Pre-Appointment Briefing")
                        .font(.headline)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text(appointment.clientName ?? "Unknown Client")
                            .font(.title3.bold())
                        
                        Divider()
                        
                        Text("Preferences")
                            .font(.subheadline.bold())
                        
                        HStack {
                            Text("Language: English")
                            Spacer()
                            Text("Contact: Email")
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
                
                // Appointment Context
                VStack(alignment: .leading, spacing: 12) {
                    Text("Details")
                        .font(.headline)
                    
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Label(appointment.date.formatted(date: .abbreviated, time: .shortened), systemImage: "clock")
                            Spacer()
                            Text(appointment.type.displayName)
                                .foregroundColor(.secondary)
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
                
                // Curated Cart Action
                VStack(alignment: .leading, spacing: 12) {
                    Text("Remote Selling")
                        .font(.headline)
                    
                    Button(action: {
                        showingCuratedCartBuilder = true
                    }) {
                        HStack {
                            Image(systemName: "bag.badge.plus")
                            Text("Create Curated Cart")
                        }
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    
                    Text("Build a personalized selection of items and share it securely with the client before or after the appointment.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding(.top, 16)
            }
            .padding()
        }
        .navigationTitle("Appointment")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingCuratedCartBuilder) {
            CuratedCartBuilderView(appointment: appointment)
        }
    }
}
