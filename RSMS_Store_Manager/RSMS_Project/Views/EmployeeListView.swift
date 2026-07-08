//
//  EmployeeListView.swift
//  RSMS_Project
//
//  Created by Yatharth Mishra on 30/06/26.
//

import SwiftUI
import PhotosUI
import Supabase

struct EmployeeListView: View {
    @State private var employees: [User] = []
    @State private var roles: [Role] = []
    @State private var stores: [Store] = []
    @State private var shifts: [Shift] = []


    @State private var searchText = ""
    @State private var isLoading = true
    @State private var errorMessage: String? = nil
    @State private var selectedEmployee: User? = nil
    @State private var isShowingDeleteConfirmation = false
    @State private var employeeToDelete: User? = nil
    @State private var isShowingRegistration = false
    @State private var isOverviewVisible = false

    private let userService = UserService()
    private let dbService = DatabaseService.shared

    init() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithDefaultBackground()
        appearance.largeTitleTextAttributes = [
            .font: UIFont.systemFont(ofSize: 28, weight: .bold)
        ]
        appearance.titleTextAttributes = [
            .font: UIFont.systemFont(ofSize: 17, weight: .semibold)
        ]
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
    }

    // MARK: - Calculations for Overview Cards

    private var currentActiveShift: Shift? {
        guard !shifts.isEmpty else { return nil }
        
        let now = Date()
        let calendar = Calendar.current
        let currentHour = calendar.component(.hour, from: now)
        let currentMinute = calendar.component(.minute, from: now)
        let currentMinutes = currentHour * 60 + currentMinute
        
        for shift in shifts {
            let startParts = shift.startTime.split(separator: ":").compactMap { Int($0) }
            let endParts = shift.endTime.split(separator: ":").compactMap { Int($0) }
            
            guard startParts.count == 2, endParts.count == 2 else { continue }
            
            let startMinutes = startParts[0] * 60 + startParts[1]
            let endMinutes = endParts[0] * 60 + endParts[1]
            
            if startMinutes <= endMinutes {
                if currentMinutes >= startMinutes && currentMinutes <= endMinutes {
                    return shift
                }
            } else {
                // overnight shift
                if currentMinutes >= startMinutes || currentMinutes <= endMinutes {
                    return shift
                }
            }
        }
        return shifts.first
    }


    var body: some View {
        Group {
            if isLoading {
                VStack(spacing: 12) {
                    ProgressView()
                        .scaleEffect(1.2)
                    Text("Fetching directory...")
                        .font(.system(size: 15))
                        .foregroundColor(Color(.secondaryLabel))
                }
            } else if let error = errorMessage {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(Color(.systemOrange))
                    Text(error)
                        .font(.system(size: 16))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                    Button(action: {
                        Swift.Task {
                            await loadData()
                        }
                    }) {
                        Text("Retry")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 10)
                            .background(Color(.systemBlue))
                            .cornerRadius(8)
                    }
                }
            } else {
                let filtered = filteredEmployees
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {

                        
                        if filtered.isEmpty {
                            VStack(spacing: 16) {
                                ZStack {
                                    Circle()
                                        .fill(Color(.systemBlue).opacity(0.1))
                                        .frame(width: 80, height: 80)
                                    Image(systemName: "person.3.sequence.fill")
                                        .font(.system(size: 32))
                                        .foregroundColor(Color(.systemBlue))
                                }
                                Text(searchText.isEmpty ? "No Employees Yet" : "No Match Found")
                                    .font(.system(size: 20, weight: .bold))
                                Text(searchText.isEmpty ? "Get started by adding your first store employee." : "Check the spelling or try searching for another name or role.")
                                    .font(.system(size: 15))
                                    .foregroundColor(Color(.secondaryLabel))
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 32)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.top, 40)
                        } else {
                            // All Employees Section (Styled as clean cards without individual checkin/checkout status badges)
                            VStack(alignment: .leading, spacing: 12) {
                                Text("All Employees (\(filtered.count))")
                                    .font(.system(size: 18, weight: .semibold, design: .default))
                                    .foregroundColor(Color(.label))
                                    .textCase(nil)
                                
                                ForEach(filtered) { employee in
                                    Button(action: {
                                        selectedEmployee = employee
                                    }) {
                                        EmployeeCardRow(
                                            employee: employee,
                                            roleName: roleName(for: employee.roleId),
                                            shiftName: shiftName(for: employee.shiftId)
                                        )
                                    }
                                    .buttonStyle(RowButtonStyle())
                                    .contextMenu {
                                        Button(role: .destructive) {
                                            employeeToDelete = employee
                                            isShowingDeleteConfirmation = true
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 30)
                }
                .background(Color(.systemGroupedBackground).edgesIgnoringSafeArea(.all))
            }
        }
        .navigationTitle("Directory")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searchText, prompt: "Search employees, roles...")
        .task {
            await loadData()
        }
        .sheet(item: $selectedEmployee) { employee in
            EmployeeDetailView(
                employee: employee,
                roleName: roleName(for: employee.roleId),
                storeName: storeName(for: employee.storeId),
                shiftName: shiftName(for: employee.shiftId),
                onUpdate: { updatedEmployee in
                    if let index = employees.firstIndex(where: { $0.id == updatedEmployee.id }) {
                        employees[index] = updatedEmployee
                    }
                },
                onDelete: { deletedEmployee in
                    employees.removeAll(where: { $0.id == deletedEmployee.id })
                }
            )
        }
        .sheet(isPresented: $isShowingRegistration, onDismiss: {
            Swift.Task {
                await loadData()
            }
        }) {
            NavigationStack {
                EmployeeRegistrationView()
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    isShowingRegistration = true
                }) {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .semibold))
                }
            }
        }
        .alert("Delete Employee?", isPresented: $isShowingDeleteConfirmation, presenting: employeeToDelete) { employee in
            Button("Delete", role: .destructive) {
                Swift.Task {
                    await deleteEmployee(employee)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: { employee in
            Text("Are you sure you want to delete \(employee.fullName)? This action cannot be undone.")
        }
    }

    // MARK: - Helper Methods

    private var filteredEmployees: [User] {
        if searchText.isEmpty {
            return employees
        }
        return employees.filter { employee in
            let rName = roleName(for: employee.roleId).lowercased()
            return employee.fullName.localizedCaseInsensitiveContains(searchText) ||
                   employee.username.localizedCaseInsensitiveContains(searchText) ||
                   employee.email.localizedCaseInsensitiveContains(searchText) ||
                   rName.contains(searchText.lowercased())
        }
    }

    private func roleName(for id: UUID) -> String {
        roles.first(where: { $0.id == id })?.roleName ?? "Staff"
    }

    private func storeName(for id: UUID?) -> String {
        guard let id = id else { return "Not Assigned" }
        return stores.first(where: { $0.id == id })?.storeName ?? "Unknown Store"
    }

    private func shiftName(for id: UUID?) -> String {
        guard let id = id else { return "Not Assigned" }
        if let shift = shifts.first(where: { $0.id == id }) {
            return shift.shiftName
        }
        return "Unknown Shift"
    }

    private func loadData() async {
        isLoading = true
        errorMessage = nil
        do {
            if SessionManager.shared.currentUser == nil {
                await SessionManager.shared.resolveSession()
            }
            
            guard let storeId = SessionManager.shared.currentUser?.storeId else {
                throw NSError(domain: "EmployeeListView", code: 401, userInfo: [NSLocalizedDescriptionKey: "No assigned store found for the current manager session."])
            }
            
            let roleList = try await dbService.fetch(from: "roles", as: Role.self)
            let storeList = try await dbService.fetch(from: "stores", as: Store.self)
            
            // 1. Fetch users scoped to the current store
            let empResponse = try await SupabaseManager.shared.client
                .from("users")
                .select()
                .eq("store_id", value: storeId.uuidString)
                .execute()
            let empList = try JSONDecoder.supabaseDecoder.decodeSupabase([User].self, from: empResponse.data)
            
            // 2. Fetch shifts scoped to the current store
            let shiftResponse = try await SupabaseManager.shared.client
                .from("shifts")
                .select()
                .eq("store_id", value: storeId.uuidString)
                .execute()
            let shiftList = try JSONDecoder.supabaseDecoder.decodeSupabase([Shift].self, from: shiftResponse.data)
            
            // 3. Filter employees to exclude the current logged-in manager
            let currentUserId = SessionManager.shared.currentUser?.id
            let storeEmployees = empList.filter { $0.id != currentUserId }
            
            self.employees = storeEmployees.sorted { $0.fullName.localizedCaseInsensitiveCompare($1.fullName) == .orderedAscending }
            self.roles = roleList
            self.stores = storeList
            self.shifts = shiftList
        } catch {
            if let decodingError = error as? DecodingError {
                var details = ""
                switch decodingError {
                case .typeMismatch(let type, let context):
                    details = "Type '\(type)' mismatch at coding path: \(context.codingPath.map { $0.stringValue }.joined(separator: ".")) (\(context.debugDescription))"
                case .valueNotFound(let type, let context):
                    details = "Value of type '\(type)' not found at coding path: \(context.codingPath.map { $0.stringValue }.joined(separator: ".")) (\(context.debugDescription))"
                case .keyNotFound(let key, let context):
                    details = "Key '\(key.stringValue)' not found at coding path: \(context.codingPath.map { $0.stringValue }.joined(separator: ".")) (\(context.debugDescription))"
                case .dataCorrupted(let context):
                    details = "Data corrupted at coding path: \(context.codingPath.map { $0.stringValue }.joined(separator: ".")) (\(context.debugDescription))"
                @unknown default:
                    details = error.localizedDescription
                }
                errorMessage = "Decoding Error: \(details)"
            } else {
                errorMessage = "Failed to load directory. \(error.localizedDescription)"
            }
        }
        isLoading = false
    }

    private func deleteEmployee(_ employee: User) async {
        do {
            let employeeIdString = employee.id.uuidString.lowercased()
            
            // Clean up dependencies first to avoid foreign key constraint errors
            try? await dbService.delete(from: "appointments", column: "sales_associate_id", equals: employeeIdString)
            try? await dbService.delete(from: "attendance", column: "employee_id", equals: employeeIdString)
            
            try await dbService.delete(from: "users", column: "id", equals: employeeIdString)
            
            await MainActor.run {
                employees.removeAll(where: { $0.id == employee.id })
            }
        } catch {
            print("Failed to delete user: \(error)")
        }
    }
}

// MARK: - Row Button Style (Scale animation on click)
struct RowButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// MARK: - Overview Stat Card Component
struct OverviewCard: View {
    let iconName: String
    let iconBgColor: Color
    let iconColor: Color
    let value: String
    let subtitle: String
    let footerText: String?
    let footerColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            // Icon Badge
            ZStack {
                Circle()
                    .fill(iconBgColor)
                    .frame(width: 32, height: 32)
                Image(systemName: iconName)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(iconColor)
            }
            
            // Value (Format fraction numerator/denominator baseline alignment)
            let parts = value.components(separatedBy: "/")
            if parts.count == 2 {
                HStack(alignment: .firstTextBaseline, spacing: 0) {
                    Text(parts[0].trimmingCharacters(in: .whitespaces))
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(Color(.label))
                    
                    Text("/" + parts[1].trimmingCharacters(in: .whitespaces))
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color(.secondaryLabel))
                }
                .lineLimit(1)
                .padding(.top, 4)
            } else {
                Text(value)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(Color(.label))
                    .lineLimit(1)
                    .padding(.top, 4)
            }
            
            // Subtitle
            Text(subtitle)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(Color(.secondaryLabel))
                .lineLimit(1)
                .padding(.top, 1)
            
            // Footer
            if let footer = footerText {
                Text(footer)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(footerColor)
                    .padding(.top, 2)
            }
        }
        .padding(.top, 12)
        .padding(.horizontal, 16)
        .padding(.bottom, 12)
        .frame(maxWidth: 180, alignment: .leading)
        .frame(height: 110)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(22)
        .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 3)
    }
}

