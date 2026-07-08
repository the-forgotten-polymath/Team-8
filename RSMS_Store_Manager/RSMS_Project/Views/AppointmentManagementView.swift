//
//  AppointmentManagementView.swift
//  RSMS_Project
//
//  Created by Yatharth Mishra on 30/06/26.
//

import SwiftUI
import Supabase

struct AppointmentManagementView: View {
    @State private var appointments: [Appointment] = []
    @State private var employees: [User] = []
    @State private var stores: [Store] = []
    @State private var customers: [Customer] = []

    @State private var searchText = ""
    @State private var isLoading = true
    @State private var errorMessage: String? = nil
    @State private var statusFilter: StatusFilter = .all
    @State private var isShowingCreateSheet = false

    @State private var selectedAppointment: Appointment? = nil
    private let dbService = DatabaseService.shared

    enum StatusFilter: String, CaseIterable {
        case all = "All"
        case open = "Open"
        case completed = "Completed"
    }

    // MARK: - Filtered & Grouped Data

    private var displayedAppointments: [Appointment] {
        let statusFiltered: [Appointment]
        switch statusFilter {
        case .all:
            statusFiltered = appointments
        case .open:
            statusFiltered = appointments.filter { $0.status != "done" }
        case .completed:
            statusFiltered = appointments.filter { $0.status == "done" }
        }

        if searchText.isEmpty { return statusFiltered }
        let q = searchText.lowercased()
        return statusFiltered.filter { appointment in
            if let name = appointment.appointmentName, name.lowercased().contains(q) { return true }
            if let desc = appointment.description, desc.lowercased().contains(q) { return true }
            if let assignedEmp = employees.first(where: { $0.id == appointment.salesAssociateId }),
               assignedEmp.fullName.lowercased().contains(q) {
                return true
            }
            if let cust = customers.first(where: { $0.id == appointment.customerId }),
               cust.name.lowercased().contains(q) {
                return true
            }
            return false
        }
    }

    private var todayAppointments: [Appointment] {
        displayedAppointments.filter { Calendar.current.isDateInToday($0.appointmentDatetime) }
    }

    private var tomorrowAppointments: [Appointment] {
        displayedAppointments.filter { Calendar.current.isDateInTomorrow($0.appointmentDatetime) }
    }

    private var thisWeekAppointments: [Appointment] {
        let cal = Calendar.current
        return displayedAppointments.filter { appt in
            !cal.isDateInToday(appt.appointmentDatetime) &&
            !cal.isDateInTomorrow(appt.appointmentDatetime) &&
            cal.isDate(appt.appointmentDatetime, equalTo: Date(), toGranularity: .weekOfYear)
        }
    }

    private var laterAppointments: [Appointment] {
        let cal = Calendar.current
        return displayedAppointments.filter { appt in
            !cal.isDate(appt.appointmentDatetime, equalTo: Date(), toGranularity: .weekOfYear)
        }
    }

