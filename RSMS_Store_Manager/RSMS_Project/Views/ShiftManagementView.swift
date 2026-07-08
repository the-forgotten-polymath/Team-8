//
//  ShiftManagementView.swift
//  RSMS_Project
//
//  Created by Yatharth Mishra on 30/06/26.
//

import SwiftUI
import Supabase

// MARK: - Shift Management View (Premium Calendar Redesign)
struct ShiftManagementView: View {
    @State private var shifts: [Shift] = []
    @State private var stores: [Store] = []
    @State private var employees: [User] = []

    @State private var selectedDate = Date()
    @State private var searchText = ""
    @State private var isLoading = true
    @State private var errorMessage: String? = nil
    @State private var isShowingMonthPicker = false

    @State private var isShowingAddShift = false
    @State private var selectedShift: Shift? = nil
    @State private var shiftToDelete: Shift? = nil
    @State private var isShowingDeleteConfirmation = false

    private let dbService = DatabaseService.shared
    private let monthsArray = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11]

    private func monthName(for index: Int) -> String {
        let cal = Calendar.current
        let year = cal.component(.year, from: selectedDate)
        let targetDate = cal.date(from: DateComponents(year: year, month: index + 1, day: 1)) ?? selectedDate
        let monthFmt = DateFormatter()
        monthFmt.dateFormat = "MMMM"
        return monthFmt.string(from: targetDate)
    }

    private func isCurrentMonth(_ index: Int) -> Bool {
        return Calendar.current.component(.month, from: selectedDate) == index + 1
    }

    @ViewBuilder
    private var monthSelectorMenu: some View {
        Menu {
            ForEach(0..<12, id: \.self) { monthIndex in
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.78)) {
                        var comps = Calendar.current.dateComponents([.year, .day], from: selectedDate)
                        comps.month = monthIndex + 1
                        if let newDate = Calendar.current.date(from: comps) {
                            selectedDate = newDate
                        }
                    }
                } label: {
                    Label(monthName(for: monthIndex), systemImage: isCurrentMonth(monthIndex) ? "checkmark" : "")
                }
            }
        } label: {
            HStack(spacing: 4) {
                Text(monthYearLabel)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.primary)
                Image(systemName: "chevron.down")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.secondary)
            }
        }
    }

    // MARK: - Computed Properties

    var filteredShifts: [Shift] {
        if searchText.isEmpty { return shifts }
        let q = searchText.lowercased()
        return shifts.filter { shift in
            if shift.shiftName.lowercased().contains(q) { return true }
            if formatTime(shift.startTime).lowercased().contains(q) { return true }
            if formatTime(shift.endTime).lowercased().contains(q) { return true }
            let assigned = employees.filter { $0.shiftId == shift.id }
            return assigned.contains { $0.fullName.lowercased().contains(q) }
        }
    }

    var totalStaffScheduled: Int {
        let shiftIds = Set(shifts.map { $0.id })
        return employees.filter { emp in
            guard let sId = emp.shiftId else { return false }
            return shiftIds.contains(sId)
        }.count
    }

    var formattedSelectedDate: String {
        let f = DateFormatter()
        f.dateFormat = "EEEE d MMM"
        return f.string(from: selectedDate)
    }

    var monthYearLabel: String {
        let f = DateFormatter()
        f.dateFormat = "MMMM"
        return f.string(from: selectedDate)
    }

    // Generated dates: 60 days in past and 60 days in future
    var scrollableDates: [Date] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        return (-60...60).compactMap { dayOffset in
            cal.date(byAdding: .day, value: dayOffset, to: today)
        }
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            // Week Calendar Header (fixed static top)
            weekCalendarSection

            // Soft Divider
            Rectangle()
                .fill(Color(.systemGray5).opacity(0.8))
                .frame(height: 1)
                .padding(.horizontal, 20)
                .padding(.top, 18)

            // Date + Staff Count Row
            HStack(alignment: .center, spacing: 0) {
                Text(formattedSelectedDate)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.primary)
                Spacer()
                if !isLoading && errorMessage == nil {
                    HStack(spacing: 4) {
                        Image(systemName: "person.2")
                            .font(.system(size: 13))
                            .foregroundColor(Color(.tertiaryLabel))
                        Text("\(totalStaffScheduled)")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)
            .padding(.bottom, 16)

            // Content Area using List to support swipeActions
            if isLoading {
                Spacer()
                loadingView
                Spacer()
            } else if let error = errorMessage {
                Spacer()
                errorView(error)
                Spacer()
            } else if filteredShifts.isEmpty && searchText.isEmpty {
                Spacer()
                emptyStateView
                Spacer()
            } else if filteredShifts.isEmpty {
                Spacer()
                searchEmptyView
                Spacer()
            } else {
                List {
                    ForEach(filteredShifts) { shift in
                        Button {
                            selectedShift = shift
                        } label: {
                            PremiumShiftCard(
                                shift: shift,
                                assignedEmployees: employees.filter { $0.shiftId == shift.id }
                            )
                        }
                        .buttonStyle(ShiftCardButtonStyle())
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 6, leading: 20, bottom: 6, trailing: 20))
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                shiftToDelete = shift
                                isShowingDeleteConfirmation = true
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                    
                    // Dashed Create New Shift Button
                    NavigationLink {
                        AddShiftView(stores: stores, employees: employees, shifts: shifts)
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "plus.circle")
                                .font(.system(size: 15))
                                .foregroundColor(Color(.secondaryLabel))
                            Text("Create new shift")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(Color(.secondaryLabel))
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(style: StrokeStyle(lineWidth: 1.5, dash: [6]))
                                .foregroundColor(Color(.systemGray4))
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: 12, leading: 20, bottom: 20, trailing: 20))
                }
                .listStyle(PlainListStyle())
                .background(Color.clear)
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searchText, prompt: "Search shifts...")
        .toolbar {
            // Centered Month Selector Menu in navigation bar
            ToolbarItem(placement: .principal) {
                monthSelectorMenu
            }
        }
        .task { await loadData() }
        .sheet(isPresented: $isShowingAddShift, onDismiss: {
            Swift.Task { await loadData() }
        }) {
            NavigationStack {
                AddShiftView(stores: stores, employees: employees, shifts: shifts)
            }
        }
        .sheet(item: $selectedShift, onDismiss: {
            Swift.Task { await loadData() }
        }) { shift in
            ShiftDetailView(
                shift: shift,
                onUpdate: { Swift.Task { await loadData() } }
            )
        }
        .alert("Delete Shift?", isPresented: $isShowingDeleteConfirmation, presenting: shiftToDelete) { shift in
            Button("Delete", role: .destructive) {
                Swift.Task {
                    await performDeleteShift(shift)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: { shift in
            let count = employees.filter { $0.shiftId == shift.id }.count
            if count > 0 {
                Text("There are \(count) employees assigned to '\(shift.shiftName)'. Deleting will unassign them. Proceed?")
            } else {
                Text("Are you sure you want to delete '\(shift.shiftName)'?")
            }
        }
    }

    private func performDeleteShift(_ shift: Shift) async {
        isLoading = true
        do {
            let assignedToThisShift = employees.filter { $0.shiftId == shift.id }
            for emp in assignedToThisShift {
                var update = UserUpdate()
                update.shiftId = nil
                update.hasShiftIdValue = true
                try await dbService.update(table: "users", value: update, column: "id", equals: emp.id.uuidString.lowercased())
            }
            try await dbService.delete(from: "shifts", column: "id", equals: shift.id.uuidString.lowercased())
            ShiftMetadataStore.shared.delete(id: shift.id)
            await loadData()
        } catch {
            print("Failed to delete shift: \(error)")
            errorMessage = "Failed to delete shift: \(error.localizedDescription)"
        }
        isLoading = false
    }

    // MARK: - Week Calendar Section

    @ViewBuilder
    private var weekCalendarSection: some View {
        VStack(spacing: 12) {
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 8) {
                        ForEach(scrollableDates, id: \.timeIntervalSince1970) { day in
                            let isSelected = Calendar.current.isDate(day, inSameDayAs: selectedDate)
                            let isToday = Calendar.current.isDateInToday(day)

                            Button {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    selectedDate = day
                                }
                            } label: {
                                VStack(spacing: 6) {
                                    Text(dayAbbrev(day))
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(isSelected ? .white : Color(.tertiaryLabel))

                                    Text(dayNumber(day))
                                        .font(.system(size: 20, weight: isSelected ? .bold : .medium))
                                        .foregroundColor(isSelected ? .white : (isToday ? Color(.systemBlue) : .primary))
                                }
                                .frame(width: 48)
                                .padding(.vertical, 10)
                                .background(
                                    Group {
                                        if isSelected {
                                            RoundedRectangle(cornerRadius: 16)
                                                .fill(Color(.systemBlue))
                                                .matchedGeometryEffect(id: "selectedDay", in: calendarNamespace)
                                        } else {
                                            Color.clear
                                        }
                                    }
                                )
                                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .id(Calendar.current.startOfDay(for: day).timeIntervalSince1970)
                        }
                    }
                    .padding(.horizontal, 16)
                }
                .frame(height: 70)
                .onAppear {
                    let targetId = Calendar.current.startOfDay(for: selectedDate).timeIntervalSince1970
                    proxy.scrollTo(targetId, anchor: .center)
                }
                .onChange(of: selectedDate) { newDate in
                    withAnimation {
                        let targetId = Calendar.current.startOfDay(for: newDate).timeIntervalSince1970
                        proxy.scrollTo(targetId, anchor: .center)
                    }
                }
            }
        }
        .padding(.top, 20)
        .padding(.bottom, 0)
        .background(Color(.systemGroupedBackground))
    }

    @Namespace private var calendarNamespace

    // MARK: - Shift List

    @ViewBuilder
    private var shiftListContent: some View {
        VStack(spacing: 16) {
            ForEach(filteredShifts) { shift in
                Button {
                    selectedShift = shift
                } label: {
                    PremiumShiftCard(
                        shift: shift,
                        assignedEmployees: employees.filter { $0.shiftId == shift.id }
                    )
                }
                .buttonStyle(ShiftCardButtonStyle())
            }

            // Dashed Create New Shift Button (Push transition, no modal)
            NavigationLink {
                AddShiftView(stores: stores, employees: employees, shifts: shifts)
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle")
                        .font(.system(size: 15))
                        .foregroundColor(Color(.secondaryLabel))
                    Text("Create new shift")
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
            .padding(.top, 4)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 40)
    }

    // MARK: - Empty State

    @ViewBuilder
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer(minLength: 32)

            ZStack(alignment: .bottomTrailing) {
                Image(systemName: "calendar")
                    .font(.system(size: 80))
                    .foregroundColor(Color(.systemGray4))
                ZStack {
                    Circle()
                        .fill(Color(.systemBlue))
                        .frame(width: 32, height: 32)
                    Image(systemName: "clock.fill")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                }
                .offset(x: 8, y: 8)
            }
            .padding(.bottom, 8)

            Text("No Shifts Scheduled")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.primary)

            Text("Create shifts and assign employees to cover\ntoday's store operations.")
                .font(.system(size: 15))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            NavigationLink {
                AddShiftView(stores: stores, employees: employees, shifts: shifts)
            } label: {
                Text("Create Shift")
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
            Text("Try a different shift name, time, or employee.")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
            Spacer(minLength: 48)
        }
    }

    // MARK: - Loading

    @ViewBuilder
    private var loadingView: some View {
        VStack {
            Spacer(minLength: 60)
            ProgressView("Loading schedules...")
                .scaleEffect(1.1)
            Spacer(minLength: 60)
        }
    }

    // MARK: - Error

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

    // MARK: - Data Loading

    private func loadData() async {
        isLoading = true
        errorMessage = nil
        do {
            if SessionManager.shared.currentUser == nil {
                await SessionManager.shared.resolveSession()
            }
            
            guard let storeId = SessionManager.shared.currentUser?.storeId else {
                throw NSError(domain: "ShiftManagementView", code: 401, userInfo: [NSLocalizedDescriptionKey: "No assigned store found for the current manager session."])
            }

            // 1. Fetch shifts scoped to the current store
            let shiftResponse = try await SupabaseManager.shared.client
                .from("shifts")
                .select()
                .eq("store_id", value: storeId.uuidString)
                .execute()
            
            // Console audit prints
            print("--- 🔍 SHIFT ARCHITECTURAL AUDIT ---")
            print("• Current Manager ID: \(SessionManager.shared.currentUser?.id.uuidString ?? "nil")")
            print("• Current Store ID: \(storeId.uuidString)")
            print("• Supabase Query: select() from shifts where store_id = \(storeId.uuidString)")
            if let rawJson = String(data: shiftResponse.data, encoding: .utf8) {
                print("• Raw Response: \(rawJson)")
            } else {
                print("• Raw Response: Unable to convert data to UTF-8 string")
            }
            
            let fetchedShifts = try JSONDecoder.supabaseDecoder.decodeSupabase([Shift].self, from: shiftResponse.data)
            print("• Decoded Shifts Count: \(fetchedShifts.count)")
            print("-----------------------------------")
            
            let fetchedStores: [Store] = try await dbService.fetch(from: "stores", as: Store.self)
            
            // 2. Fetch users scoped to the current store
            let empResponse = try await SupabaseManager.shared.client
                .from("users")
                .select()
                .eq("store_id", value: storeId.uuidString)
                .execute()
            let fetchedEmployees = try JSONDecoder.supabaseDecoder.decodeSupabase([User].self, from: empResponse.data)
            
            // 3. Filter employees to exclude system roles (Admin, Manager, Inventory Controller)
            let roleList = try await dbService.fetch(from: "roles", as: Role.self)
            let excludedRoles = ["admin", "manager", "inventory controller"]
            let allowedRoles = roleList.filter { role in
                !excludedRoles.contains(role.roleName.lowercased())
            }
            let allowedRoleIds = Set(allowedRoles.map { $0.id })
            let storeEmployees = fetchedEmployees.filter { allowedRoleIds.contains($0.roleId) }
            
            self.shifts = fetchedShifts.sorted { $0.shiftName.localizedCaseInsensitiveCompare($1.shiftName) == .orderedAscending }
            self.stores = fetchedStores
            self.employees = storeEmployees
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
                errorMessage = "Failed to load shift information.\n\(error.localizedDescription)"
            }
        }
        isLoading = false
    }

    // MARK: - Date Helpers

    private func dayAbbrev(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "EEE"
        return f.string(from: date)
    }

    private func dayNumber(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "d"
        return f.string(from: date)
    }

    private func formatTime(_ timeStr: String) -> String {
        return formatTimeHelper(timeStr)
    }
}

