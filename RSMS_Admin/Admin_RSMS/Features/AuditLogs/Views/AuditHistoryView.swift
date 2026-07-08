import SwiftUI

struct AuditHistoryView: View {
    let entries: [AuditTrailEntry]
    let stores: [AdminStore]
    let onExport: (AuditExportFormat) -> Void
    
    @State private var searchText: String = ""
    @State private var selectedModule: AuditModuleFilter = .all
    @State private var selectedStore: String = "All Stores"
    @State private var selectedDateRange: DateRangeFilter = .last30Days
    @State private var customStartDate: Date = Date().addingTimeInterval(-3600 * 24 * 30)
    @State private var customEndDate: Date = Date()
    @State private var showCustomDatePicker: Bool = false
    
    // Additional Filters
    @State private var selectedActivityType: String = "All Types"
    @State private var selectedStatus: String = "All Statuses"
    @State private var selectedSeverity: String = "All Severities"
    @State private var selectedRole: String = "All Roles"
    
    @State private var showAdvancedFilters: Bool = false
    @State private var selectedEntry: AuditTrailEntry? = nil
    
    let activityTypes = ["All Types", "Created", "Updated", "Approved", "Rejected", "Completed", "Deleted"]
    let statuses = ["All Statuses", "Open", "In Progress", "Resolved"]
    let severities = ["All Severities", "High", "Medium", "Low"]
    let userRoles = ["All Roles", "Corporate Admin", "Boutique Manager", "Sales Associate", "Inventory Controller"]
    
