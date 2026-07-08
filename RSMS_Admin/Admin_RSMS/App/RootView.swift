//
//  ContentView.swift
//  Admin_RSMS
//

import SwiftUI

enum ActiveView {
    case dashboard
    case auditLogs
}

struct ContentView: View {
    @State private var activeView: ActiveView = .dashboard
    
    var body: some View {
        NavigationStack {
            Group {
                switch activeView {
                case .dashboard:
                    DashboardView()
                case .auditLogs:
                    AuditLogsView()
                }
            }
            .navigationTitle(activeView == .dashboard ? "Dashboard" : "Audit Logs")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    customSegmentedControl
                }
                profileToolbarItem
            }
        }
        .tint(Color.brandGreenDark)
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }
    
    private var customSegmentedControl: some View {
        HStack(spacing: 0) {
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    activeView = .dashboard
                }
            }) {
                Text("Dashboard")
                    .font(.subheadline.weight(.semibold))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(activeView == .dashboard ? Color.brandGreenLight : Color.clear)
                    .clipShape(Capsule())
                    .foregroundColor(activeView == .dashboard ? Color.brandGreenDark : Color.secondary)
            }
            .buttonStyle(.plain)
            
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    activeView = .auditLogs
                }
            }) {
                Text("Audit Logs")
                    .font(.subheadline.weight(.semibold))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(activeView == .auditLogs ? Color.brandGreenLight : Color.clear)
                    .clipShape(Capsule())
                    .foregroundColor(activeView == .auditLogs ? Color.brandGreenDark : Color.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(4)
        .background(Color(uiColor: .systemGray6))
        .clipShape(Capsule())
    }
    
    @ToolbarContentBuilder
    private var profileToolbarItem: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            Menu {
                if let user = AuthManager.shared.currentUser {
                    Section {
                        Text("Signed in as:")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text(user.fullName)
                            .font(.headline)
                        Text(user.email)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                } else {
                    Section {
                        Text("Offline Admin Mode")
                            .font(.headline)
                    }
                }
                
                Divider()
                
                Button(role: .destructive, action: {
                    AuthManager.shared.signOut()
                }) {
                    Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                }
            } label: {
                Circle()
                    .fill(Color.orange)
                    .frame(width: 36, height: 36)
                    .overlay(
                        Text("AM")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white)
                    )
            }
        }
    }
}

#Preview {
    ContentView()
}
