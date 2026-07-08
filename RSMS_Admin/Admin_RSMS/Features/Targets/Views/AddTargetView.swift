import SwiftUI

// Uses existing FormTheme from StoreForm.swift, assuming it's available globally or we can redefine minimally
private enum TargetFormTheme {
    static let navy = Color(red: 0.1, green: 0.2, blue: 0.4)
    static let cardBackground = Color(uiColor: .secondarySystemGroupedBackground)
    static let fieldBackground = Color(uiColor: .systemGray6)
    static let cornerRadius: CGFloat = 16
    static let fieldCornerRadius: CGFloat = 12
}

struct AddTargetView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var sizeClass
    @ObservedObject private var dataManager = RSMSDataManager.shared
    
    // Form state
    @State private var targetAmount: Double? = nil
    @State private var targetPeriod: TargetPeriod = .monthly
    @State private var targetStartDate: Date = Date()
    @State private var targetEndDate: Date = Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date()
    @State private var selectedStores: Set<UUID> = []
    
    let editingTarget: RevenueTarget?
    var onSave: (RevenueTarget) -> Void
    
    init(editingTarget: RevenueTarget? = nil, onSave: @escaping (RevenueTarget) -> Void) {
        self.editingTarget = editingTarget
        self.onSave = onSave
        if let amt = editingTarget?.amount {
            _targetAmount = State(initialValue: amt)
        }
        _targetPeriod = State(initialValue: editingTarget?.period ?? .monthly)
        _targetStartDate = State(initialValue: editingTarget?.startDate ?? Date())
        _targetEndDate = State(initialValue: editingTarget?.endDate ?? Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date())
        _selectedStores = State(initialValue: Set(editingTarget?.assignedStoreIDs ?? []))
    }
    
    // Dummy formatted amount
    private var amountString: Binding<String> {
        Binding(
            get: {
                if let amount = targetAmount { return String(format: "%.0f", amount) }
                return ""
            },
            set: {
                if let value = Double($0) { targetAmount = value }
                else if $0.isEmpty { targetAmount = nil }
            }
        )
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    basicInfoSection
                    assignmentSection
                }
                .padding(sizeClass == .regular ? 32 : 20)
            }
            .onChange(of: targetPeriod) { _ in autoUpdateEndDate() }
            .onChange(of: targetStartDate) { _ in autoUpdateEndDate() }
            .background(Color(uiColor: .systemGroupedBackground).ignoresSafeArea())
            .navigationTitle(editingTarget == nil ? "Create Revenue Target" : "Edit Revenue Target")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: saveAction) {
                        Text(editingTarget == nil ? "Create" : "Save").fontWeight(.bold)
                    }
                    .disabled(targetAmount == nil || selectedStores.isEmpty)
                }
            }
        }
    }
    
    // MARK: - Sections
    
    private var basicInfoSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            sectionHeader(title: "Target Details", icon: "chart.bar.fill")
            

            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("AMOUNT (₹)")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.secondary)
                    
                    TextField("0.00", text: amountString)
                        .keyboardType(.decimalPad)
                        .padding()
                        .background(TargetFormTheme.fieldBackground)
                        .clipShape(RoundedRectangle(cornerRadius: TargetFormTheme.fieldCornerRadius))
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("PERIOD")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.secondary)
                    
                    Text(TargetPeriod.monthly.rawValue)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(TargetFormTheme.fieldBackground)
                        .clipShape(RoundedRectangle(cornerRadius: TargetFormTheme.fieldCornerRadius))
                }
            }
            
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("START DATE")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.secondary)
                    
                    HStack {
                        DatePicker("Select Start Date", selection: $targetStartDate, in: Date()..., displayedComponents: [.date])
                            .labelsHidden()
                        Spacer()
                    }
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("END DATE")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.secondary)
                    
                    HStack {
                        DatePicker("Select End Date", selection: $targetEndDate, in: endDateRange, displayedComponents: [.date])
                            .labelsHidden()
                        Spacer()
                    }
                }
            }
        }
        .padding(24)
        .background(TargetFormTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: TargetFormTheme.cornerRadius))
    }
    
    private var assignmentSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            sectionHeader(title: "Store Assignment", icon: "building.2.crop.circle.fill")
            storeSelectionList
        }
        .padding(24)
        .background(TargetFormTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: TargetFormTheme.cornerRadius))
    }
    
    private var storeSelectionList: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Select Stores")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                if !dataManager.stores.isEmpty {
                    Button(action: {
                        if selectedStores.count == dataManager.stores.count {
                            selectedStores.removeAll()
                        } else {
                            selectedStores = Set(dataManager.stores.map { $0.id })
                        }
                    }) {
                        Text(selectedStores.count == dataManager.stores.count ? "Deselect All" : "Select All")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.blue)
                    }
                }
            }
            
            if dataManager.stores.isEmpty {
                Text("No stores available.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(dataManager.stores, id: \.id) { store in
                    Button(action: {
                        toggleStoreSelection(store.id)
                    }) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(store.name)
                                    .foregroundStyle(.primary)
                                    .fontWeight(.semibold)
                                Text(store.storeID ?? "")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            if selectedStores.contains(store.id) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.blue)
                                    .font(.system(size: 20))
                            } else {
                                Image(systemName: "circle")
                                    .foregroundStyle(.secondary.opacity(0.3))
                                    .font(.system(size: 20))
                            }
                        }
                        .padding()
                        .background(TargetFormTheme.fieldBackground)
                        .clipShape(RoundedRectangle(cornerRadius: TargetFormTheme.fieldCornerRadius))
                        .overlay(
                            RoundedRectangle(cornerRadius: TargetFormTheme.fieldCornerRadius)
                                .stroke(selectedStores.contains(store.id) ? Color.blue : Color.clear, lineWidth: 2)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
    
    // MARK: - Helpers
    
    private var endDateRange: ClosedRange<Date> {
        let calendar = Calendar.current
        let minDate = calendar.date(byAdding: .day, value: 1, to: targetStartDate) ?? targetStartDate
        let maxDate: Date
        
        switch targetPeriod {
        case .monthly:
            maxDate = calendar.date(byAdding: .month, value: 1, to: targetStartDate) ?? targetStartDate
        }
        
        return minDate...maxDate
    }
    
    private func autoUpdateEndDate() {
        let calendar = Calendar.current
        switch targetPeriod {
        case .monthly:
            targetEndDate = calendar.date(byAdding: .month, value: 1, to: targetStartDate) ?? targetStartDate
        }
    }
    
    private func sectionHeader(title: String, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(TargetFormTheme.navy)
            Text(title)
                .font(.system(size: 18, weight: .bold, design: .rounded))
        }
    }
    
    private func toggleStoreSelection(_ id: UUID) {
        if selectedStores.contains(id) {
            selectedStores.remove(id)
        } else {
            selectedStores.insert(id)
        }
    }
    
    private func saveAction() {
        let finalStores = Array(selectedStores)
        
        var target = editingTarget ?? RevenueTarget(
            name: "Target",
            amount: targetAmount ?? 0.0,
            period: targetPeriod,
            assignedStoreIDs: finalStores,
            startDate: targetStartDate,
            endDate: targetEndDate
        )
        
        target.name = "Target"
        target.amount = targetAmount ?? 0.0
        target.period = targetPeriod
        target.assignedStoreIDs = finalStores
        target.startDate = targetStartDate
        target.endDate = targetEndDate
        
        onSave(target)
        dismiss()
    }
}

#Preview {
    AddTargetView(editingTarget: nil) { _ in }
}