    private var pastAppointments: [Appointment] {
        displayedAppointments.filter { $0.appointmentDatetime < Date() && !Calendar.current.isDateInToday($0.appointmentDatetime) }
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            // Status Filter Bar
            statusFilterBar
                .padding(.top, 8)

            // Content
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    if isLoading {
                        loadingView
                    } else if let error = errorMessage {
                        errorView(error)
                    } else if displayedAppointments.isEmpty && searchText.isEmpty {
                        emptyStateView
                    } else if displayedAppointments.isEmpty {
                        searchEmptyView
                    } else {
                        appointmentListContent
                    }
                }
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Appointments")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searchText, prompt: "Search by name, customer, or employee...")
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Appointments")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.primary)
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    isShowingCreateSheet = true
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 30, height: 30)
                        .background(Color(.systemBlue))
                        .clipShape(Circle())
                }
            }
        }
        .task { await loadData() }
        .onAppear {
            Swift.Task { await loadData() }
        }
        .sheet(item: $selectedAppointment, onDismiss: {
            Swift.Task { await loadData() }
        }) { appointment in
            AppointmentDetailView(
                appointment: appointment,
                employees: employees,
                stores: stores,
                existingAppointments: appointments,
                onUpdate: { Swift.Task { await loadData() } }
            )
        }
        .sheet(isPresented: $isShowingCreateSheet, onDismiss: {
            Swift.Task { await loadData() }
        }) {
            NavigationStack {
                CreateAppointmentView(stores: stores, employees: employees, existingAppointments: appointments)
            }
        }
    }

    // MARK: - Status Filter Bar

    private var statusFilterBar: some View {
        HStack(spacing: 8) {
            ForEach(StatusFilter.allCases, id: \.self) { filter in
                let isSelected = statusFilter == filter
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        statusFilter = filter
                    }
                } label: {
                    Text(filter.rawValue)
                        .font(.system(size: 14, weight: isSelected ? .semibold : .medium))
                        .foregroundColor(isSelected ? .white : .secondary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(isSelected ? Color(.systemBlue) : Color(.tertiarySystemGroupedBackground))
                        )
                }
                .buttonStyle(.plain)
            }
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 4)
    }

    // MARK: - Appointment List Content

    @ViewBuilder
    private var appointmentListContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Time-based sections
            appointmentSection(title: "Today", appointments: todayAppointments)
            appointmentSection(title: "Tomorrow", appointments: tomorrowAppointments)
            appointmentSection(title: "This Week", appointments: thisWeekAppointments)
            appointmentSection(title: "Later", appointments: laterAppointments)

            // Past (only visible when showing "Completed" or "All")
            if statusFilter != .open {
                appointmentSection(title: "Past", appointments: pastAppointments)
            }

            Spacer(minLength: 40)
        }
    }

    @ViewBuilder
    private func appointmentSection(title: String, appointments: [Appointment]) -> some View {
        if !appointments.isEmpty {
            // Section header
            Text(title.uppercased())
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundColor(.secondary)
                .tracking(1.0)
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 10)

            VStack(spacing: 12) {
                ForEach(appointments) { appointment in
                    Button {
                        selectedAppointment = appointment
                    } label: {
                        AppointmentCard(
                            appointment: appointment,
                            customer: customers.first(where: { $0.id == appointment.customerId }),
                            employee: employees.first(where: { $0.id == appointment.salesAssociateId })
                        )
                    }
                    .buttonStyle(AppointmentCardButtonStyle())
                }
            }
            .padding(.horizontal, 20)
        }
    }

    // MARK: - Empty State

    @ViewBuilder
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer(minLength: 60)

            ZStack(alignment: .bottomTrailing) {
                Image(systemName: "calendar.badge.clock")
                    .font(.system(size: 72))
                    .foregroundStyle(
                        Color(.systemBlue).opacity(0.6),
                        Color(.systemBlue).opacity(0.3)
                    )
                    .symbolRenderingMode(.hierarchical)
            }
            .padding(.bottom, 8)

            Text(statusFilter == .completed ? "No Completed Appointments" : "No Appointments Yet")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.primary)

            Text(statusFilter == .completed
                 ? "Completed appointments will appear here."
                 : "Schedule appointments to keep your\nstore operations organized.")
                .font(.system(size: 15))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            if statusFilter != .completed {
                Button {
                    isShowingCreateSheet = true
                } label: {
                    Text("Create Appointment")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(Color(.systemBlue))
                        .cornerRadius(16)
                        .shadow(color: Color(.systemBlue).opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .padding(.horizontal, 32)
                .padding(.top, 12)
            }

            Spacer(minLength: 60)
        }
    }

    // MARK: - Search Empty

    @ViewBuilder
    private var searchEmptyView: some View {
        VStack(spacing: 16) {
            Spacer(minLength: 48)
            Image(systemName: "magnifyingglass")
                .font(.system(size: 44))
                .foregroundColor(Color(.systemGray3))
            Text("No results for \"\(searchText)\"")
                .font(.system(size: 17, weight: .semibold))
            Text("Try a different name, customer, or employee.")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
            Spacer(minLength: 48)
        }
    }

    // MARK: - Loading View

    @ViewBuilder
    private var loadingView: some View {
        VStack {
            Spacer(minLength: 60)
            ProgressView("Loading appointments...")
                .scaleEffect(1.1)
            Spacer(minLength: 60)
        }
    }

    // MARK: - Error View

    @ViewBuilder
    private func errorView(_ message: String) -> some View {
        VStack(spacing: 16) {
            Spacer(minLength: 48)
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 44))
                .foregroundColor(.orange)
            Text(message)
                .font(.system(size: 15))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Button("Retry") {
                Swift.Task { await loadData() }
            }
            .font(.system(size: 15, weight: .semibold))
            .foregroundColor(.white)
            .padding(.horizontal, 28)
            .padding(.vertical, 12)
            .background(Color(.systemBlue))
            .cornerRadius(10)
            Spacer(minLength: 48)
        }
    }

    // MARK: - Load Data

    private func loadData() async {
        isLoading = true
        errorMessage = nil
        do {
            if SessionManager.shared.currentUser == nil {
                await SessionManager.shared.resolveSession()
            }
            
            guard let storeId = SessionManager.shared.currentUser?.storeId else {
                throw NSError(domain: "AppointmentManagementView", code: 401, userInfo: [NSLocalizedDescriptionKey: "No assigned store found for the current manager session."])
            }

            // 1. Fetch appointments scoped to the current store
            let taskResponse = try await SupabaseManager.shared.client
                .from("appointments")
                .select()
                .eq("store_id", value: storeId.uuidString)
                .execute()
            let fetchedAppointments = try JSONDecoder.supabaseDecoder.decodeSupabase([Appointment].self, from: taskResponse.data)
            
            // 2. Fetch users scoped to the current store
            let empResponse = try await SupabaseManager.shared.client
                .from("users")
                .select()
                .eq("store_id", value: storeId.uuidString)
                .execute()
            let fetchedEmployees = try JSONDecoder.supabaseDecoder.decodeSupabase([User].self, from: empResponse.data)
            
            let fetchedStores: [Store] = try await dbService.fetch(from: "stores", as: Store.self)

            // 3. Fetch customers
            let fetchedCustomers: [Customer] = try await dbService.fetch(from: "customers", as: Customer.self)
            
            // 4. Filter employees to exclude system roles (Admin, Manager, Inventory Controller)
            let roleList = try await dbService.fetch(from: "roles", as: Role.self)
            let excludedRoles = ["admin", "manager", "inventory controller"]
            let allowedRoles = roleList.filter { role in
                !excludedRoles.contains(role.roleName.lowercased())
            }
            let allowedRoleIds = Set(allowedRoles.map { $0.id })
            let storeEmployees = fetchedEmployees.filter { allowedRoleIds.contains($0.roleId) }
            
            // Sort by appointment datetime
            self.appointments = fetchedAppointments.sorted {
                $0.appointmentDatetime < $1.appointmentDatetime
            }
            self.employees = storeEmployees
            self.stores = fetchedStores
            self.customers = fetchedCustomers
        } catch {
            errorMessage = "Failed to load appointments.\n\(error.localizedDescription)"
        }
        isLoading = false
    }
}

