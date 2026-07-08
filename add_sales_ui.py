import sys

def main():
    file_path = '/Users/abhistro/Desktop/Team-8/RSMS_Store_Manager/RSMS_Project/Views/SalesHistoryView.swift'
    with open(file_path, 'r') as f:
        content = f.read()

    new_ui = """// MARK: - Analytics Header UI

struct SalesKPICardView: View {
    let symbol: String
    let title: String
    let value: String
    let subtitle: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: symbol)
                .font(.system(size: 24))
                .foregroundColor(.blue)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Color(.secondaryLabel))
                Text(value)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(Color(.label))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Text(subtitle)
                    .font(.system(size: 11))
                    .foregroundColor(Color(.tertiaryLabel))
                    .lineLimit(2)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .cornerRadius(18)
        .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 4)
    }
}

struct SalesDoughnutChartView: View {
    let currentRevenue: Double
    let monthlyTarget: Double
    @State private var isExpanded = false
    
    var completionPercentage: Double {
        if monthlyTarget == 0 { return 100.0 }
        return min((currentRevenue / monthlyTarget) * 100, 100.0)
    }
    
    var body: some View {
        VStack(spacing: 24) {
            ZStack {
                // Background Track
                Circle()
                    .stroke(Color(.systemGray5), lineWidth: 20)
                
                // Progress
                Circle()
                    .trim(from: 0, to: CGFloat(completionPercentage / 100.0))
                    .stroke(Color.blue, style: StrokeStyle(lineWidth: 20, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 0.6, dampingFraction: 0.7), value: completionPercentage)
                
                // Center text
                VStack(spacing: 4) {
                    Text("Current Revenue")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color(.secondaryLabel))
                    Text(formatIndianCurrency(amount: currentRevenue))
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(Color(.label))
                    
                    HStack(spacing: 4) {
                        Text(String(format: "%.0f%%", completionPercentage))
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(monthlyTarget > 0 ? .blue : .green)
                        Text("of Target")
                            .font(.system(size: 12))
                            .foregroundColor(Color(.secondaryLabel))
                    }
                }
            }
            .frame(width: 220, height: 220)
            .scaleEffect(isExpanded ? 1.05 : 1.0)
            .onTapGesture {
                withAnimation(.spring()) {
                    isExpanded.toggle()
                }
            }
            
            // Labels Below Chart
            HStack(spacing: 32) {
                VStack(spacing: 4) {
                    Text("Target")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Color(.secondaryLabel))
                    Text(formatIndianCurrency(amount: monthlyTarget))
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(Color(.label))
                }
                
                VStack(spacing: 4) {
                    Text("Remaining")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Color(.secondaryLabel))
                    let remaining = max(monthlyTarget - currentRevenue, 0)
                    Text(formatIndianCurrency(amount: remaining))
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(Color(.label))
                }
            }
            
            if isExpanded {
                HStack(spacing: 24) {
                    Label(formatIndianCurrency(amount: currentRevenue), systemImage: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.blue)
                    
                    Label(formatIndianCurrency(amount: max(monthlyTarget - currentRevenue, 0)), systemImage: "flag.fill")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Color(.systemGray2))
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(24)
        .background(Color(.systemBackground))
        .cornerRadius(24)
        .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 4)
    }
}

struct SalesAnalyticsHeaderView: View {
    @ObservedObject var viewModel: SalesHistoryViewModel
    
    var body: some View {
        VStack(spacing: 16) {
            // 1. Chart Card
            if viewModel.monthlyTarget > 0 || viewModel.currentRevenue > 0 {
                SalesDoughnutChartView(currentRevenue: viewModel.currentRevenue, monthlyTarget: viewModel.monthlyTarget)
            } else if viewModel.isLoading {
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color(.systemBackground))
                    .frame(height: 340)
                    .shimmering()
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "target")
                        .font(.system(size: 40))
                        .foregroundColor(.orange)
                    Text("No Target Set")
                        .font(.system(size: 18, weight: .bold))
                    Text("Set a monthly revenue target to track your progress.")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(32)
                .frame(maxWidth: .infinity)
                .background(Color(.systemBackground))
                .cornerRadius(24)
                .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 4)
            }
            
            // 2. KPI Cards
            HStack(spacing: 16) {
                if viewModel.isLoading {
                    RoundedRectangle(cornerRadius: 18)
                        .fill(Color(.systemBackground))
                        .frame(height: 120)
                        .shimmering()
                    RoundedRectangle(cornerRadius: 18)
                        .fill(Color(.systemBackground))
                        .frame(height: 120)
                        .shimmering()
                } else {
                    SalesKPICardView(
                        symbol: "cube.box.fill",
                        title: "Units Sold",
                        value: "\\(viewModel.totalUnitsSold)",
                        subtitle: "Products sold in selected period"
                    )
                    
                    SalesKPICardView(
                        symbol: "indianrupeesign.circle.fill",
                        title: "Average Order Value",
                        value: formatIndianCurrency(amount: viewModel.averageOrderValue),
                        subtitle: "Average per invoice"
                    )
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 8)
    }
}
"""
    
    # insert new views at the end of the file
    content += "\n" + new_ui
    
    # inject the header view into SalesHistoryView
    old_list = """                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.sales) {"""
                        
    new_list = """                ScrollView(showsIndicators: false) {
                    SalesAnalyticsHeaderView(viewModel: viewModel)
                    
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.sales) {"""
    
    content = content.replace(old_list, new_list)
    
    with open(file_path, 'w') as f:
        f.write(content)

    print("Added UI elements")

if __name__ == "__main__":
    main()
