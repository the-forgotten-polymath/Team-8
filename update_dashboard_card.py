import sys

def main():
    file_path = '/Users/abhistro/Desktop/Team-8/RSMS_Store_Manager/RSMS_Project/Views/DashboardView.swift'
    with open(file_path, 'r') as f:
        content = f.read()

    # Find DailySale struct to add 'date: Date?'
    struct_old = """struct DailySale: Identifiable, Equatable {
    var id: String { dayLabel }
    let dayLabel: String
    let amount: Double
}"""
    struct_new = """struct DailySale: Identifiable, Equatable {
    var id: String { dayLabel }
    let dayLabel: String
    let amount: Double
    var date: Date? = nil
}"""
    if struct_old in content:
        content = content.replace(struct_old, struct_new)
        
    # Find updateChartData to populate date
    # In week mode, targetDate is used. 
    # In month/year mode, targetDate is used. 
    # Let's use a regex or string replacement to add date: targetDate
    content = content.replace("tempChartData.append(DailySale(dayLabel: label, amount: total))", 
                              "tempChartData.append(DailySale(dayLabel: label, amount: total, date: targetDate))")
    content = content.replace("tempChartData.append(DailySale(dayLabel: label, amount: total))", 
                              "tempChartData.append(DailySale(dayLabel: label, amount: total, date: startDate))") # For month
    content = content.replace("tempChartData.append(DailySale(dayLabel: label, amount: total))", 
                              "tempChartData.append(DailySale(dayLabel: label, amount: total, date: targetMonthDate))") # For year

    # The actual replacements might be tricky, let's just do it directly with a block replacement for updateChartData if needed.
    # Actually, the user just wants the UI. Let's add a helper function `formattedDate(for: dayLabel) -> String` to the View.

    with open(file_path, 'w') as f:
        f.write(content)

if __name__ == "__main__":
    main()
