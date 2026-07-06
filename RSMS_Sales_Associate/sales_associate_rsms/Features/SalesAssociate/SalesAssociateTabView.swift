// SalesAssociateTabView.swift
// RSMS — Sales Associate Module
// Root tab container — all 6 epics as tabs

import SwiftUI

struct SalesAssociateTabView: View {

    @EnvironmentObject private var authVM: AuthViewModel
    @EnvironmentObject var checkoutEnv: CheckoutEnvironment

    var body: some View {
        TabView(selection: $checkoutEnv.selectedTab) {

            // Tab 1 — Home
            DashboardView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(0)

            // Tab 2 — Catalog
            SellingView()
                .tabItem {
                    Label("Catalog", systemImage: "square.grid.3x3.fill")
                }
                .tag(1)

            // Tab 3 — Operations
            OperationsView()
                .tabItem {
                    Label("Operations", systemImage: "square.grid.2x2.fill")
                }
                .tag(2)
        }
        .tint(.blue)
    }
}

#Preview {
    SalesAssociateTabView()
        .environmentObject(AuthViewModel())
}
