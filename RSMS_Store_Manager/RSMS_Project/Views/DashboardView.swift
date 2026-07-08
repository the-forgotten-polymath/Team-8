//
//  DashboardView.swift
//  RSMS_Project
//
//  Created by Antigravity on 03/07/26.
//

import SwiftUI
import Supabase
import Combine

// MARK: - Models

struct DailySale: Identifiable, Equatable {
    var id: String { dayLabel }
    let dayLabel: String
    let amount: Double
}

struct StaffShiftDisplay: Identifiable, Equatable {
    let id: UUID
    let name: String
    let role: String
    let shiftTime: String
    let initials: String
    let isAbsent: Bool
    let user: User
    let roleName: String
    let storeName: String
    let shiftName: String

    static func ==(lhs: StaffShiftDisplay, rhs: StaffShiftDisplay) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - View Model

@MainActor
final class DashboardViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String? = nil
    
    @Published var lowStockCount: Int = 0
    @Published var todaySalesAmount: Double = 0.0
    @Published var salesGoal: Double = 0.0
    @Published var chartData: [DailySale] = []
    @Published var upcomingAppointments: [Appointment] = []
    @Published var nextAppointmentDate: Date? = nil
    @Published var nextAppointmentCount: Int = 0
    @Published var customers: [Customer] = []
    @Published var staffShifts: [StaffShiftDisplay] = []
    @Published var users: [User] = []
    @Published var stores: [Store] = []
    
    @Published var attendanceValueText: String = "Loading..."
    @Published var presentCount: Int = 0
    @Published var assignedCount: Int = 0
    
    @Published var currentShift: Shift? = nil
    @Published var currentShiftHeader: String = "Staff Shifts"
    @Published var nextShiftName: String? = nil
    @Published var nextShiftTimeRange: String? = nil
    @Published var nextShiftStaffCount: Int = 0
    
    private let client = SupabaseManager.shared.client
    private let dbService = DatabaseService.shared
    
    private func formatShiftTime(_ timeStr: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        if let date = formatter.date(from: timeStr) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateFormat = "h a"
            return displayFormatter.string(from: date).lowercased()
        }
        