// MARK: - Appointment Card (Redesigned)

struct AppointmentCard: View {
    let appointment: Appointment
    let customer: Customer?
    let employee: User?

    private var statusColor: Color {
        switch appointment.status.lowercased() {
        case "done":
            return Color(.systemGreen)
        case "open":
            return Color(.systemBlue)
        default:
            return Color(.systemOrange)
        }
    }

    private var isDone: Bool {
        appointment.status.lowercased() == "done"
    }

    private var formattedTime: String {
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        return f.string(from: appointment.appointmentDatetime)
    }

    private var formattedDate: String {
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        return f.string(from: appointment.appointmentDatetime)
    }

    var body: some View {
        HStack(spacing: 14) {
            // Time Column
            VStack(spacing: 4) {
                Text(formattedTime)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(isDone ? .secondary : statusColor)
                Text(formattedDate)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .frame(width: 70)

            // Vertical divider with status dot
            VStack(spacing: 0) {
                Circle()
                    .fill(statusColor)
                    .frame(width: 10, height: 10)
                    .overlay(
                        Circle()
                            .stroke(statusColor.opacity(0.3), lineWidth: 2)
                    )
            }

            // Content
            VStack(alignment: .leading, spacing: 6) {
                // Title
                Text(appointment.appointmentName ?? appointment.description ?? "Appointment")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(isDone ? .secondary : .primary)
                    .lineLimit(1)
                    .strikethrough(isDone, color: .secondary)
                    
                if let desc = appointment.description, appointment.appointmentName != nil {
                    Text(desc)
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                // Customer & Employee row
                HStack(spacing: 12) {
                    if let cust = customer {
                        HStack(spacing: 4) {
                            Image(systemName: "person.fill")
                                .font(.system(size: 10))
                                .foregroundColor(Color(.systemBlue))
                            Text(cust.name)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                    }

                    if let emp = employee {
                        HStack(spacing: 4) {
                            let localProfile = EmployeeProfileStore.shared.get(id: emp.id)
                            if let photoData = localProfile?.profilePhotoData, let uiImage = UIImage(data: photoData) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 16, height: 16)
                                    .clipShape(Circle())
                            } else {
                                Image(systemName: "person.crop.circle.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(Color(.systemGreen))
                            }
                            Text(emp.fullName)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                    }
                }

                // Status badge
                if isDone {
                    Text("Completed")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(Color(.systemGreen))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color(.systemGreen).opacity(0.12))
                        .cornerRadius(6)
                }
            }

            Spacer(minLength: 4)

            // Chevron
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Color(.tertiaryLabel))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(isDone ? 0.03 : 0.06), radius: 10, x: 0, y: 3)
        .opacity(isDone ? 0.7 : 1.0)
    }
}

// MARK: - Appointment Card Button Style

struct AppointmentCardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Create Task View Component (Settings Style)

struct CreateAppointmentView: View {
    @Environment(\.dismiss) private var dismiss

