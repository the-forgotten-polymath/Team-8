//
//  ContentView.swift
//  Admin_RSMS
//

import SwiftUI

enum ActiveView {
    case dashboard
    case targets
    case auditLogs
}

struct ContentView: View {
    @State private var activeView: ActiveView = .dashboard
    
    var body: some View {
        TabView(selection: $activeView) {
            Tab("Dashboard", systemImage: "square.grid.2x2", value: .dashboard) {
                NavigationStack {
                    DashboardView()
                        .navigationTitle("Dashboard")
                        .navigationBarTitleDisplayMode(.large)
                        .toolbar { profileToolbarItem }
                }
            }
            
            Tab("Targets", systemImage: "bullseye", value: .targets) {
                NavigationStack {
                    TargetsView()
                        .toolbar { profileToolbarItem }
                }
            }
            
            Tab("Audit Logs", systemImage: "list.clipboard", value: .auditLogs) {
                NavigationStack {
                    AuditLogsView()
                        .navigationTitle("Audit Logs")
                        .navigationBarTitleDisplayMode(.large)
                        .toolbar { profileToolbarItem }
                }
            }
        }
        .tint(Color.brandGreenDark)
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }
    
    @ToolbarContentBuilder
    private var profileToolbarItem: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Menu {
                if let user = AuthManager.shared.currentUser {
                    Section {
                        Text("Signed in as:")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text(user.fullName)
                            .font(.headline)
                        Text(user.email)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
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
                            .foregroundStyle(.white)
                    )
            }
        }
    }
}

#Preview {
    ContentView()
}