// MARK: - Employee Card Row Component (Uncluttered HIG styling)
struct EmployeeCardRow: View {
    let employee: User
    let roleName: String
    let shiftName: String

    var body: some View {
        let localProfile = EmployeeProfileStore.shared.get(id: employee.id)
        let displayRole = localProfile?.jobRole ?? roleName
        
        HStack(spacing: 16) {
            // Circular Avatar or Profile Photo
            if let photoData = localProfile?.profilePhotoData, let uiImage = UIImage(data: photoData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 56, height: 56)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color(.systemGray5), lineWidth: 1))
            } else {
                Text(initials(for: employee.fullName))
                    .font(.system(size: 18, weight: .bold, design: .default))
                    .foregroundColor(.white)
                    .frame(width: 56, height: 56)
                    .background(avatarColor(for: employee.fullName))
                    .clipShape(Circle())
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(employee.fullName)
                    .font(.system(size: 20, weight: .semibold, design: .default))
                    .foregroundColor(Color(.label))
                    .multilineTextAlignment(.leading)
                
                Text(displayRole)
                    .font(.system(size: 16, weight: .regular, design: .default))
                    .foregroundColor(Color(.secondaryLabel))
                    .multilineTextAlignment(.leading)
                
                Text(shiftName)
                    .font(.system(size: 14, weight: .regular, design: .default))
                    .foregroundColor(Color(.tertiaryLabel))
                    .multilineTextAlignment(.leading)
            }
            
            Spacer()
            
            // Subtle chevron
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(Color(.tertiaryLabel))
        }
        .padding(.horizontal, 16)
        .frame(height: 96)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(22)
        .shadow(color: Color.black.opacity(0.04), radius: 5, x: 0, y: 2.5)
    }

    private func initials(for name: String) -> String {
        let components = name.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        if components.count >= 2 {
            let first = components[0].prefix(1)
            let last = components[components.count - 1].prefix(1)
            return "\(first)\(last)".uppercased()
        }
        return String(name.prefix(2)).uppercased()
    }

    private func avatarColor(for name: String) -> Color {
        let colors: [Color] = [
            Color(red: 0/255, green: 122/255, blue: 255/255), // System Blue
            Color(red: 52/255, green: 199/255, blue: 89/255),  // System Green
            Color(red: 255/255, green: 149/255, blue: 0/255), // System Orange
            Color(red: 175/255, green: 82/255, blue: 222/255), // System Purple
            Color(red: 255/255, green: 45/255, blue: 85/255),  // System Pink
            Color(red: 88/255, green: 86/255, blue: 214/255)   // Indigo
        ]
        let hash = name.hashValue
        let index = abs(hash) % colors.count
        return colors[index]
    }
}

