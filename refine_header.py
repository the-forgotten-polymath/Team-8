import sys

def main():
    file_path = '/Users/abhistro/Desktop/Team-8/RSMS_Store_Manager/RSMS_Project/Views/DashboardView.swift'
    with open(file_path, 'r') as f:
        content = f.read()

    # 1. First, we need to create the headerRevenueView
    headerRevenueView_code = """    @ViewBuilder
    private var headerRevenueView: some View {
        if let day = selectedDay, let sale = viewModel.chartData.first(where: { $0.dayLabel == day }) {
            Text(formatIndianCurrency(amount: sale.amount))
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(Color(.label))
        } else {
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(formatIndianCurrency(amount: viewModel.todaySalesAmount))
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(Color(.label))
                
                Text("/ " + formatIndianCurrency(amount: viewModel.salesGoal))
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color(.secondaryLabel))
            }
        }
    }
    
    private var salesProgressChartCard: some View {"""
    content = content.replace("    private var salesProgressChartCard: some View {", headerRevenueView_code)
    
    # 2. Modify the Header part inside salesProgressChartCard
    old_header = """                    // Header
                    VStack(alignment: .leading, spacing: 4) {
                        Text("TOTAL REVENUE")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(Color(.systemGray))
                            .textCase(.uppercase)
                        
                        Text(headerSubtitle)
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(Color(.label))
                            .animation(.spring(), value: viewModel.todaySalesAmount)
                        
                        if let trend = viewModel.revenueTrend {
                            let isPositive = trend >= 0
                            let trendText = String(format: "%.1f%%", abs(trend))
                            let periodText = viewModel.selectedTimeRange == .week ? "last week" : (viewModel.selectedTimeRange == .month ? "last month" : "last year")
                            
                            Text("\\(isPositive ? "↑" : "↓") \\(trendText) vs \\(periodText)")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(isPositive ? .green : .red)
                                .padding(.top, 2)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    
                    // Date & Picker Row
                    HStack(alignment: .center) {
                        Picker("Time Range", selection: $viewModel.selectedTimeRange) {
                            ForEach(SalesTimeRange.allCases, id: \\.self) { range in
                                Text(range.rawValue).tag(range)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 8)"""
                    
    new_header = """                    // Header & Picker
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("TOTAL REVENUE")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(Color(.systemGray))
                                .textCase(.uppercase)
                            
                            headerRevenueView
                                .animation(.spring(), value: viewModel.todaySalesAmount)
                            
                            if let trend = viewModel.revenueTrend {
                                let isPositive = trend >= 0
                                let trendText = String(format: "%.1f%%", abs(trend))
                                let periodText = viewModel.selectedTimeRange == .week ? "last week" : (viewModel.selectedTimeRange == .month ? "last month" : "last year")
                                
                                Text("\\(isPositive ? "↑" : "↓") \\(trendText) vs \\(periodText)")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(isPositive ? .green : .red)
                                    .padding(.top, 2)
                            }
                        }
                        
                        Spacer()
                        
                        Picker("Time Range", selection: $viewModel.selectedTimeRange) {
                            ForEach([SalesTimeRange.week, SalesTimeRange.month], id: \\.self) { range in
                                Text(range.rawValue).tag(range)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .frame(width: 140)
                        .padding(.top, 16)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 8)"""
    
    content = content.replace(old_header, new_header)
    
    with open(file_path, 'w') as f:
        f.write(content)
        
    print("Done")

if __name__ == "__main__":
    main()
