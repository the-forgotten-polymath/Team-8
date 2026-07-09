//
//  EmployeeTabView.swift
//  RSMS_Project
//
//  Created by Yatharth Mishra on 30/06/26.
//

import SwiftUI

struct EmployeeTabView: View {
    @State private var navigationPath = NavigationPath()

    var body: some View {
        NavigationStack(path: $navigationPath) {
            ScrollView {
                VStack(spacing: 24) {
                    // Custom Header Row aligning Title "Staff"
                    HStack(spacing: 12) {
                        Text("Staff")
                            .font(.system(size: 34, weight: .bold))
                            .foregroundColor(Color(.label))
                        Spacer()
                    }
                    .padding(.horizontal, 4)
                    .padding(.top, 16)
                    
                    // Card 1 — Employee Management
                    NavigationLink(value: ManagementRoute.employees) {
                        ManagementCard(
                            title: "Employee Management",
                            subtitle: "Attendance, profiles and shifts",
                            iconName: "person.2.fill",
                            iconColor: Color(.systemBlue)
                        )
                    }
                    .buttonStyle(CardButtonStyle())

                    // Card 2 — Shift Management
                    NavigationLink(value: ManagementRoute.shifts) {
                        ManagementCard(
                            title: "Shift Management",
                            subtitle: "Schedule and assign staff shifts",
                            iconName: "calendar.badge.clock",
                            iconColor: Color(.systemRed)
                        )
                    }
                    .buttonStyle(CardButtonStyle())

                    // Card 3 — Appointments
                    NavigationLink(value: ManagementRoute.appointments) {
                        ManagementCard(
                            title: "Appointments",
                            subtitle: "Create, schedule and manage appointments",
                            iconName: "checklist",
                            iconColor: Color(.systemBlue)
                        )
                    }
                    .buttonStyle(CardButtonStyle())

                    // Card 4 — Staff Performance
                    NavigationLink(value: ManagementRoute.performance) {
                        ManagementCard(
                            title: "Staff Performance",
                            subtitle: "Track sales, rankings and performance",
                            iconName: "chart.bar.xaxis",
                            iconColor: Color(.systemBlue)
                        )
                    }
                    .buttonStyle(CardButtonStyle())

                }
                .padding(.horizontal, 16)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Staff")
            .navigationBarHidden(true)
            .navigationDestination(for: ManagementRoute.self) { route in
                switch route {
                case .employees:
                    EmployeeListView()
                case .shifts:
                    ShiftManagementView()
                case .appointments:
                    AppointmentManagementView()
                case .performance:
                    StaffPerformanceView()
                }
            }
        }
    }
}

// MARK: - Navigation Routes
enum ManagementRoute: Hashable {
    case employees
    case shifts
    case appointments
    case performance
}

// MARK: - Custom Card Button Style (HIG compliant scale animation)
struct CardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// MARK: - Management Card Component
struct ManagementCard: View {
    let title: String
    let subtitle: String
    let iconName: String
    let iconColor: Color

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(Color(.label))
                    .multilineTextAlignment(.leading)

                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(Color(.secondaryLabel))
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }
            
            Spacer()

            HStack(spacing: 12) {
                // Illustration container with white background
                Image(systemName: iconName)
                    .font(.system(size: 24))
                    .foregroundColor(iconColor)
                    .frame(width: 50, height: 50)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .shadow(color: Color.black.opacity(0.04), radius: 3, x: 0, y: 1.5)
                
                // Chevron button
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 26, height: 26)
                    .background(Color(.systemBlue))
                    .clipShape(Circle())
            }
        }
        .padding(16)
        .frame(height: 125)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.02), radius: 6, x: 0, y: 3)
    }
}

