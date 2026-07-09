// AddClientView.swift
// RSMS — Sales Associate Module

import SwiftUI

struct AddClientView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject private var authVM: AuthViewModel
    var onRegistrationSuccess: ((ClientDigitalTwin) -> Void)? = nil
    
    // Basic Information
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var email = ""
    @State private var phone = ""
    
    // Demographics & Preferences
    @State private var gender = "Female"
    @State private var dateOfBirth = Date()
    @State private var hasAnniversary = false
    @State private var anniversaryDate = Date()
    @State private var preferredBrand = ""
    @State private var preferredCategory = "Watches"
    @State private var preferredContactMethod = "Email"
    
    // Categorization Inputs
    @State private var monthlySpend = ""
    @State private var purchasesPerMonth = "0"
    
    // Consent & Notes
    @State private var privacyConsent = true
    @State private var notes = ""
    
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    // Helper to calculate tier in real-time for display
    private var calculatedTier: CustomerTier {
        let spend = Decimal(string: monthlySpend) ?? 0
        let purchases = Int(purchasesPerMonth) ?? 0
        return CustomerTier.compute(spend: spend, purchasesPerMonth: purchases)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Basic Information")) {
                    TextField("First Name (Required)", text: $firstName)
                        .foregroundColor(.primary)
                    TextField("Last Name", text: $lastName)
                        .foregroundColor(.primary)
                    TextField("Email (Required)", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .foregroundColor(.primary)
                    TextField("Phone (Required)", text: $phone)
                        .keyboardType(.phonePad)
                        .foregroundColor(.primary)
                }
                .listRowBackground(Color(.secondarySystemGroupedBackground))
                
                Section(header: Text("Demographics & Preferences")) {
                    Picker("Gender", selection: $gender) {
                        Text("Male").tag("Male")
                        Text("Female").tag("Female")
                        Text("Other").tag("Other")
                        Text("Prefer not to say").tag("Prefer not to say")
                    }
                    .pickerStyle(.navigationLink)
                    
                    DatePicker("Date of Birth", selection: $dateOfBirth, displayedComponents: .date)
                    
                    Toggle("Has Anniversary Date", isOn: $hasAnniversary)
                    
                    if hasAnniversary {
                        DatePicker("Anniversary Date", selection: $anniversaryDate, displayedComponents: .date)
                    }
                    
                    TextField("Preferred Brand", text: $preferredBrand)
                        .foregroundColor(.primary)
                    
                    Picker("Preferred Category", selection: $preferredCategory) {
                        ForEach(ProductCategory.allCases, id: \.self) { cat in
                            Text(cat.rawValue).tag(cat.rawValue)
                        }
                    }
                    .pickerStyle(.navigationLink)
                }
                .listRowBackground(Color(.secondarySystemGroupedBackground))
                
                Section(header: Text("Communication")) {
                    Picker("Contact Method", selection: $preferredContactMethod) {
                        Text("Email").tag("Email")
                        Text("SMS").tag("SMS")
                        Text("WhatsApp").tag("WhatsApp")
                    }
                    .pickerStyle(.segmented)
                }
                .listRowBackground(Color(.secondarySystemGroupedBackground))
                
                Section(header: Text("Notes")) {
                    TextField("Customer profile notes, sizes or custom details...", text: $notes)
                        .foregroundColor(.primary)
                }
                .listRowBackground(Color(.secondarySystemGroupedBackground))
                
                if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.subheadline)
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
                        .disabled(firstName.trimmingCharacters(in: .whitespaces).isEmpty ||
                                  email.trimmingCharacters(in: .whitespaces).isEmpty ||
                                  phone.trimmingCharacters(in: .whitespaces).isEmpty ||
                                  isLoading)
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
            
            // Email and Phone constraints
            let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
            let trimmedPhone = phone.trimmingCharacters(in: .whitespacesAndNewlines)
            
            guard trimmedEmail.contains("@") && trimmedEmail.contains(".") else {
                errorMessage = "Invalid Email: Must match name@domain.com format."
                isLoading = false
                UINotificationFeedbackGenerator().notificationOccurred(.error)
                return
            }
            
            let phoneDigits = trimmedPhone.filter { $0.isNumber }
            guard phoneDigits.count >= 10 else {
                errorMessage = "Invalid Phone: Must contain at least 10 digits."
                isLoading = false
                UINotificationFeedbackGenerator().notificationOccurred(.error)
                return
            }
            
            do {
                let spendDecimal: Decimal = 0
                let purchasesCount = 0
                let calculatedTier = CustomerTier.standard
                
                let selectedCategoryEnum = ProductCategory(rawValue: preferredCategory)
                
                let newClient = ClientDigitalTwin(
                    id: UUID(),
                    customerID: nil,
                    firstName: firstName,
                    lastName: lastName,
                    email: email.trimmingCharacters(in: .whitespaces).isEmpty ? nil : email,
                    phone: phone.trimmingCharacters(in: .whitespaces).isEmpty ? nil : phone,
                    dateOfBirth: dateOfBirth,
                    gender: gender,
                    anniversaryDate: hasAnniversary ? anniversaryDate : nil,
                    tier: calculatedTier,
                    lifetimeSpend: spendDecimal,
                    preferredStore: authVM.userStoreID,
                    preferredAdvisor: authVM.currentUser?.id,
                    createdAt: Date(),
                    updatedAt: Date(),
                    preferences: ClientPreferences(
                        clientID: UUID(),
                        preferredBrands: preferredBrand.isEmpty ? [] : [preferredBrand],
                        preferredCategories: selectedCategoryEnum.map { [$0] } ?? [],
                        preferredColors: [],
                        preferredMaterials: [],
                        communicationChannel: mapContactMethod(preferredContactMethod),
                        languagePreference: "en",
                        shoppingOccasions: [],
                        anniversaryDate: hasAnniversary ? anniversaryDate : nil,
                        birthdayDate: dateOfBirth,
                        notes: notes.isEmpty ? nil : notes,
                        sizes: nil
                    ),
                    events: nil,
                    ownedProducts: nil,
                    wishlistItems: nil,
                    consentStatus: ConsentRecord(
                        clientID: UUID(),
                        marketingEmail: privacyConsent,
                        marketingSMS: privacyConsent,
                        marketingWhatsApp: false,
                        marketingPush: privacyConsent,
                        dataProcessing: privacyConsent,
                        profilingForRecommendations: privacyConsent,
                        consentDate: Date(),
                        consentVersion: "v1.0",
                        withdrawnDate: nil
                    ),
                    gdprFlags: GDPRFlags(
                        clientID: UUID(),
                        canStore: privacyConsent,
                        canProcess: privacyConsent,
                        canProfile: privacyConsent,
                        rightToErasureRequested: false,
                        exportRequested: false
                    )
                )
                
                let createdClient = try await ClientDigitalTwinService.shared.createClient(
                    newClient,
                    preferences: newClient.preferences,
                    sizes: nil
                )
                
                isLoading = false
                if let onRegistrationSuccess = onRegistrationSuccess {
                    onRegistrationSuccess(createdClient)
                }
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
                isLoading = false
            }
        }
    }
    
    private func mapContactMethod(_ method: String) -> CommunicationChannel {
        switch method.lowercased() {
        case "sms":       return .sms
        case "email":     return .email
        case "whatsapp":  return .whatsapp
        case "push":      return .push
        default:          return .email
        }
    }
}

