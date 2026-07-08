import sys

def main():
    file_path = '/Users/abhistro/Desktop/Team-8/RSMS_Store_Manager/RSMS_Project/Views/SalesHistoryView.swift'
    with open(file_path, 'r') as f:
        content = f.read()

    # We want to replace the whole SalesDoughnutChartView struct to avoid parsing mistakes
    old_struct_start = "struct SalesDoughnutChartView: View {"
    old_struct_end = "struct SalesAnalyticsHeaderView: View {"
    
    parts = content.split(old_struct_start)
    if len(parts) < 2:
        print("Could not find SalesDoughnutChartView")
        return
        
    before_struct = parts[0]
    rest = parts[1]
    
    sub_parts = rest.split(old_struct_end)
    after_struct = old_struct_end + sub_parts[1]
    
    new_struct = """struct SalesDoughnutChartView: View {
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
        VStack(spacing: 24) {
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
            
            // Native Info List
            if isTargetSet {
                VStack(spacing: 12) {
                    Divider()
                    
                    HStack {
                        Text("Target")
                            .font(.system(size: 15))
                            .foregroundColor(Color(.secondaryLabel))
                        Spacer()
                        Text(formatIndianCurrency(amount: monthlyTarget))
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(Color(.label))
                    }
                    
                    Divider()
                    
                    HStack {
                        Text("Remaining")
                            .font(.system(size: 15))
                            .foregroundColor(Color(.secondaryLabel))
                        Spacer()
                        let remaining = max(monthlyTarget - currentRevenue, 0)
                        Text(formatIndianCurrency(amount: remaining))
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(Color(.label))
                    }
                }
                .padding(.top, 4)
                .padding(.horizontal, 4)
            } else {
                VStack(spacing: 12) {
                    Divider()
                    Text("No Monthly Target Set")
                        .font(.system(size: 15))
                        .foregroundColor(Color(.secondaryLabel))
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                .padding(.top, 4)
            }
        }
        .padding(24)
        .background(Color(.systemBackground))
        .cornerRadius(24)
        .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 4)
    }
}

"""

    content = before_struct + new_struct + after_struct

    with open(file_path, 'w') as f:
        f.write(content)
        
    print("Replaced SalesDoughnutChartView successfully")

if __name__ == "__main__":
    main()
