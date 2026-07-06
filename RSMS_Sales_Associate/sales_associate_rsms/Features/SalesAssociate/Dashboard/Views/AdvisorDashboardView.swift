// AdvisorDashboardView.swift
// RSMS — Sales Associate Module

import SwiftUI

struct AdvisorDashboardView: View {
    @EnvironmentObject var viewModel: DashboardViewModel
    
    var body: some View {
        List {
            Section(header: Text("Performance Tracker")) {
                if let metrics = viewModel.advisorMetrics {
                    SalesGoalGaugeView(metrics: metrics)
                        .padding(.vertical)
                }
            }
            
            Section(header: Text("Today's Agenda")) {
                if viewModel.todayAppointments.isEmpty {
                    Text("No appointments scheduled for today.")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(viewModel.todayAppointments) { appointment in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(appointment.type.rawValue)
                                    .font(.headline)
                                Text(appointment.date, style: .time)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                        }
                    }
                }
            }
            
            Section(header: HStack {
                Text("Active Opportunities")
                Spacer()
                NavigationLink(destination: ActiveOpportunitiesView().environmentObject(viewModel)) {
                    Text("See All")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }) {
                if viewModel.activeOpportunities.isEmpty {
                    Text("No active opportunities.")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(viewModel.activeOpportunities.prefix(3)) { opp in
                        HStack {
                            Image(systemName: iconForOpportunity(opp.type))
                                .foregroundColor(colorForOpportunity(opp.type))
                                .frame(width: 30)
                            VStack(alignment: .leading) {
                                Text(opp.title)
                                    .font(.body)
                                Text(opp.clientName ?? "Unknown Client")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
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
