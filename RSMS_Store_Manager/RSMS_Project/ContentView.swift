//
//  ContentView.swift
//  RSMS_Project
//
//  Created by Yatharth Mishra on 30/06/26.
//

import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0 // Default active tab is "Dashboard" (tag 0)
    @State private var selectedStockFilter: StockFilterType = .all

    var body: some View {
        TabView(selection: $selectedTab) {
            // Dashboard
            NavigationStack {
                DashboardView(selectedTab: $selectedTab, selectedStockFilter: $selectedStockFilter)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button(action: {
                                SessionManager.shared.currentUser = nil
                            }) {
                                Image(systemName: "rectangle.portrait.and.arrow.right")
                                    .foregroundColor(.red)
                            }
                        }
                    }
            }
            .tabItem {
                Label("Dashboard", systemImage: "chart.bar.fill")
            }
            .tag(0)


            // Staff Tab (Active)
            EmployeeTabView()
                .tabItem {
                    Label("Staff", systemImage: "person.2.fill")
                }
                .tag(1)

            // Stock Tab
            NavigationStack {
                StockManagementView(selectedStockFilter: $selectedStockFilter)
            }
            .tabItem {
                Label("Stock", systemImage: "shippingbox.fill")
            }
            .tag(2)
        }
        .tint(Color(.systemBlue))
    }
}

#Preview {
    ContentView()
}
