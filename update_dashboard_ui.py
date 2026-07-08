import sys

def main():
    file_path = '/Users/abhistro/Desktop/Team-8/RSMS_Store_Manager/RSMS_Project/Views/DashboardView.swift'
    with open(file_path, 'r') as f:
        content = f.read()

    # 1. Add revenueTrend to DashboardViewModel
    if "var revenueTrend: Double?" not in content:
        content = content.replace("@Published var chartData: [DailySale] = []", "@Published var chartData: [DailySale] = []\n    @Published var revenueTrend: Double? = nil")
        
    # 2. Update updateChartData to calculate trend
    # Replace the end of updateChartData
    end_of_update_chart = """        self.todaySalesAmount = tempChartData.last?.amount ?? 0.0
        
        // Update stats
        self.transactions = filteredSales.count
        let totalRevenue = filteredSales.reduce(0.0) { $0 + $1.totalAmount }
        self.averageSaleValue = self.transactions > 0 ? totalRevenue / Double(self.transactions) : 0.0
        
        let filteredSaleIds = Set(filteredSales.map { $0.id })
        let relevantItems = allSaleItems.filter { filteredSaleIds.contains($0.saleId) }
        self.unitsSold = relevantItems.reduce(0) { $0 + $1.quantity }"""
        
    new_end_of_update_chart = """        self.todaySalesAmount = tempChartData.last?.amount ?? 0.0
        
        // Update stats
        self.transactions = filteredSales.count
        let totalRevenue = filteredSales.reduce(0.0) { $0 + $1.totalAmount }
        self.averageSaleValue = self.transactions > 0 ? totalRevenue / Double(self.transactions) : 0.0
        
        let filteredSaleIds = Set(filteredSales.map { $0.id })
        let relevantItems = allSaleItems.filter { filteredSaleIds.contains($0.saleId) }
        self.unitsSold = relevantItems.reduce(0) { $0 + $1.quantity }
        
        // Calculate Trend
        var previousRevenue = 0.0
        switch selectedTimeRange {
        case .week:
            let lastWeekStart = calendar.date(byAdding: .day, value: -13, to: today) ?? Date()
            let lastWeekEnd = calendar.date(byAdding: .day, value: -7, to: today) ?? Date()
            previousRevenue = allSales.filter { $0.saleDate >= lastWeekStart && $0.saleDate <= lastWeekEnd }.reduce(0.0) { $0 + $1.totalAmount }
        case .month:
            let lastMonthStart = calendar.date(byAdding: .day, value: -56, to: today) ?? Date()
            let lastMonthEnd = calendar.date(byAdding: .day, value: -28, to: today) ?? Date()
            previousRevenue = allSales.filter { $0.saleDate >= lastMonthStart && $0.saleDate < lastMonthEnd }.reduce(0.0) { $0 + $1.totalAmount }
        case .year:
            let lastYearStart = calendar.date(byAdding: .month, value: -23, to: today) ?? Date()
            let lastYearEnd = calendar.date(byAdding: .month, value: -11, to: today) ?? Date()
            previousRevenue = allSales.filter { $0.saleDate >= lastYearStart && $0.saleDate < lastYearEnd }.reduce(0.0) { $0 + $1.totalAmount }
        }
        
        if previousRevenue > 0 {
            self.revenueTrend = ((totalRevenue - previousRevenue) / previousRevenue) * 100.0
        } else if previousRevenue == 0 && totalRevenue > 0 {
            self.revenueTrend = 100.0 // 100% increase if previous was 0 and now we have sales
        } else {
            self.revenueTrend = nil
        }"""
        
    if end_of_update_chart in content:
        content = content.replace(end_of_update_chart, new_end_of_update_chart)

    # 3. Replace salesProgressChartCard
    start_str = "    private var formattedSelectedDate: String {"
    start_idx = content.find(start_str)
    
    end_str = "    private var salesProgressChartCard: some View {"
    end_idx_search = content.find(end_str)
    
    if start_idx != -1 and end_idx_search != -1:
        balance = 0
        end_idx = -1
        in_method = False
        for i in range(end_idx_search, len(content)):
            if content[i] == '{':
                balance += 1
                in_method = True
            elif content[i] == '}':
                balance -= 1
                if in_method and balance == 0:
                    end_idx = i + 1
                    break

        new_ui = """    private var formattedSelectedDate: String {
        if let selected = selectedDay, let sale = viewModel.chartData.first(where: { $0.dayLabel == selected }), let date = sale.date {
            let formatter = DateFormatter()
            formatter.dateFormat = "d MMM yyyy"
            let dateString = formatter.string(from: date)
            return Calendar.current.isDateInToday(date) ? "Today • \\(dateString)" : dateString
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM yyyy"
        return "Today • \\(formatter.string(from: Date()))"
    }
    
    private var isChartEmpty: Bool {
        viewModel.chartData.isEmpty || viewModel.chartData.allSatisfy { $0.amount == 0 }
    }
    
    private var salesProgressChartCard: some View {
        Button(action: {
            // Navigate to SalesHistoryView (we can use a NavigationLink around this or programmatically)
            // But since NavigationLink is better, we'll wrap the inner content in a NavigationLink below
        }) {
            NavigationLink(destination: SalesHistoryView()) {
                VStack(alignment: .leading, spacing: 16) {
                    // Header
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
                            ForEach(SalesTimeRange.allCases, id: \.self) { range in
                                Text(range.rawValue).tag(range)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 8)
                    
                    // Line Chart
                    ZStack {
                        if isChartEmpty {
                            VStack {
                                Spacer()
                                Text("No sales recorded for this period.")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Spacer()
                            }
                            .frame(height: 150)
                        }
                        
                        Chart {
                            if !isChartEmpty {
                                ForEach(viewModel.chartData) { day in
                                    LineMark(
                                        x: .value("Time", day.dayLabel),
                                        y: .value("Sales", day.amount)
                                    )
                                    .foregroundStyle(Color.blue)
                                    .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                                    .interpolationMethod(.catmullRom)
                                    
                                    AreaMark(
                                        x: .value("Time", day.dayLabel),
                                        y: .value("Sales", day.amount)
                                    )
                                    .foregroundStyle(
                                        LinearGradient(
                                            gradient: Gradient(colors: [Color.blue.opacity(0.15), Color.blue.opacity(0.0)]),
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                                    .interpolationMethod(.catmullRom)
                                    
                                    if let selected = selectedDay, day.dayLabel == selected {
                                        PointMark(
                                            x: .value("Time", day.dayLabel),
                                            y: .value("Sales", day.amount)
                                        )
                                        .foregroundStyle(Color.blue)
                                        .symbolSize(80)
                                        .annotation(position: .top, spacing: 8) {
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(day.dayLabel)
                                                    .font(.system(size: 10, weight: .regular))
                                                    .foregroundColor(.white.opacity(0.9))
                                                Text("Revenue")
                                                    .font(.system(size: 8, weight: .regular))
                                                    .foregroundColor(.white.opacity(0.7))
                                                Text(formatIndianCurrency(amount: day.amount))
                                                    .font(.system(size: 14, weight: .bold))
                                                    .foregroundColor(.white)
                                            }
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 6)
                                            .background(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .fill(Color.blue)
                                            )
                                            .shadow(radius: 3, y: 2)
                                        }
                                    }
                                }
                            }
                            
                            // Horizontal target line (only if not empty)
                            if viewModel.salesGoal > 0 && !isChartEmpty {
                                RuleMark(
                                    y: .value("Target", viewModel.salesGoal)
                                )
                                .foregroundStyle(Color.green.opacity(0.5))
                                .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [4, 4]))
                                .annotation(position: .top, alignment: .leading) {
                                    Text("TARGET")
                                        .font(.system(size: 8, weight: .bold))
                                        .foregroundColor(.green)
                                        .padding(.leading, 4)
                                }
                            }
                            
                            if let selected = selectedDay, !isChartEmpty {
                                RuleMark(
                                    x: .value("Time", selected)
                                )
                                .foregroundStyle(Color.blue.opacity(0.3))
                                .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [4]))
                            }
                        }
                        .chartXAxis {
                            AxisMarks { value in
                                AxisValueLabel {
                                    if let text = value.as(String.self) {
                                        Text(text)
                                            .font(.system(size: 9))
                                            .foregroundColor(Color(.systemGray2))
                                    }
                                }
                            }
                        }
                        .chartYAxis {
                            AxisMarks(position: .leading, values: .automatic(desiredCount: 4)) { value in
                                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [2]))
                                    .foregroundStyle(Color(.systemGray5))
                                AxisValueLabel {
                                    if let doubleValue = value.as(Double.self) {
                                        Text("₹\\(Int(doubleValue/1000))k")
                                            .font(.system(size: 9))
                                            .foregroundColor(Color(.systemGray2))
                                    }
                                }
                            }
                        }
                        .frame(height: 140)
                        .padding(.horizontal, 8)
                        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: viewModel.chartData)
                        .chartOverlay { proxy in
                            GeometryReader { geometry in
                                Rectangle().fill(.clear).contentShape(Rectangle())
                                    .onTapGesture { location in
                                        if isChartEmpty { return }
                                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                        let origin = geometry[proxy.plotAreaFrame].origin
                                        let x = location.x - origin.x
                                        if let dayLabel: String = proxy.value(atX: x) {
                                            if selectedDay == dayLabel {
                                                selectedDay = nil
                                            } else {
                                                selectedDay = dayLabel
                                            }
                                        }
                                    }
                            }
                        }
                    }
                    .padding(.bottom, 20)
                }
                .background(Color(.systemBackground))
                .cornerRadius(24)
                .shadow(color: Color.black.opacity(0.04), radius: 15, x: 0, y: 8)
                .padding(.horizontal)
            }
            .buttonStyle(PlainButtonStyle())
        }
    }"""
        
        content = content[:start_idx] + new_ui + content[end_idx:]

    with open(file_path, 'w') as f:
        f.write(content)
    print("Done updating DashboardView.")

if __name__ == "__main__":
    main()
