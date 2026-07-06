// AddClientView.swift
// RSMS — Sales Associate Module

import SwiftUI

struct AddClientView: View {
    @Environment(\.dismiss) var dismiss
    
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Basic Information")) {
                    TextField("First Name", text: $firstName)
                        .foregroundColor(.primary)
                    TextField("Last Name", text: $lastName)
                        .foregroundColor(.primary)
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .foregroundColor(.primary)
                    TextField("Phone", text: $phone)
                        .keyboardType(.phonePad)
                        .foregroundColor(.primary)
                }
                .listRowBackground(Color(.secondarySystemGroupedBackground))
                
                if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                    }
                    .listRowBackground(Color.clear)
                }
            }
            .navigationTitle("New Client")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.secondary)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") { saveClient() }
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                        .disabled(firstName.isEmpty || lastName.isEmpty || isLoading)
                }
            }
            .overlay(
                isLoading ?
                Color.black.opacity(0.25).ignoresSafeArea().overlay(ProgressView().tint(.blue))
                : nil
            )
        }
    }
    
    private func saveClient() {
        Task {
            isLoading = true
            errorMessage = nil
            do {
                let newClient = ClientDigitalTwin(
                    id: UUID(),
                    customerID: nil,
                    firstName: firstName,
                    lastName: lastName,
                    email: email.isEmpty ? nil : email,
                    phone: phone.isEmpty ? nil : phone,
                    dateOfBirth: nil,
                    tier: .standard,
                    lifetimeSpend: 0.0,
                    preferredStore: nil,
                    preferredAdvisor: nil,
                    createdAt: Date(),
                    updatedAt: Date()
                )
                
                _ = try await ClientDigitalTwinService.shared.createClient(newClient, preferences: nil, sizes: nil)
                
                isLoading = false
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
                isLoading = false
            }
        }
    }
}