// MARK: - Premium Shift Card

struct PremiumShiftCard: View {
    let shift: Shift
    let assignedEmployees: [User]

    private var accentColor: Color {
        let name = shift.shiftName.lowercased()
        if name.contains("morning")   || hour(shift.startTime).isBetween(5, 12)  { return Color(red: 0.23, green: 0.51, blue: 0.96) }
        if name.contains("afternoon") || hour(shift.startTime).isBetween(12, 17) { return Color(red: 0.96, green: 0.62, blue: 0.04) }
        if name.contains("evening")   || hour(shift.startTime).isBetween(17, 21) { return Color(red: 0.55, green: 0.36, blue: 0.96) }
        if name.contains("night")     || hour(shift.startTime) >= 21 || hour(shift.startTime) < 5 { return Color(red: 0.22, green: 0.25, blue: 0.31) }
        return Color(.systemBlue)
    }

    private var shiftIcon: String {
        let name = shift.shiftName.lowercased()
        if name.contains("morning")   || hour(shift.startTime).isBetween(5, 12)  { return "sun.max.fill" }
        if name.contains("afternoon") || hour(shift.startTime).isBetween(12, 17) { return "cloud.sun.fill" }
        if name.contains("evening")   || hour(shift.startTime).isBetween(17, 21) { return "sunset.fill" }
        return "moon.fill"
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
                Image(systemName: shiftIcon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(accentColor)
            }
            .padding(.leading, 14)

            // Info
            VStack(alignment: .leading, spacing: 5) {
                Text(shift.shiftName)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.primary)

                Text("\(formatTime(shift.startTime)) – \(formatTime(shift.endTime))")
                    .font(.system(size: 15))
                    .foregroundColor(.secondary)

                // Avatar row + count
                HStack(spacing: 8) {
                    if !assignedEmployees.isEmpty {
                        overlappingAvatars
                    }
                    Text("\(assignedEmployees.count) Staff Assigned")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
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
    }

    // MARK: - Overlapping Avatars

    @ViewBuilder
    private var overlappingAvatars: some View {
        HStack(spacing: -9) {
            ForEach(Array(assignedEmployees.prefix(4).enumerated()), id: \.element.id) { idx, emp in
                avatarView(for: emp, colorIndex: idx)
                    .zIndex(Double(4 - idx))
            }
            if assignedEmployees.count > 4 {
                ZStack {
                    Circle()
                        .fill(Color(.systemGray5))
                    Text("+\(assignedEmployees.count - 4)")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(.secondary)
                }
                .frame(width: 22, height: 22)
                .overlay(Circle().stroke(Color(.systemBackground), lineWidth: 1.5))
            }
        }
    }

    @ViewBuilder
    private func avatarView(for emp: User, colorIndex: Int) -> some View {
        let profile = EmployeeProfileStore.shared.get(id: emp.id)
        Group {
            if let data = profile?.profilePhotoData, let uiImg = UIImage(data: data) {
                Image(uiImage: uiImg)
                    .resizable()
                    .scaledToFill()
            } else {
                ZStack {
                    Circle().fill(avatarPalette[colorIndex % avatarPalette.count])
                    Text(initials(emp.fullName))
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(.white)
                }
            }
        }
        .frame(width: 22, height: 22)
        .clipShape(Circle())
        .overlay(Circle().stroke(Color(.systemBackground), lineWidth: 1.5))
    }

    // MARK: - Helpers

    private let avatarPalette: [Color] = [
        Color(.systemBlue), Color(.systemGreen), Color(.systemOrange), Color(.systemPurple)
    ]

    private func hour(_ timeStr: String) -> Int {
        Int(timeStr.prefix(2)) ?? 0
    }

    private func formatTime(_ timeStr: String) -> String {
        return formatTimeHelper(timeStr)
    }

    private func initials(_ name: String) -> String {
        let parts = name.components(separatedBy: " ").filter { !$0.isEmpty }
        if parts.count >= 2 {
            return "\(parts[0].prefix(1))\(parts[parts.count - 1].prefix(1))".uppercased()
        }
        return String(name.prefix(2)).uppercased()
    }
}

// MARK: - Shift Card Button Style

struct ShiftCardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.975 : 1.0)
            .opacity(configuration.isPressed ? 0.92 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// MARK: - Int Range Helper

private extension Int {
    func isBetween(_ lower: Int, _ upper: Int) -> Bool {
        return self >= lower && self < upper
    }
}

// MARK: - Add Shift View Component (Pushed, Settings-Style Full-Screen)
struct AddShiftView: View {
    @Environment(\.dismiss) private var dismiss

    let stores: [Store]
    let employees: [User]
    let shifts: [Shift]

    @State private var shiftName = ""
    @State private var startTime = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date()
    @State private var endTime = Calendar.current.date(bySettingHour: 17, minute: 0, second: 0, of: Date()) ?? Date()
    @State private var shiftType = "Permanent"
    @State private var selectedEmployeeIds: Set<UUID> = []
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
        !shiftName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !selectedEmployeeIds.isEmpty
    }

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    
                    // SECTION 1 — Shift Details Grouped Card
                    VStack(alignment: .leading, spacing: 16) {
                        
                        // Shift Name Field
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Shift Name")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.secondary)
                            TextField("Morning Shift", text: $shiftName)
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
                        
                        // Start / End Time DatePickers side-by-side
                        HStack(spacing: 16) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Start Time")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.secondary)
                                DatePicker("", selection: $startTime, displayedComponents: .hourAndMinute)
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
                            
                            VStack(alignment: .leading, spacing: 6) {
                                Text("End Time")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.secondary)
                                DatePicker("", selection: $endTime, displayedComponents: .hourAndMinute)
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
                        
                        // Shift Type Picker (Custom Radio Selector side-by-side)
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Shift Type")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.secondary)
                            HStack(spacing: 12) {
                                ForEach(["Permanent", "Temporary"], id: \.self) { type in
                                    let isSelected = shiftType == type
                                    Button {
                                        withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) {
                                            shiftType = type
                                        }
                                    } label: {
                                        HStack(spacing: 8) {
                                            ZStack {
                                                Circle()
                                                    .stroke(isSelected ? Color(.systemBlue) : Color(.systemGray4), lineWidth: 1.5)
                                                    .frame(width: 20, height: 20)
                                                if isSelected {
                                                    Circle()
                                                        .fill(Color(.systemBlue))
                                                        .frame(width: 10, height: 10)
                                                }
                                            }
                                            Text(type)
                                                .font(.system(size: 15, weight: .medium))
                                                .foregroundColor(isSelected ? .primary : .secondary)
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 14)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(isSelected ? Color(.systemBlue).opacity(0.3) : Color(.systemGray5), lineWidth: 1.5)
                                                .background(Color(.secondarySystemGroupedBackground))
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
                        Text(selectedEmployeeIds.isEmpty ? "Assigned Staff" : "Assigned Staff (\(selectedEmployeeIds.count))")
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
                        
                        // Employee List (Show only unassigned employees)
                        let unassignedEmployees = employees.filter { $0.shiftId == nil }
                        
                        let filteredEmployees = unassignedEmployees.filter { emp in
                            if employeeSearchText.isEmpty { return true }
                            let query = employeeSearchText.lowercased()
                            let localProfile = EmployeeProfileStore.shared.get(id: emp.id)
                            let roleName = emp.designation ?? localProfile?.jobRole ?? "Staff"
                            return emp.fullName.lowercased().contains(query) || roleName.lowercased().contains(query)
                        }
                        
                        if unassignedEmployees.isEmpty {
                            Text("No unassigned employees available.")
                                .foregroundColor(.secondary)
                                .font(.system(size: 14))
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.vertical, 20)
                        } else if filteredEmployees.isEmpty {
                            Text("No employees found")
                                .foregroundColor(.secondary)
                                .font(.system(size: 14))
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.vertical, 20)
                        } else {
                            VStack(spacing: 12) {
                                ForEach(filteredEmployees) { emp in
                                    let isSelected = selectedEmployeeIds.contains(emp.id)
                                    let localProfile = EmployeeProfileStore.shared.get(id: emp.id)
                                    
                                    Button {
                                        if isSelected {
                                            selectedEmployeeIds.remove(emp.id)
                                        } else {
                                            selectedEmployeeIds.insert(emp.id)
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
                Text("Create Shift")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.primary)
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    saveShift()
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
        .onChange(of: startTime) { newValue in
            let corrected = clampToBusinessHours(newValue)
            if corrected != newValue {
                startTime = corrected
            }
            
            if endTime <= corrected {
                let calendar = Calendar.current
                let newEnd = calendar.date(byAdding: .hour, value: 1, to: corrected) ?? corrected
                endTime = clampToBusinessHours(newEnd)
            }
        }
        .onChange(of: endTime) { newValue in
            let corrected = clampToBusinessHours(newValue)
            if corrected != newValue {
                endTime = corrected
            }
            
            if corrected <= startTime {
                let calendar = Calendar.current
                let newStart = calendar.date(byAdding: .hour, value: -1, to: corrected) ?? corrected
                startTime = clampToBusinessHours(newStart)
            }
        }
    }

    private func saveShift() {
        guard isFormValid else { return }
        
        let calendar = Calendar.current
        let startComponents = calendar.dateComponents([.hour, .minute], from: startTime)
        let endComponents = calendar.dateComponents([.hour, .minute], from: endTime)
        let startMinutes = (startComponents.hour ?? 0) * 60 + (startComponents.minute ?? 0)
        let endMinutes = (endComponents.hour ?? 0) * 60 + (endComponents.minute ?? 0)
        
        if endMinutes <= startMinutes {
            alertMessage = "End time must be after start time."
            isShowingAlert = true
            return
        }
        
        let nameTrimmed = shiftName.trimmingCharacters(in: .whitespacesAndNewlines)
        if shifts.contains(where: { $0.shiftName.lowercased() == nameTrimmed.lowercased() }) {
            alertMessage = "A shift with the name '\(nameTrimmed)' already exists."
            isShowingAlert = true
            return
        }
        
        var overlappingEmployeeName: String? = nil
        for empId in selectedEmployeeIds {
            if let emp = employees.first(where: { $0.id == empId }),
               let existingShiftId = emp.shiftId,
               let existingShift = shifts.first(where: { $0.id == existingShiftId }) {
                
                let f = DateFormatter()
                f.dateFormat = "HH:mm"
                if let sDate = f.date(from: existingShift.startTime),
                   let eDate = f.date(from: existingShift.endTime) {
                    
                    let existStartComponents = calendar.dateComponents([.hour, .minute], from: sDate)
                    let existEndComponents = calendar.dateComponents([.hour, .minute], from: eDate)
                    let existStartMin = (existStartComponents.hour ?? 0) * 60 + (existStartComponents.minute ?? 0)
                    let existEndMin = (existEndComponents.hour ?? 0) * 60 + (existEndComponents.minute ?? 0)
                    
                    let isOverlapping = max(startMinutes, existStartMin) < min(endMinutes, existEndMin)
                    if isOverlapping {
                        overlappingEmployeeName = emp.fullName
                        break
                    }
                }
            }
        }
        
        if let overlapName = overlappingEmployeeName {
            alertMessage = "\(overlapName) is already assigned to an overlapping shift during this time."
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

        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        let startStr = formatter.string(from: startTime)
        let endStr = formatter.string(from: endTime)
        let newShiftId = UUID()

        Swift.Task {
            let newShift = Shift(
                id: newShiftId,
                storeId: targetStoreId,
                shiftName: nameTrimmed,
                startTime: startStr,
                endTime: endStr,
                status: "active",
                createdBy: creatorId,
                createdAt: Date()
            )

            let metadata = ShiftMetadata(
                id: newShiftId, color: "Blue", type: shiftType, notes: nil
            )

            do {
                try await dbService.insert(into: "shifts", value: newShift)
                ShiftMetadataStore.shared.save(metadata: metadata)

                for empId in selectedEmployeeIds {
                    if let emp = employees.first(where: { $0.id == empId }) {
                        let updatedEmp = emp.copy(storeId: targetStoreId, shiftId: newShiftId)
                        try await dbService.update(table: "users", value: updatedEmp, column: "id", equals: emp.id.uuidString.lowercased())
                    }
                }

                UINotificationFeedbackGenerator().notificationOccurred(.success)
                isShowingSuccess = true
                alertMessage = "Shift created successfully."
                isShowingAlert = true
            } catch {
                UINotificationFeedbackGenerator().notificationOccurred(.error)
                isShowingSuccess = false
                alertMessage = "Failed to create shift: \(error.localizedDescription)"
                isShowingAlert = true
            }
            isSubmitting = false
        }
    }

    private func clampToBusinessHours(_ date: Date) -> Date {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        guard let hour = components.hour else { return date }
        
        if hour < 8 {
            components.hour = 8
            return calendar.date(from: components) ?? date
        } else if hour > 22 {
            components.hour = 22
            return calendar.date(from: components) ?? date
        } else {
            return date
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

// MARK: - ShiftDetailView
struct ShiftDetailView: View {
    @Environment(\.dismiss) private var dismiss

    let shift: Shift
    var onUpdate: () -> Void

    @State private var isShowingAssignSheet = false
    @State private var isUpdating = false
    @State private var isShowingDeleteAlert = false
    @State private var localEmployees: [User] = []

    private let dbService = DatabaseService.shared

    var assignedEmployees: [User] {
        localEmployees.filter { $0.shiftId == shift.id }
    }

    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("Shift Schedule")) {
                    InfoRow(label: "Shift Name", value: shift.shiftName)
                    InfoRow(label: "Hours", value: "\(formatTime(shift.startTime)) – \(formatTime(shift.endTime))")
                    InfoRow(label: "Duration", value: calculateDuration(start: shift.startTime, end: shift.endTime))
                }

                Section(header: Text("Audit Details")) {
                    InfoRow(label: "Created On", value: formatCreatedDate(shift.createdAt))
                    InfoRow(label: "Created By", value: resolveCreatorName(shift.createdBy))
                }

                Section(header: Text("Assigned Staff (\(assignedEmployees.count))")) {
                    if assignedEmployees.isEmpty {
                        Text("No employees assigned to this shift.")
                            .font(.system(size: 14))
                            .foregroundColor(Color(.secondaryLabel))
                            .padding(.vertical, 4)
                    } else {
                        ForEach(assignedEmployees) { employee in
                            let localProfile = EmployeeProfileStore.shared.get(id: employee.id)
                            HStack {
                                if let photoData = localProfile?.profilePhotoData, let uiImage = UIImage(data: photoData) {
                                    Image(uiImage: uiImage)
                                        .resizable().scaledToFill()
                                        .frame(width: 38, height: 38).clipShape(Circle())
                                } else {
                                    Text(initials(for: employee.fullName))
                                        .font(.system(size: 12, weight: .bold)).foregroundColor(.white)
                                        .frame(width: 38, height: 38)
                                        .background(Color(.systemBlue)).clipShape(Circle())
                                }
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(employee.fullName).font(.system(size: 15, weight: .semibold))
                                    Text(employee.designation ?? localProfile?.jobRole ?? "Staff")
                                        .font(.system(size: 12)).foregroundColor(Color(.secondaryLabel))
                                }
                                .padding(.leading, 4)
                                Spacer()
                                Button {
                                    Swift.Task { await unassignEmployee(employee) }
                                } label: {
                                    Text("Unassign")
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(Color(.systemRed))
                                        .padding(.horizontal, 10).padding(.vertical, 5)
                                        .background(Color(.systemRed).opacity(0.1))
                                        .cornerRadius(8)
                                }
                                .disabled(isUpdating)
                            }
                            .padding(.vertical, 2)
                        }
                    }
                }

                Section {
                    Button(role: .destructive) {
                        isShowingDeleteAlert = true
                    } label: {
                        HStack {
                            Spacer()
                            if isUpdating { ProgressView().padding(.trailing, 8) }
                            Text("Delete Shift")
                                .font(.system(size: 17, weight: .bold))
                                .foregroundColor(.red)
                            Spacer()
                        }
                    }
                    .disabled(isUpdating)
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Shift Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) { Button("Close") { dismiss() } }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        isShowingAssignSheet = true
                    } label: {
                        Image(systemName: "person.badge.plus")
                            .font(.system(size: 16, weight: .semibold))
                    }
                }
            }
            .sheet(isPresented: $isShowingAssignSheet) {
                NavigationStack {
                    AssignEmployeeView(
                        shiftId: shift.id,
                        storeId: shift.storeId,
                        allEmployees: localEmployees,
                        onAssign: { employee in
                            Swift.Task {
                                if employee.shiftId == shift.id {
                                    await unassignEmployee(employee)
                                } else {
                                    await assignEmployee(employee)
                                }
                                isShowingAssignSheet = false
                            }
                        }
                    )
                }
            }
            .alert("Delete Shift?", isPresented: $isShowingDeleteAlert) {
                Button("Delete", role: .destructive) { Swift.Task { await deleteShift() } }
                Button("Cancel", role: .cancel) {}
            } message: {
                if assignedEmployees.count > 0 {
                    Text("There are \(assignedEmployees.count) employees assigned to '\(shift.shiftName)'. Deleting will unassign them. Proceed?")
                } else {
                    Text("Are you sure you want to delete '\(shift.shiftName)'?")
                }
            }
            .task {
                await fetchLocalEmployees()
            }
        }
    }

    private func fetchLocalEmployees() async {
        do {
            let empResponse = try await SupabaseManager.shared.client
                .from("users")
                .select()
                .eq("store_id", value: shift.storeId.uuidString)
                .execute()
            let fetchedEmployees = try JSONDecoder.supabaseDecoder.decodeSupabase([User].self, from: empResponse.data)
            
            // Filter excluded roles
            let roleList = try await dbService.fetch(from: "roles", as: Role.self)
            let excludedRoles = ["admin", "manager", "inventory controller"]
            let allowedRoles = roleList.filter { role in
                !excludedRoles.contains(role.roleName.lowercased())
            }
            let allowedRoleIds = Set(allowedRoles.map { $0.id })
            let storeEmployees = fetchedEmployees.filter { allowedRoleIds.contains($0.roleId) }
            
            await MainActor.run {
                self.localEmployees = storeEmployees
            }
        } catch {
            print("Failed to fetch shift details employees: \(error)")
        }
    }

    private func formatTime(_ timeStr: String) -> String {
        return formatTimeHelper(timeStr)
    }

    private func calculateDuration(start: String, end: String) -> String {
        guard let s = parseTime(start), let e = parseTime(end) else {
            return "Not Available"
        }
        var diff = e.timeIntervalSince(s)
        if diff < 0 { diff += 24 * 3600 }
        
        let totalMinutes = Int(round(diff / 60.0))
        let h = totalMinutes / 60
        let m = totalMinutes % 60
        
        var result = ""
        if h > 0 {
            result += "\(h) \(h == 1 ? "Hour" : "Hours")"
        }
        if m > 0 {
            if !result.isEmpty { result += " " }
            result += "\(m) \(m == 1 ? "Minute" : "Minutes")"
        }
        
        if result.isEmpty {
            return "0 Hours"
        }
        return result
    }

    private func formatCreatedDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateStyle = .medium
        return f.string(from: date)
    }

    private func resolveCreatorName(_ creatorId: UUID?) -> String {
        guard let creatorId = creatorId else { return "System" }
        if let current = SessionManager.shared.currentUser, current.id == creatorId {
            return current.fullName
        }
        return "Store Manager"
    }

    private func initials(for name: String) -> String {
        let p = name.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        if p.count >= 2 { return "\(p[0].prefix(1))\(p[p.count-1].prefix(1))".uppercased() }
        return String(name.prefix(2)).uppercased()
    }

    private func assignEmployee(_ employee: User) async {
        isUpdating = true
        var update = UserUpdate()
        update.shiftId = shift.id
        update.hasShiftIdValue = true
        do {
            try await dbService.update(table: "users", value: update, column: "id", equals: employee.id.uuidString.lowercased())
            await fetchLocalEmployees()
            onUpdate()
        } catch { print("Failed to assign: \(error)") }
        isUpdating = false
    }

    private func unassignEmployee(_ employee: User) async {
        isUpdating = true
        var update = UserUpdate()
        update.shiftId = nil
        update.hasShiftIdValue = true
        do {
            try await dbService.update(table: "users", value: update, column: "id", equals: employee.id.uuidString.lowercased())
            await fetchLocalEmployees()
            onUpdate()
        } catch { print("Failed to unassign: \(error)") }
        isUpdating = false
    }

    private func deleteShift() async {
        isUpdating = true
        do {
            for emp in assignedEmployees {
                var update = UserUpdate()
                update.shiftId = nil
                update.hasShiftIdValue = true
                try await dbService.update(table: "users", value: update, column: "id", equals: emp.id.uuidString.lowercased())
            }
            try await dbService.delete(from: "shifts", column: "id", equals: shift.id.uuidString.lowercased())
            ShiftMetadataStore.shared.delete(id: shift.id)
            await fetchLocalEmployees()
            onUpdate()
            dismiss()
        } catch { print("Failed to delete shift: \(error)") }
        isUpdating = false
    }
}

