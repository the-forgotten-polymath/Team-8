// ActiveOpportunitiesView.swift
// RSMS — Sales Associate Module

import SwiftUI

struct ActiveOpportunitiesView: View {
    @EnvironmentObject var viewModel: DashboardViewModel
    
    var body: some View {
        List {
            if viewModel.activeOpportunities.isEmpty {
                Text("No active opportunities.")
                    .foregroundColor(.secondary)
            } else {
                ForEach(viewModel.activeOpportunities) { opp in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: iconForOpportunity(opp.type))
                                .foregroundColor(colorForOpportunity(opp.type))
                            Text(opp.type.rawValue)
                                .font(.caption.bold())
                                .foregroundColor(colorForOpportunity(opp.type))
                            Spacer()
                            Text(opp.dateGenerated, style: .date)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        
                        Text(opp.title)
                            .font(.headline)
                        
                        Text(opp.description)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        if let clientName = opp.clientName {
                            Text("Client: \(clientName)")
                                .font(.caption)
                                .padding(.top, 2)
                        }
                        
                        HStack {
                            Button(action: {
                                let generator = UIImpactFeedbackGenerator(style: .medium)
                                generator.impactOccurred()
                                viewModel.convertOpportunity(opp.id)
                            }) {
                                Text("Act Now")
                                    .font(.caption.bold())
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color(hex: "C9A84C"))
                                    .foregroundColor(.white)
                                    .cornerRadius(8)
                            }
                            
                            Button(action: {
                                let generator = UIImpactFeedbackGenerator(style: .light)
                                generator.impactOccurred()
                                viewModel.dismissOpportunity(opp.id)
                            }) {
                                Text("Dismiss")
                                    .font(.caption)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .foregroundColor(.gray)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.gray, lineWidth: 1)
                                    )
                            }
                        }
                        .padding(.top, 8)
                    }
                    .padding(.vertical, 8)
                }
            }
        }
        .navigationTitle("Opportunities")
        .toolbar(.hidden, for: .tabBar)
    }
    
    private func iconForOpportunity(_ type: OpportunityType) -> String {
        switch type {
        case .anniversary, .birthday: return "gift.fill"
        case .wishlistInStock: return "star.fill"
        case .warrantyExpiring: return "wrench.and.screwdriver.fill"
        case .newCollectionMatch: return "sparkles"
        case .retentionRisk: return "exclamationmark.triangle.fill"
        case .vipEventInvitation: return "envelope.open.fill"
        }
    }
    
    private func colorForOpportunity(_ type: OpportunityType) -> Color {
        switch type {
        case .anniversary, .birthday: return .pink
        case .wishlistInStock: return .yellow
        case .warrantyExpiring: return .orange
        case .newCollectionMatch: return .purple
        case .retentionRisk: return .red
        case .vipEventInvitation: return .blue
        }
    }
}
