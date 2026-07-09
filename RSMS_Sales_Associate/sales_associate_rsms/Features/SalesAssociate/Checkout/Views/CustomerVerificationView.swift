// CustomerVerificationView.swift
// RSMS — Sales Associate Module

import SwiftUI
import Supabase
import Combine

struct CustomerVerificationView: View {
    @EnvironmentObject var checkoutEnv: CheckoutEnvironment
    @StateObject private var viewModel = CustomerVerificationViewModel()
    @State private var showingRegistrationSheet = false
    @State private var navigateToBillSummary = false
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 20) {
                    // Header Block
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Customer Verification")
                            .font(.largeTitle.bold())
                        Text("Enter the customer's phone number to retrieve or register their loyalty profile.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    .padding(.top, 16)
                    
                    // Lookup Input
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Phone Number")
                            .font(.caption.bold())
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 12) {
                            HStack {
                                Image(systemName: "phone.fill")
                                    .foregroundColor(.secondary)
                                TextField("e.g. +91 99999 99999", text: $viewModel.phoneNumber)
                                    .keyboardType(.phonePad)
                                    .foregroundColor(.primary)
                            }
                            .padding()
                            .background(Color(.secondarySystemGroupedBackground))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.appleBorder, lineWidth: 1)
                            )
                            
                            Button(action: {
                                Task {
                                    await viewModel.lookupCustomer()
                                }
                            }) {
                                if viewModel.isLoading {
                                    ProgressView()
                                        .tint(.white)
                                        .frame(width: 48, height: 48)
                                        .background(Color.blue)
                                        .cornerRadius(12)
                                } else {
                                    Image(systemName: "magnifyingglass")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                        .frame(width: 48, height: 48)
                                        .background(viewModel.phoneNumber.isEmpty ? Color.gray : Color.blue)
                                        .cornerRadius(12)
                                }
                            }
                            .disabled(viewModel.phoneNumber.isEmpty || viewModel.isLoading)
                        }
                    }
                    if !viewModel.recommendations.isEmpty && !viewModel.searched {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Matching Customers")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 4)
                            
                            ForEach(viewModel.recommendations) { suggestion in
                                Button(action: {
                                    viewModel.phoneNumber = suggestion.phone
                                    Task {
                                        await viewModel.lookupCustomer()
                                    }
                                }) {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(suggestion.name)
                                                .font(.system(size: 15, weight: .semibold))
                                                .foregroundColor(.primary)
                                            Text(suggestion.phone)
                                                .font(.system(size: 12))
                                                .foregroundColor(.secondary)
                                        }
                                        Spacer()
                                        Image(systemName: "plus.circle.fill")
                                            .foregroundColor(.blue)
                                    }
                                    .padding(12)
                                    .background(Color(.secondarySystemGroupedBackground))
                                    .cornerRadius(10)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    if viewModel.searched {
                        if let client = viewModel.customer {
                            // Customer Card
                            VStack(alignment: .leading, spacing: 16) {
                                HStack(spacing: 16) {
                                    Circle()
                                        .fill(LinearGradient(colors: [Color(hex: "C9A84C"), Color(hex: "9B7B25")], startPoint: .topLeading, endPoint: .bottomTrailing))
                                        .frame(width: 60, height: 60)
                                        .overlay(
                                            Text(client.initials)
                                                .font(.title2.bold())
                                                .foregroundColor(.white)
                                        )
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(client.fullName)
                                            .font(.title3.bold())
                                        
                                        HStack(spacing: 6) {
                                            ClientTierBadgeView(tier: client.tier)
                                            if let points = client.consentStatus?.marketingPush == true ? 150 : 0 {
                                                Text("Points: \(points)")
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                                    .padding(.horizontal, 8)
                                                    .padding(.vertical, 2)
                                                    .background(Color(.systemGray5))
                                                    .cornerRadius(6)
                                            }
                                        }
                                    }
                                    Spacer()
                                }
                                
                                Divider()
                                
                                // Editable Fields Section
                                VStack(spacing: 12) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Email Address")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        TextField("Email Address", text: $viewModel.email)
                                            .textFieldStyle(.roundedBorder)
                                            .keyboardType(.emailAddress)
                                            .autocapitalization(.none)
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Shipping Address")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        TextField("Enter Shipping Address", text: $viewModel.address)
                                            .textFieldStyle(.roundedBorder)
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Profile Notes")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        TextField("Notes...", text: $viewModel.notes)
                                            .textFieldStyle(.roundedBorder)
                                    }
                                }
                            }
                            .padding()
                            .background(Color(.secondarySystemGroupedBackground))
                            .cornerRadius(16)
                            .shadow(color: Color.black.opacity(0.04), radius: 8, y: 4)
                            .padding(.horizontal)
                        } else {
                            // Customer not found card
                            VStack(spacing: 16) {
                                Image(systemName: "person.fill.badge.plus")
                                    .font(.system(size: 40))
                                    .foregroundColor(.secondary)
                                
                                Text("Customer not found.")
                                    .font(.headline)
                                
                                Text("This phone number is not registered in our database. You can quickly register them to continue.")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 24)
                                
                                Button(action: {
                                    showingRegistrationSheet = true
                                }) {
                                    Text("Register Customer")
                                        .fontWeight(.semibold)
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 24)
                                        .padding(.vertical, 12)
                                        .background(Color.blue)
                                        .cornerRadius(10)
                                }
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color(.secondarySystemGroupedBackground))
                            .cornerRadius(16)
                            .shadow(color: Color.black.opacity(0.04), radius: 8, y: 4)
                            .padding(.horizontal)
                        }
                    }
                    
                    if let error = viewModel.errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding(.horizontal)
                    }
                }
            }
            
            // Sticky proceed button
            if let _ = viewModel.customer {
                VStack {
                    Button(action: {
                        Task {
                            let success = await viewModel.saveEdits()
                            if success {
                                navigateToBillSummary = true
                            }
                        }
                    }) {
                        Text("Confirm & Proceed")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .cornerRadius(12)
                    }
                    .padding()
                }
                .background(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 5, y: -3)
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Verification")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .sheet(isPresented: $showingRegistrationSheet) {
            AddClientView(onRegistrationSuccess: { newClient in
                viewModel.customer = newClient
                viewModel.email = newClient.email ?? ""
                viewModel.address = newClient.address ?? ""
                viewModel.notes = newClient.preferences?.notes ?? ""
                viewModel.searched = true
                
                // Automatically go to Bill Summary View
                navigateToBillSummary = true
            })
        }
        .navigationDestination(isPresented: $navigateToBillSummary) {
            if let client = viewModel.customer {
                BillSummaryView(customer: client)
            }
        }
        .onChange(of: viewModel.phoneNumber) { _ in
            Task {
                await viewModel.updateRecommendations()
            }
        }
    }
}

