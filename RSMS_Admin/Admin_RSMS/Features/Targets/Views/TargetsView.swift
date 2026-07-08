import SwiftUI

struct TargetsView: View {
    @ObservedObject private var dataManager = RSMSDataManager.shared
    @State private var searchText = ""
    @State private var showingAddTarget = false
    @State private var targetToEdit: RevenueTarget?

    var filteredTargets: [RevenueTarget] {
        if searchText.isEmpty {
            return dataManager.targets
        } else {
            return dataManager.targets.filter { target in
                target.name.localizedCaseInsensitiveContains(searchText)
            }
        }
    }

    var body: some View {
        Group {
            if dataManager.targets.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "bullseye")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary.opacity(0.5))
                    Text("No Targets Found")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Text("Get started by adding a new target.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.pageBG)
            } else {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(filteredTargets) { target in
                            NavigationLink(destination: TargetDetailView(target: target)) {
                                targetCard(target)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding()
                }
                .background(Color.pageBG)
            }
        }
        .searchable(text: $searchText, prompt: "Search targets...")
        .navigationTitle("Targets")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    showingAddTarget = true
                }) {
                    Image(systemName: "plus")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.accentColor)
                }
            }
        }
        .sheet(isPresented: $showingAddTarget) {
            AddTargetView(editingTarget: nil) { newTarget in
                dataManager.addTarget(newTarget)
            }
        }
        .sheet(item: $targetToEdit) { target in
            AddTargetView(editingTarget: target) { updatedTarget in
                dataManager.updateTarget(updatedTarget)
            }
        }
    }
    
    // MARK: - Target Card
    private func targetCard(_ target: RevenueTarget) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.1))
                        .frame(width: 48, height: 48)
                    Image(systemName: "chart.bar.fill")
                        .foregroundColor(.blue)
                        .font(.system(size: 20))
                }
                
                // Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(target.name)
                        .font(.headline)
                        .fontWeight(.bold)
                    
                    HStack(spacing: 12) {
                        Label(target.period.rawValue, systemImage: "calendar")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Label("\(target.assignedStoreIDs.count) Stores", systemImage: "building.2")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                Spacer()
                
                // Amount
                VStack(alignment: .trailing, spacing: 4) {
                    Text("₹\(target.amount, specifier: "%.2f")")
                        .font(.title3)
                        .fontWeight(.heavy)
                        .foregroundColor(.primary)
                }
            }
            .padding()
            
            Divider()
            
            HStack {
                Text("\(target.startDate.formatted(date: .abbreviated, time: .omitted)) - \(target.endDate.formatted(date: .abbreviated, time: .omitted))")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Menu {
                    Button("Edit") {
                        targetToEdit = target
                    }
                    Button("Delete", role: .destructive) {
                        dataManager.removeTarget(target)
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 8)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color(uiColor: .systemGray6).opacity(0.5))
        }
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
    }
}

#Preview {
    NavigationStack {
        TargetsView()
    }
}
