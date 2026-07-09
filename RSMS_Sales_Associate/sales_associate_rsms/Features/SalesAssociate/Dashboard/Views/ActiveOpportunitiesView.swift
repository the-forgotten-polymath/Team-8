// ActiveOpportunitiesView.swift
// RSMS — Sales Associate Module

import SwiftUI

struct ActiveOpportunitiesView: View {
    @EnvironmentObject var viewModel: DashboardViewModel
    @State private var selectedContactClient: Opportunity? = nil
    @State private var showingAppointmentSheet = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if viewModel.activeOpportunities.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "sparkles")
                            .font(.largeTitle)
                            .foregroundColor(.secondary)
                        Text("No active opportunities.")
                            .foregroundColor(.secondary)
                            .font(.subheadline)
                    }
                    .frame(maxWidth: .infinity, minHeight: 200)
                } else {
                    ForEach(viewModel.activeOpportunities) { opp in
                        OpportunityCard(
                            opp: opp,
                            onContact: {
                                selectedContactClient = opp
                            },
                            onCreateAppointment: {
                                showingAppointmentSheet = true
                            },
                            onDismiss: {
                                let generator = UIImpactFeedbackGenerator(style: .light)
                                generator.impactOccurred()
                                viewModel.dismissOpportunity(opp.id)
                            }
                        )
                    }
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationTitle("Opportunities")
        .toolbar(.hidden, for: .tabBar)
        .sheet(item: $selectedContactClient) { opp in
            ContactDetailsSheet(opp: opp)
        }
        .sheet(isPresented: $showingAppointmentSheet) {
            CreateAppointmentView(appointments: .constant([]))
        }
    }
}

struct OpportunityCard: View {
    let opp: Opportunity
    var onContact: () -> Void
    var onCreateAppointment: () -> Void
    var onDismiss: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Top Header: Badge (e.g. 🎁 Birthday Today)
            HStack {
                HStack(spacing: 6) {
                    Text(emojiForType(opp.type))
                    Text(opp.title)
                        .font(.system(size: 13, weight: .bold))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(colorForType(opp.type).opacity(0.12))
                .foregroundColor(colorForType(opp.type))
                .cornerRadius(12)
                
                Spacer()
                
                if let tier = opp.customerTier {
                    Text(tier.uppercased())
                        .font(.system(size: 10, weight: .bold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(colorForTier(tier).opacity(0.15))
                        .foregroundColor(colorForTier(tier))
                        .cornerRadius(8)
                }
                
                // Dismiss action
                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.secondary.opacity(0.6))
                }
                .buttonStyle(.plain)
            }
            
            // Customer Info Row
            HStack(spacing: 16) {
                // Larger circular avatar (52pt)
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.12))
                        .frame(width: 52, height: 52)
                    Text(opp.clientName?.initials ?? "??")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.blue)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(opp.clientName ?? "Unknown Customer")
                        .font(.system(size: 18, weight: .bold, design: .default))
                        .foregroundColor(.primary)
                    
                    Text(opp.description)
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }
            
            // Offer Display
            if let offer = opp.personalizedOffer {
                VStack(alignment: .leading, spacing: 4) {
                    Text("SPECIAL OFFER")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.secondary)
                    Text(offer)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(Color(hex: "C9A84C"))
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.blue.opacity(0.05))
                .cornerRadius(12)
            }
            
            // Recommended Product
            if let prodName = opp.recommendedProductName {
                HStack(spacing: 12) {
                    if let imgUrlStr = opp.recommendedProductImageURL, let imgUrl = URL(string: imgUrlStr) {
                        AsyncImage(url: imgUrl) { image in
                            image.resizable()
                                 .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Color.gray.opacity(0.1)
                        }
                        .frame(width: 50, height: 50)
                        .cornerRadius(10)
                        .clipped()
                    } else {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(LinearGradient(colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.3)], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 50, height: 50)
                            .overlay(
                                Image(systemName: "sparkles")
                                    .foregroundColor(.white)
                            )
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(prodName)
                            .font(.system(size: 14, weight: .bold))
                            .lineLimit(1)
                        HStack(spacing: 8) {
                            if let discPrice = opp.recommendedProductDiscountedPrice {
                                Text(discPrice, format: .currency(code: AppConstants.App.currencyCode))
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(.green)
                            }
                            if let currentPrice = opp.recommendedProductPrice {
                                Text(currentPrice, format: .currency(code: AppConstants.App.currencyCode))
                                    .font(.system(size: 12))
                                    .strikethrough()
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                .padding(10)
                .background(Color(.secondarySystemGroupedBackground).opacity(0.5))
                .cornerRadius(12)
            }
            
            // Primary Filled CTA Buttons (Height: 50pt, Corner Radius: 16pt)
            HStack(spacing: 12) {
                Button(action: {
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                    onContact()
                }) {
                    Label(opp.type == .birthday ? "Contact" : "Message", systemImage: opp.type == .birthday ? "phone.fill" : "bubble.left.fill")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.blue)
                        .cornerRadius(16)
                }
                .buttonStyle(.plain)
                
                Button(action: {
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                    onCreateAppointment()
                }) {
                    Label("Schedule", systemImage: "calendar.badge.plus")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.green)
                        .cornerRadius(16)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(20)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(24)
        .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 5)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.white.opacity(0.3), lineWidth: 1)
        )
    }
    
    private func colorForType(_ type: OpportunityType) -> Color {
        switch type {
        case .birthday: return .orange
        case .anniversary: return .pink
        default: return .purple
        }
    }
    
    private func emojiForType(_ type: OpportunityType) -> String {
        switch type {
        case .birthday: return "🎂"
        case .anniversary: return "💍"
        default: return "🎉"
        }
    }
    
    private func colorForTier(_ tier: String) -> Color {
        switch tier.lowercased() {
        case "vip", "vvip": return .purple
        case "standard": return .blue
        default: return .gray
        }
    }
}

struct ContactDetailsSheet: View {
    let opp: Opportunity
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("Client Name")) {
                    Text(opp.clientName ?? "Unknown Customer")
                        .font(.headline)
                }
                
                Section(header: Text("Contact Options")) {
                    HStack {
                        Image(systemName: "phone.fill")
                            .foregroundColor(.blue)
                        Text("Phone")
                        Spacer()
                        Text("+91 98765 81361") // Example/Placeholder or from Customer object
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Image(systemName: "envelope.fill")
                            .foregroundColor(.blue)
                        Text("Email")
                        Spacer()
                        Text("client@example.com")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Contact Information")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}