    let stores: [Store]
    let employees: [User]
    let existingAppointments: [Appointment]
    var appointmentToEdit: Appointment? = nil

    @State private var description = ""
    @State private var detailedDescription = ""
    @State private var salesAssociateId: UUID? = nil
    @State private var customerId: UUID? = nil
    @State private var dueDate = Date()
    @State private var employeeSearchText = ""
    @State private var customerSearchText = ""
    @State private var customers: [Customer] = []
    @State private var showingCustomerSheet = false
    @State private var showingEmployeeSheet = false

    @State private var isSubmitting = false
    @State private var alertMessage = ""
    @State private var isShowingAlert = false
    @State private var isShowingSuccess = false

    private let dbService = DatabaseService.shared
    private let avatarPalette: [Color] = [
        Color(.systemBlue), Color(.systemGreen), Color(.systemOrange), Color(.systemPurple)
    ]

    var isFormValid: Bool {
        !description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        salesAssociateId != nil && customerId != nil
    }

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    
                    // SECTION 1 — Appointment Details Card
                    VStack(alignment: .leading, spacing: 16) {
                        
                        // Appointment Name Field
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Appointment Name")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.secondary)
                            TextField("e.g., Client Styling", text: $description)
                                .font(.system(size: 17))
                                .padding(.horizontal, 12)
                                .frame(height: 48)
                                .background(Color(.secondarySystemGroupedBackground))
                                .cornerRadius(10)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color(.systemGray5), lineWidth: 1)
                                )
                                .disableAutocorrection(true)
                        }
                        
                        // Appointment Description Field
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Description (Optional)")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.secondary)
                            TextField("Add details...", text: $detailedDescription, axis: .vertical)
                                .font(.system(size: 17))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 14)
                                .frame(minHeight: 80, alignment: .top)
                                .background(Color(.secondarySystemGroupedBackground))
                                .cornerRadius(10)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color(.systemGray5), lineWidth: 1)
                                )
                                .disableAutocorrection(true)
                        }
                        
                        // Date & Time Picker
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Date & Time")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.secondary)
                            DatePicker("", selection: $dueDate, in: Date()..., displayedComponents: [.date, .hourAndMinute])
                                .labelsHidden()
                                .datePickerStyle(.compact)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 12)
                                .frame(height: 48)
                                .background(Color(.secondarySystemGroupedBackground))
                                .cornerRadius(10)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color(.systemGray5), lineWidth: 1)
                                )
                        }

                    }
                    .padding(20)
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(22)
                    .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 4)

                    // SECTION 1.5 - Assign Customer Section
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Customer")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.secondary)
                            
                        Button {
                            showingCustomerSheet = true
                        } label: {
                            HStack {
                                if let selectedId = customerId, let cust = customers.first(where: { $0.id == selectedId }) {
                                    ZStack {
                                        Circle()
                                            .fill(avatarPalette[abs(cust.name.hashValue) % avatarPalette.count])
                                            .frame(width: 32, height: 32)
                                        Text(initials(for: cust.name))
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundColor(.white)
                                    }
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(cust.name)
                                            .font(.system(size: 15, weight: .medium))
                                            .foregroundColor(.primary)
                                        Text(cust.phone)
                                            .font(.system(size: 12))
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    Button {
                                        customerId = nil
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(Color(.systemGray3))
                                            .font(.system(size: 20))
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                } else {
                                    Image(systemName: "person.crop.circle")
                                        .font(.system(size: 24))
                                        .foregroundColor(.secondary)
                                    Text("Select Customer")
                                        .font(.system(size: 17))
                                        .foregroundColor(.primary)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(Color(.tertiaryLabel))
                                }
                            }
                            .padding(.horizontal, 12)
                            .frame(height: 56)
                            .background(Color(.secondarySystemGroupedBackground))
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color(.systemGray5), lineWidth: 1)
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    
                    // SECTION 2 — Assign Staff Section
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Employee")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.secondary)
                            
                        Button {
                            showingEmployeeSheet = true
                        } label: {
                            HStack {
                                if let selectedId = salesAssociateId, let emp = employees.first(where: { $0.id == selectedId }) {
                                    let localProfile = EmployeeProfileStore.shared.get(id: emp.id)
                                    if let photoData = localProfile?.profilePhotoData, let uiImage = UIImage(data: photoData) {
                                        Image(uiImage: uiImage)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 32, height: 32)
                                            .clipShape(Circle())
                                    } else {
                                        ZStack {
                                            Circle()
                                                .fill(avatarPalette[abs(emp.fullName.hashValue) % avatarPalette.count])
                                                .frame(width: 32, height: 32)
                                            Text(initials(for: emp.fullName))
                                                .font(.system(size: 10, weight: .bold))
                                                .foregroundColor(.white)
                                        }
                                    }
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(emp.fullName)
                                            .font(.system(size: 15, weight: .medium))
                                            .foregroundColor(.primary)
                                        Text(emp.designation ?? localProfile?.jobRole ?? "Staff")
                                            .font(.system(size: 12))
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    Button {
                                        salesAssociateId = nil
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(Color(.systemGray3))
                                            .font(.system(size: 20))
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                } else {
                                    Image(systemName: "person.crop.circle.badge.plus")
                                        .font(.system(size: 24))
                                        .foregroundColor(.secondary)
                                    Text("Select Employee")
                                        .font(.system(size: 17))
                                        .foregroundColor(.primary)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(Color(.tertiaryLabel))
                                }
                            }
                            .padding(.horizontal, 12)
                            .frame(height: 56)
                            .background(Color(.secondarySystemGroupedBackground))
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color(.systemGray5), lineWidth: 1)
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 32)
            }
        }
        .onAppear {
            if let edit = appointmentToEdit {
                description = edit.appointmentName ?? ""
                detailedDescription = edit.description ?? ""
                salesAssociateId = edit.salesAssociateId
                customerId = edit.customerId
                dueDate = edit.appointmentDatetime
            }
        }
        .task {
            do {
                let fetchedCustomers = try await dbService.fetch(from: "customers", as: Customer.self)
                await MainActor.run {
                    self.customers = fetchedCustomers
                }
            } catch {
                print("Failed to fetch customers: \(error)")
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    ZStack {
                        Circle()
                            .fill(Color(.systemGray6))
                            .frame(width: 32, height: 32)
                        Image(systemName: "xmark")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.primary)
                    }
                }
            }
            ToolbarItem(placement: .principal) {
                Text(appointmentToEdit == nil ? "Create Appointment" : "Edit Appointment")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.primary)
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    saveAppointment()
                } label: {
                    Text("Done")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(isFormValid ? Color(.systemBlue) : Color(.secondaryLabel))
                }
                .disabled(!isFormValid || isSubmitting)
            }
        }
        .sheet(isPresented: $showingCustomerSheet) {
            CustomerPickerSheet(
                customers: customers,
                selectedCustomerId: $customerId,
                searchText: $customerSearchText
            )
            .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showingEmployeeSheet) {
            EmployeePickerSheet(
                employees: employees,
                selectedEmployeeId: $salesAssociateId,
                searchText: $employeeSearchText
            )
            .presentationDetents([.medium, .large])
        }
        .alert("Status", isPresented: $isShowingAlert) {
            Button("OK") { if isShowingSuccess { dismiss() } }
        } message: {
            Text(alertMessage)
        }
    }

    private func saveAppointment() {
        guard isFormValid else { return }
        
        let nameTrimmed = description.trimmingCharacters(in: .whitespacesAndNewlines)
        if existingAppointments.contains(where: { ($0.appointmentName ?? "").lowercased() == nameTrimmed.lowercased() && $0.id != appointmentToEdit?.id }) {
            alertMessage = "An appointment with the name '\(nameTrimmed)' already exists."
            isShowingAlert = true
            return
        }

        guard let currentUser = SessionManager.shared.currentUser else {
            alertMessage = "Your session has expired. Please sign in again."
            isShowingAlert = true
            return
        }

        isSubmitting = true

        Swift.Task {
            let finalName = description.trimmingCharacters(in: .whitespacesAndNewlines)
            let finalDesc = detailedDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : detailedDescription.trimmingCharacters(in: .whitespacesAndNewlines)
            
            do {
                if let edit = appointmentToEdit {
                    let updatedAppointment = Appointment(
                        id: edit.id,
                        customerId: customerId,
                        storeId: edit.storeId,
                        salesAssociateId: salesAssociateId,
                        appointmentDatetime: dueDate,
                        appointmentName: finalName,
                        description: finalDesc,
                        status: edit.status,
                        createdBy: edit.createdBy,
                        createdAt: edit.createdAt,
                        updatedAt: Date()
                    )
                    try await dbService.update(table: "appointments", value: updatedAppointment, column: "id", equals: edit.id.uuidString.lowercased())
                    alertMessage = "Appointment updated successfully."
                } else {
                    let newTaskId = UUID()
                    let newAppointment = Appointment(
                        id: newTaskId,
                        customerId: customerId,
                        storeId: SessionManager.shared.currentUser?.storeId ?? stores.first?.id ?? UUID(),
                        salesAssociateId: salesAssociateId,
                        appointmentDatetime: dueDate,
                        appointmentName: finalName,
                        description: finalDesc,
                        status: "open",
                        createdBy: SessionManager.shared.currentUser?.id,
                        createdAt: Date(),
                        updatedAt: Date()
                    )
                    try await dbService.insert(into: "appointments", value: newAppointment)
                    alertMessage = "Appointment created successfully."
                }
                
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                isShowingSuccess = true
                isShowingAlert = true
            } catch {
                UINotificationFeedbackGenerator().notificationOccurred(.error)
                isShowingSuccess = false
                alertMessage = "Failed to create appointment: \(error.localizedDescription)"
                isShowingAlert = true
            }
            isSubmitting = false
        }
    }

    private func initials(for name: String) -> String {
        let components = name.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        if components.count >= 2 {
            return "\(components[0].prefix(1))\(components[components.count - 1].prefix(1))".uppercased()
        }
        return String(name.prefix(2)).uppercased()
    }
}

