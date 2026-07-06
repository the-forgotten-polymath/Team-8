// ClientOverviewView.swift
// RSMS — Sales Associate Module

import SwiftUI

struct ClientOverviewView: View {
    let client: ClientDigitalTwin
    
    var body: some View {
        VStack(spacing: 24) {
            if !client.hasDataProcessingConsent {
                HStack {
                    Image(systemName: "exclamationmark.shield.fill")
                    Text("Data processing consent has been revoked or is missing. Some information is masked.")
                        .font(.caption)
                }
                .foregroundColor(.orange)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(8)
            }
            
            // Preferences Preview
            if let prefs = client.preferences, client.hasDataProcessingConsent {
                SectionCard(title: "Preferences") {
                    VStack(alignment: .leading, spacing: 12) {
                        if !prefs.preferredBrands.isEmpty {
                            PreferenceRow(title: "Brands", values: prefs.preferredBrands)
                        }
                        if !prefs.preferredCategories.isEmpty {
                            PreferenceRow(title: "Categories", values: prefs.preferredCategories.map { $0.rawValue })
                        }
                        if !prefs.preferredColors.isEmpty {
                            PreferenceRow(title: "Colors", values: prefs.preferredColors)
                        }
                        if let notes = prefs.notes {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Style Notes")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                Text(notes)
                                    .font(.subheadline)
                            }
                        }
                    }
                }
            } else if !client.hasDataProcessingConsent {
                SectionCard(title: "Preferences") {
                    Text("Hidden due to data privacy settings.")
                        .foregroundColor(.gray)
                        .font(.subheadline)
                }
            } else {
                SectionCard(title: "Preferences") {
                    Text("No preferences recorded.")
                        .foregroundColor(.gray)
                        .font(.subheadline)
                }
            }
            
            // Sizes Preview
            if let sizes = client.preferences?.sizes, client.hasDataProcessingConsent {
                SectionCard(title: "Size Profile") {
                    HStack(spacing: 24) {
                        if let ring = sizes.ring { SizeItem(label: "Ring", value: ring) }
                        if let dress = sizes.dress { SizeItem(label: "Dress", value: dress) }
                        if let shoes = sizes.shoes { SizeItem(label: "Shoes", value: shoes) }
                    }
                }
            }
            
            // Contact & Info
            SectionCard(title: "Information") {
                VStack(alignment: .leading, spacing: 12) {
                    InfoRow(icon: "envelope.fill", text: client.maskedEmail ?? "No Email")
                    
                    if let dob = client.maskedDateOfBirth {
                        InfoRow(icon: "gift.fill", text: dob)
                    }
                }
            }
        }
        .padding()
    }
}

struct SectionCard<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title.uppercased())
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.secondary)
            
            content
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.appleBorder, lineWidth: 1)
        )
    }
}

struct PreferenceRow: View {
    let title: String
    let values: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(values.joined(separator: ", "))
                .font(.subheadline)
        }
    }
}

struct SizeItem: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

struct InfoRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.gray)
                .frame(width: 20)
            Text(text)
                .font(.subheadline)
        }
    }
}
