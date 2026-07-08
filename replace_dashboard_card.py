import sys

def main():
    file_path = '/Users/abhistro/Desktop/Team-8/RSMS_Store_Manager/RSMS_Project/Views/DashboardView.swift'
    with open(file_path, 'r') as f:
        content = f.read()

    start_str = "    private var salesProgressChartCard: some View {"
    start_idx = content.find(start_str)
    if start_idx != -1:
        balance = 0
        end_idx = -1
        in_method = False
        for i in range(start_idx, len(content)):
            if content[i] == '{':
                balance += 1
                in_method = True
            elif content[i] == '}':
                balance -= 1
                if in_method and balance == 0:
                    end_idx = i + 1
                    break
                    
        new_method = """    private var formattedSelectedDate: String {
        if let selected = selectedDay, let sale = viewModel.chartData.first(where: { $0.dayLabel == selected }), let date = sale.date {
            let formatter = DateFormatter()
            formatter.dateFormat = "d MMMM yyyy"
            return formatter.string(from: date)
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMMM yyyy"
        return formatter.string(from: Date())
    }
    
    private var salesProgressChartCard: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Header
            VStack(alignment: .leading, spacing: 6) {
                Text("TOTAL REVENUE")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(Color(.systemGray))
                    .textCase(.uppercase)
                
                Text(headerSubtitle)
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(Color(.label))
                
                Text(formattedSelectedDate)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
            }
            .padding(.horizontal, 20)
            .padding(.top, 24)
            
            // Picker
            HStack {
                Picker("Time Range", selection: $viewModel.selectedTimeRange) {
                    ForEach(SalesTimeRange.allCases, id: \.self) { range in
                        Text(range.rawValue).tag(range)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .frame(width: 220)
                Spacer()
            }
            .padding(.horizontal, 20)
            
            // Line Chart
            VStack {
                Chart {
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
                            // Point on line
                            PointMark(
                                x: .value("Time", day.dayLabel),
                                y: .value("Sales", day.amount)
                            )
                            .foregroundStyle(Color.blue)
                            .symbolSize(80)
                            .annotation(position: .top, spacing: 8) {
                                VStack(spacing: 2) {
                                    Text(formatIndianCurrency(amount: day.amount))
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(.white)
                                    if let date = day.date {
                                        Text(DateFormatter.localizedString(from: date, dateStyle: .medium, timeStyle: .none))
                                            .font(.system(size: 10, weight: .regular))
                                            .foregroundColor(.white.opacity(0.9))
                                    }
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
                    
                    if let selected = selectedDay {
                        RuleMark(
                            x: .value("Time", selected)
                        )
                        .foregroundStyle(Color.blue.opacity(0.3))
                        .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [4]))
                    }
                }
                .chartXAxis {
                    AxisMarks { value in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [2]))
                            .foregroundStyle(Color(.systemGray5))
                        AxisValueLabel {
                            if let text = value.as(String.self) {
                                Text(text)
                                    .font(.caption2)
                                    .foregroundColor(Color(.systemGray2))
                            }
                        }
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading, values: .automatic(desiredCount: 5)) { value in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [2]))
                            .foregroundStyle(Color(.systemGray5))
                        AxisValueLabel {
                            if let doubleValue = value.as(Double.self) {
                                Text("₹\\(Int(doubleValue/1000))k")
                                    .font(.caption2)
                                    .foregroundColor(Color(.systemGray2))
                            }
                        }
                    }
                }
                .frame(height: 220)
                .padding(.horizontal, 12)
                .chartOverlay { proxy in
                    GeometryReader { geometry in
                        Rectangle().fill(.clear).contentShape(Rectangle())
                            .onTapGesture { location in
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
            .padding(.bottom, 24)
        }
        .background(Color(.systemBackground))
        .cornerRadius(24)
        .shadow(color: Color.black.opacity(0.04), radius: 15, x: 0, y: 8)
        .padding(.horizontal)
        .onTapGesture {
            selectedDay = nil
        }
    }"""
        
        content = content[:start_idx] + new_method + content[end_idx:]
        with open(file_path, 'w') as f:
            f.write(content)
        print("Updated dashboard card UI successfully.")
    else:
        print("Method not found")

if __name__ == "__main__":
    main()