// MARK: - Task Detail View Component

struct AppointmentDetailView: View {
    @Environment(\.dismiss) private var dismiss

    let appointment: Appointment
    let employees: [User]
    let stores: [Store]
    let existingAppointments: [Appointment]
    var onUpdate: () -> Void

    @State private var isUpdating = false
    @State private var isShowingDeleteAlert = false
    @State private var isShowingEditSheet = false

    private let dbService = DatabaseService.shared

    var assignedEmployee: User? {
        employees.first(where: { $0.id == appointment.salesAssociateId })
    }

    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("Appointment Details")) {
                    InfoRow(label: "Title", value: (appointment.appointmentName ?? appointment.description ?? "Appointment"))
                    InfoRow(label: "Status", value: appointment.status)
                    InfoRow(label: "Time", value: formattedDueDate(appointment.appointmentDatetime))
                }

                if let desc = appointment.description {
                    Section(header: Text("Description")) {
                        Text(desc)
                            .font(.system(size: 15))
                            .foregroundColor(Color(.label))
                            .padding(.vertical, 2)
                    }
                }

                Section(header: Text("Audit Details")) {
                    InfoRow(label: "Created On", value: formatCreatedDate(appointment.createdAt))
                    InfoRow(label: "Created By", value: resolveCreatorName(appointment.createdBy))
                }

                Section(header: Text("Assigned Staff")) {
                    if let emp = assignedEmployee {
                        let localProfile = EmployeeProfileStore.shared.get(id: emp.id)
                        HStack {
                            if let photoData = localProfile?.profilePhotoData, let uiImage = UIImage(data: photoData) {
                                Image(uiImage: uiImage)
                                    .resizable().scaledToFill()
                                    .frame(width: 38, height: 38).clipShape(Circle())
                            } else {
                                Text(String(emp.fullName.prefix(2)).uppercased())
                                    .font(.system(size: 12, weight: .bold)).foregroundColor(.white)
                                    .frame(width: 38, height: 38)
                                    .background(Color(.systemBlue)).clipShape(Circle())
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                Text(emp.fullName).font(.system(size: 15, weight: .semibold))
                                Text(emp.designation ?? localProfile?.jobRole ?? "Staff")
                                    .font(.system(size: 12)).foregroundColor(Color(.secondaryLabel))
                            }
                            .padding(.leading, 4)
                        }
                        .padding(.vertical, 2)
                    } else {
                        Text("No one assigned.")
                            .foregroundColor(.secondary)
                    }
                }

                Section {
                    Button(role: .destructive) {
                        isShowingDeleteAlert = true
                    } label: {
                        HStack {
                            Spacer()
                            if isUpdating { ProgressView().padding(.trailing, 8) }
                            Text("Delete Appointment")
                                .font(.system(size: 17, weight: .bold))
                                .foregroundColor(.red)
                            Spacer()
                        }
                    }
                    .disabled(isUpdating)
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Appointment Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) { Button("Close") { dismiss() } }
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        Button("Edit") {
                            isShowingEditSheet = true
                        }
                        .font(.system(size: 14, weight: .bold))
                        
                        if appointment.status != "done" {
                            Button("Mark Completed") {
                                Swift.Task { await markCompleted() }
                            }
                            .font(.system(size: 14, weight: .bold))
                            .disabled(isUpdating)
                        }
                    }
                }
            }
            .sheet(isPresented: $isShowingEditSheet, onDismiss: {
                onUpdate()
                dismiss() // Close the detail view after edit so the user sees the updated list
            }) {
                NavigationStack {
                    CreateAppointmentView(
                        stores: stores,
                        employees: employees,
                        existingAppointments: existingAppointments,
                        appointmentToEdit: appointment
                    )
                }
            }
            .alert("Delete Appointment?", isPresented: $isShowingDeleteAlert) {
                Button("Delete", role: .destructive) { Swift.Task { await deleteTask() } }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Are you sure you want to delete '\((appointment.appointmentName ?? appointment.description ?? "Appointment"))'?")
            }
        }
    }

    private func markCompleted() async {
        isUpdating = true
        let updated = Appointment(
            id: appointment.id, 
            customerId: appointment.customerId,
            storeId: appointment.storeId, 
            salesAssociateId: appointment.salesAssociateId, 
            appointmentDatetime: appointment.appointmentDatetime,
            appointmentName: appointment.appointmentName,
            description: appointment.description, 
            status: "done", 
            createdBy: appointment.createdBy, 
            createdAt: appointment.createdAt, 
            updatedAt: Date()
        )
        do {
            try await dbService.update(table: "appointments", value: updated, column: "id", equals: appointment.id.uuidString.lowercased())
            onUpdate()
            dismiss()
        } catch {
            print("Failed to complete appointment: \(error)")
        }
        isUpdating = false
    }

    private func deleteTask() async {
        isUpdating = true
        do {
            try await dbService.delete(from: "appointments", column: "id", equals: appointment.id.uuidString.lowercased())
            onUpdate()
            dismiss()
        } catch {
            print("Failed to delete appointment: \(error)")
        }
        isUpdating = false
    }

    private func formattedDueDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "MMM d, yyyy h:mm a"
        return f.string(from: date)
    }

    private func resolveCreatorName(_ creatorId: UUID?) -> String {
        guard let creatorId = creatorId else { return "Unknown" }
        if let emp = employees.first(where: { $0.id == creatorId }) {
            return emp.fullName
        }
        if let current = SessionManager.shared.currentUser, current.id == creatorId {
            return current.fullName
        }
        return "Store Manager"
    }

    private func formatCreatedDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "MMM d, yyyy"
        return f.string(from: date)
    }
}

