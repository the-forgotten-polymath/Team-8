import SwiftUI
import Supabase

@MainActor
final class AppointmentManagementViewModel: ObservableObject {
    @Published var appointments: [Appointment] = []
    @Published var customers: [Customer] = []
    @Published var users: [User] = []
    @Published var stores: [Store] = []
    @Published var isLoading = false
    @Published var errorMessage: String? = nil

    private let client = SupabaseManager.shared.client
    private let dbService = DatabaseService.shared

    func loadData() async {
        isLoading = true
        errorMessage = nil
        do {
            guard let currentUser = SessionManager.shared.currentUser,
                  let storeId = currentUser.storeId else {
                throw URLError(.badURL)
            }
            
            // Fetch appointments for this store
            let apptResponse = try await client
                .from("appointments")
                .select()
                .eq("store_id", value: storeId.uuidString)
                .order("appointment_datetime", ascending: true)
                .execute()
            self.appointments = try JSONDecoder.supabaseDecoder.decodeSupabase([Appointment].self, from: apptResponse.data)
            
            // Fetch related data
            self.customers = try await dbService.fetch(from: "customers", as: Customer.self)
            
            let usersResponse = try await client
                .from("users")
                .select()
                .eq("store_id", value: storeId.uuidString)
                .execute()
            self.users = try JSONDecoder.supabaseDecoder.decodeSupabase([User].self, from: usersResponse.data)
            
            self.stores = try await dbService.fetch(from: "stores", as: Store.self)
        } catch {
            print("Error loading appointment data: \(error)")
            self.errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func deleteAppointment(_ appt: Appointment) async {
        do {
            try await client
                .from("appointments")
                .delete()
                .eq("id", value: appt.id.uuidString)
                .execute()
            await loadData()
        } catch {
            print("Failed to delete appointment: \(error)")
            self.errorMessage = error.localizedDescription
        }
    }
}

struct AppointmentManagementView: View {
    @StateObject private var viewModel = AppointmentManagementViewModel()
    @State private var showingAddSheet = false
    @State private var selectedAppointment: Appointment?
    @State private var selectedStatusFilter = "All"
    
    let statuses = ["All", "pending", "attended", "missed", "cancelled"]

    var filteredAppointments: [Appointment] {
        if selectedStatusFilter == "All" {
            return viewModel.appointments
        }
        return viewModel.appointments.filter { $0.computedStatus == selectedStatusFilter }
    }

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            if viewModel.isLoading && viewModel.appointments.isEmpty {
                ProgressView("Loading Appointments...")
            } else {
                VStack(spacing: 0) {
                    // Header
                    HStack {
                        Text("Appointments")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        Spacer()
                        Button(action: { showingAddSheet = true }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 28))
                                .foregroundColor(.blue)
                        }
                    }
                    .padding()
                    
                    // Filter
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(statuses, id: \.self) { status in
                                FilterChip(
                                    title: status.capitalized,
                                    isSelected: selectedStatusFilter == status,
                                    action: {
                                        withAnimation { selectedStatusFilter = status }
                                    }
                                )
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 12)
                    }

                    if filteredAppointments.isEmpty {
                        Spacer()
                        VStack(spacing: 16) {
                            Image(systemName: "calendar.badge.exclamationmark")
                                .font(.system(size: 64))
                                .foregroundColor(Color(.tertiaryLabel))
                            Text("No appointments found")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(Color(.secondaryLabel))
                        }
                        Spacer()
                    } else {
                        List {
                            ForEach(filteredAppointments) { appt in
                                AppointmentRowView(
                                    appointment: appt,
                                    customers: viewModel.customers
                                )
                                .onTapGesture {
                                    selectedAppointment = appt
                                }
                            }
                            .onDelete { indexSet in
                                for index in indexSet {
                                    let appt = filteredAppointments[index]
                                    Swift.Task {
                                        await viewModel.deleteAppointment(appt)
                                    }
                                }
                            }
                        }
                        .listStyle(.insetGrouped)
                    }
                }
            }
        }
        .onAppear {
            Swift.Task { await viewModel.loadData() }
        }
        .sheet(isPresented: $showingAddSheet) {
            AddAppointmentSheet(
                customers: viewModel.customers,
                users: viewModel.users,
                onSave: {
                    Swift.Task { await viewModel.loadData() }
                }
            )
        }
        .sheet(item: $selectedAppointment) { appt in
            AppointmentDetailView(
                appointment: appt,
                customers: viewModel.customers,
                users: viewModel.users,
                existingAppointments: viewModel.appointments,
                stores: viewModel.stores
            )
            .onDisappear {
                Swift.Task { await viewModel.loadData() }
            }
        }
    }
}

// MARK: - Filter Chip
struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.blue : Color(.secondarySystemGroupedBackground))
                .foregroundColor(isSelected ? .white : Color(.label))
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(isSelected ? Color.blue : Color(.systemGray4), lineWidth: 1)
                )
        }
    }
}

// MARK: - Row View
struct AppointmentRowView: View {
    let appointment: Appointment
    let customers: [Customer]

