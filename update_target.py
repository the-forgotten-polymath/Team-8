import sys

def main():
    file_path = '/Users/abhistro/Desktop/Team-8/RSMS_Store_Manager/RSMS_Project/Views/DashboardView.swift'
    with open(file_path, 'r') as f:
        content = f.read()

    # The current headerRevenueView looks like this:
    old_view = """    @ViewBuilder
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
    }"""
    
    new_view = """    @ViewBuilder
    private var headerRevenueView: some View {
        if let day = selectedDay, let sale = viewModel.chartData.first(where: { $0.dayLabel == day }) {
            Text(formatIndianCurrency(amount: sale.amount))
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(Color(.label))
        } else {
            Text(formatIndianCurrency(amount: viewModel.todaySalesAmount))
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(Color(.label))
        }
    }"""
    
    if old_view in content:
        content = content.replace(old_view, new_view)
        with open(file_path, 'w') as f:
            f.write(content)
        print("Updated")
    else:
        print("Not found")

if __name__ == "__main__":
    main()
