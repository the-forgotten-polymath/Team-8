import re
import sys

def main():
    file_path = '/Users/abhistro/Desktop/Team-8/RSMS_Store_Manager/RSMS_Project/Views/DashboardView.swift'
    try:
        with open(file_path, 'r') as f:
            content = f.read()
    except Exception as e:
        print(f"Error reading {file_path}: {e}")
        return

    # 1. Models update
    old_models = """// MARK: - Models

struct DailySale: Identifiable, Equatable {"""
    new_models = """// MARK: - Models

enum SalesTimeRange: String, CaseIterable {
    case week = "Week"
    case month = "Month"
    case year = "Year"
}

struct DailySale: Identifiable, Equatable {"""
    content = content.replace(old_models, new_models)

    # 2. ViewModel properties
    old_vm_props = """    @Published var chartData: [DailySale] = []
    @Published var upcomingTasks: [Task] = []"""
    new_vm_props = """    @Published var chartData: [DailySale] = []
    
    @Published var selectedTimeRange: SalesTimeRange = .week {
        didSet { updateChartData() }
    }
    @Published var transactions: Int = 0
    @Published var averageSaleValue: Double = 0.0
    @Published var unitsSold: Int = 0
    private var allSales: [Sale] = []
    private var allSaleItems: [SaleItem] = []
    
    @Published var upcomingTasks: [Task] = []"""
    content = content.replace(old_vm_props, new_vm_props)

    # 3. Modify fetch logic
    old_fetch_start = "            // 2. Fetch Sales from last 7 days"
    old_fetch_end = "            self.todaySalesAmount = tempChartData.last?.amount ?? 0.0"
    
    if old_fetch_start in content and old_fetch_end in content:
        start_idx = content.find(old_fetch_start)
        end_idx = content.find(old_fetch_end) + len(old_fetch_end)
        
        new_fetch = """            // 2. Fetch Sales for the current year
            let calendar = Calendar.current
            let oneYearAgo = calendar.date(byAdding: .year, value: -1, to: calendar.startOfDay(for: Date())) ?? Date()
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            let dateString = formatter.string(from: oneYearAgo)
            
            let salesResponse = try await client
                .from("sales")
                .select()
                .eq("store_id", value: storeId.uuidString)
                .gte("sale_date", value: dateString)
                .execute()
            self.allSales = try JSONDecoder.supabaseDecoder.decodeSupabase([Sale].self, from: salesResponse.data)
            
            if !self.allSales.isEmpty {
                if let itemsResponse = try? await client.from("sale_items").select().execute() {
                    self.allSaleItems = (try? JSONDecoder.supabaseDecoder.decodeSupabase([SaleItem].self, from: itemsResponse.data)) ?? []
                }
            }
            
            updateChartData()"""
        
        content = content[:start_idx] + new_fetch + content[end_idx:]

    # 4. Add updateChartData method
    old_func_end = """        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }"""
    new_func_end = old_func_end + """
    
    func updateChartData() {
        let calendar = Calendar.current
        var tempChartData: [DailySale] = []
        var filteredSales: [Sale] = []
        let today = calendar.startOfDay(for: Date())
        
        switch selectedTimeRange {
        case .week:
            let weekdaySymbols = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
            for i in 0..<7 {
                let targetDate = calendar.date(byAdding: .day, value: -6 + i, to: today) ?? Date()
                let weekdayIndex = calendar.component(.weekday, from: targetDate) - 1
                let label = weekdaySymbols[weekdayIndex]
                
                let daySales = allSales.filter { calendar.isDate($0.saleDate, inSameDayAs: targetDate) }
                let total = daySales.reduce(0.0) { $0 + $1.totalAmount }
                tempChartData.append(DailySale(dayLabel: label, amount: total))
                filteredSales.append(contentsOf: daySales)
            }
        case .month:
            // Group by 4 weeks (last 28 days)
            for i in 0..<4 {
                let startDate = calendar.date(byAdding: .day, value: -28 + (i * 7), to: today) ?? Date()
                let endDate = calendar.date(byAdding: .day, value: 7, to: startDate) ?? Date()
                let label = "W\(i+1)"
                
                let weekSales = allSales.filter { $0.saleDate >= startDate && $0.saleDate < endDate }
                let total = weekSales.reduce(0.0) { $0 + $1.totalAmount }
                tempChartData.append(DailySale(dayLabel: label, amount: total))
                filteredSales.append(contentsOf: weekSales)
            }
        case .year:
            let monthSymbols = calendar.shortMonthSymbols
            for i in 0..<12 {
                let targetMonthDate = calendar.date(byAdding: .month, value: -11 + i, to: today) ?? Date()
                let monthIndex = calendar.component(.month, from: targetMonthDate) - 1
                let label = monthSymbols[monthIndex]
                
                let monthSales = allSales.filter { 
                    calendar.component(.month, from: $0.saleDate) == monthIndex + 1 &&
                    calendar.component(.year, from: $0.saleDate) == calendar.component(.year, from: targetMonthDate)
                }
                let total = monthSales.reduce(0.0) { $0 + $1.totalAmount }
                tempChartData.append(DailySale(dayLabel: label, amount: total))
                filteredSales.append(contentsOf: monthSales)
            }
        }
        
        self.chartData = tempChartData
        self.todaySalesAmount = tempChartData.last?.amount ?? 0.0
        
        // Update stats
        self.transactions = filteredSales.count
        let totalRevenue = filteredSales.reduce(0.0) { $0 + $1.totalAmount }
        self.averageSaleValue = self.transactions > 0 ? totalRevenue / Double(self.transactions) : 0.0
        
        let filteredSaleIds = Set(filteredSales.map { $0.id })
        let relevantItems = allSaleItems.filter { filteredSaleIds.contains($0.saleId ?? UUID()) }
        self.unitsSold = relevantItems.reduce(0) { $0 + $1.quantity }
    }"""
    content = content.replace(old_func_end, new_func_end)

    # 5. UI Updates to salesProgressChartCard
    old_ui_header = """            // Header
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Image(systemName: "chart.bar.xaxis")"""
    new_ui_header = """            // Header
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Image(systemName: "chart.bar.xaxis")"""
    # Wait, the picker should be on the top right
    old_spacer = """                        .animation(.easeInOut, value: selectedDay)
                }
                
                Spacer()
            }"""
    new_spacer = """                        .animation(.easeInOut, value: selectedDay)
                }
                
                Spacer()
                
                Picker("Time Range", selection: $viewModel.selectedTimeRange) {
                    ForEach(SalesTimeRange.allCases, id: \\.self) { range in
                        Text(range.rawValue).tag(range)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .frame(width: 180)
            }"""
    content = content.replace(old_spacer, new_spacer)
    
    # Add stats below the chart
    old_end_chart = """                }
                .frame(maxWidth: .infinity, alignment: .center)
            }"""
    new_end_chart = """                }
                .frame(maxWidth: .infinity, alignment: .center)
            }
            
            Divider().padding(.vertical, 8)
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Transactions")
                        .font(.caption).foregroundColor(Color(.secondaryLabel))
                    Text("\\(viewModel.transactions)")
                        .font(.headline).fontWeight(.bold)
                }
                Spacer()
                VStack(alignment: .leading, spacing: 4) {
                    Text("Avg Sale Value")
                        .font(.caption).foregroundColor(Color(.secondaryLabel))
                    Text(formatIndianCurrency(amount: viewModel.averageSaleValue))
                        .font(.headline).fontWeight(.bold)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Units Sold")
                        .font(.caption).foregroundColor(Color(.secondaryLabel))
                    Text("\\(viewModel.unitsSold)")
                        .font(.headline).fontWeight(.bold)
                }
            }"""
    content = content.replace(old_end_chart, new_end_chart)

    with open(file_path, 'w') as f:
        f.write(content)
    print("Updated DashboardView.swift successfully.")

if __name__ == "__main__":
    main()