// MARK: - Detail View Component
struct UserUpdate: Encodable {
    var fullName: String? = nil
    var username: String? = nil
    var email: String? = nil
    var phone: String? = nil
    var gender: String? = nil
    var dateOfBirth: String? = nil
    var address: String? = nil
    var shiftId: UUID? = nil
    var hasShiftIdValue: Bool = false
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        if let fullName = fullName { try container.encode(fullName, forKey: .fullName) }
        if let username = username { try container.encode(username, forKey: .username) }
        if let email = email { try container.encode(email, forKey: .email) }
        if let phone = phone { try container.encode(phone, forKey: .phone) }
        if let gender = gender { try container.encode(gender, forKey: .gender) }
        if let dateOfBirth = dateOfBirth { try container.encode(dateOfBirth, forKey: .dateOfBirth) }
        if let address = address { try container.encode(address, forKey: .address) }
        if hasShiftIdValue {
            try container.encode(shiftId, forKey: .shiftId)
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case fullName = "full_name"
        case username
        case email
        case phone
        case gender
        case dateOfBirth = "date_of_birth"
        case address
        case shiftId = "shift_id"
    }
}

struct EmployeeDetailView: View {
    @State private var currentEmployee: User
    let roleName: String
    let storeName: String
    let shiftName: String
    var onUpdate: (User) -> Void
    var onDelete: (User) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var isShowingDeleteAlert = false
    
