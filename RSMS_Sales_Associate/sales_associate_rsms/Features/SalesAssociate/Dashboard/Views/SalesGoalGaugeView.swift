// SalesGoalGaugeView.swift
// RSMS — Sales Associate Module

import SwiftUI
import Charts

struct SalesGoalGaugeView: View {
    let metrics: AdvisorMetrics
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Daily Sales Goal")
                .font(.headline)
            
            Chart {
                SectorMark(
                    angle: .value("Sales", min(metrics.currentSales, metrics.dailyGoal)),
                    innerRadius: .ratio(0.8),
                    angularInset: 1.5
                )
                .cornerRadius(4)
                .foregroundStyle(Color(hex: "C9A84C"))
                
                if metrics.currentSales < metrics.dailyGoal {
                    SectorMark(
                        angle: .value("Remaining", metrics.dailyGoal - metrics.currentSales),
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
                        Text(String(format: "%.0f%%", metrics.goalProgress * 100))
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
                    Text("$\(metrics.currentSales, specifier: "%.2f")")
                        .font(.subheadline.bold())
                }
                Spacer()
                VStack(alignment: .trailing) {
                    Text("Target")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("$\(metrics.dailyGoal, specifier: "%.2f")")
                        .font(.subheadline.bold())
                }
            }
            .padding(.horizontal, 40)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Daily Sales Goal")
        .accessibilityValue("\(String(format: "%.0f", metrics.goalProgress * 100)) percent complete. Current sales: \(String(format: "%.0f", metrics.currentSales)) dollars. Target: \(String(format: "%.0f", metrics.dailyGoal)) dollars.")
    }
}
