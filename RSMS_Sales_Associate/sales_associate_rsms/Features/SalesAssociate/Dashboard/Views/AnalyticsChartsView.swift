// AnalyticsChartsView.swift
// RSMS — Sales Associate Module

import SwiftUI
import Charts

struct AnalyticsChartsView: View {
    @EnvironmentObject var viewModel: DashboardViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                if let metrics = viewModel.storeMetrics {
                    
                    VStack(alignment: .leading) {
                        Text("7-Day Conversion Trend")
                            .font(.headline)
                        
                        Chart(metrics.dailyConversionHistory) { item in
                            LineMark(
                                x: .value("Date", item.date, unit: .day),
                                y: .value("Conversion (%)", item.value)
                            )
                            .symbol(Circle())
                            .interpolationMethod(.catmullRom)
                            
                            AreaMark(
                                x: .value("Date", item.date, unit: .day),
                                y: .value("Conversion (%)", item.value)
                            )
                            .foregroundStyle(LinearGradient(
                                colors: [Color.blue.opacity(0.3), Color.blue.opacity(0.0)],
                                startPoint: .top,
                                endPoint: .bottom
                            ))
                        }
                        .frame(height: 250)
                    }
                    .padding()
                    .background(Color(uiColor: .secondarySystemGroupedBackground))
                    .cornerRadius(12)
                    
                    // Export Button
                    ShareLink(item: generateCSV(metrics: metrics), subject: Text("Analytics Report"), message: Text("Here is the latest boutique performance report.")) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                            Text("Export Report to CSV")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(hex: "C9A84C"))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    
                } else {
                    Text("No metrics data to visualize.")
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical)
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle("Analytics")
    }
    
    private func generateCSV(metrics: StoreMetrics) -> String {
        var csv = "Metric,Value\n"
        csv += "Conversion Rate,\(metrics.conversionRate)%\n"
        csv += "Average Order Value,$\(metrics.averageOrderValue)\n"
        csv += "Client Retention,\(metrics.clientRetentionRate)%\n"
        csv += "Appointment Conversion,\(metrics.appointmentConversion)%\n"
        csv += "Endless Aisle Capture,\(metrics.endlessAisleCaptureRate)%\n"
        
        csv += "\nDate,Daily Conversion\n"
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        for daily in metrics.dailyConversionHistory {
            csv += "\(formatter.string(from: daily.date)),\(String(format: "%.1f", daily.value))%\n"
        }
        return csv
    }
}