        formatter.dateFormat = "HH:mm"
        if let date = formatter.date(from: timeStr) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateFormat = "h a"
            return displayFormatter.string(from: date).lowercased()
        }
        return timeStr
    }
    
    func loadDashboardData() async {
        isLoading = true
        errorMessage = nil
        
        // Ensure session is resolved
        if SessionManager.shared.currentUser == nil {
            await SessionManager.shared.resolveSession()
        }
        
        guard let currentUser = SessionManager.shared.currentUser,
              let storeId = currentUser.storeId else {
            isLoading = false
            return
        }
        
        // Fetch Attendance Data Independently so it always loads
        Swift.Task {
            await fetchAttendanceForStaff(storeId: storeId, currentUser: currentUser)
        }
        
        do {
            // 1. Fetch Inventory for Low Stock count
            let inventoryResponse = try await client
                .from("inventory")
                .select()
                .eq("store_id", value: storeId.uuidString)
                .execute()
            let inventoryItems = try JSONDecoder.supabaseDecoder.decodeSupabase([InventoryItem].self, from: inventoryResponse.data)
            
            // Count items requiring attention (quantity <= reorder_level)
            self.lowStockCount = inventoryItems.filter { $0.quantity <= $0.reorderLevel }.count
            
            // 2. Fetch Sales from last 7 days
            let calendar = Calendar.current
            let sevenDaysAgo = calendar.date(byAdding: .day, value: -6, to: calendar.startOfDay(for: Date())) ?? Date()
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            let dateString = formatter.string(from: sevenDaysAgo)
            
            let salesResponse = try await client
                .from("sales")
                .select()
                .eq("store_id", value: storeId.uuidString)
                .gte("sale_date", value: dateString)
                .execute()
            let sales = try JSONDecoder.supabaseDecoder.decodeSupabase([Sale].self, from: salesResponse.data)
            
            // Group sales by the last 7 days
            var tempChartData: [DailySale] = []
            let weekdaySymbols = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
            
            for i in 0..<7 {
                let targetDate = calendar.date(byAdding: .day, value: -6 + i, to: calendar.startOfDay(for: Date())) ?? Date()
                let weekdayIndex = calendar.component(.weekday, from: targetDate) - 1
                let label = weekdaySymbols[weekdayIndex]
                
                let daySales = sales.filter { calendar.isDate($0.saleDate, inSameDayAs: targetDate) }
                let total = daySales.reduce(0.0) { $0 + $1.totalAmount }
                
                tempChartData.append(DailySale(dayLabel: label, amount: total))
            }
            
            self.chartData = tempChartData
            // Today is the last element in tempChartData
            self.todaySalesAmount = tempChartData.last?.amount ?? 0.0
            
            // 3. Fetch today's appointments (rest of today only)
            let now = Date()
            let endOfDay = calendar.startOfDay(for: now).addingTimeInterval(86400) // midnight tonight
            let nowString = now.ISO8601Format()
            let endOfDayString = endOfDay.ISO8601Format()
            
            let tasksResponse = try await client
                .from("appointments")
                .select()
                .eq("store_id", value: storeId.uuidString)
                .neq("status", value: "done")
                .gte("appointment_datetime", value: nowString)
                .lt("appointment_datetime", value: endOfDayString)
                .order("appointment_datetime", ascending: true)
                .execute()
            self.upcomingAppointments = try JSONDecoder.supabaseDecoder.decodeSupabase([Appointment].self, from: tasksResponse.data)
            
            // 3a. If today is empty, peek at the next future appointment
            if self.upcomingAppointments.isEmpty {
                let peekResponse = try await client
                    .from("appointments")
                    .select()
                    .eq("store_id", value: storeId.uuidString)
                    .neq("status", value: "done")
                    .gte("appointment_datetime", value: endOfDayString)
                    .order("appointment_datetime", ascending: true)
                    .limit(1)
                    .execute()
                let futureAppointments = try JSONDecoder.supabaseDecoder.decodeSupabase([Appointment].self, from: peekResponse.data)
                if let next = futureAppointments.first {
                    self.nextAppointmentDate = next.appointmentDatetime
                    // Count how many appointments are on that same day
                    let nextDayStart = calendar.startOfDay(for: next.appointmentDatetime)
                    let nextDayEnd = nextDayStart.addingTimeInterval(86400)
                    let countResponse = try await client
                        .from("appointments")
                        .select()
                        .eq("store_id", value: storeId.uuidString)
                        .neq("status", value: "done")
                        .gte("appointment_datetime", value: nextDayStart.ISO8601Format())
                        .lt("appointment_datetime", value: nextDayEnd.ISO8601Format())
                        .execute()
                    let nextDayAppointments = try JSONDecoder.supabaseDecoder.decodeSupabase([Appointment].self, from: countResponse.data)
                    self.nextAppointmentCount = nextDayAppointments.count
                } else {
                    self.nextAppointmentDate = nil
                    self.nextAppointmentCount = 0
                }
            } else {
                self.nextAppointmentDate = nil
                self.nextAppointmentCount = 0
            }
            
            // 3b. Fetch customers for appointment display
            let fetchedCustomers: [Customer] = try await dbService.fetch(from: "customers", as: Customer.self)
            self.customers = fetchedCustomers
            
            // 4. Fetch Shifts, Staff and Roles
            let shiftsResponse = try await client
                .from("shifts")
                .select()
                .eq("store_id", value: storeId.uuidString)
                .eq("status", value: "active")
                .execute()
            let shifts = try JSONDecoder.supabaseDecoder.decodeSupabase([Shift].self, from: shiftsResponse.data)
            
            let usersResponse = try await client
                .from("users")
                .select()
                .eq("store_id", value: storeId.uuidString)
                .execute()
            let users = try JSONDecoder.supabaseDecoder.decodeSupabase([User].self, from: usersResponse.data)
            
            let rolesResponse = try await client
                .from("roles")
                .select()
                .execute()
            let roles = try JSONDecoder.supabaseDecoder.decodeSupabase([Role].self, from: rolesResponse.data)
            let roleMap = Dictionary(uniqueKeysWithValues: roles.map { ($0.id, $0.roleName) })
            
            let fetchedStores: [Store] = try await dbService.fetch(from: "stores", as: Store.self)
            
            self.users = users
            self.stores = fetchedStores
            
            // Resolve current shift based on current hour (8 AM to 10 PM)
            let currentHour = calendar.component(.hour, from: Date())
            
            if currentHour >= 8 && currentHour < 22 {
                let timeFormatter = DateFormatter()
                timeFormatter.dateFormat = "HH:mm:ss"
                
                let matchingShift = shifts.first { shift in
                    guard let startDate = timeFormatter.date(from: shift.startTime),
                          let endDate = timeFormatter.date(from: shift.endTime) else {
                        return false
                    }
                    let startHour = calendar.component(.hour, from: startDate)
                    let endHour = calendar.component(.hour, from: endDate)
                    return currentHour >= startHour && currentHour < endHour
                }
                
                if let shift = matchingShift {
                    self.currentShift = shift
                    
                    let startStr = formatShiftTime(shift.startTime)
                    let endStr = formatShiftTime(shift.endTime)
                    self.currentShiftHeader = "\(shift.shiftName) (\(startStr) - \(endStr))"
                    
                    // Filter users assigned to this shift
                    var tempStaffShifts: [StaffShiftDisplay] = []
                    let shiftUsers = users.filter { $0.shiftId == shift.id }
                    
                    for user in shiftUsers {
                        let roleName = roleMap[user.roleId] ?? "Staff"
                        let initials = String(user.fullName.split(separator: " ").compactMap { $0.first }.prefix(2)).uppercased()
                        let initialsString = initials.isEmpty ? String(user.fullName.prefix(2)).uppercased() : initials
                        
                        let timeRange = "\(shift.startTime) - \(shift.endTime)"
                        let isAbsent = (user.employeeStatus?.lowercased() == "absent")
                        let storeName = fetchedStores.first(where: { $0.id == storeId })?.storeName ?? "Store"
                        
                        tempStaffShifts.append(StaffShiftDisplay(
                            id: user.id,
                            name: user.fullName,
                            role: roleName,
                            shiftTime: timeRange,
                            initials: initialsString,
                            isAbsent: isAbsent,
                            user: user,
                            roleName: roleName,
                            storeName: storeName,
                            shiftName: shift.shiftName
                        ))
                    }
                    self.staffShifts = tempStaffShifts
                } else {
                    self.currentShift = nil
                    self.currentShiftHeader = ""
                    self.staffShifts = []
                }
            } else {
                self.currentShift = nil
                self.currentShiftHeader = ""
                self.staffShifts = []
            }
            
            // If no current shift, find the next upcoming one
            if self.currentShift == nil && !shifts.isEmpty {
                let timeFormatter = DateFormatter()
                timeFormatter.dateFormat = "HH:mm:ss"
                let sortedShifts = shifts.sorted { s1, s2 in
                    let d1 = timeFormatter.date(from: s1.startTime) ?? Date.distantFuture
                    let d2 = timeFormatter.date(from: s2.startTime) ?? Date.distantFuture
                    return d1 < d2
                }
                let nextShift = sortedShifts.first { shift in
                    guard let startDate = timeFormatter.date(from: shift.startTime) else { return false }
                    let startHour = calendar.component(.hour, from: startDate)
                    return startHour > currentHour
                } ?? sortedShifts.first // wrap around to first shift tomorrow
                
                if let next = nextShift {
                    let startStr = formatShiftTime(next.startTime)
                    let endStr = formatShiftTime(next.endTime)
                    self.nextShiftName = next.shiftName
                    self.nextShiftTimeRange = "\(startStr) – \(endStr)"
                    self.nextShiftStaffCount = users.filter { $0.shiftId == next.id }.count
                } else {
                    self.nextShiftName = nil
                    self.nextShiftTimeRange = nil
                    self.nextShiftStaffCount = 0
                }
            } else if self.currentShift != nil {
                self.nextShiftName = nil
                self.nextShiftTimeRange = nil
                self.nextShiftStaffCount = 0
            }
            
        } catch {
            print("Failed to load dashboard data: \(error)")
            self.errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    private func fetchAttendanceForStaff(storeId: UUID, currentUser: User) async {
        do {
            let usersResponse = try await client
                .from("users")
                .select()
                .eq("store_id", value: storeId.uuidString)
                .execute()
            let users = try JSONDecoder.supabaseDecoder.decodeSupabase([User].self, from: usersResponse.data)
            
            let fetchedAttendance: [Attendance] = try await dbService.fetch(from: "attendance", as: Attendance.self)
            
            let currentUserId = currentUser.id
            let storeEmployees = users.filter { $0.id != currentUserId }
            
            await MainActor.run {
                if storeEmployees.isEmpty {
                    self.attendanceValueText = "No Staff"
                    self.presentCount = 0
                    self.assignedCount = 0
                } else {
                    let assigned = storeEmployees.count
                    let calendar = Calendar.current
                    let todayRecords = fetchedAttendance.filter { calendar.isDateInToday($0.attendanceDate) }
                    let present = storeEmployees.filter { emp in
                        todayRecords.contains { $0.employeeId == emp.id && $0.status.lowercased() == "present" }
                    }.count
                    self.presentCount = present
                    self.assignedCount = assigned
                    self.attendanceValueText = "\(present) / \(assigned)"
                }
            }
        } catch {
            print("Failed to compute attendanceValueText: \(error)")
            await MainActor.run {
                self.attendanceValueText = "Error"
            }
        }
    }
}

// MARK: - View

struct DashboardView: View {
    @Binding var selectedTab: Int
    @Binding var selectedStockFilter: StockFilterType
    @StateObject private var viewModel = DashboardViewModel()
    
    @State private var selectedDay: String? = nil
    @State private var showBars = false
    

    @State private var selectedEmployeeDetail: StaffShiftDisplay? = nil
    @State private var selectedAppointment: Appointment? = nil
    @State private var showingNotifications = false
    @State private var showingProfile = false
    
    private var currentDayString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: Date())
    }
    
    private var headerSubtitle: String {
        if let day = selectedDay, let sale = viewModel.chartData.first(where: { $0.dayLabel == day }) {
            return formatIndianCurrency(amount: sale.amount)
        }
        return "\(formatIndianCurrency(amount: viewModel.todaySalesAmount)) / \(formatIndianCurrency(amount: viewModel.salesGoal))"
    }
    
    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.chartData.isEmpty {
                VStack(spacing: 12) {
                    ProgressView()
                        .scaleEffect(1.2)
                    Text("Loading Dashboard...")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Custom Header Row aligning Title and Notification Button
                        HStack(spacing: 12) {
                            Text("Dashboard")
                                .font(.system(size: 34, weight: .bold))
                                .foregroundColor(Color(.label))
                            Spacer()
                            Button {
                                showingNotifications = true
                            } label: {
                                ZStack {
                                    Circle()
                                        .fill(Color(.secondarySystemGroupedBackground))
                                        .frame(width: 40, height: 40)
                                        .shadow(color: Color.black.opacity(0.04), radius: 5, x: 0, y: 2)
                                    Image(systemName: "bell.fill")
                                        .font(.system(size: 18, weight: .medium))
                                        .foregroundColor(.blue)
                                }
                            }
                            Button {
                                showingProfile = true
                            } label: {
                                ZStack {
                                    Circle()
                                        .fill(Color(.secondarySystemGroupedBackground))
                                        .frame(width: 40, height: 40)
                                        .shadow(color: Color.black.opacity(0.04), radius: 5, x: 0, y: 2)
                                    Image(systemName: "person.fill")
                                        .font(.system(size: 18, weight: .medium))
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 16)

                        // Hidden navigation link to shift page removed, using navigationDestination instead
                        
                        // 1. Low Stock Banner/Card (Conditional)
                        if viewModel.lowStockCount > 0 {
                            lowStockBannerCard
                        }
                        
                        // 2. Interactive Sales Chart Card
                        salesProgressChartCard
                        
                        // 3. Staff on Floor (Unified Card)
                        staffOnFloorCard
                        
                        // 4. Upcoming Appointments Card
                        upcomingAppointmentsCard
                    }
                    .padding(.vertical)
                }
            }
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationBarHidden(true)

        .sheet(item: $selectedEmployeeDetail) { staff in
            NavigationStack {
                EmployeeDetailView(
                    employee: staff.user,
                    roleName: staff.roleName,
                    storeName: staff.storeName,
                    shiftName: staff.shiftName,
                    onUpdate: { updatedUser in
                        Swift.Task {
                            await viewModel.loadDashboardData()
                        }
                    },
                    onDelete: { deletedUser in
                        Swift.Task {
                            await viewModel.loadDashboardData()
                        }
                    }
                )
            }
        }
        .sheet(isPresented: $showingNotifications) {
            NotificationsOrdersView()
        }
        .sheet(isPresented: $showingProfile) {
            if let user = SessionManager.shared.currentUser {
                StoreManagerProfileSheet(user: user, onLogout: {
                    SessionManager.shared.currentUser = nil
                })
            }
        }
        .onAppear {
            Swift.Task {
                await viewModel.loadDashboardData()
                showBars = true
            }
        }
        .refreshable {
            await viewModel.loadDashboardData()
        }
        .sheet(item: $selectedAppointment, onDismiss: {
            Swift.Task { await viewModel.loadDashboardData() }
        }) { appointment in
            AppointmentDetailView(
                appointment: appointment,
                employees: viewModel.users,
                stores: viewModel.stores,
                existingAppointments: viewModel.upcomingAppointments,
                onUpdate: { Swift.Task { await viewModel.loadDashboardData() } }
            )
        }
    }
    
    // MARK: - Cards
    
    private var lowStockBannerCard: some View {
        Button {
            selectedStockFilter = .lowStock
            withAnimation {
                selectedTab = 2 // Navigate to Stock Tab
            }
        } label: {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color.orange.opacity(0.2))
                        .frame(width: 40, height: 40)
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.headline).fontWeight(.bold)
                        .foregroundColor(.orange)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(viewModel.lowStockCount) items Low Stock")
                        .font(.subheadline).fontWeight(.bold)
                        .foregroundColor(Color(.label))
                    
                    Text("Keep an eye on this")
                        .font(.caption).fontWeight(.medium)
                        .foregroundColor(Color(.secondaryLabel))
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.footnote).fontWeight(.bold)
                    .foregroundColor(Color.orange.opacity(0.5))
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.orange.opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.orange.opacity(0.3), lineWidth: 1)
            )
            .padding(.horizontal, 20)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var staffOnFloorCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack(spacing: 6) {
                Image(systemName: "person.2.fill")
                    .foregroundColor(Color(.label))
                Text(viewModel.currentShift != nil ? "STAFF ON FLOOR" : "STAFF")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(Color(.label))
                    .tracking(1)
                
                Spacer()
                
                NavigationLink(destination: ShiftManagementView()) {
                    Image(systemName: "chevron.right")
                        .font(.footnote).fontWeight(.bold)
                        .foregroundColor(Color(.secondaryLabel))
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            // Attendance headline
            if viewModel.assignedCount == 0 {
                Text("No Staff")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(Color(.secondaryLabel))
            } else {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    if viewModel.presentCount == viewModel.assignedCount {
                        Text("All \(viewModel.assignedCount) present")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(Color(.label))
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.system(size: 16))
                    } else {
                        Text("\(viewModel.presentCount)")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(Color(.label))
                        Text("/ \(viewModel.assignedCount) present")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Color(.secondaryLabel))
                    }
                }
            }
            
            // Current shift subtitle
            if let shift = viewModel.currentShift {
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 6, height: 6)
                    Text(viewModel.currentShiftHeader)
                        .font(.caption)
                        .foregroundColor(Color(.secondaryLabel))
                }
            }
            
            // Shift staff carousel OR next shift teaser
            if !viewModel.staffShifts.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(viewModel.staffShifts) { staff in
                            staffAvatarPill(for: staff)
                                .onTapGesture {
                                    selectedEmployeeDetail = staff
                                }
                        }
                    }
                }
            } else if let nextName = viewModel.nextShiftName, let nextTime = viewModel.nextShiftTimeRange {
                // No current shift — show next shift teaser
                HStack(spacing: 8) {
                    Image(systemName: "clock")
                        .font(.system(size: 14))
                        .foregroundColor(Color(.tertiaryLabel))
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Next: \(nextName)")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(Color(.label))
                        HStack(spacing: 4) {
                            Text(nextTime)
                            Text("·")
                            Text("\(viewModel.nextShiftStaffCount) staff")
                        }
                        .font(.caption)
                        .foregroundColor(Color(.secondaryLabel))
                    }
                    Spacer()
                }
                .padding(12)
                .background(Color(.secondaryLabel).opacity(0.04))
                .cornerRadius(12)
            }
        }
        .padding(20)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.04), radius: 15, x: 0, y: 8)
        .padding(.horizontal)
    }
    
    @ViewBuilder
    private func staffAvatarPill(for staff: StaffShiftDisplay) -> some View {
        HStack(spacing: 10) {
            ZStack(alignment: .bottomTrailing) {
                Circle()
                    .fill(Color(.secondaryLabel).opacity(0.1))
                    .frame(width: 36, height: 36)
                    .overlay(
                        Text(String(staff.initials.prefix(1)))
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(Color(.label))
                    )
                Circle()
                    .fill(staff.isAbsent ? Color.red : Color.green)
                    .frame(width: 10, height: 10)
                    .overlay(Circle().stroke(Color(.secondarySystemGroupedBackground), lineWidth: 1.5))
            }
            
            VStack(alignment: .leading, spacing: 1) {
                Text(staff.name.components(separatedBy: " ").first ?? "")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(Color(.label))
                    .lineLimit(1)
                Text(staff.role)
                    .font(.caption2)
                    .foregroundColor(Color(.secondaryLabel))
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.secondaryLabel).opacity(0.05))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(staff.isAbsent ? Color.red.opacity(0.2) : Color(.secondaryLabel).opacity(0.08), lineWidth: 1)
        )
    }
    
    private var salesProgressChartCard: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Header
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Image(systemName: "chart.bar.xaxis")
                            .foregroundColor(Color(.label))
                        Text(selectedDay != nil ? "SALES (\(selectedDay!.uppercased()))" : "SALES")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(Color(.label))
                            .textCase(.uppercase)
                            .animation(.easeInOut, value: selectedDay)
                    }
                    
                    Text(headerSubtitle)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(selectedDay != nil ? .blue : Color(.label))
                        .animation(.easeInOut, value: selectedDay)
                }
                
                Spacer()
            }
            
            // Bar Chart
            HStack(alignment: .bottom, spacing: 0) {
                let maxSales = max(viewModel.chartData.map { $0.amount }.max() ?? 0.0, 5000.0)
                
                // Y-Axis Labels
                VStack(alignment: .trailing, spacing: 0) {
                    ForEach((0...5).reversed(), id: \.self) { i in
                        let value = (maxSales / 5.0) * Double(i)
                        Text(formatK(value))
                            .font(.caption2)
                            .foregroundColor(Color(.secondaryLabel))
                            .frame(maxHeight: .infinity, alignment: .bottom)
                    }
                }
                .frame(height: 180)
                .padding(.trailing, 16)
                
                // Bars
                HStack(alignment: .bottom, spacing: 20) {
                    ForEach(Array(viewModel.chartData.enumerated()), id: \.element.id) { index, day in
                        let isCurrentDay = day.dayLabel == currentDayString
                        let isAnySelected = selectedDay != nil
                        let showPresentDayHighlight = isCurrentDay && !isAnySelected
                        let isSelected = selectedDay == day.dayLabel
                        
                        VStack(spacing: 8) {
                            GeometryReader { geometry in
                                ZStack(alignment: .bottom) {
                                    // Background track
                                    Capsule()
                                        .fill(Color(.secondaryLabel).opacity(0.15))
                                        .frame(height: geometry.size.height)
                                    
                                    // Foreground track (Actual)
                                    Capsule()
                                        .fill(isSelected || !isAnySelected ? Color.blue : Color(.secondaryLabel).opacity(0.3))
                                        .shadow(color: Color.blue.opacity(isSelected ? 0.6 : (showPresentDayHighlight ? 0.8 : 0.0)), radius: isSelected ? 10 : (showPresentDayHighlight ? 12 : 0), x: 0, y: isSelected ? 4 : 0)
                                        .frame(height: showBars ? geometry.size.height * CGFloat(day.amount / maxSales) : 0)
                                        .scaleEffect(isSelected ? 1.15 : 1.0, anchor: .bottom)
                                        .zIndex(isSelected || showPresentDayHighlight ? 1 : 0)
                                        .animation(.spring(response: 0.6, dampingFraction: 0.65, blendDuration: 0).delay(Double(index) * 0.1), value: showBars)
                                        .animation(.spring(response: 0.4, dampingFraction: 0.6, blendDuration: 0), value: selectedDay)
                                }
                            }
                            .frame(width: showPresentDayHighlight ? 22 : 16, height: 180)
                            .animation(.spring(response: 0.4, dampingFraction: 0.6, blendDuration: 0), value: selectedDay)
                            
                            // X-Axis Label
                            Text(day.dayLabel)
                                .font(.caption2)
                                .fontWeight(showPresentDayHighlight ? .bold : .regular)
                                .foregroundColor(selectedDay == day.dayLabel || showPresentDayHighlight ? .blue : Color(.secondaryLabel))
                                .animation(.easeInOut, value: selectedDay)
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            if selectedDay == day.dayLabel {
                                selectedDay = nil
                            } else {
                                selectedDay = day.dayLabel
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .padding(20)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.04), radius: 15, x: 0, y: 8)
        .padding(.horizontal)
        .onTapGesture {
            // Tapping background clears selection
            selectedDay = nil
        }
    }
    
    private var upcomingAppointmentsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            NavigationLink(destination: AppointmentManagementView()) {
                HStack(spacing: 6) {
                    Image(systemName: "calendar")
                        .foregroundColor(Color(.label))
                    Text("TODAY'S APPOINTMENTS")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(Color(.label))
                        .tracking(1)
                    

                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.footnote).fontWeight(.bold)
                        .foregroundColor(Color(.secondaryLabel))
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            // Appointment Rows
            if viewModel.upcomingAppointments.isEmpty {
                NavigationLink(destination: AppointmentManagementView()) {
                    VStack(spacing: 10) {
                        Image(systemName: "calendar.badge.checkmark")
                            .font(.system(size: 28))
                            .foregroundColor(Color(.tertiaryLabel))
                        Text("All clear for today")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(Color(.secondaryLabel))
                        
                        if let nextDate = viewModel.nextAppointmentDate {
                            HStack(spacing: 4) {
                                Text("Next:")
                                    .foregroundColor(Color(.tertiaryLabel))
                                Text(nextDateLabel(nextDate))
                                    .foregroundColor(Color(.label))
                                    .fontWeight(.medium)
                                Text("·")
                                    .foregroundColor(Color(.tertiaryLabel))
                                Text("\(viewModel.nextAppointmentCount) appointment\(viewModel.nextAppointmentCount == 1 ? "" : "s")")
                                    .foregroundColor(Color(.tertiaryLabel))
                            }
                            .font(.caption)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                }
                .buttonStyle(PlainButtonStyle())
            } else {
                VStack(spacing: 0) {
                    let displayAppointments = Array(viewModel.upcomingAppointments.prefix(3))
                    ForEach(Array(displayAppointments.enumerated()), id: \.element.id) { index, appointment in
                        Button(action: {
                            selectedAppointment = appointment
                        }) {
                            appointmentRow(for: appointment)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        if index < displayAppointments.count - 1 {
                            Divider()
                                .padding(.leading, 62)
                        }
                    }
                }
                .padding(.vertical, 4)
                .background(Color(.secondaryLabel).opacity(0.04))
                .cornerRadius(14)
            }
        }
        .padding(20)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.04), radius: 15, x: 0, y: 8)
        .padding(.horizontal)
    }
    
    @ViewBuilder
    private func appointmentRow(for appointment: Appointment) -> some View {
        HStack(spacing: 12) {
            // Time badge
            VStack(spacing: 2) {
                Text(formatTime(appointment.appointmentDatetime))
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(.blue)
                    .lineLimit(1)
                
                // Relative day label if not today
                if !Calendar.current.isDateInToday(appointment.appointmentDatetime) {
                    let dayLabel = Calendar.current.isDateInTomorrow(appointment.appointmentDatetime) ? "Tomorrow" : formatShortDate(appointment.appointmentDatetime)
                    Text(dayLabel)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(Color(.secondaryLabel))
                        .lineLimit(1)
                }
            }
            .frame(width: 65)
            
            // Vertical accent line
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.blue.opacity(0.3))
                .frame(width: 3, height: 36)
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(appointment.appointmentName ?? appointment.description ?? "Appointment")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(Color(.label))
                    .lineLimit(1)
                
                if let desc = appointment.description, appointment.appointmentName != nil {
                    Text(desc)
                        .font(.caption2)
                        .foregroundColor(Color(.secondaryLabel))
                        .lineLimit(1)
                }
                
                HStack(spacing: 8) {
                    if let customer = viewModel.customers.first(where: { $0.id == appointment.customerId }) {
                        HStack(spacing: 3) {
                            Image(systemName: "person.fill")
                                .font(.system(size: 9))
                                .foregroundColor(Color(.systemBlue))
                            Text(customer.name)
                                .font(.caption)
                                .foregroundColor(Color(.secondaryLabel))
                                .lineLimit(1)
                        }
                    }
                }
            }
            
            Spacer(minLength: 4)
            
            Image(systemName: "chevron.right")
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(Color(.tertiaryLabel))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }
    
    private func formatShortDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        return f.string(from: date)
    }
    
    private func nextDateLabel(_ date: Date) -> String {
        if Calendar.current.isDateInTomorrow(date) {
            return "Tomorrow"
        }
        let f = DateFormatter()
        f.dateFormat = "EEE, MMM d"
        return f.string(from: date)
    }
    


    
    // MARK: - Formatting Helpers
    
    private func formatK(_ amount: Double) -> String {
        if amount == 0 { return "0K" }
        if amount >= 1000 {
            return "\(Int(amount / 1000))K"
        }
        return "\(Int(amount))"
    }
    
    private func formatTime(_ date: Date?) -> String {
        guard let d = date else { return "--:--" }
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: d)
    }
    
    private func formatIndianCurrency(amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "en_IN")
        formatter.currencySymbol = "₹"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "₹0"
    }
}