// MARK: - Completed Appointments View

struct CompletedAppointmentsView: View {
    let employees: [User]
    let stores: [Store]

    @State private var completedAppointments: [Appointment] = []
    @State private var isLoading = true
    @State private var errorMessage: String? = nil
    @State private var selectedAppointment: Appointment? = nil

    private let dbService = DatabaseService.shared

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                // Soft Divider at the top
                Rectangle()
                    .fill(Color(.systemGray5).opacity(0.8))
                    .frame(height: 1)
                    .padding(.horizontal, 20)
                    .padding(.top, 10)

                // Header Row
                HStack(alignment: .center) {
                    Text("Completed Appointments (\(completedAppointments.count))")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.primary)
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 18)
                .padding(.bottom, 16)

                // Content Area
                if isLoading {
                    VStack {
                        Spacer(minLength: 60)
                        ProgressView("Loading completed appointments...")
                            .scaleEffect(1.1)
                        Spacer(minLength: 60)
                    }
                } else if let error = errorMessage {
                    VStack(spacing: 16) {
                        Spacer(minLength: 48)
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 44))
                            .foregroundColor(.orange)
                        Text(error)
                            .font(.system(size: 15))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                        Spacer(minLength: 48)
                    }
                } else if completedAppointments.isEmpty {
                    VStack(spacing: 16) {
                        Spacer(minLength: 48)
                        Image(systemName: "checkmark.circle")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        Text("No completed appointments yet")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.secondary)
                        Spacer(minLength: 48)
                    }
                } else {
                    VStack(spacing: 16) {
                        ForEach(completedAppointments) { appointment in
                            Button {
                                selectedAppointment = appointment
                            } label: {
                                AppointmentCard(
                                    appointment: appointment,
                                    customer: nil,
                                    employee: employees.first(where: { $0.id == appointment.salesAssociateId })
                                )
                            }
                            .buttonStyle(AppointmentCardButtonStyle())
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("History")
        .navigationBarTitleDisplayMode(.inline)
        .task { await loadCompletedTasks() }
        .sheet(item: $selectedAppointment, onDismiss: {
            Swift.Task { await loadCompletedTasks() }
        }) { appointment in
            AppointmentDetailView(
                appointment: appointment,
                employees: employees,
                stores: stores,
                existingAppointments: completedAppointments,
                onUpdate: { Swift.Task { await loadCompletedTasks() } }
            )
        }
    }

    private func loadCompletedTasks() async {
        isLoading = true
        errorMessage = nil
        do {
            guard let storeId = SessionManager.shared.currentUser?.storeId else {
                throw NSError(domain: "CompletedAppointmentsView", code: 401, userInfo: [NSLocalizedDescriptionKey: "No assigned store found."])
            }
            let taskResponse = try await SupabaseManager.shared.client
                .from("appointments")
                .select()
                .eq("store_id", value: storeId.uuidString)
                .eq("status", value: "done")
                .execute()
            let fetchedAppointments = try JSONDecoder.supabaseDecoder.decodeSupabase([Appointment].self, from: taskResponse.data)
            self.completedAppointments = fetchedAppointments.sorted { $0.updatedAt > $1.updatedAt }
        } catch {
            errorMessage = "Failed to load completed appointments: \(error.localizedDescription)"
        }
        isLoading = false
    }
}

// MARK: - Picker Sheets

struct CustomerPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    let customers: [Customer]
    @Binding var selectedCustomerId: UUID?
    @Binding var searchText: String
    
    private let avatarPalette: [Color] = [
        Color(.systemBlue), Color(.systemGreen), Color(.systemOrange), Color(.systemPurple)
    ]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Search customer name or phone", text: $searchText)
                        .font(.system(size: 16))
                        .disableAutocorrection(true)
                        .keyboardType(.default)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color(.secondarySystemGroupedBackground))
                .cornerRadius(12)
                .padding()
                
                let filteredCustomers = customers.filter { cust in
                    if searchText.isEmpty { return true }
                    let query = searchText.lowercased()
                    return cust.name.lowercased().contains(query) || cust.phone.contains(query)
                }
                
                if filteredCustomers.isEmpty {
                    Spacer()
                    Text(customers.isEmpty ? "Loading customers..." : "No customers found")
                        .foregroundColor(.secondary)
                    Spacer()
                } else {
                    List(filteredCustomers) { cust in
                        Button {
                            selectedCustomerId = cust.id
                            dismiss()
                        } label: {
                            HStack(spacing: 12) {
                                ZStack {
                                    Circle()
                                        .fill(avatarPalette[abs(cust.name.hashValue) % avatarPalette.count])
                                        .frame(width: 40, height: 40)
                                    Text(initials(for: cust.name))
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(.white)
                                }
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(cust.name)
                                        .font(.system(size: 17, weight: .medium))
                                        .foregroundColor(.primary)
                                    Text(cust.phone)
                                        .font(.system(size: 14))
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                if selectedCustomerId == cust.id {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                        .font(.system(size: 16, weight: .bold))
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Select Customer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.system(size: 17, weight: .semibold))
                }
            }
        }
    }
    
    private func initials(for name: String) -> String {
        let components = name.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        if components.count >= 2 {
            return "\(components[0].prefix(1))\(components[components.count - 1].prefix(1))".uppercased()
        }
        return String(name.prefix(2)).uppercased()
    }
}

