//
//  EmployeeRegistrationView.swift
//  RSMS_Project
//
//  Created by Yatharth Mishra on 30/06/26.
//

import SwiftUI
import PhotosUI
import Supabase

struct EmployeeRegistrationView: View {
    @Environment(\.dismiss) private var dismiss

    // Core state
    @State private var employeeId = "EMP-" + String(UUID().uuidString.prefix(6)).uppercased()
    
    // Form fields
    @State private var fullName = ""
    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    @State private var profilePhotoData: Data? = nil
    @State private var gender = "Male"
    @State private var dateOfBirth = Calendar.current.date(byAdding: .year, value: -18, to: Date()) ?? Date()
    
    private var maxDOB: Date {
        Calendar.current.date(byAdding: .year, value: -18, to: Date()) ?? Date()
    }
    
    @State private var mobileNumber = ""
    @State private var email = ""
    
    @State private var address = ""
    
    @State private var jobRole = "Sales Associate"
    @State private var selectedShiftId: UUID? = nil

    // Loaded data
    @State private var shifts: [Shift] = []
    @State private var isLoading = false
    @State private var isSubmitting = false

        // Validation alerts
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var isShowingAlert = false
    @State private var isShowingSuccess = false

    @State private var nameError: String? = nil
    @State private var phoneError: String? = nil
    @State private var emailError: String? = nil
    @State private var addressError: String? = nil
    @State private var dobError: String? = nil
    @State private var validationTriggered = false

    private let dbService = DatabaseService.shared
    
    // Constants for Pickers
    let genders = ["Male", "Female", "Other"]
    let jobRoles = [
        "Sales Associate",
        "Cashier",
        "House Keeping",
        "Visual Merchandiser"
    ]

    var body: some View {
        Form {
            // Profile Photo section
            Section {
                VStack(spacing: 8) {
                    if let data = profilePhotoData, let uiImage = UIImage(data: data) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 90, height: 90)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color(.systemGray5), lineWidth: 1))
                            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                    } else {
                        Image(systemName: "person.crop.circle.fill.badge.plus")
                            .font(.system(size: 76))
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(Color(.systemBlue), Color(.systemGray4))
                            .frame(width: 90, height: 90)
                    }
                    
                    PhotosPicker(
                        selection: $selectedPhotoItem,
                        matching: .images,
                        photoLibrary: .shared()
                    ) {
                        Text("Upload Photo")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(Color(.systemBlue))
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }
            .listRowBackground(Color.clear)

