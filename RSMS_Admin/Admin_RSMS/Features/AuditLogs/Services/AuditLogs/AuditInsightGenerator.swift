//
//  AuditInsightGenerator.swift
//  RSMS_Project
//
//  Implements the "Audit Insight (Foundation Model)" block from the flow doc:
//  the rules engine (AuditRulesEngine) decides WHICH stores need attention
//  and WHY — this file only turns that already-decided, structured data into
//  a human-readable executive sentence. The model never makes decisions; it
//  never sees raw table rows, only the small structured summary below.
//
//  Uses Apple's on-device FoundationModels framework (new in iOS 26 / the
//  "Apple Intelligence" on-device LLM). Guarded with `#if canImport` +
//  `#available` so the file still builds against SDKs/targets that don't
//  have it, and falls back to a deterministic, template-built sentence when
//  the model is unavailable (Simulator without Apple Intelligence, an
//  unsupported device, or the feature disabled in Settings).
//

import Foundation

#if canImport(FoundationModels)
import FoundationModels
#endif

actor AuditInsightGenerator {

    static let shared = AuditInsightGenerator()

    /// Builds the "AI Audit Insight" sentence shown at the top of the screen.
    func generateExecutiveSummary(from snapshots: [StorePerformanceSnapshot]) async -> String {
        let atRisk = snapshots.filter { !$0.isHealthy }
        guard !atRisk.isEmpty else {
            return "All stores are currently performing within target across sales, inventory, and fulfillment metrics."
        }

        let structuredInput = Self.buildStructuredSummary(atRisk: atRisk)
        let instructions = """
        You are writing an executive constructive audit feedback summary for a Corporate Admin. \
        Provide detailed, constructive feedback based on the store performance data. \
        Highlight issues (sales deficits, exceptions, delays) in a constructive, \
        professional manner, and give clear, positive guidance on what area needs improvement. \
        Do not invent numbers. Keep it under 50 words total.
        """

        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            if let generated = await Self.runFoundationModel(structuredInput: structuredInput, instructions: instructions) {
                return generated
            }
        }
        #endif

        // Fallback: deterministic, still reads naturally, never blocks the UI.
        return Self.fallbackSummary(atRisk: atRisk)
    }

    /// Explains why a specific store requires attention.
    func generateStoreSummary(for snapshot: StorePerformanceSnapshot) async -> String {
        guard let reason = snapshot.attentionReason else {
            return "Operational Performance Feedback: \(snapshot.store.name) is currently meeting compliance standards. Continue regular monitoring to maintain target levels."
        }

        let structuredInput = "\(snapshot.store.name): \(reason.title), value \(reason.metricValue), label \(reason.metricLabel)"
        let instructions = """
        You are writing a single-sentence constructive store audit feedback for a Boutique Manager. \
        Explain constructively what specific metric requires attention and suggest a positive action. \
        Do not invent numbers. Keep it under 30 words total.
        """

        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            if let generated = await Self.runFoundationModel(structuredInput: structuredInput, instructions: instructions) {
                return generated
            }
        }
        #endif

        // Fallback
        return "Constructive Review: " + reason.description(for: snapshot.store.name)
    }

    /// Generates a report-ready summary for exported spreadsheets/PDFs.
    func generateExportSummary(snapshots: [StorePerformanceSnapshot], entries: [AuditTrailEntry]) async -> String {
        let atRisk = snapshots.filter { !$0.isHealthy }
        let structuredInput = "Stores requiring attention: \(atRisk.map(\.store.name).joined(separator: ", ")). Recent activities count: \(entries.count)."
        let instructions = """
        You are writing a concise constructive management feedback summary for exported audit logs. \
        Highlight key areas of concern and suggest constructive steps for store managers. Keep it under 40 words.
        """

        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            if let generated = await Self.runFoundationModel(structuredInput: structuredInput, instructions: instructions) {
                return generated
            }
        }
        #endif

        // Fallback
        return "Executive report summary: \(atRisk.count) stores require attention. A total of \(entries.count) audit events were analyzed this period."
    }

    // MARK: - Structured input (this is ALL the model ever sees)

    private static func buildStructuredSummary(atRisk: [StorePerformanceSnapshot]) -> String {
        // Sends only the top few most severe stores to keep the prompt small
        // and keep the model focused, matching the "London Flagship" example
        // in the flow doc.
        let top = atRisk.sorted { ($0.attentionReason?.priority ?? 99) < ($1.attentionReason?.priority ?? 99) }.prefix(4)

        var lines: [String] = []
        for snap in top {
            var parts: [String] = ["\(snap.store.name):"]
            if let pct = snap.salesAchievementPct {
                parts.append("Sales Achievement \(Int(pct.rounded()))%")
            }
            parts.append("Inventory Exceptions \(snap.inventoryExceptionsOpenCount)")
            parts.append("Shipment Discrepancies \(snap.shipmentDiscrepancyCount)")
            if let acc = snap.cycleCountAccuracyPct {
                parts.append("Cycle Count Accuracy \(Int(acc.rounded()))%")
            }
            lines.append(parts.joined(separator: ", "))
        }
        return lines.joined(separator: "\n")
    }

    // MARK: - On-device model call

    #if canImport(FoundationModels)
    @available(iOS 26.0, *)
    private static func runFoundationModel(structuredInput: String, instructions: String) async -> String? {
        let model = SystemLanguageModel.default
        guard model.availability == .available else { return nil }

        do {
            let session = LanguageModelSession(instructions: instructions)
            let response = try await session.respond(to: structuredInput)
            let text = response.content.trimmingCharacters(in: .whitespacesAndNewlines)
            return text.isEmpty ? nil : text
        } catch {
            print("[AuditInsightGenerator] Foundation Model call failed, using fallback: \(error)")
            return nil
        }
    }
    #endif

    // MARK: - Fallback (no on-device model available)

    private static func fallbackSummary(atRisk: [StorePerformanceSnapshot]) -> String {
        guard let primary = atRisk.first, let reason = primary.attentionReason else {
            return "Operational Performance Feedback: All stores are currently performing within healthy parameters. Maintain standard processes to preserve current levels."
        }

        var sentence = "Operational Review & Feedback: \(primary.store.name) "
        switch reason {
        case .salesBelowTarget(let pct):
            sentence += "needs to implement local promotional efforts to address a sales gap, currently performing at \(Int(pct.rounded()))% of monthly revenue target."
        case .inventoryAccuracyIssue(let count):
            sentence += "should execute a focused count audit to resolve \(count) open inventory discrepancies and stabilize stock accuracy."
        case .fulfillmentDelays(let count):
            sentence += "requires matching pending ASN shipments to clear \(count) fulfillment exceptions currently impacting the supply pipeline."
        case .operationalDelays(let count):
            sentence += "must schedule completion of \(count) overdue store-to-store stock transfers to prevent stockouts."
        }

        if atRisk.count > 1 {
            sentence += " Additionally, \(atRisk.count - 1) other location\(atRisk.count - 1 == 1 ? "" : "s") need minor operational guidance to resolve compliance gaps."
        } else {
            sentence += " All other network locations are operating within target parameters."
        }
        return sentence
    }
}
