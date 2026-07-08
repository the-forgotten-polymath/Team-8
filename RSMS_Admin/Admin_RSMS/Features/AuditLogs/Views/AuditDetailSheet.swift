//
//  AuditDetailSheet.swift
//  RSMS_Project
//
//  "Tap Behaviour" from the flow doc — shows Module / Action / ASN /
//  Status / Timestamp for the tapped audit trail entry.
//

import SwiftUI

struct AuditDetailSheet: View {
    let entry: AuditTrailEntry
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    HStack(spacing: 14) {
                        ZStack {
                            Circle().fill(entry.tint.opacity(0.16)).frame(width: 56, height: 56)
                            Image(systemName: entry.icon)
                                .font(.system(size: 22, weight: .semibold))
                                .foregroundColor(entry.tint)
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            Text(entry.title)
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.auditLabel)
                            Text(entry.storeName)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.auditLabel2)
                        }
                        Spacer()
                    }

                    VStack(spacing: 0) {
                        ForEach(Array(entry.detailFields.enumerated()), id: \.element.id) { index, field in
                            HStack {
                                Text(field.label)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.auditLabel2)
                                Spacer()
                                Text(field.value)
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.auditLabel)
                                    .multilineTextAlignment(.trailing)
                            }
                            .padding(.vertical, 14)

                            if index < entry.detailFields.count - 1 {
                                Divider().overlay(Color.auditSeparator)
                            }
                        }
                    }
                    .padding(.horizontal, AuditDS.cardPad)
                    .glassCard()
                }
                .padding(AuditDS.pagePad)
            }
            .background(Color.auditPageBG.ignoresSafeArea())
            .navigationTitle("Audit Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
        }
    }
}

#Preview {
    AuditDetailSheet(entry: AuditTrailEntry(
        id: UUID(), module: .shipments, title: "Shipment Verified",
        subtitle: "ASN-DC-810574 • Fully Verified", storeName: "Dubai Mall",
        timestamp: Date(), icon: "checkmark.seal.fill", tint: .auditGreen, statusDotColor: .auditGreen,
        detailFields: [
            .init("Module", "Shipment Verification"),
            .init("Action", "Verified Shipment"),
            .init("ASN", "ASN-DC-810574"),
            .init("Status", "Fully Verified"),
            .init("Timestamp", "09:04 AM")
        ]
    ))
}
