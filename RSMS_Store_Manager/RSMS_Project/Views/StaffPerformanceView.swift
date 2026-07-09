import SwiftUI
import StoreManagerModule
import Charts

struct StaffPerformanceView: View {
    @StateObject private var viewModel = StaffPerformanceViewModel()
    @State private var selectedEmployeeId: UUID?
    @State private var selectedAngle: Double?
    
    // Adaptive iOS colors for chart
    let chartColors: [Color] = [.blue, .green, .orange, .purple, .pink, .teal]
    
    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()
            
            if viewModel.isLoading {
                ProgressView("Loading Performance...")
            } else if let error = viewModel.errorMessage {
                VStack {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundColor(.orange)
                        .padding(.bottom, 8)
                    Text(error)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding()
                }
            } else if viewModel.performanceData.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "chart.pie")
                        .font(.system(size: 60))
                        .foregroundColor(.secondary)
                    Text("No sales recorded")
                        .font(.title2)
                        .fontWeight(.semibold)
                    Text("Sales performance will appear once transactions are recorded.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
            } else {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 32) {
                        
                        // Section 1: Sales Contribution Chart
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Sales Contribution")
                                .font(.title3)
                                .fontWeight(.bold)
                                .padding(.horizontal)
                            
                            chartSection
                                .padding(.horizontal)
                        }
                        .padding(.top)
                        
                        // Section 2: Staff Performance List
                        VStack(alignment: .leading, spacing: 16) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Top Performers")
                                    .font(.title3)
                                    .fontWeight(.bold)
                            }
                            .padding(.horizontal)
                            
                            LazyVStack(spacing: 16) {
                                ForEach(Array(viewModel.performanceData.enumerated()), id: \.element.id) { index, data in
                                    NavigationLink(destination: EmployeePerformanceView(metrics: data)) {
                                        StaffPerformanceCard(
                                            data: data,
                                            isTopPerformer: index == 0
                                        )
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.bottom, 40)
                }
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Text("Performance")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(Color(.label))
            }
        }
        .onAppear {
            Swift.Task {
                await viewModel.loadData()
                if let topPerformer = viewModel.performanceData.first {
                    withAnimation(.snappy) {
                        selectedEmployeeId = topPerformer.user.id
                    }
                }
            }
        }
    }
    
    private var chartSection: some View {
        ZStack {
            Chart {
                ForEach(Array(viewModel.performanceData.enumerated()), id: \.element.id) { index, data in
                    let isSelected = selectedEmployeeId == data.user.id
                    
                    SectorMark(
                        angle: .value("Contribution", data.contributionPercentage),
                        innerRadius: .ratio(0.65),
                        outerRadius: isSelected ? .ratio(1.0) : .ratio(0.92),
                        angularInset: 1.5
                    )
                    .cornerRadius(6)
                    .foregroundStyle(chartColors[index % chartColors.count])
                    .opacity(isSelected ? 1.0 : 0.6)
                }
            }
            .chartAngleSelection(value: $selectedAngle)
            .onChange(of: selectedAngle) { oldValue, newValue in
                if let newValue {
                    findSelectedEmployee(at: newValue)
                }
            }
            .frame(height: 300)
            .animation(.snappy, value: selectedEmployeeId)
            
            // Center Overlay
            if let selectedData = viewModel.performanceData.first(where: { $0.user.id == selectedEmployeeId }) {
                VStack(spacing: 4) {
                    Text("\(Int(round(selectedData.contributionPercentage)))%")
                        .font(.system(size: 38, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    Text(selectedData.user.fullName ?? "Unknown")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(formatCurrency(selectedData.totalSalesAmount))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                    
                    Text("\(selectedData.transactionCount) Sales")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .transition(.opacity)
                .id(selectedEmployeeId) // Forces transition on change
            }
        }
        .padding(.vertical, 24)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        )
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
    }
    
    private func findSelectedEmployee(at angle: Double) {
        var cumulative: Double = 0
        for data in viewModel.performanceData {
            cumulative += data.contributionPercentage
            if angle <= cumulative {
                withAnimation(.snappy) {
                    selectedEmployeeId = data.user.id
                }
                return
            }
        }
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

struct StaffPerformanceCard: View {
    let data: StaffPerformanceMetrics
    let isTopPerformer: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            // Top section: Avatar, Name, Role, Contribution
            HStack(spacing: 16) {
                // Profile Image
                Group {
                    if let imageURLStr = data.user.profileImageURL, let url = URL(string: imageURLStr) {
                        AsyncImage(url: url) { image in
                            image
                                .resizable()
                                .scaledToFill()
                        } placeholder: {
                            Color(.systemGray5)
                        }
                    } else {
                        Image(systemName: "person.crop.circle.fill")
                            .resizable()
                            .scaledToFit()
                            .foregroundColor(Color(.systemGray4))
                    }
                }
                .frame(width: isTopPerformer ? 52 : 44, height: isTopPerformer ? 52 : 44)
                .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(data.user.fullName ?? "Unknown Staff")
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text(data.user.designation ?? "Sales Associate")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(Int(round(data.contributionPercentage)))%")
                        .font(isTopPerformer ? .title : .title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    Text("Contribution")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Divider()
            
            // Bottom section: Metrics
            HStack {
                MetricItem(title: "Today's Sales", value: formatCurrency(data.totalSalesAmount))
                Spacer()
                MetricItem(title: "Transactions", value: "\(data.transactionCount)")
                Spacer()
                MetricItem(title: "Average Sale", value: formatCurrency(data.averageSale))
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        )
        .shadow(
            color: Color.black.opacity(isTopPerformer ? 0.08 : 0.04),
            radius: isTopPerformer ? 12 : 8,
            x: 0,
            y: isTopPerformer ? 6 : 4
        )
        // Pressed scale animation is handled implicitly by NavigationLink button style,
        // but we add a custom scale effect if needed. Using PlainButtonStyle already gives a slight native fade.
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

struct MetricItem: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
        }
    }
}
