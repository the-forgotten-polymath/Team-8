// ManagerDashboardView.swift
// RSMS — Sales Associate Module

import SwiftUI
import Charts

enum TimeFrame: String, CaseIterable {
    case week = "Week"
    case month = "Month"
}

struct ManagerDashboardView: View {
    @EnvironmentObject var viewModel: DashboardViewModel
    @State private var timeFrame: TimeFrame = .week
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                
                // Analytics Navigation
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Analytics & Reports")
                            .font(.headline)
                        Spacer()
                        NavigationLink(destination: AnalyticsChartsView().environmentObject(viewModel)) {
                            HStack(spacing: 4) {
                                Image(systemName: "chart.xyaxis.line")
                                Text("View Insight")
                            }
                            .font(.subheadline)
                            .foregroundColor(.blue)
                        }
                    }
                    .padding(.horizontal, 4)
                }
                
                // Boutique Performance Analytics Header
                HStack {
                    Text("Boutique Performance")
                        .font(.headline)
                    Spacer()
                    Picker("TimeFrame", selection: $timeFrame.animation(.easeInOut)) {
                        ForEach(TimeFrame.allCases, id: \.self) { frame in
                            Text(frame.rawValue).tag(frame)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 140)
                }
                .padding(.horizontal, 4)
                
                // KPI Metrics Grid
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    KPICard(title: "Today's Sales", value: formatCurrency(viewModel.todayRevenue), systemImage: "indianrupeesign.circle.fill", color: .green)
                    KPICard(title: "Today's Orders", value: "\(viewModel.todayOrdersCount)", systemImage: "cart.fill", color: .blue)
                }
                .padding(.horizontal, 4)
                
                // Revenue Analytics Chart
                RevenueChartView(
                    data: timeFrame == .week ? viewModel.weeklyChartData : viewModel.monthlyChartData,
                    title: timeFrame == .week ? "Weekly Revenue Trend" : "Monthly Revenue Trend"
                )
                .padding(.horizontal, 4)
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
    }
    
    private func formatCurrency(_ value: Double) -> String {
        if value >= 1_000_000 {
            return String(format: "₹%.1fM", value / 1_000_000.0)
        } else if value >= 1_000 {
            return String(format: "₹%.0fK", value / 1_000.0)
        } else {
            return String(format: "₹%.0f", value)
        }
    }
}

struct KPICard: View {
    let title: String
    let value: String
    let systemImage: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.12))
                    .frame(width: 36, height: 36)
                Image(systemName: systemImage)
                    .foregroundColor(color)
                    .font(.system(size: 14, weight: .semibold))
            }
            
            VStack(alignment: .leading, spacing: 2) {
                if !title.isEmpty {
                    Text(title)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.secondary)
                    Text(value)
                        .font(.subheadline.bold())
                        .foregroundColor(.primary)
                } else {
                    Text(value)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.primary)
                }
            }
            Spacer()
        }
        .padding(12)
        .whiteCard()
    }
}

struct RevenueChartView: View {
    let data: [RevenueDataPoint]
    let title: String
    
    @State private var selectedPoint: RevenueDataPoint? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            Text(title)
                .font(.subheadline.bold())
                .foregroundColor(.secondary)
            
