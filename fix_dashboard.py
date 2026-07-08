import sys

def main():
    file_path = '/Users/abhistro/Desktop/Team-8/RSMS_Store_Manager/RSMS_Project/Views/DashboardView.swift'
    with open(file_path, 'r') as f:
        content = f.read()

    # The file is mangled around line 446
    # Let's find the start of salesProgressChartCard and replace up to the Bar Chart
    
    start_str = "    private var salesProgressChartCard: some View {"
    end_str = "            // Bar Chart"
    
    if start_str in content and end_str in content:
        start_idx = content.find(start_str)
        end_idx = content.find(end_str)
        
        new_header = """    private var salesProgressChartCard: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Header
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top) {
                    NavigationLink(destination: SalesHistoryView()) {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 6) {
                                Image(systemName: "chart.bar.xaxis")
                                    .foregroundColor(Color(.label))
                                Text(selectedDay != nil ? "SALES (\\(selectedDay!.uppercased()))" : "SALES")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(Color(.label))
                                    .textCase(.uppercase)
                                    .animation(.easeInOut, value: selectedDay)
                                Image(systemName: "chevron.right")
                                    .font(.footnote).fontWeight(.bold)
                                    .foregroundColor(Color(.label))
                            }
                            
                            Text(headerSubtitle)
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(selectedDay != nil ? .blue : Color(.label))
                                .animation(.easeInOut, value: selectedDay)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Spacer()
                    
                    Picker("Time Range", selection: $viewModel.selectedTimeRange) {
                        ForEach(SalesTimeRange.allCases, id: \\.self) { range in
                            Text(range.rawValue).tag(range)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .frame(width: 180)
                }
            }
            
"""
        content = content[:start_idx] + new_header + content[end_idx:]
        
        with open(file_path, 'w') as f:
            f.write(content)
        print("Fixed DashboardView.swift successfully.")
    else:
        print("Could not find start or end string.")

if __name__ == "__main__":
    main()
