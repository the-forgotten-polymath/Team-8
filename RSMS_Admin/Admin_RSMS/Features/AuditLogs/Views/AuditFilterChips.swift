//
//  AuditFilterChips.swift
//  RSMS_Project
//
//  Audit Focus Areas - horizontal chips for filtering activity feed
//

import SwiftUI

struct AuditFilterChips: View {
    @Binding var selected: AuditModuleFilter

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Audit Focus Areas")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.auditLabel2)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(AuditModuleFilter.allCases) { filter in
                        chip(for: filter)
                    }
                }
                .padding(.horizontal, 1) // Prevent edge clipping
            }
        }
    }

    private func chip(for filter: AuditModuleFilter) -> some View {
        let isSelected = selected == filter
        let tint = filter.accentColor
        
        return Button {
            withAnimation(.spring(response: 0.32, dampingFraction: 0.85)) {
                selected = filter
            }
        } label: {
            Text(filter.rawValue)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(isSelected ? tint : .auditLabel)
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
        }
        .glassChip(isSelected: isSelected, tint: tint)
    }
}

#Preview {
    VStack(alignment: .leading, spacing: 16) {
        AuditFilterChips(selected: .constant(.all))
            .padding()
    }
    .background(Color.auditPageBG)
}
