// AdvisorDashboardView.swift
// RSMS — Sales Associate Module

import SwiftUI

struct AdvisorDashboardView: View {
    @EnvironmentObject var viewModel: DashboardViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Performance Tracker
                VStack(alignment: .leading, spacing: 12) {
                    Text("Performance Tracker")
                        .font(.headline)
                        .padding(.horizontal, 4)
                    
                    if let metrics = viewModel.advisorMetrics {
                        SalesGoalGaugeView(metrics: metrics)
                            .padding()
                            .liquidGlass()
                    }
                }
                
                // Today's Agenda
                VStack(alignment: .leading, spacing: 12) {
                    Text("Today's Agenda")
                        .font(.headline)
                        .padding(.horizontal, 4)
                    
                    VStack(spacing: 12) {
                        if viewModel.todayAppointments.isEmpty {
                            Text("No appointments scheduled for today.")
                                .foregroundColor(.secondary)
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .center)
                        } else {
                            ForEach(viewModel.todayAppointments) { appointment in
                                HStack(spacing: 16) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(appointment.type.rawValue)
                                            .font(.headline)
                                            .foregroundColor(.primary)
                                        Text(appointment.date, style: .time)
                                            .font(.subheadline)
                                            .foregroundColor(.blue)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(Color(.systemGray4))
                                }
                                .padding()
                                .liquidGlass()
                            }
                        }
                    }
                }
                
                // Active Opportunities
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Active Opportunities")
                            .font(.headline)
                        Spacer()
                        NavigationLink(destination: ActiveOpportunitiesView().environmentObject(viewModel)) {
                            Text("See All")
                                .font(.subheadline)
                                .foregroundColor(.blue)
                        }
                    }
                    .padding(.horizontal, 4)
                    
                    VStack(spacing: 12) {
                        if viewModel.activeOpportunities.isEmpty {
                            Text("No active opportunities.")
                                .foregroundColor(.secondary)
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .center)
                        } else {
                            ForEach(viewModel.activeOpportunities.prefix(3)) { opp in
                                HStack(spacing: 16) {
                                    ZStack {
                                        Circle()
                                            .fill(colorForOpportunity(opp.type).opacity(0.12))
                                            .frame(width: 44, height: 44)
                                        Image(systemName: iconForOpportunity(opp.type))
                                            .font(.system(size: 18, weight: .semibold))
                                            .foregroundColor(colorForOpportunity(opp.type))
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(opp.title)
                                            .font(.headline)
                                        Text(opp.clientName ?? "Unknown Client")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                }
                                .padding()
                                .liquidGlass()
                            }
                        }
                    }
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
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