            // Selection overlay showing Sales & Order counts
            if let selected = selectedPoint {
                VStack(alignment: .leading, spacing: 6) {
                    Text(selected.label)
                        .font(.caption.bold())
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 16) {
                        VStack(alignment: .leading) {
                            Text("Revenue")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Text(formatCurrency(selected.amount))
                                .font(.subheadline.bold())
                                .foregroundColor(.primary)
                        }
                    }
                    
                    if let comparison = calculateComparison(for: selected) {
                        HStack(spacing: 4) {
                            Image(systemName: comparison.isIncrease ? "arrow.up.right" : "arrow.down.right")
                            Text("\(comparison.isIncrease ? "Increased" : "Decreased") by \(comparison.diffAmountString) (\(comparison.percentageString))")
                        }
                        .font(.caption.bold())
                        .foregroundColor(comparison.isIncrease ? .green : .red)
                        .padding(.top, 4)
                    }
                }
                .padding(12)
                .background(Color(.secondarySystemGroupedBackground))
                .cornerRadius(10)
                .transition(.opacity.combined(with: .move(edge: .top)))
            } else {
                Text("Tap on any chart point to inspect details.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Curve Line Chart
            Chart(data) { point in
                // Shaded region under the curve
                AreaMark(
                    x: .value("Date", point.label),
                    y: .value("Revenue", point.amount)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.blue.opacity(0.25), Color.blue.opacity(0.0)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .interpolationMethod(.monotone)
                
                // Curve line
                LineMark(
                    x: .value("Date", point.label),
                    y: .value("Revenue", point.amount)
                )
                .foregroundStyle(Color.blue)
                .lineStyle(StrokeStyle(lineWidth: 2.5))
                .interpolationMethod(.monotone)
                
                // Point markers
                PointMark(
                    x: .value("Date", point.label),
                    y: .value("Revenue", point.amount)
                )
                .foregroundStyle(Color.blue)
                .symbol {
                    let isToday = isPointToday(point)
                    Circle()
                        .fill(isToday ? Color.green : (selectedPoint?.id == point.id ? Color.blue : Color.white))
                        .frame(width: isToday ? 10 : 8, height: isToday ? 10 : 8)
                        .overlay(
                            Circle()
                                .stroke(isToday ? Color.green : Color.blue, lineWidth: 2)
                        )
                }
            }
            .frame(height: 180)
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisTick()
                    AxisValueLabel {
                        if let doubleValue = value.as(Double.self) {
                            Text(formatCurrencyYAxis(doubleValue))
                                .font(.caption2)
                        }
                    }
                }
            }
            .chartOverlay { proxy in
                GeometryReader { geometry in
                    Rectangle()
                        .fill(Color.clear)
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    let origin = geometry[proxy.plotFrame!].origin
                                    let location = CGPoint(
                                        x: value.location.x - origin.x,
                                        y: value.location.y - origin.y
                                    )
                                    if let label: String = proxy.value(atX: location.x) {
                                        if let point = data.first(where: { $0.label == label }) {
                                            if selectedPoint?.id != point.id {
                                                let generator = UIImpactFeedbackGenerator(style: .light)
                                                generator.impactOccurred()
                                                withAnimation(.spring()) {
                                                    selectedPoint = point
                                                }
                                            }
                                        }
                                    }
                                }
                        )
                }
            }
        }
        .padding()
        .liquidGlass()
    }
    
    private func isPointToday(_ point: RevenueDataPoint) -> Bool {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE" // "Mon", "Tue", etc.
        let todayLabel = formatter.string(from: Date())
        return point.label.lowercased() == todayLabel.lowercased()
    }
    
    private func calculateComparison(for point: RevenueDataPoint) -> ComparisonResult? {
        guard let index = data.firstIndex(where: { $0.id == point.id }) else {
            return nil
        }
        if index == 0 {
            return nil
        }
        let prevPoint = data[index - 1]
        
        let diff = point.amount - prevPoint.amount
        let isIncrease = diff >= 0
        
        let percent: Double
        if prevPoint.amount == 0 {
            percent = point.amount > 0 ? 100.0 : 0.0
        } else {
            percent = (abs(diff) / prevPoint.amount) * 100.0
        }
        
        let percentageString = String(format: "%.1f%%", percent)
        let diffAmountString = formatCurrency(abs(diff))
        
        return ComparisonResult(percentageString: percentageString, diffAmountString: diffAmountString, isIncrease: isIncrease)
    }
    
    private func formatCurrencyYAxis(_ value: Double) -> String {
        if value == 0 { return "0" }
        return String(format: "%.1fE6", value / 1_000_000.0)
    }
    
    private func formatCurrency(_ value: Double) -> String {
        if value >= 1_000_000 {
            return String(format: "₹%.1fM", value / 1_000_000.0)
        } else if value >= 1_000 {
            return String(format: "₹%.0fK", value / 1_000.0)
        } else {
            return String(format: "₹%.0f", value)
        }
    }
}

struct ComparisonResult {
    let percentageString: String
    let diffAmountString: String
    let isIncrease: Bool
}