    @State private var attendanceRecords: [Attendance] = []
    @State private var isFetchingAttendance = false

    @State private var isEditing = false
    @State private var isLoadingShifts = false
    @State private var isSaving = false
    
    // Editable field states
    @State private var fullName: String = ""
    @State private var username: String = ""
    @State private var email: String = ""
    @State private var mobileNumber: String = ""
    @State private var gender: String = ""
    @State private var dateOfBirth: Date = Date()
    @State private var address: String = ""
    @State private var selectedShiftId: UUID? = nil
    @State private var profilePhotoData: Data? = nil
    
    // Alert and error states
    @State private var errorMessage: String? = nil
    @State private var isShowingAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""

    @State private var nameError: String? = nil
    @State private var usernameError: String? = nil
    @State private var phoneError: String? = nil
    @State private var emailError: String? = nil
    @State private var addressError: String? = nil
    @State private var dobError: String? = nil
    @State private var validationTriggered = false
    
    // Discard changes confirmation state
    @State private var isShowingDiscardAlert = false
    
    // Image selection state
    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    
    // Dynamic Shifts List
    @State private var availableShifts: [Shift] = []

    init(employee: User, roleName: String, storeName: String, shiftName: String, onUpdate: @escaping (User) -> Void, onDelete: @escaping (User) -> Void) {
        self._currentEmployee = State(initialValue: employee)
        self.roleName = roleName
        self.storeName = storeName
        self.shiftName = shiftName
        self.onUpdate = onUpdate
        self.onDelete = onDelete
    }

    private var selectedShiftName: String {
        if let shift = availableShifts.first(where: { $0.id == selectedShiftId }) {
            return shift.shiftName
        }
        return shiftName
    }

    private var hasChanges: Bool {
        let localProfile = EmployeeProfileStore.shared.get(id: currentEmployee.id)
        
        let originalPhone = localProfile?.mobileNumber ?? currentEmployee.phone ?? ""
        let originalGender = localProfile?.gender ?? currentEmployee.gender ?? "Male"
        
        let originalDobDate: Date
        if let dobStr = currentEmployee.dateOfBirth, let dobDate = parseDateString(dobStr) {
            originalDobDate = dobDate
        } else if let localDob = localProfile?.dateOfBirth {
            originalDobDate = localDob
        } else {
            originalDobDate = Date()
        }
        
        let originalAddress = localProfile?.address ?? currentEmployee.address ?? ""
        let originalShiftId = currentEmployee.shiftId
        let originalPhotoData = localProfile?.profilePhotoData
        
        let dobChanged = !Calendar.current.isDate(dateOfBirth, inSameDayAs: originalDobDate)
        
        return fullName != currentEmployee.fullName ||
               username != currentEmployee.username ||
               email != currentEmployee.email ||
               mobileNumber != originalPhone ||
               gender != originalGender ||
               dobChanged ||
               address != originalAddress ||
               selectedShiftId != originalShiftId ||
               profilePhotoData != originalPhotoData
    }

