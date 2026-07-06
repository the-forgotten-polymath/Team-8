// ManagerDashboardView.swift
// RSMS — Sales Associate Module

import SwiftUI
import Charts

struct ManagerDashboardView: View {
    @EnvironmentObject var viewModel: DashboardViewModel
    
    var body: some View {
        List {
            Section(header: Text("Boutique KPI Overview")) {
                if let metrics = viewModel.storeMetrics {
                    StoreGoalGaugeView(metrics: metrics)
                        .padding(.vertical)
                    
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Conversion Rate")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("\(metrics.conversionRate, specifier: "%.1f")%")
                                .font(.title2.bold())
                                .foregroundColor(metrics.conversionRate > 10.0 ? .green : .red)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing) {
                            Text("Average Order Value")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("$\(metrics.averageOrderValue, specifier: "%.0f")")
                                .font(.title2.bold())
                        }
                    }
                    .padding(.vertical, 8)
                    
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Client Retention")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("\(metrics.clientRetentionRate, specifier: "%.1f")%")
                                .font(.headline)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing) {
                            Text("Apt. Conversion")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("\(metrics.appointmentConversion, specifier: "%.1f")%")
                                .font(.headline)
                        }
                    }
                    .padding(.vertical, 8)
                } else {
                    Text("No metrics available.")
                }
            }
            
            Section(header: HStack {
                Text("Analytics & Reports")
                Spacer()
                NavigationLink(destination: AnalyticsChartsView().environmentObject(viewModel)) {
                    Text("Deep Dive")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }) {
                HStack {
                    Image(systemName: "chart.xyaxis.line")
                        .foregroundColor(.blue)
                    Text("View Detailed Charts")
                }
            }
        }
        .listStyle(.insetGrouped)
    }
}

struct StoreGoalGaugeView: View {
    let metrics: StoreMetrics
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Boutique Conversion Goal")
                .font(.headline)
            
            Chart {
                SectorMark(
                    angle: .value("Conversion Rate", min(metrics.conversionRate, 20.0)),
                    innerRadius: .ratio(0.8),
                    angularInset: 1.5
                )
                .cornerRadius(4)
                .foregroundStyle(Color.blue)
                
                if metrics.conversionRate < 20.0 {
                    SectorMark(
                        angle: .value("Remaining", 20.0 - metrics.conversionRate),
                        innerRadius: .ratio(0.8),
                        angularInset: 1.5
                    )
                    .cornerRadius(4)
                    .foregroundStyle(Color.gray.opacity(0.2))
                }
            }
            .frame(height: 200)
            .chartBackground { chartProxy in
                GeometryReader { geometry in
                    let frame = geometry[chartProxy.plotFrame!]
                    VStack {
                        Text(String(format: "%.1f%%", metrics.conversionRate))
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.primary)
                    }
                    .position(x: frame.midX, y: frame.midY)
                }
            }
            
            HStack {
                VStack(alignment: .leading) {
                    Text("Current")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(metrics.conversionRate, specifier: "%.1f")%")
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
            .padding(.horizontal, 40)
        }
    }
}