struct EmployeePickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    let employees: [User]
    @Binding var selectedEmployeeId: UUID?
    @Binding var searchText: String
    
    private let avatarPalette: [Color] = [
        Color(.systemBlue), Color(.systemGreen), Color(.systemOrange), Color(.systemPurple)
    ]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Search employee", text: $searchText)
                        .font(.system(size: 16))
                        .disableAutocorrection(true)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color(.secondarySystemGroupedBackground))
                .cornerRadius(12)
                .padding()
                
                let filteredEmployees = employees.filter { emp in
                    if searchText.isEmpty { return true }
                    let query = searchText.lowercased()
                    let localProfile = EmployeeProfileStore.shared.get(id: emp.id)
                    let roleName = emp.designation ?? localProfile?.jobRole ?? "Staff"
                    return emp.fullName.lowercased().contains(query) || roleName.lowercased().contains(query)
                }
                
                if filteredEmployees.isEmpty {
                    Spacer()
                    Text("No employees found")
                        .foregroundColor(.secondary)
                    Spacer()
                } else {
                    List(filteredEmployees) { emp in
                        Button {
                            selectedEmployeeId = emp.id
                            dismiss()
                        } label: {
                            HStack(spacing: 12) {
                                let localProfile = EmployeeProfileStore.shared.get(id: emp.id)
                                if let photoData = localProfile?.profilePhotoData, let uiImage = UIImage(data: photoData) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 40, height: 40)
                                        .clipShape(Circle())
                                } else {
                                    ZStack {
                                        Circle()
                                            .fill(avatarPalette[abs(emp.fullName.hashValue) % avatarPalette.count])
                                            .frame(width: 40, height: 40)
                                        Text(initials(for: emp.fullName))
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundColor(.white)
                                    }
                                }
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(emp.fullName)
                                        .font(.system(size: 17, weight: .medium))
                                        .foregroundColor(.primary)
                                    Text(emp.designation ?? localProfile?.jobRole ?? "Staff")
                                        .font(.system(size: 14))
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                if selectedEmployeeId == emp.id {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                        .font(.system(size: 16, weight: .bold))
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Select Employee")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.system(size: 17, weight: .semibold))
                }
            }
        }
    }
    
    private func initials(for name: String) -> String {
        let components = name.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        if components.count >= 2 {
            return "\(components[0].prefix(1))\(components[components.count - 1].prefix(1))".uppercased()
        }
        return String(name.prefix(2)).uppercased()
    }
}