// MARK: - Shift Metadata Local Storage Model
struct ShiftMetadata: Codable {
    let id: UUID
    let color: String
    let type: String
    let notes: String?
}

final class ShiftMetadataStore {
    static let shared = ShiftMetadataStore()
    private let key = "shift_metadata_local"
    private init() {}

    func save(metadata: ShiftMetadata) {
        var data = getAll()
        data[metadata.id] = metadata
        if let encoded = try? JSONEncoder().encode(data) {
            UserDefaults.standard.set(encoded, forKey: key)
        }
    }

    func get(id: UUID) -> ShiftMetadata? { getAll()[id] }

    func delete(id: UUID) {
        var data = getAll()
        data.removeValue(forKey: id)
        if let encoded = try? JSONEncoder().encode(data) {
            UserDefaults.standard.set(encoded, forKey: key)
        }
    }

    func getAll() -> [UUID: ShiftMetadata] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode([UUID: ShiftMetadata].self, from: data) else { return [:] }
        return decoded
    }
}

// MARK: - Assign Employee List View Component
struct AssignEmployeeView: View {
    @Environment(\.dismiss) private var dismiss

    let shiftId: UUID
    let storeId: UUID
    let allEmployees: [User]
    var onAssign: (User) -> Void

    @State private var searchText = ""