    // Filtered Entries
    private var filteredEntries: [AuditTrailEntry] {
        var result = entries
        
        // 1. Search filter
        if !searchText.isEmpty {
            result = result.filter {
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                $0.subtitle.localizedCaseInsensitiveContains(searchText) ||
                $0.storeName.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // 2. Module (Audit Area) filter
        if selectedModule != .all {
            result = result.filter { $0.module == selectedModule }
        }
        
        // 3. Store filter
        if selectedStore != "All Stores" {
            result = result.filter { $0.storeName.localizedCaseInsensitiveCompare(selectedStore) == .orderedSame }
        }
        
        // 4. Date Range filter
        let now = Date()
        let calendar = Calendar.current
        let startDate: Date? = {
            switch selectedDateRange {
            case .today:
                return calendar.startOfDay(for: now)
            case .last7Days:
                return calendar.date(byAdding: .day, value: -7, to: now)
            case .last30Days:
                return calendar.date(byAdding: .day, value: -30, to: now)
            case .thisQuarter:
                let components = calendar.dateComponents([.year], from: now)
                let currentMonth = calendar.component(.month, from: now)
                let quarterStartMonth = ((currentMonth - 1) / 3) * 3 + 1
                var startComponents = DateComponents()
                startComponents.year = components.year
                startComponents.month = quarterStartMonth
                startComponents.day = 1
                return calendar.date(from: startComponents)
            case .customRange:
                return nil // Handled separately
            }
        }()
        
        if selectedDateRange == .customRange {
            // Include dates matching range boundary
            let start = calendar.startOfDay(for: customStartDate)
            let end = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: customEndDate) ?? customEndDate
            result = result.filter { $0.timestamp >= start && $0.timestamp <= end }
        } else if let startDate {
            result = result.filter { $0.timestamp >= startDate }
        }
        
        // 5. Activity Type
        if selectedActivityType != "All Types" {
            result = result.filter { entry in
                let t = entry.title.lowercased()
                switch selectedActivityType {
                case "Created":
                    return t.contains("created") || t.contains("started") || t.contains("reported")
                case "Updated":
                    return t.contains("adjustment") || t.contains("updated")
                case "Approved":
                    return t.contains("approved") || t.contains("verified")
                case "Rejected":
                    return t.contains("rejected")
                case "Completed":
                    return t.contains("completed") || t.contains("received")
                case "Deleted":
                    return t.contains("deleted")
                default:
                    return true
                }
            }
        }
        
        // 6. Status
        if selectedStatus != "All Statuses" {
            result = result.filter { entry in
                switch selectedStatus {
                case "Open":
                    return entry.statusDotColor != nil
                case "Resolved":
                    return entry.title.contains("Adjustment") || entry.title.contains("Verified")
                case "In Progress":
                    return entry.statusDotColor == nil && !entry.title.contains("Adjustment") && !entry.title.contains("Verified")
                default:
                    return true
                }
            }
        }
        
        // 7. Severity
        if selectedSeverity != "All Severities" {
            result = result.filter { entry in
                switch selectedSeverity {
                case "High":
                    return entry.tint == .auditRed
                case "Medium":
                    return entry.tint == .auditOrange || entry.tint == .auditYellow
                case "Low":
                    return entry.tint == .auditGreen || entry.tint == .auditBlue || entry.tint == .auditPurple || entry.tint == .auditIndigo
                default:
                    return true
                }
            }
        }
        
        // 8. User Role
        if selectedRole != "All Roles" {
            result = result.filter { entry in
                // Infer role from fields or defaults
                let userField = entry.detailFields.first(where: { $0.label.localizedCaseInsensitiveContains("User") || $0.label.localizedCaseInsensitiveContains("Manager") })?.value ?? ""
                switch selectedRole {
                case "Corporate Admin":
                    return userField.localizedCaseInsensitiveContains("Admin") || entry.title.contains("Target")
                case "Boutique Manager":
                    return userField.localizedCaseInsensitiveContains("Manager") || entry.title.contains("Stock")
                case "Sales Associate":
                    return userField.localizedCaseInsensitiveContains("Sales") || entry.title.contains("Sale")
                case "Inventory Controller":
                    return userField.localizedCaseInsensitiveContains("Inventory") || entry.title.contains("Shipment") || entry.title.contains("Cycle")
                default:
                    return true
                }
            }
        }
        
        return result
    }

    var body: some View {
        VStack(spacing: 0) {
            // Search Bar & Advanced filter toggle
            HStack(spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Search history...", text: $searchText)
                        .font(.bodyPrimary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color.cardBG, in: RoundedRectangle(cornerRadius: 12))
                .cardShadow()
                
                Button(action: { showAdvancedFilters.toggle() }) {
                    Image(systemName: showAdvancedFilters ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                        .font(.title3)
                        .foregroundColor(showAdvancedFilters ? Color.brandGreenDark : .secondary)
                        .frame(width: 44, height: 44)
                        .background(Color.cardBG, in: RoundedRectangle(cornerRadius: 12))
                        .cardShadow()
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            
            // Standard Filters Row
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    // Audit Area Picker Menu
                    filterMenu(title: "Area: \(selectedModule.rawValue)", selections: AuditModuleFilter.allCases) { selectedModule = $0 }
                    
                    // Store Picker Menu
                    filterMenu(title: "Store: \(selectedStore)", selections: ["All Stores"] + stores.map(\.name)) { selectedStore = $0 }
                    
                    // Date Range Picker Menu
                    filterMenu(title: "Date: \(selectedDateRange.rawValue)", selections: DateRangeFilter.allCases) { selectedDateRange = $0 }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 12)
            }
            
            if selectedDateRange == .customRange {
                HStack(spacing: 12) {
                    Text("From:")
                        .font(.caption.weight(.bold))
                        .foregroundColor(.secondary)
                    DatePicker("Start:", selection: $customStartDate, displayedComponents: .date)
                        .labelsHidden()
                        .font(.caption)
                    
                    Text("to")
                        .font(.caption.weight(.bold))
                        .foregroundColor(.secondary)
                    
                    DatePicker("End:", selection: $customEndDate, displayedComponents: .date)
                        .labelsHidden()
                        .font(.caption)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 12)
            }
            
            // Advanced Filters Drawer
            if showAdvancedFilters {
                VStack(alignment: .leading, spacing: 14) {
                    Text("ADDITIONAL HISTORICAL FILTERS")
                        .font(.caption2.weight(.heavy))
                        .foregroundColor(.secondary)
                        .tracking(1.0)
                    
                    Grid(horizontalSpacing: 16, verticalSpacing: 12) {
                        GridRow {
                            pickerField(label: "Activity Type", value: selectedActivityType, options: activityTypes) { selectedActivityType = $0 }
                            pickerField(label: "Status", value: selectedStatus, options: statuses) { selectedStatus = $0 }
                        }
                        GridRow {
                            pickerField(label: "Severity", value: selectedSeverity, options: severities) { selectedSeverity = $0 }
                            pickerField(label: "User Role", value: selectedRole, options: userRoles) { selectedRole = $0 }
                        }
                    }
                }
                .padding(18)
                .background(Color.cardBG)
                .cornerRadius(16)
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
                .cardShadow()
                .transition(.move(edge: .top).combined(with: .opacity))
            }
            
            // List of filtered history entries
            ScrollView {
                LazyVStack(spacing: 10) {
                    if filteredEntries.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "tray")
                                .font(.system(size: 32))
                                .foregroundColor(.secondary)
                            Text("No audit events match your filters.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 80)
                    } else {
                        ForEach(filteredEntries) { entry in
                            Button { selectedEntry = entry } label: {
                                AuditTrailRow(entry: entry)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
        }
        .background(Color.pageBG.ignoresSafeArea())
        .navigationTitle("Full Audit History")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button("Export PDF") { onExport(.pdf) }
                    Button("Export Excel") { onExport(.excel) }
                    Button("Export CSV") { onExport(.csv) }
                } label: {
                    Label("Export", systemImage: "square.and.arrow.up")
                        .font(.system(size: 15, weight: .semibold))
                }
            }
        }
        .sheet(item: $selectedEntry) { entry in
            AuditDetailSheet(entry: entry)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .animation(.easeInOut(duration: 0.2), value: showAdvancedFilters)
    }
    
    @ViewBuilder
    private func filterMenu<T: RawRepresentable & Hashable>(
        title: String,
        selections: [T],
        onSelect: @escaping (T) -> Void
    ) -> some View where T.RawValue == String {
        Menu {
            ForEach(selections, id: \.self) { item in
                Button(item.rawValue) { onSelect(item) }
            }
        } label: {
            HStack(spacing: 6) {
                Text(title)
                    .font(.caption.weight(.bold))
                Image(systemName: "chevron.down")
                    .font(.system(size: 10, weight: .bold))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Color.cardBG, in: Capsule())
            .foregroundColor(.primary)
            .chipShadow()
        }
    }
    
    @ViewBuilder
    private func filterMenu(
        title: String,
        selections: [String],
        onSelect: @escaping (String) -> Void
    ) -> some View {
        Menu {
            ForEach(selections, id: \.self) { item in
                Button(item) { onSelect(item) }
            }
        } label: {
            HStack(spacing: 6) {
                Text(title)
                    .font(.caption.weight(.bold))
                Image(systemName: "chevron.down")
                    .font(.system(size: 10, weight: .bold))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Color.cardBG, in: Capsule())
            .foregroundColor(.primary)
            .chipShadow()
        }
    }
    
    @ViewBuilder
    private func pickerField(label: String, value: String, options: [String], onSelect: @escaping (String) -> Void) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label.uppercased())
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(.secondary)
                .tracking(0.5)
            
            Menu {
                ForEach(options, id: \.self) { opt in
                    Button(opt) { onSelect(opt) }
                }
            } label: {
                HStack {
                    Text(value)
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.primary)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.pageBG, in: RoundedRectangle(cornerRadius: 8))
            }
        }
    }
}

#Preview {
    NavigationStack {
        AuditHistoryView(entries: [], stores: [], onExport: { _ in })
    }
}