// MARK: - Notifications View for Delivered or Approved Orders

struct NotificationsOrdersView: View {
    @StateObject private var viewModel = OrderHistoryViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                if viewModel.isLoading {
                    ProgressView("Loading updates...")
                } else {
                    let filtered = viewModel.orders.filter {
                        let s = $0.status.lowercased()
                        return s == "delivered" || s == "approved"
                    }
                    
                    if filtered.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "bell.slash")
                                .font(.system(size: 48))
                                .foregroundColor(.secondary)
                            Text("No Notifications")
                                .font(.system(size: 18, weight: .bold))
                            Text("Orders approved or delivered will show here.")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                        }
                    } else {
                        ScrollView(showsIndicators: false) {
                            LazyVStack(spacing: 12) {
                                ForEach(filtered) { order in
                                    NavigationLink(destination: OrderDetailView(orderId: order.orderId)) {
                                        OrderHistoryCard(order: order)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 16)
                        }
                    }
                }
            }
            .navigationTitle("Updates")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Dismiss") {
                        dismiss()
                    }
                }
            }
            .task {
                await viewModel.loadOrders()
            }
        }
    }
}

struct StoreManagerProfileSheet: View {
    let user: User
    var onLogout: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var storeName: String = "Loading..."
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Profile Avatar/Header
                VStack(spacing: 12) {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.blue)
                    