    var eligibleEmployees: [User] {
        let storeStaff = allEmployees.filter { $0.storeId == storeId && ($0.shiftId == nil || $0.shiftId == shiftId) }
        if searchText.isEmpty { return storeStaff }
        return storeStaff.filter { $0.fullName.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        List {
            let candidates = eligibleEmployees
            if candidates.isEmpty {
                Text("No available store employees found to assign.")
                    .foregroundColor(Color(.secondaryLabel))
                    .font(.system(size: 14))
            } else {
                ForEach(candidates) { candidate in
                    let localProfile = EmployeeProfileStore.shared.get(id: candidate.id)
                    HStack {
                        if let photoData = localProfile?.profilePhotoData, let uiImage = UIImage(data: photoData) {
                            Image(uiImage: uiImage)
                                .resizable().scaledToFill()
                                .frame(width: 38, height: 38).clipShape(Circle())
                        } else {
                            Text(initials(for: candidate.fullName))
                                .font(.system(size: 12, weight: .bold)).foregroundColor(.white)
                                .frame(width: 38, height: 38)
                                .background(Color(.systemBlue)).clipShape(Circle())
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text(candidate.fullName).font(.system(size: 15, weight: .semibold))
                            HStack(spacing: 6) {
                                Text(candidate.designation ?? localProfile?.jobRole ?? "Staff")
                                    .font(.system(size: 12)).foregroundColor(Color(.secondaryLabel))
                                Text("•").font(.system(size: 10)).foregroundColor(Color(.tertiaryLabel))
                                Text(candidate.shiftId == nil ? "Not Assigned" : "Assigned to this Shift")
                                    .font(.system(size: 12)).foregroundColor(Color(.secondaryLabel))
                            }
                        }
                        .padding(.leading, 4)
                        Spacer()
                        if candidate.shiftId == shiftId {
                            Button("Unassign") { onAssign(candidate) }
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.red)
                                .padding(.horizontal, 12).padding(.vertical, 6)
                                .background(Color(.systemRed).opacity(0.1))
                                .cornerRadius(8)
                        } else {
                            Button("Assign") { onAssign(candidate) }
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 12).padding(.vertical, 6)
                                .background(Color(.systemBlue))
                                .cornerRadius(8)
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        }
        .searchable(text: $searchText, prompt: "Search employees...")
        .navigationTitle("Assign Employee")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") { dismiss() }
            }
        }
    }

    private func initials(for name: String) -> String {
        let p = name.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        if p.count >= 2 { return "\(p[0].prefix(1))\(p[p.count-1].prefix(1))".uppercased() }
        return String(name.prefix(2)).uppercased()
    }
}

// MARK: - File-level Shift Time Helpers
private func parseTime(_ timeStr: String) -> Date? {
    let f = DateFormatter()
    f.locale = Locale(identifier: "en_US_POSIX")
    f.timeZone = TimeZone(secondsFromGMT: 0)
    
    let formats = ["HH:mm:ss", "HH:mm", "h:mm a"]
    for format in formats {
        f.dateFormat = format
        if let date = f.date(from: timeStr) {
            return date
        }
    }
    return nil
}

private func formatTimeHelper(_ timeStr: String) -> String {
    if let d = parseTime(timeStr) {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(secondsFromGMT: 0)
        f.dateFormat = "h:mm a"
        return f.string(from: d)
    }
    return timeStr
}