    var body: some View {
        HStack(spacing: 16) {
            // Date Badge
            VStack(spacing: 4) {
                Text(formatMonth(appointment.appointmentDatetime))
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
                    .textCase(.uppercase)
                Text(formatDay(appointment.appointmentDatetime))
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(Color(.label))
                Text(formatTime(appointment.appointmentDatetime))
                    .font(.caption2)
                    .foregroundColor(Color(.secondaryLabel))
            }
            .frame(width: 60)
            .padding(.vertical, 8)
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(12)

            VStack(alignment: .leading, spacing: 6) {
                Text(appointment.appointmentName ?? appointment.description ?? "Appointment")
                    .font(.headline)
                    .foregroundColor(Color(.label))
                    .lineLimit(1)
                
                if let customerId = appointment.customerId,
                   let customer = customers.first(where: { $0.id == customerId }) {
                    HStack(spacing: 4) {
                        Image(systemName: "person.fill")
                            .font(.caption)
                        Text(customer.name)
                            .font(.subheadline)
                    }
                    .foregroundColor(Color(.secondaryLabel))
                }
                
                StatusBadge(status: appointment.computedStatus)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundColor(Color(.tertiaryLabel))
                .font(.system(size: 14, weight: .bold))
        }
        .padding(.vertical, 4)
        .opacity(appointment.computedStatus == "cancelled" ? 0.5 : 1.0)
    }

    private func formatMonth(_ date: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "MMM"; return f.string(from: date)
    }
    private func formatDay(_ date: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "d"; return f.string(from: date)
    }
    private func formatTime(_ date: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "h:mm a"; return f.string(from: date)
    }
}

// MARK: - Status Badge
struct StatusBadge: View {
    let status: String
    var body: some View {
        Text(status.capitalized)
            .font(.caption2)
            .fontWeight(.bold)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(colorForStatus(status).opacity(0.15))
            .foregroundColor(colorForStatus(status))
            .cornerRadius(8)
    }
    
    private func colorForStatus(_ status: String) -> Color {
        switch status.lowercased() {
        case "pending": return .orange
        case "attended": return .green
        case "missed": return .red
        case "cancelled": return .gray
        default: return .gray
        }
    }
}

// MARK: - Add Appointment Sheet

// MARK: - Generic Selection List View
struct SelectionListView<T: Identifiable, Content: View>: View {
    let title: String
    let items: [T]
    @Binding var selection: T.ID?
    let rowContent: (T) -> Content

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List {
            Button(action: {
                selection = nil
                dismiss()
            }) {
                HStack {
                    Text("None")
                    Spacer()
                    if selection == nil {
                        Image(systemName: "checkmark").foregroundColor(.blue)
                    }
                }
            }
            .foregroundColor(.primary)

            ForEach(items) { item in
                Button(action: {
                    selection = item.id
                    dismiss()
                }) {
                    HStack {
                        rowContent(item)
                        Spacer()
                        if selection == item.id {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                }
                .foregroundColor(.primary)
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct AddAppointmentSheet: View {
    @Environment(\.dismiss) private var dismiss
    let customers: [Customer]
    let users: [User]
    let onSave: () -> Void

    @State private var appointmentName = ""
    @State private var descriptionText = ""
    @State private var selectedDate = Date()
    @State private var selectedCustomerId: UUID?
    @State private var selectedEmployeeId: UUID?
    @State private var isSaving = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Details")) {
                    TextField("Appointment Name", text: $appointmentName)
                    TextField("Description (Optional)", text: $descriptionText)
                    DatePicker("Date & Time", selection: $selectedDate)
                }

                Section(header: Text("Assignments")) {
                    NavigationLink {
                        SelectionListView(title: "Select Customer", items: customers, selection: $selectedCustomerId) { customer in
                            Text(customer.name)
                        }
                    } label: {
                        HStack {
                            Text("Customer")
                            Spacer()
                            if let id = selectedCustomerId, let cust = customers.first(where: { $0.id == id }) {
                                Text(cust.name).foregroundColor(.secondary)
                            } else {
                                Text("None").foregroundColor(.secondary)
                            }
                        }
                    }

                    NavigationLink {
                        SelectionListView(title: "Select Employee", items: users, selection: $selectedEmployeeId) { user in
                            Text(user.fullName)
                        }
                    } label: {
                        HStack {
                            Text("Assigned Employee")
                            Spacer()
                            if let id = selectedEmployeeId, let emp = users.first(where: { $0.id == id }) {
                                Text(emp.fullName).foregroundColor(.secondary)
                            } else {
                                Text("None").foregroundColor(.secondary)
                            }
                        }
                    }
                }
                
                if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("New Appointment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") { saveAppointment() }
                        .disabled(appointmentName.trimmingCharacters(in: .whitespaces).isEmpty || isSaving)
                }
            }
        }
    }

