import Foundation

enum TargetPeriod: String, Codable, CaseIterable {
    case weekly = "Weekly"
    case monthly = "Monthly"
}

struct RevenueTarget: Identifiable, Codable {
    var id: UUID = UUID()
    var name: String
    var amount: Double
    var period: TargetPeriod
    var assignedStoreIDs: [UUID]
    var startDate: Date
    var endDate: Date
    var isArchived: Bool = false
}
