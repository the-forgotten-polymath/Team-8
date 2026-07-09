import SwiftUI
import Supabase

struct StoreDetailModalView: View {
    let store: AdminStore
    var onDismiss: () -> Void
    
    @State private var employees: [User] = []
    @State private var isLoadingEmployees = true
    
    @State private var healthScore: HealthScore? = nil
    @State private var isLoadingHealthScore = true
    
    private let userService = UserService()
    @Environment(\.horizontalSizeClass) private var sizeClass
    
    var body: some View {
        NavigationStack {
            ScrollView {
                if sizeClass == .regular {
                    wideLayout
                } else {
                    compactLayout
                }
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle(store.name)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close", action: onDismiss)
                }
            }
        }
        .task {
            await fetchEmployees()
            await fetchHealthScore()
        }
    }
    
    // MARK: - Layouts
    
    private var wideLayout: some View {
        HStack(alignment: .top, spacing: 24) {
            VStack(spacing: 20) {
                storeDetailsSection
                healthScoreSection
            }
            .frame(maxWidth: .infinity)
            
            VStack(spacing: 20) {
                managerSection
                employeesSection
            }
            .frame(maxWidth: .infinity)
        }
        .padding(28)
    }
    
    private var compactLayout: some View {
        VStack(spacing: 20) {
            storeDetailsSection
            healthScoreSection
            managerSection
            employeesSection
        }
        .padding(20)
    }
    
    // MARK: - Sections
    
    private var storeDetailsSection: some View {
        FormSectionCard(title: "Store Details", icon: "building.2") {
            VStack(alignment: .leading, spacing: 16) {
                detailRow(label: "Store ID", value: store.storeID ?? "Auto-generated", icon: "number")
                detailRow(label: "Location / Address", value: store.address, icon: "mappin.circle.fill")
                detailRow(label: "Status", value: store.status.rawValue.capitalized, icon: "circle.fill", valueColor: statusColor(for: store.status))
            }
        }
    }
    
    private var healthScoreSection: some View {
        FormSectionCard(title: "Retail Health", icon: "heart.text.square") {
            HStack {
                Text("Overall Score")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.primary)
                
                Spacer()
                
                if isLoadingHealthScore {
                    ProgressView()
                } else if let score = healthScore {
                    Text("\(Int(score.overallScore))%")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(scoreColor(for: score.overallScore))
                } else {
                    Text("-")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 8)
        }
    }
    
    private var managerSection: some View {
        let isVacant = store.managerName.trimmingCharacters(in: .whitespaces).isEmpty || 
                       store.managerName.lowercased() == "vacant"
        let initials = isVacant ? "-" : (store.managerInitials.isEmpty ? "-" : store.managerInitials)
        let nameToDisplay = isVacant ? "-" : store.managerName
        
        return FormSectionCard(title: "Assigned Manager", icon: "person.fill") {
            HStack(spacing: 16) {
                Circle()
                    .fill(Color(uiColor: .systemGray5))
                    .frame(width: 48, height: 48)
                    .overlay(
                        Text(initials)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.primary)
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(nameToDisplay)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.primary)
                    Text("Manager")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding(.vertical, 8)
        }
    }
    
    private var employeesSection: some View {
        FormSectionCard(title: "Employees", icon: "person.3.fill") {
            if isLoadingEmployees {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding()
            } else if employees.isEmpty {
                Text("No employees assigned to this store.")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 8)
            } else {
                VStack(spacing: 12) {
                    ForEach(employees) { employee in
                        HStack(spacing: 12) {
                            Circle()
                                .fill(Color(uiColor: .systemGray5))
                                .frame(width: 36, height: 36)
                                .overlay(
                                    Text(employeeInitials(for: employee.fullName))
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundStyle(.primary)
                                )
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(employee.fullName)
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(.primary)
                                Text(employee.designation ?? "Employee")
                                    .font(.system(size: 12))
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                        }
                        .padding(.vertical, 4)
                        
                        if employee.id != employees.last?.id {
                            Divider()
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Handlers
    
    private func fetchHealthScore() async {
        do {
            let scores: [HealthScore] = try await SupabaseManager.shared.client
                .from("health_scores")
                .select()
                .eq("store_id", value: store.id.uuidString)
                .execute()
                .value
            
            DispatchQueue.main.async {
                self.healthScore = scores.first
                self.isLoadingHealthScore = false
            }
        } catch {
            print("Error fetching health score: \(error)")
            DispatchQueue.main.async {
                self.isLoadingHealthScore = false
            }
        }
    }
    
    private func fetchEmployees() async {
        do {
            let fetchedUsers = try await userService.fetchUsersByStore(storeId: store.id)
            DispatchQueue.main.async {
                self.employees = fetchedUsers
                self.isLoadingEmployees = false
            }
        } catch {
            print("Error fetching employees: \(error)")
            DispatchQueue.main.async {
                self.isLoadingEmployees = false
            }
        }
    }
    
    private func detailRow(label: String, value: String, icon: String, valueColor: Color = .primary) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label.uppercased())
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(.secondary)
            
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(valueColor)
            }
        }
    }
    
    private func statusColor(for status: StoreStatus) -> Color {
        switch status {
        case .active: return .green
        case .maintenance: return .orange
        case .inventory: return .blue
        }
    }
    
    private func scoreColor(for score: Double) -> Color {
        if score >= 80 { return .green }
        if score >= 60 { return .orange }
        return .red
    }
    
    private func employeeInitials(for name: String) -> String {
        let components = name.components(separatedBy: " ")
        if components.count >= 2 {
            let first = components[0].prefix(1)
            let last = components.last?.prefix(1) ?? ""
            return String(first + last).uppercased()
        } else {
            return String(name.prefix(2)).uppercased()
        }
    }
}