            // Personal Information
            Section(header: Text("Personal Details")) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Full Name")
                            .foregroundColor(validationTriggered && nameError != nil ? .red : .primary)
                        Spacer()
                        TextField("Full Name", text: $fullName)
                            .textInputAutocapitalization(.words)
                            .disableAutocorrection(true)
                            .multilineTextAlignment(.trailing)
                    }
                    if validationTriggered, let err = nameError {
                        Text(err).font(.system(size: 12)).foregroundColor(.red)
                    }
                }
                
                HStack {
                    Text("Employee ID")
                    Spacer()
                    Text(employeeId)
                        .foregroundColor(Color(.secondaryLabel))
                }
                
                Picker("Gender", selection: $gender) {
                    ForEach(genders, id: \.self) { g in
                        Text(g).tag(g)
                    }
                }
                .pickerStyle(.menu)
                
                VStack(alignment: .leading, spacing: 4) {
                    DatePicker("Date of Birth", selection: $dateOfBirth, in: ...maxDOB, displayedComponents: .date)
                        .foregroundColor(validationTriggered && dobError != nil ? .red : .primary)
                    if validationTriggered, let err = dobError {
                        Text(err).font(.system(size: 12)).foregroundColor(.red)
                    }
                }
            }

            // Contact Information
            Section(header: Text("Contact Information")) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Mobile Number")
                            .foregroundColor(validationTriggered && phoneError != nil ? .red : .primary)
                        Spacer()
                        TextField("Mobile Number", text: $mobileNumber)
                            .keyboardType(.phonePad)
                            .multilineTextAlignment(.trailing)
                    }
                    if validationTriggered, let err = phoneError {
                        Text(err).font(.system(size: 12)).foregroundColor(.red)
                    }
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Email Address")
                            .foregroundColor(validationTriggered && emailError != nil ? .red : .primary)
                        Spacer()
                        TextField("Email Address", text: $email)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .disableAutocorrection(true)
                            .multilineTextAlignment(.trailing)
                    }
                    if validationTriggered, let err = emailError {
                        Text(err).font(.system(size: 12)).foregroundColor(.red)
                    }
                }
            }

            // Address Details
            Section(header: Text("Address")) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Residential Address")
                            .foregroundColor(validationTriggered && addressError != nil ? .red : .primary)
                        Spacer()
                        TextField("Residential Address", text: $address)
                            .multilineTextAlignment(.trailing)
                    }
                    if validationTriggered, let err = addressError {
                        Text(err).font(.system(size: 12)).foregroundColor(.red)
                    }
                }
            }

            // Employment Details
            Section(header: Text("Employment Details")) {
                Picker("Job Role", selection: $jobRole) {
                    ForEach(jobRoles, id: \.self) { role in
                        Text(role).tag(role)
                    }
                }
                .pickerStyle(.menu)

                if isLoading {
                    HStack {
                        Text("Loading shifts...")
                        Spacer()
                        ProgressView()
                    }
                } else {
                    Picker("Assigned Shift", selection: $selectedShiftId) {
                        Text("Select Shift").tag(nil as UUID?)
                        ForEach(shifts) { shift in
                            Text(shift.shiftName).tag(shift.id as UUID?)
                        }
                    }
                    .pickerStyle(.menu)
                }
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Add Employee")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") {
                    dismiss()
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Save") {
                    saveEmployee()
                }
                .font(.system(size: 17, weight: .bold))
                .disabled(isSubmitting)
            }
        }
        .task {
            await fetchShifts()
        }
        .onChange(of: selectedPhotoItem) { _, newItem in
            Swift.Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self) {
                    profilePhotoData = data
                }
            }
        }
        .alert(alertTitle, isPresented: $isShowingAlert) {
            Button("OK") {
                if isShowingSuccess {
                    dismiss()
                }
            }
        } message: {
            Text(alertMessage)
        }
    }

    // MARK: - Operations

    private func fetchShifts() async {
        isLoading = true
        do {
            if let storeId = SessionManager.shared.currentUser?.storeId {
                let response = try await SupabaseManager.shared.client
                    .from("shifts")
                    .select()
                    .eq("store_id", value: storeId.uuidString)
                    .execute()
                let fetchedShifts = try JSONDecoder.supabaseDecoder.decodeSupabase([Shift].self, from: response.data)
                self.shifts = fetchedShifts
            } else {
                self.shifts = []
            }
        } catch {
            print("Failed to fetch shifts: \(error)")
        }
        isLoading = false
    }

    private func validateForm() -> Bool {
        validationTriggered = true
        var isValid = true

        // Profile Photo
        if profilePhotoData == nil {
            showErrorAlert(title: "Profile Photo Required", message: "Please upload a Profile Photo.")
            return false
        }
        
        // Full Name
        let cleanName = fullName.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleanName.isEmpty {
            nameError = "Full Name is required"
            isValid = false
        } else if cleanName.count < 2 {
            nameError = "Name must be at least 2 characters"
            isValid = false
        } else {
            nameError = nil
        }
        
        // Mobile Number
        let cleanPhone = mobileNumber.trimmingCharacters(in: .whitespaces)
        let isNumeric = cleanPhone.allSatisfy { $0.isNumber }
        if cleanPhone.isEmpty {
            phoneError = "Phone Number is required"
            isValid = false
        } else if cleanPhone.count != 10 || !isNumeric {
            phoneError = "Phone must be exactly 10 digits (numbers only)"
            isValid = false
        } else {
            phoneError = nil
        }
        
        // Email
        let cleanEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleanEmail.isEmpty {
            emailError = "Email Address is required"
            isValid = false
        } else if !isValidEmail(cleanEmail) {
            emailError = "Please enter a valid email format"
            isValid = false
        } else {
            emailError = nil
        }
        
        // Address
        let cleanAddress = address.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleanAddress.isEmpty {
            addressError = "Residential Address is required"
            isValid = false
        } else {
            addressError = nil
        }
        
        // Date of Birth (Age >= 18 Check)
        let calendar = Calendar.current
        let ageComponents = calendar.dateComponents([.year], from: dateOfBirth, to: Date())
        if let age = ageComponents.year, age >= 18 {
            dobError = nil
        } else {
            dobError = "Employee must be at least 18 years old"
            isValid = false
        }
        
        // Uniqueness validation checks (locally stored profiles)
        if isValid {
            let localProfiles = EmployeeProfileStore.shared.getAll().values
            let emailLower = cleanEmail.lowercased()
            
            if localProfiles.contains(where: { $0.email.lowercased() == emailLower }) {
                showErrorAlert(title: "Duplicate Email", message: "The email address '\(cleanEmail)' is already registered to another employee.")
                return false
            }
            
            let phoneClean = mobileNumber.trimmingCharacters(in: .whitespaces)
            if localProfiles.contains(where: { $0.mobileNumber == phoneClean }) {
                showErrorAlert(title: "Duplicate Phone", message: "The mobile number '\(phoneClean)' is already registered to another employee.")
                return false
            }
        }
        
        if !isValid {
            showErrorAlert(title: "Invalid Information", message: "Please correct the highlighted fields before saving.")
        }
        
        return isValid
    }

    private func showErrorAlert(title: String, message: String) {
        let feedbackGenerator = UINotificationFeedbackGenerator()
        feedbackGenerator.notificationOccurred(.error)
        
        self.alertTitle = title
        self.alertMessage = message
        self.isShowingAlert = true
    }

    private func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
    }

    private func saveEmployee() {
        guard validateForm() else { return }
        isSubmitting = true

        let newUserId = UUID()
        
        // 1. Map Rich job title role to valid DB Role IDs
        let mappedRoleId = getDatabaseRoleId(for: jobRole)
        
        // 2. Construct Core User struct for Supabase schema
        // Username is auto generated from email prefix
        let generatedUsername = email.split(separator: "@").first.map(String.init) ?? String(fullName.prefix(6)).lowercased()
        
        let dateFmt = DateFormatter()
        dateFmt.dateFormat = "yyyy-MM-dd"
        let dobString = dateFmt.string(from: dateOfBirth)
        let joiningString = dateFmt.string(from: Date())

        let generatedPassword = PasswordGenerator.generateTemporaryPassword()
        
        let coreUser = User(
            id: newUserId,
            fullName: fullName.trimmingCharacters(in: .whitespacesAndNewlines),
            username: generatedUsername.replacingOccurrences(of: ".", with: "").lowercased(),
            email: email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(),
            password: generatedPassword,
            isVerified: true,
            roleId: mappedRoleId,
            storeId: SessionManager.shared.currentUser?.storeId ?? shifts.first(where: { $0.id == selectedShiftId })?.storeId,
            shiftId: selectedShiftId,
            employeeCode: employeeId,
            designation: jobRole,
            phone: mobileNumber.trimmingCharacters(in: .whitespaces),
            gender: gender,
            dateOfBirth: dobString,
            address: address.trimmingCharacters(in: .whitespacesAndNewlines),
            joiningDate: joiningString,
            employeeStatus: "active"
        )
        
        // 3. Construct Extended Profile struct for local memory
        let extendedProfile = EmployeeProfile(
            id: newUserId,
            gender: gender,
            dateOfBirth: dateOfBirth,
            mobileNumber: mobileNumber.trimmingCharacters(in: .whitespaces),
            email: email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(),
            address: address.trimmingCharacters(in: .whitespacesAndNewlines),
            jobRole: jobRole,
            shiftId: selectedShiftId,
            profilePhotoData: profilePhotoData
        )

        Swift.Task {
            do {
                // Save to database
                try await dbService.insert(into: "users", value: coreUser)
                
                // Trigger send-credentials edge function
                let emailParams = [
                    "userEmail": coreUser.email,
                    "userName": coreUser.fullName,
                    "username": coreUser.username,
                    "password": generatedPassword,
                    "role": coreUser.designation
                ]
                
                do {
                    _ = try await SupabaseManager.shared.client.functions.invoke(
                        "send-credentials",
                        options: FunctionInvokeOptions(body: emailParams)
                    )
                } catch {
                    print("[RSMS] Warning: Failed to call edge function for credentials: \(error)")
                    print("[RSMS] DEBUG: Generated Password for \(coreUser.email) is \(generatedPassword)")
                }
                
                // Save to local profile store
                EmployeeProfileStore.shared.save(profile: extendedProfile)

                let feedbackGenerator = UINotificationFeedbackGenerator()
                feedbackGenerator.notificationOccurred(.success)
                
                isShowingSuccess = true
                alertTitle = "Success"
                alertMessage = "Employee registered successfully."
                isShowingAlert = true
            } catch {
                let feedbackGenerator = UINotificationFeedbackGenerator()
                feedbackGenerator.notificationOccurred(.error)
                
                isShowingSuccess = false
                alertTitle = "Save Error"
                alertMessage = "Failed to register employee: \(error.localizedDescription)"
                isShowingAlert = true
            }
            isSubmitting = false
        }
    }

    private func getDatabaseRoleId(for jobRole: String) -> UUID {
        let salesRoleId = UUID(uuidString: "dae0ff3c-0356-4344-a643-22f06a8fee61")!
        let inventoryRoleId = UUID(uuidString: "c0aa841a-7c57-43f9-b98a-523475ba43af")!
        
        switch jobRole {
        case "Inventory Planner", "Stock Specialist":
            return inventoryRoleId
        default:
            return salesRoleId
        }
    }
}