    private func saveAppointment() {
        guard let storeId = SessionManager.shared.currentUser?.storeId,
              let currentUserId = SessionManager.shared.currentUser?.id else { return }

        isSaving = true
        errorMessage = nil

        let newAppt = Appointment(
            id: UUID(),
            customerId: selectedCustomerId,
            storeId: storeId,
            salesAssociateId: selectedEmployeeId,
            appointmentDatetime: selectedDate,
            appointmentName: appointmentName.isEmpty ? nil : appointmentName,
            description: descriptionText.isEmpty ? nil : descriptionText,
            status: "pending",
            createdBy: currentUserId,
            createdAt: Date(),
            updatedAt: Date()
        )

        Swift.Task {
            do {
                try await SupabaseManager.shared.client
                    .from("appointments")
                    .insert(newAppt)
                    .execute()
                
                await MainActor.run {
                    onSave()
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isSaving = false
                }
            }
        }
    }
}

// MARK: - Appointment Detail View
struct AppointmentDetailView: View {
    let appointment: Appointment
    let customers: [Customer]
    let users: [User]
    let existingAppointments: [Appointment]
    let stores: [Store]
    
    @Environment(\.dismiss) private var dismiss
    @State private var isEditing = false
    @State private var editedName = ""
    @State private var editedDesc = ""
    @State private var editedDate = Date()
    @State private var editedStatus = ""
    @State private var isSaving = false

    var body: some View {
        NavigationStack {
            Form {
                if isEditing {
                    Section(header: Text("Edit Details")) {
                        TextField("Name", text: $editedName)
                        TextField("Description", text: $editedDesc)
                        DatePicker("Date & Time", selection: $editedDate)
                    }
                } else {
                    Section {
                        VStack(alignment: .leading, spacing: 12) {
                            Text(appointment.appointmentName ?? "Appointment")
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            if let desc = appointment.description {
                                Text(desc)
                                    .font(.body)
                                    .foregroundColor(Color(.secondaryLabel))
                            }
                            
                            HStack {
                                Image(systemName: "calendar.badge.clock")
                                    .foregroundColor(.blue)
                                Text(appointment.appointmentDatetime.formatted(date: .long, time: .shortened))
                                    .font(.subheadline)
                            }
                            
                            HStack {
                                StatusBadge(status: appointment.computedStatus)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                    
                    if let customerId = appointment.customerId,
                       let customer = customers.first(where: { $0.id == customerId }) {
                        Section(header: Text("Customer")) {
                            HStack {
                                Image(systemName: "person.circle.fill")
                                    .font(.title)
                                    .foregroundColor(.gray)
                                VStack(alignment: .leading) {
                                    Text(customer.name).font(.headline)
                                    Text(customer.phone).font(.subheadline).foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                    
                    if !isEditing && (appointment.computedStatus == "pending" || appointment.computedStatus == "missed") {
                        Section {
                            Button(action: { updateStatus(to: "attended") }) {
                                HStack {
                                    Spacer()
                                    Text("Mark Attended")
                                        .fontWeight(.semibold)
                                        .foregroundColor(.white)
                                    Spacer()
                                }
                            }
                            .listRowBackground(Color.green)
                            
                            Button(action: { updateStatus(to: "cancelled") }) {
                                HStack {
                                    Spacer()
                                    Text("Cancel Appointment")
                                        .fontWeight(.semibold)
                                        .foregroundColor(.red)
                                    Spacer()
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Appointment" : "Appointment Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if isEditing {
                        Button("Cancel") { isEditing = false }
                    } else {
                        Button("Done") { dismiss() }
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    if isEditing {
                        Button("Save") { saveChanges() }
                            .disabled(isSaving)
                    } else {
                        Button("Edit") {
                            editedName = appointment.appointmentName ?? ""
                            editedDesc = appointment.description ?? ""
                            editedDate = appointment.appointmentDatetime
                            editedStatus = appointment.status
                            isEditing = true
                        }
                    }
                }
            }
        }
    }


    private func updateStatus(to newStatus: String) {
        isSaving = true
        let updateData: [String: AnyJSON] = [
            "status": .string(newStatus),
            "updated_at": .string(Date().ISO8601Format())
        ]
        Swift.Task {
            do {
                try await SupabaseManager.shared.client
                    .from("appointments")
                    .update(updateData)
                    .eq("id", value: appointment.id.uuidString)
                    .execute()
                await MainActor.run { dismiss() }
            } catch {
                print("Status update failed: \(error)")
                await MainActor.run { isSaving = false }
            }
        }
    }

    private func saveChanges() {
        isSaving = true
        let updateData: [String: AnyJSON] = [
            "appointment_name": .string(editedName),
            "description": .string(editedDesc),
            "appointment_datetime": .string(editedDate.ISO8601Format()),
            "updated_at": .string(Date().ISO8601Format())
        ]

        Swift.Task {
            do {
                try await SupabaseManager.shared.client
                    .from("appointments")
                    .update(updateData)
                    .eq("id", value: appointment.id.uuidString)
                    .execute()
                
                await MainActor.run {
                    dismiss()
                }
            } catch {
                print("Update failed: \(error)")
                await MainActor.run { isSaving = false }
            }
        }
    }
}
