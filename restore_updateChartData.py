import sys

def main():
    file_path = '/Users/abhistro/Desktop/Team-8/RSMS_Store_Manager/RSMS_Project/Views/DashboardView.swift'
    with open(file_path, 'r') as f:
        content = f.read()

    # I will insert updateChartData right before the end of the DashboardViewModel class.
    # The end of DashboardViewModel is around line 245
    old_end = """        isLoading = false
    }
}"""
    
    new_method = """        isLoading = false
    }
    
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
                let label = "W\\(i+1)"
                
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
        let relevantItems = allSaleItems.filter { filteredSaleIds.contains($0.saleId) }
        self.unitsSold = relevantItems.reduce(0) { $0 + $1.quantity }
    }
}"""
    
    if old_end in content:
        content = content.replace(old_end, new_method)
        with open(file_path, 'w') as f:
            f.write(content)
        print("updateChartData restored.")
    else:
        print("Error: could not find insertion point.")

if __name__ == "__main__":
    main()
