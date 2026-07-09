import sys

def main():
    file_path = '/Users/abhistro/Desktop/Team-8/RSMS_Store_Manager/RSMS_Project/Views/DashboardView.swift'
    with open(file_path, 'r') as f:
        content = f.read()

    # 1. Add import Charts
    if "import Charts" not in content:
        content = content.replace("import Supabase", "import Supabase\nimport Charts")
        
    # 2. Replace Bar Chart section
    start_marker = "            // Bar Chart"
    end_marker = "            Divider().padding(.vertical, 8)"
    
    if start_marker in content and end_marker in content:
        start_idx = content.find(start_marker)
        end_idx = content.find(end_marker)
        
        new_chart = """            // Bar Chart
            VStack {
                Chart {
                    ForEach(viewModel.chartData) { day in
                        BarMark(
                            x: .value("Time", day.dayLabel),
                            y: .value("Sales", day.amount)
                        )
                        .foregroundStyle(
                            (selectedDay == day.dayLabel || (selectedDay == nil && day.dayLabel == currentDayString && viewModel.selectedTimeRange == .week))
                            ? Color.blue.gradient
                            : Color.blue.opacity(0.3).gradient
                        )
                        .cornerRadius(6)
                    }
                }
                .chartXAxis {
                    AxisMarks { value in
                        AxisValueLabel {
                            if let text = value.as(String.self) {
                                Text(text)
                                    .font(.caption2)
                                    .fontWeight(selectedDay == text || (selectedDay == nil && text == currentDayString && viewModel.selectedTimeRange == .week) ? .bold : .regular)
                                    .foregroundColor(selectedDay == text || (selectedDay == nil && text == currentDayString && viewModel.selectedTimeRange == .week) ? .blue : Color(.secondaryLabel))
                            }
                        }
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .trailing, values: .automatic(desiredCount: 5)) { value in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4]))
                        AxisValueLabel {
                            if let doubleValue = value.as(Double.self) {
                                Text(formatK(doubleValue))
                                    .font(.caption2)
                                    .foregroundColor(Color(.secondaryLabel))
                            }
                        }
                    }
                }
                .frame(height: 220)
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
            .padding(.top, 16)
            .padding(.bottom, 8)
            
"""
        content = content[:start_idx] + new_chart + content[end_idx:]
        
        with open(file_path, 'w') as f:
            f.write(content)
        print("Updated DashboardView.swift with Native Chart successfully.")
    else:
        print("Error: Could not find markers.")

if __name__ == "__main__":
    main()
