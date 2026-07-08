import sys

def main():
    file_path = '/Users/abhistro/Desktop/Team-8/RSMS_Store_Manager/RSMS_Project/Views/DashboardView.swift'
    with open(file_path, 'r') as f:
        content = f.read()

    start_marker = "                Chart {"
    end_marker = "                .chartXAxis {"
    
    if start_marker in content and end_marker in content:
        start_idx = content.find(start_marker)
        end_idx = content.find(end_marker)
        
        new_chart = """                Chart {
                    ForEach(viewModel.chartData) { day in
                        LineMark(
                            x: .value("Time", day.dayLabel),
                            y: .value("Sales", day.amount)
                        )
                        .foregroundStyle(Color.blue.gradient)
                        .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                        .interpolationMethod(.catmullRom)
                        
                        AreaMark(
                            x: .value("Time", day.dayLabel),
                            y: .value("Sales", day.amount)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.blue.opacity(0.3), Color.blue.opacity(0.0)]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .interpolationMethod(.catmullRom)
                        
                        // Add points on the line
                        PointMark(
                            x: .value("Time", day.dayLabel),
                            y: .value("Sales", day.amount)
                        )
                        .foregroundStyle((selectedDay == day.dayLabel || (selectedDay == nil && day.dayLabel == currentDayString && viewModel.selectedTimeRange == .week)) ? Color.blue : Color.white)
                        .symbolSize((selectedDay == day.dayLabel || (selectedDay == nil && day.dayLabel == currentDayString && viewModel.selectedTimeRange == .week)) ? 100 : 50)
                    }
                    
                    if let selected = selectedDay {
                        RuleMark(
                            x: .value("Time", selected)
                        )
                        .foregroundStyle(Color.gray.opacity(0.4))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [4]))
                    }
                }
"""
        content = content[:start_idx] + new_chart + "                " + content[end_idx:]
        
        with open(file_path, 'w') as f:
            f.write(content)
        print("Updated to LineChart successfully.")
    else:
        print("Could not find markers")

if __name__ == "__main__":
    main()