    @ViewBuilder
    private var headerPhotoView: some View {
        let localProfile = EmployeeProfileStore.shared.get(id: currentEmployee.id)
        if isEditing {
            PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                if let photoData = profilePhotoData, let uiImage = UIImage(data: photoData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 80, height: 80)
                        .clipShape(Circle())
                        .overlay(
                            Image(systemName: "camera.fill")
                                .foregroundColor(.white)
                                .padding(6)
                                .background(Color.black.opacity(0.5))
                                .clipShape(Circle())
                                .padding(2),
                            alignment: .bottomTrailing
                        )
                } else {
                    Text(initials(for: currentEmployee.fullName))
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 80, height: 80)
                        .background(avatarColor(for: currentEmployee.fullName))
                        .clipShape(Circle())
                        .overlay(
                            Image(systemName: "camera.fill")
                                .foregroundColor(.white)
                                .padding(6)
                                .background(Color.black.opacity(0.5))
                                .clipShape(Circle())
                                .padding(2),
                            alignment: .bottomTrailing
                        )
                }
            }
        } else {
            if let photoData = localProfile?.profilePhotoData, let uiImage = UIImage(data: photoData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 80, height: 80)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color(.systemGray5), lineWidth: 1))
                    .shadow(color: Color.black.opacity(0.1), radius: 6, x: 0, y: 3)
            } else {
                Text(initials(for: currentEmployee.fullName))
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 80, height: 80)
                    .background(avatarColor(for: currentEmployee.fullName))
                    .clipShape(Circle())
                    .shadow(color: Color.black.opacity(0.1), radius: 6, x: 0, y: 3)
            }
        }
    }

    @ViewBuilder
    private var accountProfileSection: some View {
        let localProfile = EmployeeProfileStore.shared.get(id: currentEmployee.id)
        Section(header: Text("Account Profile")) {
            if isEditing {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Full Name")
                            .foregroundColor(validationTriggered && nameError != nil ? .red : Color(.secondaryLabel))
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
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Username")
                            .foregroundColor(validationTriggered && usernameError != nil ? .red : Color(.secondaryLabel))
                        Spacer()
                        TextField("Username", text: $username)
                            .textInputAutocapitalization(.never)
                            .disableAutocorrection(true)
                            .multilineTextAlignment(.trailing)
                    }
                    if validationTriggered, let err = usernameError {
                        Text(err).font(.system(size: 12)).foregroundColor(.red)
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Email Address")
                            .foregroundColor(validationTriggered && emailError != nil ? .red : Color(.secondaryLabel))
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

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Mobile Number")
                            .foregroundColor(validationTriggered && phoneError != nil ? .red : Color(.secondaryLabel))
                        Spacer()
                        TextField("Mobile Number", text: $mobileNumber)
                            .keyboardType(.phonePad)
                            .multilineTextAlignment(.trailing)
                    }
                    if validationTriggered, let err = phoneError {
                        Text(err).font(.system(size: 12)).foregroundColor(.red)
                    }
                }
            } else {
                InfoRow(label: "Username", value: currentEmployee.username)
                InfoRow(label: "Email Address", value: currentEmployee.email)
                InfoRow(label: "Mobile Number", value: localProfile?.mobileNumber ?? currentEmployee.phone ?? "Not Available")
            }
        }
    }

    @ViewBuilder
    private var personalDetailsSection: some View {
        let localProfile = EmployeeProfileStore.shared.get(id: currentEmployee.id)
        let dobVal: String = {
            if let localDob = localProfile?.dateOfBirth {
                return localDob.formatted(date: .abbreviated, time: .omitted)
            } else if let dobStr = currentEmployee.dateOfBirth, let dobDate = parseDateString(dobStr) {
                return dobDate.formatted(date: .abbreviated, time: .omitted)
            } else {
                return "Not Available"
            }
        }()
        
        Section(header: Text("Personal Details")) {
            if isEditing {
                Picker("Gender", selection: $gender) {
                    Text("Male").tag("Male")
                    Text("Female").tag("Female")
                    Text("Other").tag("Other")
                }
                .pickerStyle(.menu)
                
                VStack(alignment: .leading, spacing: 4) {
                    DatePicker("Date of Birth", selection: $dateOfBirth, displayedComponents: .date)
                        .foregroundColor(validationTriggered && dobError != nil ? .red : .primary)
                    if validationTriggered, let err = dobError {
                        Text(err).font(.system(size: 12)).foregroundColor(.red)
                    }
                }
            } else {
                InfoRow(label: "Gender", value: localProfile?.gender ?? currentEmployee.gender ?? "Not Available")
                InfoRow(label: "Date of Birth", value: dobVal)
            }
        }
    }

    @ViewBuilder
    private var residentialAddressSection: some View {
        let localProfile = EmployeeProfileStore.shared.get(id: currentEmployee.id)
        Section(header: Text("Residential Address")) {
            if isEditing {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Address")
                            .foregroundColor(validationTriggered && addressError != nil ? .red : Color(.secondaryLabel))
                        Spacer()
                        TextField("Residential Address", text: $address)
                            .multilineTextAlignment(.trailing)
                    }
                    if validationTriggered, let err = addressError {
                        Text(err).font(.system(size: 12)).foregroundColor(.red)
                    }
                }
            } else {
                InfoRow(label: "Address", value: localProfile?.address ?? currentEmployee.address ?? "Not Available")
            }
        }
    }

    @ViewBuilder
    private var storeAssignmentSection: some View {
        Section(header: Text("Store Assignment")) {
            InfoRow(label: "Store Location", value: storeName)
            if isEditing {
                Picker("Shift Schedule", selection: $selectedShiftId) {
                    Text("Select Shift").tag(nil as UUID?)
                    ForEach(availableShifts) { shift in
                        Text(shift.shiftName).tag(shift.id as UUID?)
                    }
                }
                .pickerStyle(.menu)
            } else {
                InfoRow(label: "Shift Schedule", value: selectedShiftName)
            }
        }
    }

    @ViewBuilder
    private var auditDetailsSection: some View {
        Section(header: Text("Audit Details")) {
            InfoRow(label: "Employee ID", value: currentEmployee.employeeCode ?? currentEmployee.id.uuidString.prefix(8).uppercased())
            InfoRow(label: "Created On", value: formatCreatedDate(currentEmployee.createdAt))
            InfoRow(label: "Created By", value: resolveCreatorName(currentEmployee.createdBy))
        }
    }

    var body: some View {
        let localProfile = EmployeeProfileStore.shared.get(id: currentEmployee.id)
        let displayRole = localProfile?.jobRole ?? roleName
        
        NavigationStack {
            List {
                // Header section
                VStack(spacing: 8) {
                    headerPhotoView
                    
                    Text(isEditing ? fullName : currentEmployee.fullName)
                        .font(.system(size: 22, weight: .bold))
                    
                    Text(displayRole)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(Color(.secondaryLabel))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(12)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 8)
                .padding(.bottom, 12)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())

                accountProfileSection
                personalDetailsSection
                residentialAddressSection
                storeAssignmentSection
                auditDetailsSection

                if !isEditing {
                    // Attendance History Section
                    Section(header: Text("Attendance History")) {
                        if isFetchingAttendance {
                            HStack {
                                Text("Loading history...")
                                Spacer()
                                ProgressView()
                            }
                        } else if attendanceRecords.isEmpty {
                            Text("No attendance logs found.")
                                .font(.system(size: 14))
                                .foregroundColor(Color(.secondaryLabel))
                        } else {
                            ForEach(attendanceRecords) { record in
                                HStack {
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(record.attendanceDate.formatted(date: .abbreviated, time: .omitted))
                                            .font(.system(size: 16, weight: .semibold))
                                        
                                        HStack(spacing: 8) {
                                            if let checkIn = record.checkIn {
                                                Text("In: \(checkIn.formatted(date: .omitted, time: .shortened))")
                                            }
                                            if let checkOut = record.checkOut {
                                                Text("Out: \(checkOut.formatted(date: .omitted, time: .shortened))")
                                            }
                                        }
                                        .font(.system(size: 12))
                                        .foregroundColor(Color(.secondaryLabel))
                                    }
                                    
                                    Spacer()
                                    
                                    VStack(alignment: .trailing, spacing: 3) {
                                        if let hours = record.workingHours {
                                            Text(String(format: "%.1f hrs", hours))
                                                .font(.system(size: 14, weight: .medium))
                                        }
                                        
                                        Text(record.status)
                                            .font(.system(size: 11, weight: .bold))
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .foregroundColor(statusColor(for: record.status))
                                            .background(statusColor(for: record.status).opacity(0.1))
                                            .cornerRadius(6)
                                    }
                                }
                                .padding(.vertical, 2)
                            }
                        }
                    }

                    // Danger Section
                    Section {
                        Button(role: .destructive, action: {
                            isShowingDeleteAlert = true
                        }) {
                            HStack {
                                Spacer()
                                Text("Delete Employee Record")
                                    .font(.system(size: 17, weight: .semibold))
                                Spacer()
                            }
                        }
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Employee Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        if isEditing && hasChanges {
                            isShowingDiscardAlert = true
                        } else {
                            dismiss()
                        }
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    if isEditing {
                        Button(action: {
                            Swift.Task {
                                await saveChanges()
                            }
                        }) {
                            if isSaving {
                                ProgressView()
                            } else {
                                Text("Save")
                                    .font(.system(size: 17, weight: .bold))
                            }
                        }
                        .disabled(isSaving)
                    } else {
                        Button("Edit") {
                            isEditing = true
                            prefillFields()
                        }
                    }
                }
            }
            .alert("Discard Changes?", isPresented: $isShowingDiscardAlert) {
                Button("Keep Editing", role: .cancel) {}
                Button("Discard Changes", role: .destructive) {
                    dismiss()
                }
            } message: {
                Text("You have unsaved changes. Are you sure you want to discard them?")
            }
            .alert(alertTitle, isPresented: $isShowingAlert) {
                Button("OK") {}
            } message: {
                Text(alertMessage)
            }
            .alert("Delete Employee Record?", isPresented: $isShowingDeleteAlert) {
                Button("Delete", role: .destructive) {
                    Swift.Task {
                        await deleteEmployee()
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Deleting this profile will permanently remove \(currentEmployee.fullName)'s access to the retail app.")
            }
            .task {
                prefillFields()
                await fetchShifts()
                await fetchAttendance()
            }
            .onChange(of: selectedPhotoItem) { _, newItem in
                Swift.Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self) {
                        await MainActor.run {
                            self.profilePhotoData = data
                        }
                    }
                }
            }
        }
    }

    private func prefillFields() {
        let localProfile = EmployeeProfileStore.shared.get(id: currentEmployee.id)
        
        fullName = currentEmployee.fullName
        username = currentEmployee.username
        email = currentEmployee.email
        mobileNumber = localProfile?.mobileNumber ?? currentEmployee.phone ?? ""
        gender = localProfile?.gender ?? currentEmployee.gender ?? "Male"
        
        if let dobStr = currentEmployee.dateOfBirth, let dobDate = parseDateString(dobStr) {
            dateOfBirth = dobDate
        } else if let localDob = localProfile?.dateOfBirth {
            dateOfBirth = localDob
        } else {
            dateOfBirth = Date()
        }
        
        address = localProfile?.address ?? currentEmployee.address ?? ""
        selectedShiftId = currentEmployee.shiftId
        profilePhotoData = localProfile?.profilePhotoData
    }

    private func parseDateString(_ dateStr: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: dateStr)
    }

    private func formatDateString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    private func formatCreatedDate(_ dateStr: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: dateStr) {
            let outFormatter = DateFormatter()
            outFormatter.dateFormat = "MMM d, yyyy"
            return outFormatter.string(from: date)
        }
        
        let formatter2 = ISO8601DateFormatter()
        formatter2.formatOptions = [.withInternetDateTime]
        if let date = formatter2.date(from: dateStr) {
            let outFormatter = DateFormatter()
            outFormatter.dateFormat = "MMM d, yyyy"
            return outFormatter.string(from: date)
        }
        
        let formatter3 = DateFormatter()
        formatter3.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        if let date = formatter3.date(from: dateStr) {
            let outFormatter = DateFormatter()
            outFormatter.dateFormat = "MMM d, yyyy"
            return outFormatter.string(from: date)
        }
        
        return dateStr
    }

    private func resolveCreatorName(_ creatorId: UUID?) -> String {
        guard let creatorId = creatorId else { return "System" }
        if let current = SessionManager.shared.currentUser, current.id == creatorId {
            return current.fullName
        }
        return "Store Manager"
    }

    private func fetchShifts() async {
        isLoadingShifts = true
        do {
            var query = SupabaseManager.shared.client.from("shifts").select()
            if let storeId = currentEmployee.storeId {
                query = query.eq("store_id", value: storeId.uuidString)
            } else if let storeId = SessionManager.shared.currentUser?.storeId {
                query = query.eq("store_id", value: storeId.uuidString)
            }
            let response = try await query.execute()
            let fetchedShifts = try JSONDecoder.supabaseDecoder.decodeSupabase([Shift].self, from: response.data)
            await MainActor.run {
                self.availableShifts = fetchedShifts
            }
        } catch {
            print("Failed to fetch shifts: \(error)")
        }
        isLoadingShifts = false
    }

    private func fetchAttendance() async {
        isFetchingAttendance = true
        do {
            let records: [Attendance] = try await DatabaseService.shared.fetch(from: "attendance", as: Attendance.self)
            await MainActor.run {
                self.attendanceRecords = records
                    .filter { $0.employeeId == currentEmployee.id }
                    .sorted { $0.attendanceDate > $1.attendanceDate }
            }
        } catch {
            print("Failed to fetch attendance: \(error)")
        }
        isFetchingAttendance = false
    }

    private func statusColor(for status: String) -> Color {
        switch status.lowercased() {
        case "present":
            return Color(.systemGreen)
        case "late":
            return Color(.systemOrange)
        case "absent":
            return Color(.systemRed)
        default:
            return Color(.systemGray)
        }
    }

    private func initials(for name: String) -> String {
        let components = name.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        if components.count >= 2 {
            let first = components[0].prefix(1)
            let last = components[components.count - 1].prefix(1)
            return "\(first)\(last)".uppercased()
        }
        return String(name.prefix(2)).uppercased()
    }

    private func avatarColor(for name: String) -> Color {
        let colors: [Color] = [
            Color(red: 0/255, green: 122/255, blue: 255/255), // System Blue
            Color(red: 52/255, green: 199/255, blue: 89/255),  // System Green
            Color(red: 255/255, green: 149/255, blue: 0/255), // System Orange
            Color(red: 175/255, green: 82/255, blue: 222/255), // System Purple
            Color(red: 255/255, green: 45/255, blue: 85/255),  // System Pink
            Color(red: 88/255, green: 86/255, blue: 214/255)   // Indigo
        ]
        let hash = name.hashValue
        let index = abs(hash) % colors.count
        return colors[index]
    }

    private func validateForm() -> Bool {
        validationTriggered = true
        var isValid = true
        
        // Name
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
        
        // Username
        let cleanUsername = username.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleanUsername.isEmpty {
            usernameError = "Username is required"
            isValid = false
        } else {
            usernameError = nil
        }
        
        // Phone
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
        
        if !isValid {
            showErrorAlert(title: "Invalid Information", message: "Please correct the highlighted fields before saving.")
        }
        
        return isValid
    }

    private func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
    }

    private func showErrorAlert(title: String, message: String) {
        let feedbackGenerator = UINotificationFeedbackGenerator()
        feedbackGenerator.notificationOccurred(.error)
        self.alertTitle = title
        self.alertMessage = message
        self.isShowingAlert = true
    }

    private func saveChanges() async {
        guard validateForm() else { return }
        
        if !hasChanges {
            await MainActor.run {
                self.isEditing = false
            }
            return
        }
        
        isSaving = true
        let localProfile = EmployeeProfileStore.shared.get(id: currentEmployee.id)
        
        var update = UserUpdate()
        if fullName != currentEmployee.fullName {
            update.fullName = fullName
        }
        if username != currentEmployee.username {
            update.username = username
        }
        if email != currentEmployee.email {
            update.email = email
        }
        
        let originalPhone = localProfile?.mobileNumber ?? currentEmployee.phone ?? ""
        if mobileNumber != originalPhone {
            update.phone = mobileNumber
        }
        
        let originalGender = localProfile?.gender ?? currentEmployee.gender ?? "Male"
        if gender != originalGender {
            update.gender = gender
        }
        
        let originalDobDate: Date
        if let dobStr = currentEmployee.dateOfBirth, let dobDate = parseDateString(dobStr) {
            originalDobDate = dobDate
        } else if let localDob = localProfile?.dateOfBirth {
            originalDobDate = localDob
        } else {
            originalDobDate = Date()
        }
        if !Calendar.current.isDate(dateOfBirth, inSameDayAs: originalDobDate) {
            update.dateOfBirth = formatDateString(dateOfBirth)
        }
        
        let originalAddress = localProfile?.address ?? currentEmployee.address ?? ""
        if address != originalAddress {
            update.address = address
        }
        
        if selectedShiftId != currentEmployee.shiftId {
            update.shiftId = selectedShiftId
            update.hasShiftIdValue = true
        }
        
        do {
            try await DatabaseService.shared.update(
                table: "users",
                value: update,
                column: "id",
                equals: currentEmployee.id.uuidString.lowercased()
            )
            
            let extendedProfile = EmployeeProfile(
                id: currentEmployee.id,
                gender: gender,
                dateOfBirth: dateOfBirth,
                mobileNumber: mobileNumber.trimmingCharacters(in: .whitespaces),
                email: email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(),
                address: address.trimmingCharacters(in: .whitespacesAndNewlines),
                jobRole: localProfile?.jobRole ?? roleName,
                shiftId: selectedShiftId,
                profilePhotoData: profilePhotoData
            )
            EmployeeProfileStore.shared.save(profile: extendedProfile)
            
            let feedbackGenerator = UINotificationFeedbackGenerator()
            feedbackGenerator.notificationOccurred(.success)
            
            let updatedUser = currentEmployee.copy(
                fullName: fullName,
                username: username,
                email: email,
                shiftId: selectedShiftId,
                phone: mobileNumber,
                gender: gender,
                dateOfBirth: formatDateString(dateOfBirth),
                address: address
            )
            
            await MainActor.run {
                self.currentEmployee = updatedUser
                self.isEditing = false
                self.isSaving = false
                onUpdate(updatedUser)
            }
        } catch {
            print("Failed to save employee changes: \(error)")
            let feedbackGenerator = UINotificationFeedbackGenerator()
            feedbackGenerator.notificationOccurred(.error)
            
            await MainActor.run {
                self.isSaving = false
                self.alertTitle = "Save Error"
                self.alertMessage = "Failed to save profile changes: \(error.localizedDescription)"
                self.isShowingAlert = true
            }
        }
    }

    private func deleteEmployee() async {
        do {
            let employeeIdString = currentEmployee.id.uuidString.lowercased()
            
            // Clean up dependencies first to avoid foreign key constraint errors
            try? await DatabaseService.shared.delete(from: "appointments", column: "sales_associate_id", equals: employeeIdString)
            try? await DatabaseService.shared.delete(from: "attendance", column: "employee_id", equals: employeeIdString)

            try await DatabaseService.shared.delete(
                from: "users",
                column: "id",
                equals: employeeIdString
            )
            
            await MainActor.run {
                onDelete(currentEmployee)
            }
            dismiss()
        } catch {
            print("Failed to delete user: \(error)")
        }
    }
}

// MARK: - Info Row Component
struct InfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(Color(.secondaryLabel))
            Spacer()
            Text(value)
                .foregroundColor(Color(.label))
                .multilineTextAlignment(.trailing)
        }
    }
}
