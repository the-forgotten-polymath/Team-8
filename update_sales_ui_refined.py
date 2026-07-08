import sys

def main():
    file_path = '/Users/abhistro/Desktop/Team-8/RSMS_Store_Manager/RSMS_Project/Views/SalesHistoryView.swift'
    with open(file_path, 'r') as f:
        content = f.read()

    # The block we want to replace starts at "struct SalesKPICardView: View {" and goes to the end of the file or just the Views.
    # Actually, we can use multi_replace_file_content or just split the file if it's safe.
    # Let's find the `// MARK: - Analytics Header UI` marker.
    
    parts = content.split("// MARK: - Analytics Header UI")
    
    if len(parts) < 2:
        print("Could not find MARK")
        return
        
    base_content = parts[0]
    
    new_ui = """// MARK: - Analytics Header UI

struct SalesKPICardView: View {
    let symbol: String
    let title: String
    let value: String
    let subtitle: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: symbol)
                .font(.system(size: 20))
                .foregroundColor(.blue)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(Color(.label))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Color(.secondaryLabel))
                Text(subtitle)
                    .font(.system(size: 11))
                    .foregroundColor(Color(.tertiaryLabel))
                    .lineLimit(2)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .cornerRadius(18)
        .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 4)
    }
}

struct SalesDoughnutChartView: View {
    let currentRevenue: Double
    let monthlyTarget: Double
    @State private var animatedPercentage: Double = 0
    
    var completionPercentage: Double {
        if monthlyTarget == 0 { return 0 }
        return min((currentRevenue / monthlyTarget) * 100, 100.0)
    }
    
    var isTargetSet: Bool {
        return monthlyTarget > 0
    }
    
    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                // Background Track
                Circle()
                    .stroke(Color(.systemGray5), lineWidth: 16)
                
                // Progress
                if isTargetSet {
                    Circle()
                        .trim(from: 0, to: CGFloat(animatedPercentage / 100.0))
                        .stroke(Color.blue, style: StrokeStyle(lineWidth: 16, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                }
                
                // Center text
                VStack(spacing: 2) {
                    Text(formatIndianCurrency(amount: currentRevenue))
                        .font(.system(size: 26, weight: .bold))
                        .foregroundColor(Color(.label))
                        .minimumScaleFactor(0.7)
                        .lineLimit(1)
                    
                    Text("Current Revenue")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(Color(.secondaryLabel))
                    
                    if isTargetSet {
                        Text(String(format: "%.0f%% Complete", animatedPercentage))
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.green)
                            .padding(.top, 4)
                    } else {
                        Text("Target Not Available")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(Color(.tertiaryLabel))
                            .padding(.top, 4)
                    }
                }
                .padding(24)
            }
            .frame(width: 176, height: 176)
            .onAppear {
                withAnimation(.spring(response: 1.0, dampingFraction: 0.8)) {
                    animatedPercentage = completionPercentage
                }
            }
            .onChange(of: currentRevenue) { _ in
                withAnimation(.spring(response: 1.0, dampingFraction: 0.8)) {
                    animatedPercentage = completionPercentage
                }
            }
            
            // Labels Below Chart (Chips)
            HStack(spacing: 12) {
                if isTargetSet {
                    // Target Chip
                    VStack(spacing: 4) {
                        Text("🎯 Target")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Color(.secondaryLabel))
                        Text(formatIndianCurrency(amount: monthlyTarget))
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(Color(.label))
                            .minimumScaleFactor(0.8)
                            .lineLimit(1)
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal, 8)
                    .frame(maxWidth: .infinity)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
                    
                    // Remaining Chip
                    VStack(spacing: 4) {
                        Text("⏳ Remaining")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Color(.secondaryLabel))
                        let remaining = max(monthlyTarget - currentRevenue, 0)
                        Text(formatIndianCurrency(amount: remaining))
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(Color(.label))
                            .minimumScaleFactor(0.8)
                            .lineLimit(1)
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal, 8)
                    .frame(maxWidth: .infinity)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
                } else {
                    // No Target Chip
                    Text("No Monthly Target Set")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Color(.secondaryLabel))
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(12)
                }
            }
        }
        .padding(20)
        .background(Color(.systemBackground))
        .cornerRadius(24)
        .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 4)
    }
}

struct SalesAnalyticsHeaderView: View {
    @ObservedObject var viewModel: SalesHistoryViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            
            // Sales Progress Header
            Text("Sales Progress")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(Color(.secondaryLabel))
                .padding(.top, 22)
                .padding(.bottom, 12)
            
            // 1. Chart Card
            if viewModel.isLoading && viewModel.currentRevenue == 0 {
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color(.systemBackground))
                    .frame(height: 280)
                    .shimmering()
            } else {
                SalesDoughnutChartView(currentRevenue: viewModel.currentRevenue, monthlyTarget: viewModel.monthlyTarget)
            }
            
            // Key Metrics Header
            Text("Key Metrics")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(Color(.secondaryLabel))
                .padding(.top, 22)
                .padding(.bottom, 12)
            
            // 2. KPI Cards
            HStack(spacing: 12) {
                if viewModel.isLoading && viewModel.currentRevenue == 0 {
                    RoundedRectangle(cornerRadius: 18)
                        .fill(Color(.systemBackground))
                        .frame(height: 110)
                        .shimmering()
                    RoundedRectangle(cornerRadius: 18)
                        .fill(Color(.systemBackground))
                        .frame(height: 110)
                        .shimmering()
                } else {
                    SalesKPICardView(
                        symbol: "cube.box.fill",
                        title: "Units Sold",
                        value: "\\(viewModel.totalUnitsSold)",
                        subtitle: "Units sold this period"
                    )
                    
                    SalesKPICardView(
                        symbol: "indianrupeesign.circle.fill",
                        title: "Average Order Value",
                        value: formatIndianCurrency(amount: viewModel.averageOrderValue),
                        subtitle: "Average revenue per sale"
                    )
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
    }
}
"""
    
    new_content = base_content + new_ui
    
    # We also need to add "Sales History" header above the lazyVStack in SalesHistoryView.
    # We'll replace:
    #             } else {
    #                 ScrollView(showsIndicators: false) {
    #                     SalesAnalyticsHeaderView(viewModel: viewModel)
    #                     
    #                     LazyVStack(spacing: 12) {
    
    old_list = """            } else {
                ScrollView(showsIndicators: false) {
                    SalesAnalyticsHeaderView(viewModel: viewModel)
                    
                    LazyVStack(spacing: 12) {"""
                    
    new_list = """            } else {
                ScrollView(showsIndicators: false) {
                    SalesAnalyticsHeaderView(viewModel: viewModel)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Sales History")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(Color(.secondaryLabel))
                            .padding(.horizontal, 20)
                            .padding(.top, 6)
                        
                        LazyVStack(spacing: 12) {"""
    
    new_content = new_content.replace(old_list, new_list)
    
    with open(file_path, 'w') as f:
        f.write(new_content)
        
    print("Updated Layout successfully")

if __name__ == "__main__":
    main()
