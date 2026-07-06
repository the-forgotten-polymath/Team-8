// ProductDigitalTwinMiniCardView.swift
// RSMS — Sales Associate Module

import SwiftUI

struct ProductDigitalTwinMiniCardView: View {
    let title: String
    let subtitle: String?
    let imageURL: String? // Optional image URL for future use
    let statusText: String?
    let statusColor: Color?
    
    var body: some View {
        HStack(spacing: 12) {
            // Placeholder Image
            Rectangle()
                .fill(Color.gray.opacity(0.2))
                .frame(width: 60, height: 60)
                .cornerRadius(8)
                .overlay(
                    Image(systemName: "bag.fill")
                        .foregroundColor(.gray)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            if let statusText = statusText, let statusColor = statusColor {
                Text(statusText.uppercased())
                    .font(.caption2)
                    .fontWeight(.bold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(statusColor.opacity(0.15))
                    .foregroundColor(statusColor)
                    .clipShape(Capsule())
            }
        }
        .padding(12)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

#Preview {
    VStack {
        ProductDigitalTwinMiniCardView(
            title: "Evening Gown",
            subtitle: "Purchased Feb 14, 2024",
            imageURL: nil,
            statusText: "Active",
            statusColor: .green
        )
        ProductDigitalTwinMiniCardView(
            title: "Diamond Necklace",
            subtitle: "Added Mar 1, 2024",
            imageURL: nil,
            statusText: "Out of Stock",
            statusColor: .red
        )
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
