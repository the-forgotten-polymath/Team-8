//
//  AuditInsightCard.swift
//  RSMS_Project
//
//  Hero component for AI Audit Insight
//  Full-width card with explanation text, no raw metrics
//

import SwiftUI

struct AuditInsightCard: View {
    let summary: String
    let isGenerating: Bool
    let onViewAnalysis: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 20) {
            // Large icon on left
            ZStack {
                Circle()
                    .fill(Color.auditTeal.opacity(0.12))
                    .frame(width: 64, height: 64)
                Image(systemName: "sparkles")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundColor(Color.auditTeal)
                    .symbolEffect(.pulse, isActive: isGenerating)
            }

            // Insight text center-left
            VStack(alignment: .leading, spacing: 8) {
                Text("AI AUDIT INSIGHT")
                    .font(.system(size: 11, weight: .bold))
                    .tracking(1.2)
                    .foregroundColor(Color.auditTeal)

                if isGenerating {
                    Text("Analyzing store performance across the network…")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.auditLabel)
                        .redacted(reason: .placeholder)
                } else {
                    Text(summary)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.auditLabel)
                        .fixedSize(horizontal: false, vertical: true)
                        .lineSpacing(2)
                        .transition(.opacity)
                }
            }

            Spacer()

            // Chevron CTA on right
            Button(action: onViewAnalysis) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color.auditTeal)
                    .frame(width: 32, height: 32)
            }
        }
        .padding(AuditDS.cardPad)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(minHeight: 160)
        .glassCard()
        .overlay(
            RoundedRectangle(cornerRadius: AuditDS.cardRadius, style: .continuous)
                .strokeBorder(Color.auditTeal.opacity(0.15), lineWidth: 1.5)
        )
        .animation(.easeInOut(duration: 0.3), value: isGenerating)
    }
}

#Preview {
    VStack(spacing: 24) {
        AuditInsightCard(
            summary: "Shop Royal is currently performing below target achievement levels. Inventory and fulfillment indicators remain stable, suggesting the primary issue is sales performance rather than operational execution.",
            isGenerating: false,
            onViewAnalysis: {}
        )
        AuditInsightCard(
            summary: "",
            isGenerating: true,
            onViewAnalysis: {}
        )
    }
    .padding()
    .background(Color.pageBG)
}
