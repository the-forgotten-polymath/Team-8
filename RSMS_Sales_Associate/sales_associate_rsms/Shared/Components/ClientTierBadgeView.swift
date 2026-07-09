// ClientTierBadgeView.swift
// RSMS — Sales Associate Module

import SwiftUI

struct ClientTierBadgeView: View {
    let tier: CustomerTier
    
    var body: some View {
        Text(tier.displayName.uppercased())
            .font(.caption2)
            .fontWeight(.bold)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(tierColor.opacity(0.15))
            .foregroundColor(tierColor)
            .clipShape(Capsule())
    }
    
    private var tierColor: Color {
        switch tier {
        case .regular:
            return .gray
        case .standard:
            return .blue
        case .vip:
            return .purple
        }
    }
}

#Preview {
    HStack {
        ClientTierBadgeView(tier: .regular)
        ClientTierBadgeView(tier: .standard)
        ClientTierBadgeView(tier: .vip)
    }
    .padding()
}
