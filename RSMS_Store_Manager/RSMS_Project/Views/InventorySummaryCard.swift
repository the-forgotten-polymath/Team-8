//
//  InventorySummaryCard.swift
//  RSMS_Project
//
//  Created by Antigravity on 02/07/26.
//

import SwiftUI

struct ShimmerModifier: ViewModifier {
    @State private var isAnimating = false
    
    func body(content: Content) -> some View {
        content
            .opacity(isAnimating ? 0.3 : 1.0)
            .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: isAnimating)
            .onAppear {
                isAnimating = true
            }
    }
}

extension View {
    func shimmering() -> some View {
        modifier(ShimmerModifier())
    }
}

struct InventorySummaryCard: View {
    let summary: InventorySummary?
    let isLoading: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            VStack(alignment: .leading, spacing: 4) {
                Text("TOTAL INVENTORY VALUE")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(Color(.secondaryLabel))
                    .tracking(1.1)
                
                if isLoading {
                    // Skeleton for value
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(.systemGray5))
                        .frame(width: 200, height: 32)
                        .shimmering()
                } else {
                    Text(formatIndianCurrency(amount: summary?.totalValue ?? 0))
                        .font(.system(size: 28, weight: .bold, design: .default))
                        .foregroundColor(Color(.label))
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                }
            }
            
            // Thin divider
            Divider()
                .background(Color(.separator).opacity(0.4))
            
            // Statistics columns
            HStack(spacing: 0) {
                // Total Products
                statColumn(
                    value: isLoading ? nil : formatIndianNumber(count: summary?.totalProducts ?? 0),
                    label: "Total Products"
                )
                
                Spacer()
                
                // Total Units
                statColumn(
                    value: isLoading ? nil : formatIndianNumber(count: summary?.totalUnits ?? 0),
                    label: "Total Units"
                )
                
                Spacer()
                
                // Avg. Value
                statColumn(
                    value: isLoading ? nil : formatIndianCurrency(amount: summary?.avgValue ?? 0),
                    label: "Avg. Value"
                )
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.secondarySystemGroupedBackground))
                .shadow(color: Color.black.opacity(0.04), radius: 12, x: 0, y: 6)
        )
    }
    
    @ViewBuilder
    private func statColumn(value: String?, label: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            if let value = value {
                Text(value)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(Color(.label))
            } else {
                // Skeleton
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(.systemGray5))
                    .frame(width: 55, height: 20)
                    .shimmering()
            }
            
            Text(label)
                .font(.system(size: 12, weight: .regular))
                .foregroundColor(Color(.secondaryLabel))
        }
    }
    
    private func formatIndianCurrency(amount: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "en_IN")
        formatter.currencySymbol = "₹"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: amount as NSDecimalNumber) ?? "₹0"
    }
    
    private func formatIndianNumber(count: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = Locale(identifier: "en_IN")
        return formatter.string(from: NSNumber(value: count)) ?? "0"
    }
}