                    Text(user.fullName)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text(user.designation ?? "Store Manager")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 24)
                
                // Details List
                List {
                    Section(header: Text("Account Details")) {
                        HStack {
                            Text("Username")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(user.username)
                                .foregroundColor(.primary)
                        }
                        
                        HStack {
                            Text("Email")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(user.email)
                                .foregroundColor(.primary)
                        }
                        
                        HStack {
                            Text("Phone")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(user.phone ?? "Not Provided")
                                .foregroundColor(.primary)
                        }
                        
                        HStack {
                            Text("Store")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(storeName)
                                .foregroundColor(.primary)
                        }
                    }
                }
                .listStyle(InsetGroupedListStyle())
                
                Spacer()
                
                // Logout Button
                Button(action: {
                    dismiss()
                    onLogout()
                }) {
                    Text("Log Out")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.red)
                        .cornerRadius(12)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 24)
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                fetchStoreName()
            }
        }
        .preferredColorScheme(.light)
    }
    
    private func fetchStoreName() {
        guard let storeId = user.storeId else {
            self.storeName = "No Store Assigned"
            return
        }
        
        Swift.Task {
            do {
                let client = SupabaseManager.shared.client
                struct StoreNameResponse: Codable {
                    let name: String
                }
                let store: StoreNameResponse = try await client
                    .from("stores")
                    .select("name")
                    .eq("id", value: storeId.uuidString)
                    .single()
                    .execute()
                    .value
                await MainActor.run {
                    self.storeName = store.name
                }
            } catch {
                print("Failed to fetch store name: \(error)")
                await MainActor.run {
                    self.storeName = "Unknown Store"
                }
            }
        }
    }
}
