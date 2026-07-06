// ClientDigitalTwinTimelineView.swift
// RSMS — Sales Associate Module

import SwiftUI

struct ClientDigitalTwinTimelineView: View {
    let events: [ClientDigitalTwinEvent]
    
    var body: some View {
        if events.isEmpty {
            VStack {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.largeTitle)
                    .foregroundColor(.secondary)
                Text("No events found")
                    .foregroundColor(.secondary)
            }
            .padding(40)
        } else {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(events) { event in
                    HStack(alignment: .top, spacing: 16) {
                        // Timeline Node
                        VStack {
                            Circle()
                                .fill(color(for: event.type))
                                .frame(width: 12, height: 12)
                                .padding(.top, 4)
                            
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 2)
                        }
                        
                        // Event Content
                        VStack(alignment: .leading, spacing: 4) {
                            Text(event.date, style: .date)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text(event.title)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            
                            Text(event.description)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            if let location = event.location {
                                HStack(spacing: 4) {
                                    Image(systemName: "mappin.and.ellipse")
                                    Text(location)
                                }
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .padding(.top, 2)
                            }
                        }
                        .padding(.bottom, 24)
                    }
                }
            }
            .padding()
        }
    }
    
    private func color(for type: ClientEventType) -> Color {
        switch type {
        case .purchase: return .green
        case .returnProcessed: return .red
        case .appointmentBooked, .appointmentCompleted: return .blue
        case .outreachSent: return .orange
        case .wishlistAdded, .wishlistFulfilled: return .pink
        case .boutiqueVisit: return .purple
        default: return .gray
        }
    }
}
