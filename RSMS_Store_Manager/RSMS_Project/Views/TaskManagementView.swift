//
//  TaskManagementView.swift
//  RSMS_Project
//
//  Created by Yatharth Mishra on 30/06/26.
//

import SwiftUI
import Supabase

struct TaskManagementView: View {
    @State private var tasks: [Task] = []
    @State private var employees: [User] = []
    @State private var stores: [Store] = []

    @State private var searchText = ""
    @State private var isLoading = true
    @State private var errorMessage: String? = nil

    @State private var selectedTask: Task? = nil
    private let dbService = DatabaseService.shared

    var filteredTasks: [Task] {
        let pending = tasks.filter { $0.status != "done" }
        if searchText.isEmpty { return pending }
        let q = searchText.lowercased()
        return pending.filter { task in
            if task.title.lowercased().contains(q) { return true }
            if let desc = task.description, desc.lowercased().contains(q) { return true }
            if let assignedEmp = employees.first(where: { $0.id == task.assignedTo }),
               assignedEmp.fullName.lowercased().contains(q) {
                return true
            }
            return false
        }
    }

    var appointments: [Task] {
        filteredTasks.filter { ($0.taskType?.lowercased() ?? "task") != "task" }
    }

    var standardTasks: [Task] {
        filteredTasks.filter { ($0.taskType?.lowercased() ?? "task") == "task" }
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                
                // Soft Divider at the top
                Rectangle()
                    .fill(Color(.systemGray5).opacity(0.8))
                    .frame(height: 1)
                    .padding(.horizontal, 20)
                    .padding(.top, 10)



                // Content Area
                if isLoading {
                    loadingView
                } else if let error = errorMessage {
                    errorView(error)
                } else if filteredTasks.isEmpty && searchText.isEmpty {
                    emptyStateView
                } else if filteredTasks.isEmpty {
                    searchEmptyView
                } else {
                    taskListContent
                }
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Task Management")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searchText, prompt: "Search tasks...")
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Task Management")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.primary)
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink(destination: CompletedTasksView(employees: employees, stores: stores)) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.blue)
                }
            }
        }
        .task { await loadData() }
        .onAppear {
            Swift.Task { await loadData() }
        }
        .sheet(item: $selectedTask, onDismiss: {
            Swift.Task { await loadData() }
        }) { task in
            TaskDetailView(
                task: task,
                employees: employees,
                onUpdate: { Swift.Task { await loadData() } }
            )
        }
    }

    // MARK: - Task List

    private func sectionHeader(title: String, showStats: Bool = false) -> some View {
        HStack(alignment: .center) {
            Text(title)
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.primary)
            Spacer()
            if showStats && !isLoading && errorMessage == nil {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 13))
                        .foregroundColor(Color(.systemGreen))
                    Text("\(tasks.filter { $0.status == "done" }.count)/\(tasks.count)")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 18)
        .padding(.bottom, 16)
    }

    @ViewBuilder
    private var taskListContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 1. Appointments Section
            if !appointments.isEmpty {
                let showStats = true
                sectionHeader(title: "Upcoming Appointments (\(appointments.count))", showStats: showStats)
                
                VStack(spacing: 16) {
                    ForEach(appointments) { task in
                        Button {
                            selectedTask = task
                        } label: {
                            PremiumTaskCard(
                                task: task,
                                assignedEmployee: employees.first(where: { $0.id == task.assignedTo })
                            )
                        }
                        .buttonStyle(ShiftCardButtonStyle())
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
            
            // 2. Pending Tasks Section
            if !standardTasks.isEmpty {
                let showStats = appointments.isEmpty
                sectionHeader(title: "Pending Tasks (\(standardTasks.count))", showStats: showStats)
                
                VStack(spacing: 16) {
                    ForEach(standardTasks) { task in
                        Button {
                            selectedTask = task
                        } label: {
                            PremiumTaskCard(
                                task: task,
                                assignedEmployee: employees.first(where: { $0.id == task.assignedTo })
                            )
                        }
                        .buttonStyle(ShiftCardButtonStyle())
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }

            // 3. Dashed Create New Task Button
            NavigationLink {
                CreateTaskView(stores: stores, employees: employees, existingTasks: tasks)
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle")
                        .font(.system(size: 15))
                        .foregroundColor(Color(.secondaryLabel))
                    Text("Create new task")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(Color(.secondaryLabel))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color(.systemGray4), style: StrokeStyle(lineWidth: 1.5, dash: [7, 5]))
                )
            }
            .buttonStyle(ShiftCardButtonStyle())
            .padding(.horizontal, 20)
            .padding(.top, 4)
            .padding(.bottom, 40)
        }
    }

    // MARK: - Empty State

    @ViewBuilder
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer(minLength: 32)

            ZStack(alignment: .bottomTrailing) {
                Image(systemName: "list.bullet.clipboard")
                    .font(.system(size: 80))
                    .foregroundColor(Color(.systemGray4))
                ZStack {
                    Circle()
                        .fill(Color(.systemBlue))
                        .frame(width: 32, height: 32)
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                }
                .offset(x: 8, y: 8)
            }
            .padding(.bottom, 8)

            Text("No Tasks Assigned")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.primary)

            Text("Create tasks and assign employees to keep\nstore operations organized.")
                .font(.system(size: 15))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            NavigationLink {
                CreateTaskView(stores: stores, employees: employees, existingTasks: tasks)
            } label: {
                Text("Create Task")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(Color(.systemBlue))
                    .cornerRadius(16)
                    .shadow(color: Color(.systemBlue).opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .buttonStyle(ShiftCardButtonStyle())
            .padding(.horizontal, 32)
            .padding(.top, 12)

            Spacer(minLength: 32)
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
            Text("Try searching for a different task name.")
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
            ProgressView("Loading tasks...")
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
                throw NSError(domain: "TaskManagementView", code: 401, userInfo: [NSLocalizedDescriptionKey: "No assigned store found for the current manager session."])
            }

            // 1. Fetch tasks scoped to the current store
            let taskResponse = try await SupabaseManager.shared.client
                .from("tasks")
                .select()
                .eq("store_id", value: storeId.uuidString)
                .execute()
            let fetchedTasks = try JSONDecoder.supabaseDecoder.decodeSupabase([Task].self, from: taskResponse.data)
            
            // 2. Fetch users scoped to the current store
            let empResponse = try await SupabaseManager.shared.client
                .from("users")
                .select()
                .eq("store_id", value: storeId.uuidString)
                .execute()
            let fetchedEmployees = try JSONDecoder.supabaseDecoder.decodeSupabase([User].self, from: empResponse.data)
            
            let fetchedStores: [Store] = try await dbService.fetch(from: "stores", as: Store.self)
            
            // 3. Filter employees to exclude system roles (Admin, Manager, Inventory Controller)
            let roleList = try await dbService.fetch(from: "roles", as: Role.self)
            let excludedRoles = ["admin", "manager", "inventory controller"]
            let allowedRoles = roleList.filter { role in
                !excludedRoles.contains(role.roleName.lowercased())
            }
            let allowedRoleIds = Set(allowedRoles.map { $0.id })
            let storeEmployees = fetchedEmployees.filter { allowedRoleIds.contains($0.roleId) }
            
            // Sort by status (open first) and then due date
            self.tasks = fetchedTasks.sorted {
                if $0.status != $1.status {
                    return $0.status == "open"
                }
                return ($0.dueDate ?? Date.distantFuture) < ($1.dueDate ?? Date.distantFuture)
            }
            self.employees = storeEmployees
            self.stores = fetchedStores
        } catch {
            errorMessage = "Failed to load tasks.\n\(error.localizedDescription)"
        }
        isLoading = false
    }
}

