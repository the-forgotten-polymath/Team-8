//
//  GlassChipRow.swift
//  Admin_RSMS
//
//  Created by Yatharth Mishra on 04/07/26.
//


//
//  LiquidGlass.swift
//  Admin_RSMS
//
//  Small set of reusable helpers around iOS 26's Liquid Glass material
//  (`glassEffect`, `GlassEffectContainer`, `.glass` / `.glassProminent`
//  button styles). Centralised here so every screen — not just Audit
//  Logs — can opt into the same look with one modifier.
//
//  Requires iOS 26+ (already the project's minimum deployment target,
//  see SRS §2.3 Technical Specifications).
//

import SwiftUI

extension View {

    /// Wraps the view in a rounded Liquid Glass surface.
    /// Use for cards, headers, filter bars — anything that used to be a
    /// flat `.background(Color(...))` card.
    func glassCard(cornerRadius: CGFloat = 20, tint: Color? = nil) -> some View {
        self
            .padding()
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .shadow(color: .black.opacity(0.08), radius: 16, x: 0, y: 6)
    }

    func glassChip(tint: Color? = nil, isInteractive: Bool = true) -> some View {
        self
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(.regularMaterial, in: Capsule(style: .continuous))
    }
}

struct GlassChipRow<Content: View>: View {
    private let content: () -> Content

    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    var body: some View {
        HStack(spacing: 8) {
            content()
        }
    }
}

enum RSMSGlassButtonStyle {
    static func prominent() -> some PrimitiveButtonStyle { .borderedProminent }
    static func standard() -> some PrimitiveButtonStyle { .bordered }
}