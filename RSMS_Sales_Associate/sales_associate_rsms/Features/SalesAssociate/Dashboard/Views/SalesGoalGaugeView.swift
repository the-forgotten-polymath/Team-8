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
            
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 20)
                Circle()
                    .trim(from: 0, to: CGFloat(min(metrics.goalProgress, 1.0)))
                    .stroke(Color(hex: "C9A84C"), style: StrokeStyle(lineWidth: 20, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                
                VStack {
                    Text(String(format: "%.0f%%", metrics.goalProgress * 100))
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.primary)
                }
            }
            .frame(height: 160)
            .padding()
            
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