// MARK: - Premium Task Card

struct PremiumTaskCard: View {
    let task: Task
    let assignedEmployee: User?

    private var accentColor: Color {
        if task.status == "done" {
            return Color(.systemGreen)
        }
        switch task.priority.lowercased() {
        case "high":
            return Color(.systemRed)
        case "medium":
            return Color(.systemOrange)
        default:
            return Color(.systemBlue)
        }
    }

    private var taskIcon: String {
        return task.status.lowercased() == "done" ? "checkmark.circle.fill" : "circle"
    }

    private func formatDueDate(_ date: Date?) -> String {
        guard let d = date else { return "No due date" }
        let f = DateFormatter()
        f.dateFormat = "MMM d, h:mm a"
        return "Due: \(f.string(from: d))"
    }

    var body: some View {
        HStack(spacing: 0) {
            // Left Accent Bar
            RoundedRectangle(cornerRadius: 3)
                .fill(accentColor)
                .frame(width: 4)
                .padding(.vertical, 20)
                .padding(.leading, 16)

            // Circular Icon Badge
            ZStack {
                Circle()
                    .fill(accentColor.opacity(0.12))
                    .frame(width: 48, height: 48)
                Image(systemName: task.status == "done" ? "checkmark.circle.fill" : "list.bullet.clipboard.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(accentColor)
            }
            .padding(.leading, 14)

            // Info
            VStack(alignment: .leading, spacing: 5) {
                Text(task.title)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(1)

                Text(formatDueDate(task.dueDate))
                    .font(.system(size: 15))
                    .foregroundColor(.secondary)

                // Avatar row + assigned employee
                HStack(spacing: 8) {
                    if let emp = assignedEmployee {
                        let localProfile = EmployeeProfileStore.shared.get(id: emp.id)
                        if let photoData = localProfile?.profilePhotoData, let uiImage = UIImage(data: photoData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 22, height: 22)
                                .clipShape(Circle())
                        } else {
                            ZStack {
                                Circle().fill(Color(.systemBlue))
                                    .frame(width: 22, height: 22)
                                Text(String(emp.fullName.prefix(2)).uppercased())
                                    .font(.system(size: 8, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        }
                        Text(emp.fullName)
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    } else {
                        Text("Unassigned")
                            .font(.system(size: 14))
                            .foregroundColor(Color(.placeholderText))
                    }
                }
                .padding(.top, 2)
            }
            .padding(.leading, 14)

            Spacer()

            // Chevron
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Color(.tertiaryLabel))
                .padding(.trailing, 18)
        }
        .frame(minHeight: 116)
        .background(Color(.systemBackground))
        .cornerRadius(22)
        .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 4)
        .opacity(task.status == "done" ? 0.5 : 1.0)
    }
}

// MARK: - Create Task View Component (Settings Style)

struct CreateTaskView: View {
    @Environment(\.dismiss) private var dismiss

