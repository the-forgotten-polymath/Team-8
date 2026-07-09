//
//  AuditLiquidGlass.swift
//  RSMS_Project
//
//  Design tokens for the Audit Logs module ONLY.
//  Aligned with Admin Dashboard design system for consistency.
//

import SwiftUI

// MARK: - Semantic Colors (matching Dashboard)

extension Color {

    // Backgrounds - matching Dashboard
    static let auditPageBG      = Color.pageBG
    static let auditCardBG      = Color.cardBG

    // Text
    static let auditLabel       = Color.primary
    static let auditLabel2      = Color.secondary
    static let auditLabel3      = Color(uiColor: .tertiaryLabel)
    static let auditSeparator   = Color.separator

    // Accents
    static let auditBlue        = Color.blue
    static let auditGreen       = Color.green
    static let auditOrange      = Color.orange
    static let auditYellow      = Color.yellow
    static let auditRed         = Color.red
    static let auditPurple      = Color.purple
    static let auditIndigo      = Color.indigo
    static let auditTeal        = Color.teal
}

// MARK: - Spacing / Radius (matching Dashboard)

enum AuditDS {
    static let pagePad: CGFloat        = 24      // Matching Dashboard
    static let cardPad: CGFloat        = 16      // Matching Dashboard
    static let cardSpacing: CGFloat    = 24      // Matching Dashboard
    static let sectionSpacing: CGFloat = 24      // Matching Dashboard
    static let cardRadius: CGFloat     = 20      // Matching Dashboard
    static let smallRadius: CGFloat    = 12
    static let chipRadius: CGFloat     = 100
}

// MARK: - Material Hierarchy

enum AuditMaterial {
    case hero       // AI Insight card - most prominent
    case primary    // Store cards - secondary focus
    case secondary  // Chips, activity rows - tertiary
}

// MARK: - Attention severity -> color/icon mapping

enum AuditSeverity {
    case critical, warning, caution, healthy

    var color: Color {
        switch self {
        case .critical: return .auditRed
        case .warning:  return .auditOrange
        case .caution:  return .auditYellow
        case .healthy: return .auditGreen
        }
    }
}

// MARK: - Liquid Glass modifiers

struct GlassCard: ViewModifier {
    var radius: CGFloat = AuditDS.cardRadius
    var material: AuditMaterial = .primary
    var tint: Color? = nil

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(Color.auditCardBG)
            )
            .cardShadow()
    }
}

struct GlassChip: ViewModifier {
    var isSelected: Bool
    var tint: Color = .accentColor

    func body(content: Content) -> some View {
        content
            .background(
                Capsule()
                    .fill(isSelected ? tint.opacity(0.14) : Color.white.opacity(0.5))
                    .background(
                        Capsule()
                            .fill(Color.cardBG.opacity(isSelected ? 0.9 : 0.6))
                    )
            )
            .overlay(
                Capsule()
                    .strokeBorder(isSelected ? tint : Color.secondary.opacity(0.2), lineWidth: 1.5)
            )
            .shadow(color: Color.black.opacity(0.04), radius: 3, x: 0, y: 2)
    }
}

extension View {
    /// Rounded Liquid-Glass surface for cards / panels.
    func glassCard(radius: CGFloat = AuditDS.cardRadius, material: AuditMaterial = .primary, tint: Color? = nil) -> some View {
        modifier(GlassCard(radius: radius, material: material, tint: tint))
    }
    /// Pill-shaped Liquid-Glass surface for filter chips / badges.
    func glassChip(isSelected: Bool, tint: Color = .accentColor) -> some View {
        modifier(GlassChip(isSelected: isSelected, tint: tint))
    }
    func auditCardShadow() -> some View {
        self.cardShadow()
    }
}

// MARK: - Material background helper

extension AuditMaterial {
    var background: Color {
        Color.auditCardBG
    }
}
