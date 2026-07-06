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
                VStack(spacing: 16) {
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
                            illustration: AnyView(GroupIllustration())
                        )
                    }
                    .buttonStyle(CardButtonStyle())

                    // Card 2 — Shift Management
                    NavigationLink(value: ManagementRoute.shifts) {
                        ManagementCard(
                            title: "Shift Management",
                            subtitle: "Schedule and assign staff shifts",
                            illustration: AnyView(ShiftIllustration())
                        )
                    }
                    .buttonStyle(CardButtonStyle())

                    // Card 3 — Task Management
                    NavigationLink(value: ManagementRoute.tasks) {
                        ManagementCard(
                            title: "Task Management",
                            subtitle: "Create, schedule and assign staff tasks",
                            illustration: AnyView(TaskIllustration())
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
                case .tasks:
                    TaskManagementView()
                }
            }
        }
    }
}

// MARK: - Navigation Routes
enum ManagementRoute: Hashable {
    case employees
    case shifts
    case tasks
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
    let illustration: AnyView

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color(.label))
                    .multilineTextAlignment(.leading)

                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundColor(Color(.secondaryLabel))
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }
            
            Spacer()

            HStack(spacing: 12) {
                // Illustration container with white background
                illustration
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
        .frame(height: 110)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.02), radius: 6, x: 0, y: 3)
    }
}

// MARK: - Custom Vector Illustrations

// Illustration 1: Group of Employees
struct GroupIllustration: View {
    var body: some View {
        ZStack {
            // Left employee
            VStack(spacing: 2) {
                Circle()
                    .fill(Color(.systemBlue).opacity(0.35))
                    .frame(width: 16, height: 16)
                Capsule()
                    .fill(Color(.systemBlue).opacity(0.35))
                    .frame(width: 24, height: 14)
            }
            .offset(x: -15, y: 10)

            // Right employee
            VStack(spacing: 2) {
                Circle()
                    .fill(Color(.systemBlue).opacity(0.45))
                    .frame(width: 16, height: 16)
                Capsule()
                    .fill(Color(.systemBlue).opacity(0.45))
                    .frame(width: 24, height: 14)
            }
            .offset(x: 15, y: 10)

            // Center employee (featured)
            VStack(spacing: 2) {
                Circle()
                    .fill(Color(.systemBlue))
                    .frame(width: 20, height: 20)
                    .overlay(
                        Circle()
                            .stroke(Color.white, lineWidth: 1.5)
                    )
                Capsule()
                    .fill(Color(.systemBlue))
                    .frame(width: 30, height: 18)
                    .overlay(
                        Capsule()
                            .stroke(Color.white, lineWidth: 1.5)
                    )
            }
            .offset(x: 0, y: 2)
        }
    }
}

// Illustration 2: Shift (Calendar and Clock)
struct ShiftIllustration: View {
    var body: some View {
        ZStack {
            // Calendar icon page
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.white)
                .frame(width: 38, height: 42)
                .shadow(color: Color.black.opacity(0.08), radius: 3, x: 0, y: 1.5)
                .overlay(
                    VStack(spacing: 0) {
                        // Calendar top header (red)
                        Rectangle()
                            .fill(Color(.systemRed))
                            .frame(height: 10)
                        
                        // Calendar grid lines
                        VStack(spacing: 3) {
                            Spacer()
                            HStack(spacing: 3) {
                                Circle().fill(Color(.systemGray4)).frame(width: 3, height: 3)
                                Circle().fill(Color(.systemGray4)).frame(width: 3, height: 3)
                                Circle().fill(Color(.systemGray4)).frame(width: 3, height: 3)
                            }
                            HStack(spacing: 3) {
                                Circle().fill(Color(.systemGray4)).frame(width: 3, height: 3)
                                Circle().fill(Color(.systemGray4)).frame(width: 3, height: 3)
                                Circle().fill(Color(.systemGray4)).frame(width: 3, height: 3)
                            }
                            HStack(spacing: 3) {
                                Circle().fill(Color(.systemGray4)).frame(width: 3, height: 3)
                                Circle().fill(Color(.systemGray4)).frame(width: 3, height: 3)
                                Circle().fill(Color(.systemGray4)).frame(width: 3, height: 3)
                            }
                            Spacer()
                        }
                        .padding(.horizontal, 3)
                    }
                )
                .rotationEffect(.degrees(-8))
                .offset(x: -10, y: -4)

            // Clock icon overlapping
            Circle()
                .fill(Color.white)
                .frame(width: 36, height: 36)
                .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 2)
                .overlay(
                    ZStack {
                        Circle()
                            .stroke(Color(.systemGray3), lineWidth: 1.5)
                            .padding(1.5)
                        
                        // Clock hands
                        Path { path in
                            path.move(to: CGPoint(x: 18, y: 18))
                            path.addLine(to: CGPoint(x: 18, y: 9)) // 12 o'clock
                            path.move(to: CGPoint(x: 18, y: 18))
                            path.addLine(to: CGPoint(x: 25, y: 18)) // 3 o'clock
                        }
                        .stroke(Color(.label), lineWidth: 1.5)
                        
                        Circle()
                            .fill(Color(.systemRed))
                            .frame(width: 3, height: 3)
                    }
                )
                .offset(x: 12, y: 10)
        }
    }
}

// Illustration 3: Task (Clipboard and checklist)
struct TaskIllustration: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.white)
                .frame(width: 38, height: 42)
                .shadow(color: Color.black.opacity(0.08), radius: 3, x: 0, y: 1.5)
                .overlay(
                    VStack(spacing: 3) {
                        Rectangle()
                            .fill(Color(.systemBlue))
                            .frame(height: 10)
                        
                        VStack(alignment: .leading, spacing: 3) {
                            Spacer()
                            HStack(spacing: 4) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 8))
                                    .foregroundColor(Color(.systemGreen))
                                Rectangle().fill(Color(.systemGray4)).frame(height: 2)
                            }
                            HStack(spacing: 4) {
                                Image(systemName: "circle")
                                    .font(.system(size: 8))
                                    .foregroundColor(Color(.systemGray3))
                                Rectangle().fill(Color(.systemGray4)).frame(height: 2)
                            }
                            Spacer()
                        }
                        .padding(.horizontal, 4)
                    }
                )
                .rotationEffect(.degrees(-6))
                .offset(x: -8, y: -4)

            Image(systemName: "checklist")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(Color(.systemBlue))
                .padding(8)
                .background(Circle().fill(Color.white).shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 2))
                .offset(x: 12, y: 10)
        }
    }
}

#Preview {
    EmployeeTabView()
}