    let stores: [Store]
    let employees: [User]
    let existingTasks: [Task]

    @State private var taskTitle = ""
    @State private var taskDescription = ""
    @State private var selectedEmployeeId: UUID? = nil
    @State private var dueDate = Date()
    @State private var taskType = "Task"
    @State private var priority = "Medium"
    @State private var employeeSearchText = ""

    @State private var isSubmitting = false
    @State private var alertMessage = ""
    @State private var isShowingAlert = false
    @State private var isShowingSuccess = false

    private let dbService = DatabaseService.shared
    private let avatarPalette: [Color] = [
        Color(.systemBlue), Color(.systemGreen), Color(.systemOrange), Color(.systemPurple)
    ]

    var isFormValid: Bool {
        !taskTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        selectedEmployeeId != nil
    }

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    
                    // SECTION 1 — Task Details Card
                    VStack(alignment: .leading, spacing: 16) {
                        
                        // Task Name Field
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Task Name")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.secondary)
                            TextField("Sanitize Cash Register", text: $taskTitle)
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
                        
                        // Task Description Field
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Task Description")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.secondary)
                            TextEditor(text: $taskDescription)
                                .font(.system(size: 15))
                                .padding(8)
                                .frame(height: 80)
                                .background(Color(.secondarySystemGroupedBackground))
                                .cornerRadius(10)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color(.systemGray5), lineWidth: 1)
                                )
                        }
                        
                        // Due Date Picker
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Due Date & Time")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.secondary)
                            DatePicker("", selection: $dueDate, displayedComponents: [.date, .hourAndMinute])
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

                        // Type Custom Segmented Buttons
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Type")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.secondary)
                            HStack(spacing: 12) {
                                ForEach(["Task", "Appointment"], id: \.self) { t in
                                    let isSelected = taskType == t
                                    Button {
                                        withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) {
                                            taskType = t
                                        }
                                    } label: {
                                        Text(t)
                                            .font(.system(size: 13, weight: .medium))
                                            .foregroundColor(isSelected ? .white : .secondary)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 12)
                                            .background(
                                                RoundedRectangle(cornerRadius: 10)
                                                    .fill(isSelected ? Color.blue : Color(.secondarySystemGroupedBackground))
                                                    .overlay(
                                                        RoundedRectangle(cornerRadius: 10)
                                                            .stroke(isSelected ? Color.clear : Color(.systemGray5), lineWidth: 1)
                                                    )
                                            )
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                        }

                        // Priority Custom Segmented Buttons
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Priority")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.secondary)
                            HStack(spacing: 12) {
                                ForEach(["Low", "Medium", "High"], id: \.self) { p in
                                    let isSelected = priority == p
                                    Button {
                                        withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) {
                                            priority = p
                                        }
                                    } label: {
                                        Text(p)
                                            .font(.system(size: 15, weight: .medium))
                                            .foregroundColor(isSelected ? .white : .secondary)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 12)
                                            .background(
                                                RoundedRectangle(cornerRadius: 10)
                                                    .fill(isSelected ? priorityColor(p) : Color(.secondarySystemGroupedBackground))
                                                    .overlay(
                                                        RoundedRectangle(cornerRadius: 10)
                                                            .stroke(isSelected ? Color.clear : Color(.systemGray5), lineWidth: 1)
                                                    )
                                            )
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                        }
                    }
                    .padding(20)
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(22)
                    .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 4)
                    
                    // SECTION 2 — Assign Staff Section
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Assign Employee")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.primary)
                            .padding(.top, 8)
                        
                        // Custom Search Bar
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.secondary)
                            TextField("Search employee", text: $employeeSearchText)
                                .font(.system(size: 16))
                                .disableAutocorrection(true)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(Color(.secondarySystemGroupedBackground))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color(.systemGray5), lineWidth: 1)
                        )
                        .padding(.bottom, 4)
                        
                        // Employee List
                        let filteredEmployees = employees.filter { emp in
                            if employeeSearchText.isEmpty { return true }
                            let query = employeeSearchText.lowercased()
                            let localProfile = EmployeeProfileStore.shared.get(id: emp.id)
                            let roleName = emp.designation ?? localProfile?.jobRole ?? "Staff"
                            return emp.fullName.lowercased().contains(query) || roleName.lowercased().contains(query)
                        }
                        
                        if filteredEmployees.isEmpty {
                            Text("No employees found")
                                .foregroundColor(.secondary)
                                .font(.system(size: 14))
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.vertical, 20)
                        } else {
                            VStack(spacing: 12) {
                                ForEach(filteredEmployees) { emp in
                                    let isSelected = selectedEmployeeId == emp.id
                                    let localProfile = EmployeeProfileStore.shared.get(id: emp.id)
                                    
                                    Button {
                                        if isSelected {
                                            selectedEmployeeId = nil
                                        } else {
                                            selectedEmployeeId = emp.id
                                        }
                                    } label: {
                                        HStack(spacing: 12) {
                                            // Left: Avatar
                                            if let photoData = localProfile?.profilePhotoData, let uiImage = UIImage(data: photoData) {
                                                Image(uiImage: uiImage)
                                                    .resizable()
                                                    .scaledToFill()
                                                    .frame(width: 44, height: 44)
                                                    .clipShape(Circle())
                                            } else {
                                                ZStack {
                                                    Circle()
                                                        .fill(avatarPalette[abs(emp.fullName.hashValue) % avatarPalette.count])
                                                        .frame(width: 44, height: 44)
                                                    Text(initials(for: emp.fullName))
                                                        .font(.system(size: 14, weight: .bold))
                                                        .foregroundColor(.white)
                                                }
                                            }
                                            
                                            // Center: Name & Role
                                            VStack(alignment: .leading, spacing: 3) {
                                                Text(emp.fullName)
                                                    .font(.system(size: 17, weight: .semibold))
                                                    .foregroundColor(.primary)
                                                Text(emp.designation ?? localProfile?.jobRole ?? "Staff")
                                                    .font(.system(size: 13))
                                                    .foregroundColor(.secondary)
                                            }
                                            
                                            Spacer()
                                            
                                            // Right: Selection indicator
                                            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                                                .font(.system(size: 22))
                                                .foregroundColor(isSelected ? Color(.systemBlue) : Color(.systemGray4))
                                        }
                                        .padding(.horizontal, 16)
                                        .frame(height: 76)
                                        .background(Color(.secondarySystemGroupedBackground))
                                        .cornerRadius(18)
                                        .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 3)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 32)
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
                Text("Create Task")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.primary)
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    saveTask()
                } label: {
                    Text("Done")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(isFormValid ? Color(.systemBlue) : Color(.secondaryLabel))
                }
                .disabled(!isFormValid || isSubmitting)
            }
        }
        .alert("Status", isPresented: $isShowingAlert) {
            Button("OK") { if isShowingSuccess { dismiss() } }
        } message: {
            Text(alertMessage)
        }
    }

    private func priorityColor(_ p: String) -> Color {
        switch p.lowercased() {
        case "high": return Color(.systemRed)
        case "medium": return Color(.systemOrange)
        default: return Color(.systemGreen)
        }
    }

    private func saveTask() {
        guard isFormValid else { return }
        
        let nameTrimmed = taskTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        if existingTasks.contains(where: { $0.title.lowercased() == nameTrimmed.lowercased() }) {
            alertMessage = "A task with the title '\(nameTrimmed)' already exists."
            isShowingAlert = true
            return
        }

        guard let currentUser = SessionManager.shared.currentUser else {
            alertMessage = "Your session has expired. Please sign in again."
            isShowingAlert = true
            return
        }

        let targetStoreId = currentUser.storeId ?? UUID(uuidString: "00000000-0000-0000-0000-000000000000")!
        let creatorId = currentUser.id

        isSubmitting = true
        let newTaskId = UUID()

        Swift.Task {
            let newTask = Task(
                id: newTaskId,
                storeId: targetStoreId,
                title: nameTrimmed,
                description: taskDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : taskDescription.trimmingCharacters(in: .whitespacesAndNewlines),
                priority: priority,
                status: "open",
                assignedTo: selectedEmployeeId,
                dueDate: dueDate,
                createdBy: creatorId,
                createdAt: Date(),
                completedAt: nil,
                taskType: taskType
            )

            do {
                try await dbService.insert(into: "tasks", value: newTask)
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                isShowingSuccess = true
                alertMessage = "Task created successfully."
                isShowingAlert = true
            } catch {
                UINotificationFeedbackGenerator().notificationOccurred(.error)
                isShowingSuccess = false
                alertMessage = "Failed to create task: \(error.localizedDescription)"
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

struct TaskDetailView: View {
    @Environment(\.dismiss) private var dismiss

    let task: Task
    let employees: [User]
    var onUpdate: () -> Void

    @State private var isUpdating = false
    @State private var isShowingDeleteAlert = false

    private let dbService = DatabaseService.shared

    var assignedEmployee: User? {
        employees.first(where: { $0.id == task.assignedTo })
    }

    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("Task Details")) {
                    InfoRow(label: "Task Title", value: task.title)
                    InfoRow(label: "Priority", value: task.priority)
                    InfoRow(label: "Status", value: task.status)
                    if let d = task.dueDate {
                        InfoRow(label: "Due Date", value: formattedDueDate(d))
                    }
                }

                if let desc = task.description, !desc.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Section(header: Text("Task Description")) {
                        Text(desc)
                            .font(.system(size: 15))
                            .foregroundColor(Color(.label))
                            .padding(.vertical, 2)
                    }
                }

                Section(header: Text("Audit Details")) {
                    InfoRow(label: "Created On", value: formatCreatedDate(task.createdAt))
                    InfoRow(label: "Created By", value: resolveCreatorName(task.createdBy))
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
                            Text("Delete Task")
                                .font(.system(size: 17, weight: .bold))
                                .foregroundColor(.red)
                            Spacer()
                        }
                    }
                    .disabled(isUpdating)
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Task Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) { Button("Close") { dismiss() } }
                ToolbarItem(placement: .navigationBarTrailing) {
                    if task.status != "done" {
                        Button("Mark Completed") {
                            Swift.Task { await markCompleted() }
                        }
                        .font(.system(size: 14, weight: .bold))
                        .disabled(isUpdating)
                    }
                }
            }
            .alert("Delete Task?", isPresented: $isShowingDeleteAlert) {
                Button("Delete", role: .destructive) { Swift.Task { await deleteTask() } }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Are you sure you want to delete '\(task.title)'?")
            }
        }
    }

    private func markCompleted() async {
        isUpdating = true
        let updated = Task(
            id: task.id, storeId: task.storeId, title: task.title,
            description: task.description, priority: task.priority,
            status: "done", assignedTo: task.assignedTo, dueDate: task.dueDate,
            createdBy: task.createdBy, createdAt: task.createdAt, completedAt: Date(),
            taskType: task.taskType
        )
        do {
            try await dbService.update(table: "tasks", value: updated, column: "id", equals: task.id.uuidString.lowercased())
            onUpdate()
            dismiss()
        } catch {
            print("Failed to complete task: \(error)")
        }
        isUpdating = false
    }

    private func deleteTask() async {
        isUpdating = true
        do {
            try await dbService.delete(from: "tasks", column: "id", equals: task.id.uuidString.lowercased())
            onUpdate()
            dismiss()
        } catch {
            print("Failed to delete task: \(error)")
        }
        isUpdating = false
    }

    private func formattedDueDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "MMM d, yyyy h:mm a"
        return f.string(from: date)
    }

    private func resolveCreatorName(_ creatorId: UUID) -> String {
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

// MARK: - Completed Tasks View

struct CompletedTasksView: View {
    let employees: [User]
    let stores: [Store]

    @State private var completedTasks: [Task] = []
    @State private var isLoading = true
    @State private var errorMessage: String? = nil
    @State private var selectedTask: Task? = nil

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
                    Text("Completed Tasks (\(completedTasks.count))")
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
                        ProgressView("Loading completed tasks...")
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
                } else if completedTasks.isEmpty {
                    VStack(spacing: 16) {
                        Spacer(minLength: 48)
                        Image(systemName: "checkmark.circle")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        Text("No completed tasks yet")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.secondary)
                        Spacer(minLength: 48)
                    }
                } else {
                    VStack(spacing: 16) {
                        ForEach(completedTasks) { task in
                            Button {
                                selectedTask = task
                            } label: {
                                PremiumTaskCard(
                                    task: task,
                                    assignedEmployee: employees.first(where: { $0.id == task.assignedTo })
                                )
                            }
                            .buttonStyle(ShiftCardButtonStyle())
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
        .sheet(item: $selectedTask, onDismiss: {
            Swift.Task { await loadCompletedTasks() }
        }) { task in
            TaskDetailView(
                task: task,
                employees: employees,
                onUpdate: { Swift.Task { await loadCompletedTasks() } }
            )
        }
    }

    private func loadCompletedTasks() async {
        isLoading = true
        errorMessage = nil
        do {
            guard let storeId = SessionManager.shared.currentUser?.storeId else {
                throw NSError(domain: "CompletedTasksView", code: 401, userInfo: [NSLocalizedDescriptionKey: "No assigned store found."])
            }
            let taskResponse = try await SupabaseManager.shared.client
                .from("tasks")
                .select()
                .eq("store_id", value: storeId.uuidString)
                .eq("status", value: "done")
                .execute()
            let fetchedTasks = try JSONDecoder.supabaseDecoder.decodeSupabase([Task].self, from: taskResponse.data)
            self.completedTasks = fetchedTasks.sorted { ($0.completedAt ?? Date()) > ($1.completedAt ?? Date()) }
        } catch {
            errorMessage = "Failed to load completed tasks: \(error.localizedDescription)"
        }
        isLoading = false
    }
}