@MainActor
class CustomerVerificationViewModel: ObservableObject {
    @Published var phoneNumber: String = ""
    @Published var isLoading: Bool = false
    @Published var searched: Bool = false
    @Published var customer: ClientDigitalTwin? = nil
    
    // Editable customer details
    @Published var email: String = ""
    @Published var address: String = ""
    @Published var notes: String = ""
    
    @Published var errorMessage: String? = nil
    @Published var recommendations: [CustomerSuggestion] = []
    
    struct CustomerSuggestion: Identifiable, Equatable {
        let id: UUID
        let name: String
        let phone: String
    }
    
    func updateRecommendations() async {
        let queryText = phoneNumber.trimmingCharacters(in: .whitespacesAndNewlines)
        guard queryText.count >= 3 else {
            self.recommendations = []
            return
        }
        
        do {
            if AppConstants.useMockData {
                let suggestions = MockData.clients.filter {
                    ($0.phone ?? "").contains(queryText)
                }.map {
                    CustomerSuggestion(id: $0.id, name: $0.fullName, phone: $0.phone ?? "")
                }
                self.recommendations = suggestions
            } else {
                struct CustomSuggestionRow: Decodable {
                    let id: UUID
                    let name: String
                    let phone: String
                }
                let results: [CustomSuggestionRow] = (try? await supabase
                    .from("customers")
                    .select("id, name, phone")
                    .ilike("phone", value: "%\(queryText)%")
                    .limit(5)
                    .execute()
                    .value) ?? []
                self.recommendations = results.map {
                    CustomerSuggestion(id: $0.id, name: $0.name, phone: $0.phone)
                }
            }
        } catch {
            print("Failed to get recommendations: \(error)")
        }
    }
    
    func lookupCustomer() async {
        isLoading = true
        errorMessage = nil
        searched = false
        customer = nil
        
        do {
            if AppConstants.useMockData {
                try await Task.sleep(nanoseconds: 500_000_000)
                let cleanPhone = phoneNumber.replacingOccurrences(of: " ", with: "").replacingOccurrences(of: "-", with: "")
                if let found = MockData.clients.first(where: {
                    let cPhone = ($0.phone ?? "").replacingOccurrences(of: " ", with: "").replacingOccurrences(of: "-", with: "")
                    return cPhone == cleanPhone || ($0.phone ?? "") == phoneNumber
                }) {
                    self.customer = found
                    self.email = found.email ?? ""
                    self.address = found.address ?? ""
                    self.notes = found.preferences?.notes ?? ""
                }
                searched = true
            } else {
                let cleanPhone = phoneNumber.trimmingCharacters(in: .whitespacesAndNewlines)
                let results: [Customer] = try await supabase
                    .from("customers")
                    .select()
                    .eq("phone", value: cleanPhone)
                    .limit(1)
                    .execute()
                    .value
                
                if let found = results.first {
                    let twin = ClientDigitalTwinService.shared.mapCustomerToTwin(found)
                    self.customer = twin
                    self.email = twin.email ?? ""
                    self.address = twin.address ?? ""
                    self.notes = twin.preferences?.notes ?? ""
                }
                searched = true
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
    
    func saveEdits() async -> Bool {
        guard let cust = customer else { return true }
        isLoading = true
        errorMessage = nil
        
        do {
            let compositeNotes = "Address: \(address)\n\(notes)"
            if !AppConstants.useMockData {
                let updates: [String: AnyJSON] = [
                    "email": .string(email),
                    "notes": .string(compositeNotes)
                ]
                try await ClientDigitalTwinService.shared.updateClient(clientID: cust.id, updates: updates)
            }
            
            // Update the local instance in cart
            var updatedCust = cust
            updatedCust.email = email
            updatedCust.address = address
            updatedCust.preferences?.notes = notes
            self.customer = updatedCust
            isLoading = false
            return true
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
            return false
        }
    }
}
