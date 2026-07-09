// Extensions.swift
// RSMS — Sales Associate Module
// Common Swift extensions used throughout the app

import Foundation
import SwiftUI

// MARK: - Date Extensions

extension Date {
    /// Formatted as "Jan 10, 2026"
    var displayDate: String {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .none
        return f.string(from: self)
    }

    /// Formatted as "10 Jan 2026 at 3:30 PM"
    var displayDateTime: String {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f.string(from: self)
    }

    /// Relative: "2 days ago", "in 3 hours"
    var relative: String {
        let f = RelativeDateTimeFormatter()
        f.unitsStyle = .short
        return f.localizedString(for: self, relativeTo: Date())
    }

    /// "Monday, January 10"
    var fullWeekdayAndDate: String {
        let f = DateFormatter()
        f.dateFormat = "EEEE, MMMM d"
        return f.string(from: self)
    }

    /// "3:30 PM"
    var timeOnly: String {
        let f = DateFormatter()
        f.timeStyle = .short
        f.dateStyle = .none
        return f.string(from: self)
    }

    /// Days from today (positive = future, negative = past)
    var daysFromToday: Int {
        Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: Date()),
                                        to: Calendar.current.startOfDay(for: self)).day ?? 0
    }

    var isToday: Bool { Calendar.current.isDateInToday(self) }
    var isTomorrow: Bool { Calendar.current.isDateInTomorrow(self) }
    var isPast: Bool { self < Date() }
    var isFuture: Bool { self > Date() }

    /// Days until a future date (for anniversary/birthday countdowns)
    func daysUntil(next anniversary: Date) -> Int {
        var components = Calendar.current.dateComponents([.month, .day], from: anniversary)
        let year = Calendar.current.component(.year, from: Date())
        components.year = year
        guard var nextDate = Calendar.current.date(from: components) else { return 0 }
        if nextDate < Date() {
            components.year = year + 1
            nextDate = Calendar.current.date(from: components) ?? nextDate
        }
        return Calendar.current.dateComponents([.day], from: Date(), to: nextDate).day ?? 0
    }
}

// MARK: - Decimal Extensions

extension Decimal {
    var formatted: String {
        let n = NSDecimalNumber(decimal: self)
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = AppConstants.App.currencyCode
        f.currencySymbol = AppConstants.App.currencySymbol
        f.maximumFractionDigits = 0
        f.usesGroupingSeparator = true
        return f.string(from: n) ?? "₹0"
    }

    var shortFormatted: String {
        if self >= 10_000_000 { return "₹\(NSDecimalNumber(decimal: self / 10_000_000).rounding(accordingToBehavior: nil))Cr" }
        if self >= 100_000   { return "₹\(NSDecimalNumber(decimal: self / 100_000).rounding(accordingToBehavior: nil))L" }
        if self >= 1_000     { return "₹\(NSDecimalNumber(decimal: self / 1_000).rounding(accordingToBehavior: nil))K" }
        return formatted
    }
}

// MARK: - String Extensions

extension String {
    var isValidEmail: Bool {
        let regex = #"^[A-Za-z0-9._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}$"#
        return range(of: regex, options: .regularExpression) != nil
    }

    var isValidPhone: Bool {
        let digits = filter { $0.isNumber }
        return digits.count >= 10
    }

    var initials: String {
        split(separator: " ")
            .prefix(2)
            .compactMap { $0.first.map { String($0) } }
            .joined()
            .uppercased()
    }
}

// MARK: - View Extensions

extension View {
    /// Apply a gold shimmer effect for loading states
    func shimmer(isActive: Bool) -> some View {
        self.overlay(
            isActive ?
            LinearGradient(
                colors: [.clear, Color(hex: "C9A84C").opacity(0.15), .clear],
                startPoint: .leading,
                endPoint: .trailing
            )
            .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: false), value: isActive)
            : nil
        )
    }

    /// Dismiss keyboard on tap
    func hideKeyboard() -> some View {
        self.onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                            to: nil, from: nil, for: nil)
        }
    }
    
    /// Apply an iOS 26 inspired glassmorphism effect
    func liquidGlass(cornerRadius: CGFloat = 16) -> some View {
        self.modifier(LiquidGlassModifier(cornerRadius: cornerRadius))
    }
    
    /// Apply a clean solid white card styling with a subtle border and shadow
    func whiteCard(cornerRadius: CGFloat = 16) -> some View {
        self
            .background(Color.white)
            .cornerRadius(cornerRadius)
            .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 4)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(Color.black.opacity(0.04), lineWidth: 1)
            )
    }
}

struct LiquidGlassModifier: ViewModifier {
    var cornerRadius: CGFloat
    
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.ultraThinMaterial)
            )
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(Color.white.opacity(0.05))
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [Color.white.opacity(0.5), Color.white.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.5
                    )
            )
            .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
    }
}

// MARK: - UUID Extensions

extension UUID {
    static var placeholder: UUID { UUID(uuidString: "00000000-0000-0000-0000-000000000000")! }
}

// MARK: - Color Extensions

#if canImport(UIKit)
import UIKit
#endif

extension Color {
    static let appleSecondaryBackground = Color(UIColor { traitCollection in
        return traitCollection.userInterfaceStyle == .dark
            ? UIColor.systemGray6
            : UIColor(red: 247/255, green: 248/255, blue: 250/255, alpha: 1.0)
    })
    
    static let appleBorder = Color(UIColor { traitCollection in
        return traitCollection.userInterfaceStyle == .dark
            ? UIColor.separator
            : UIColor(red: 229/255, green: 231/255, blue: 235/255, alpha: 1.0)
    })
}

