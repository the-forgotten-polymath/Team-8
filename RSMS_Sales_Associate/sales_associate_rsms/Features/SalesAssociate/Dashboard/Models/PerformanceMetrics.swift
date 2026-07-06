// PerformanceMetrics.swift
// RSMS — Sales Associate Module

import Foundation

struct AdvisorMetrics: Codable {
    var id: UUID
    var dailyGoal: Double
    var currentSales: Double
    var followUpsDue: Int
    var followUpsCompleted: Int
    
    var goalProgress: Double {
        if dailyGoal == 0 { return 0 }
        return currentSales / dailyGoal
    }
}

struct StoreMetrics: Codable {
    var storeID: UUID
    var conversionRate: Double // e.g., 12.5 for 12.5%
    var averageOrderValue: Double
    var clientRetentionRate: Double
    var appointmentConversion: Double
    var endlessAisleCaptureRate: Double
    
    // Additional chart data structure
    var dailyConversionHistory: [DailyMetric]
}

struct DailyMetric: Codable, Identifiable {
    var id = UUID()
    let date: Date
    let value: Double
}
