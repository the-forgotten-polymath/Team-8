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
                
                // KPI Overview
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("Boutique KPI Overview")
                            .font(.headline)
                        Spacer()
                        Picker("TimeFrame", selection: $timeFrame) {
                            ForEach(TimeFrame.allCases, id: \.self) { frame in
                                Text(frame.rawValue).tag(frame)
                            }
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 140)
                    }
                    .padding(.horizontal, 4)
                    
                    if let metrics = viewModel.storeMetrics {
                        VStack(spacing: 16) {
                            StoreGoalGaugeView(metrics: metrics, timeFrame: timeFrame)
                                .padding(.vertical)
                            
                            Divider()
                            
                            HStack {
                                VStack(alignment: .leading) {
                                    Text("Conversion Rate")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text("\(metrics.conversionRate, specifier: "%.1f")%")
                                        .font(.title3.bold())
                                        .foregroundColor(metrics.conversionRate > 10.0 ? .green : .red)
                                }
                                
                                Spacer()
                                
                                VStack(alignment: .trailing) {
                                    Text("Average Order Value")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text("$\(metrics.averageOrderValue, specifier: "%.0f")")
                                        .font(.title3.bold())
                                }
                            }
                            
                            HStack {
                                VStack(alignment: .leading) {
                                    Text("Client Retention")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text("\(metrics.clientRetentionRate, specifier: "%.1f")%")
                                        .font(.subheadline.bold())
                                }
                                
                                Spacer()
                                
                                VStack(alignment: .trailing) {
                                    Text("Apt. Conversion")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text("\(metrics.appointmentConversion, specifier: "%.1f")%")
                                        .font(.subheadline.bold())
                                }
                            }
                        }
                        .padding()
                        .liquidGlass()
                    } else {
                        Text("No metrics available.")
                            .foregroundColor(.secondary)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .center)
                            .liquidGlass()
                    }
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
    }
}

struct StoreGoalGaugeView: View {
    let metrics: StoreMetrics
    let timeFrame: TimeFrame
    
    // Compute displayed conversion rate based on timeframe mock data
    private var displayConversionRate: Double {
        return timeFrame == .week ? metrics.conversionRate : metrics.conversionRate * 0.85
    }
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Boutique Conversion Goal")
                .font(.subheadline.bold())
                .foregroundColor(.secondary)
            
            Chart {
                SectorMark(
                    angle: .value("Conversion Rate", min(displayConversionRate, 20.0)),
                    innerRadius: .ratio(0.8),
                    angularInset: 1.5
                )
                .cornerRadius(4)
                .foregroundStyle(Color.blue)
                
                if displayConversionRate < 20.0 {
                    SectorMark(
                        angle: .value("Remaining", 20.0 - displayConversionRate),
                        innerRadius: .ratio(0.8),
                        angularInset: 1.5
                    )
                    .cornerRadius(4)
                    .foregroundStyle(Color.gray.opacity(0.2))
                }
            }
            .frame(height: 180)
            .chartBackground { chartProxy in
                GeometryReader { geometry in
                    if let anchor = chartProxy.plotFrame {
                        let frame = geometry[anchor]
                        VStack {
                            Text(String(format: "%.1f%%", displayConversionRate))
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(.primary)
                        }
                        .position(x: frame.midX, y: frame.midY)
                    }
                }
            }
            
            HStack {
                VStack(alignment: .leading) {
                    Text("Current")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(displayConversionRate, specifier: "%.1f")%")
                        .font(.subheadline.bold())
                }
                Spacer()
                VStack(alignment: .trailing) {
                    Text("Target")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("20.0%")
                        .font(.subheadline.bold())
                }
            }
            .padding(.horizontal, 20)
        }
    }
}
