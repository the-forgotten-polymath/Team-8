import SwiftUI
import Combine

// Stub model for Staff Performance Metrics
public struct StaffPerformanceMetrics: Identifiable, Hashable {
    public let id: UUID
    public let user: User
    public let totalSalesAmount: Double
    public let transactionCount: Int
    public let contributionPercentage: Double
    
    public var averageSale: Double {
        transactionCount > 0 ? totalSalesAmount / Double(transactionCount) : 0.0
    }
    
    public init(id: UUID = UUID(), user: User, totalSalesAmount: Double, transactionCount: Int, contributionPercentage: Double) {
        self.id = id
        self.user = user
        self.totalSalesAmount = totalSalesAmount
        self.transactionCount = transactionCount
        self.contributionPercentage = contributionPercentage
    }
    
    public static func == (lhs: StaffPerformanceMetrics, rhs: StaffPerformanceMetrics) -> Bool {
        lhs.id == rhs.id
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// Stub view model for Staff Performance
@MainActor
public class StaffPerformanceViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String? = nil
    @Published var performanceData: [StaffPerformanceMetrics] = []
    
    public init() {}
    
    public func loadData() async {
        self.isLoading = true
        self.errorMessage = nil
        
        do {
            // Fetch users from database to populate performance mock data
            let allUsers = try await UserService().fetchUsers()
            // Keep only sales associates
            let salesAssociates = allUsers.filter { $0.designation?.lowercased().contains("sales") == true || $0.roleId != UUID() }
            
            var stubs: [StaffPerformanceMetrics] = []
            let totalAmount = 145000.0
            
            if !salesAssociates.isEmpty {
                let count = salesAssociates.count
                for (index, user) in salesAssociates.enumerated() {
                    let share = Double(count - index) / Double((count * (count + 1)) / 2)
                    let contribution = totalAmount * share
                    let percentage = share * 100.0
                    stubs.append(StaffPerformanceMetrics(
                        user: user,
                        totalSalesAmount: contribution,
                        transactionCount: Int.random(in: 5...25),
                        contributionPercentage: percentage
                    ))
                }
            } else {
                // Fallback to dummy data if no users exist
                let mockUser = User(
                    id: UUID(),
                    fullName: "Inventory Associate",
                    username: "associate",
                    email: "associate@rsms.com",
                    isVerified: true,
                    roleId: UUID(),
                    designation: "Sales Associate"
                )
                stubs.append(StaffPerformanceMetrics(
                    user: mockUser,
                    totalSalesAmount: 45000.0,
                    transactionCount: 15,
                    contributionPercentage: 100.0
                ))
            }
            
            self.performanceData = stubs.sorted(by: { $0.totalSalesAmount > $1.totalSalesAmount })
        } catch {
            self.errorMessage = "Failed to load performance data: \(error.localizedDescription)"
        }
        
        self.isLoading = false
    }
}

// Stub view for Employee Performance details
public struct EmployeePerformanceView: View {
    let metrics: StaffPerformanceMetrics
    
    public init(metrics: StaffPerformanceMetrics) {
        self.metrics = metrics
    }
    
    public var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.crop.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.blue)
            
            Text(metrics.user.fullName)
                .font(.title)
                .fontWeight(.bold)
            
            Text(metrics.user.designation ?? "Sales Associate")
                .foregroundColor(.secondary)
            
            Divider()
                .padding(.horizontal)
            
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Total Contribution:")
                    Spacer()
                    Text("\(Int(round(metrics.contributionPercentage)))%")
                        .fontWeight(.bold)
                }
                
                HStack {
                    Text("Total Sales:")
                    Spacer()
                    Text(formatCurrency(metrics.totalSalesAmount))
                        .fontWeight(.bold)
                }
                
                HStack {
                    Text("Transactions Count:")
                    Spacer()
                    Text("\(metrics.transactionCount)")
                        .fontWeight(.bold)
                }
                
                HStack {
                    Text("Average Transaction Size:")
                    Spacer()
                    Text(formatCurrency(metrics.averageSale))
                        .fontWeight(.bold)
                }
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(12)
            .padding(.horizontal)
            
            Spacer()
        }
        .padding(.top)
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Employee Performance")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "en_IN")
        formatter.currencySymbol = "₹"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "₹0"
    }
}
