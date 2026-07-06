//
//  HealthScoreService.swift
//  RSMS_Project
//

import Foundation
import Supabase

final class HealthScoreService {

    private let client = SupabaseManager.shared.client

    /// Latest health score per store. Supabase has no native "latest per
    /// group" select, so we fetch recent rows ordered by generated_at and
    /// reduce client-side — fine at this table size, revisit with a SQL
    /// view if it grows.
    func fetchLatestPerStore() async throws -> [HealthScore] {
        let scores: [HealthScore] = try await client
            .from("health_scores")
            .select()
            .order("generated_at", ascending: false)
            .limit(200)
            .execute()
            .value

        var latestByStore: [UUID: HealthScore] = [:]
        for score in scores where latestByStore[score.storeId] == nil {
            latestByStore[score.storeId] = score
        }
        return Array(latestByStore.values).sorted { $0.overallScore < $1.overallScore }
    }

    /// Compliance trend for the whole network, averaged per day — backs
    /// the "Compliance trend" chart. Uses overall_score (see HealthScore
    /// .complianceScore alias) since there's no separate compliance_score
    /// column. `days` is driven by the filter bar's TimePeriodFilter.
    func fetchComplianceTrend(days: Int = 7) async throws -> [(date: Date, score: Double)] {
        guard let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: Date()) else {
            return []
        }
        let scores: [HealthScore] = try await client
            .from("health_scores")
            .select()
            .gte("generated_at", value: ISO8601DateFormatter().string(from: cutoff))
            .order("generated_at", ascending: true)
            .execute()
            .value

        let grouped = Dictionary(grouping: scores) { Calendar.current.startOfDay(for: $0.generatedAt) }
        return grouped
            .map { day, entries in
                (date: day, score: entries.map(\.complianceScore).reduce(0, +) / Double(entries.count))
            }
            .sorted { $0.date < $1.date }
    }

    /// Compliance trend for a single store — backs the Inspector's mini
    /// trend chart. Same shape as fetchComplianceTrend, just scoped to
    /// one store_id and not averaged (one row per snapshot).
    func fetchTrend(storeId: UUID, days: Int) async throws -> [(date: Date, score: Double)] {
        guard let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: Date()) else {
            return []
        }
        let scores: [HealthScore] = try await client
            .from("health_scores")
            .select()
            .eq("store_id", value: storeId)
            .gte("generated_at", value: ISO8601DateFormatter().string(from: cutoff))
            .order("generated_at", ascending: true)
            .execute()
            .value

        return scores.map { (date: $0.generatedAt, score: $0.complianceScore) }
    }
}
