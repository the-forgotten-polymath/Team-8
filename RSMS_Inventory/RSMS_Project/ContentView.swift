//
//  ContentView.swift
//  RSMS_Project
//
//  Created by Yatharth Mishra on 30/06/26.
//

import SwiftUI

struct ContentView: View {
    var onBackToPortal: () -> Void = {}
    var onLogout: () -> Void = {}

    @State private var selectedTab = 0
    @State private var warehouseId: UUID?
    @State private var userId: UUID?
    @State private var isAuthenticated: Bool
    @State private var isLoading = false
    @State private var errorMessage: String? = nil

    /// Shared notification store — injected as environmentObject into the TabView
    /// so all tabs (Dashboard, Notifications sheet, LowStockAlertView) can read/write it.
    @StateObject private var notificationStore = LowStockNotificationStore()
    
    init(
        onBackToPortal: @escaping () -> Void = {},
        isAuthenticated: Bool = false,
        userId: UUID? = nil,
        warehouseId: UUID? = nil,
        onLogout: @escaping () -> Void = {}
    ) {
        self.onBackToPortal = onBackToPortal
        self.onLogout = onLogout
        self._isAuthenticated = State(initialValue: isAuthenticated)
        self._userId = State(initialValue: userId)
        self._warehouseId = State(initialValue: warehouseId)
    }
    
    var body: some View {
        Group {
            if !isAuthenticated {
                ZStack(alignment: .topLeading) {
                    InventoryLoginView(isAuthenticated: $isAuthenticated, userId: $userId, warehouseId: $warehouseId)
                    
                    Button(action: onBackToPortal) {
                        HStack(spacing: 6) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 14, weight: .bold))
                            Text("Portal")
                                .font(.system(size: 15, weight: .semibold))
                        }
                        .foregroundColor(.orange)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.white.opacity(0.08))
                        .cornerRadius(20)
                        .shadow(color: Color.black.opacity(0.1), radius: 5)
                    }
                    .padding(.leading, 16)
                    .padding(.top, 60)
                }
            } else if isLoading {
                loadingView
            } else if let error = errorMessage {
                errorView(error)
            } else if let wId = warehouseId, let uId = userId {
                mainTabApp(wId: wId, uId: uId)
            } else {
                VStack {
                    Text("Failed to initialize session.")
                        .foregroundColor(.secondary)
                }
            }
        }
        .onAppear {
            if isAuthenticated && (warehouseId == nil || userId == nil) {
                Swift.Task {
                    await resolveSessionDetails()
                }
            }
        }
    }
    
    // MARK: - Subviews
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Connecting to Supabase...")
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func errorView(_ error: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: 48))
                .foregroundColor(.red)
            Text("Connection Failed")
                .font(.headline)
            Text(error)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            Button("Retry") {
                Swift.Task {
                    await bootstrapApp()
                }
            }
            .buttonStyle(.borderedProminent)
        }
    }
    
    private var logoutAction: () -> Void {
        {
            self.isAuthenticated = false
            self.userId = nil
            self.warehouseId = nil
            self.onLogout()
        }
    }

    private func mainTabApp(wId: UUID, uId: UUID) -> some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                DashboardView(
                    warehouseId: wId,
                    userId: uId,
                    selectedTab: $selectedTab,
                    onLogout: logoutAction
                )
            }
            .tabItem {
                Label("Dashboard", systemImage: "chart.bar.fill")
            }
            .tag(0)
            
            NavigationStack {
                InventoryView(warehouseId: wId)
            }
            .tabItem {
                Label("Inventory", systemImage: "shippingbox.fill")
            }
            .tag(1)
            
            NavigationStack {
                LogisticsView(warehouseId: wId, userId: uId)
            }
            .tabItem {
                Label("Logistics", systemImage: "truck.box.fill")
            }
            .tag(2)
            
            NavigationStack {
                MoreOperationsView(warehouseId: wId, userId: uId, onLogout: {
                    self.isAuthenticated = false
                    self.userId = nil
                    self.warehouseId = nil
                    self.onLogout()
                })
            }
            .tabItem {
                Label("More", systemImage: "ellipsis.circle.fill")
            }
            .tag(3)
        }
        .tint(.blue)
        .environmentObject(notificationStore)
    }

    
    // MARK: - Bootstrapping
    
    private func bootstrapApp() async {
        isLoading = true
        errorMessage = nil
        do {
            // Fetch users to obtain a controller profile (prioritize Inventory Controller role)
            let users = try await UserService().fetchUsers()
            let controllerRoleId = UUID(uuidString: "c0aa841a-7c57-43f9-b98a-523475ba43af")
            if let controllerUser = users.first(where: { $0.roleId == controllerRoleId }) {
                self.userId = controllerUser.id
            } else if let user = users.first {
                self.userId = user.id
            } else {
                // Generate a temporary mock UUID if table is empty
                self.userId = UUID(uuidString: "8f1a30f1-4df2-4752-953e-1082c5bf4f47")
            }
            
            // Fetch warehouses
            let warehouses = try await WarehouseService.shared.fetchWarehouses()
            if let warehouse = warehouses.first {
                self.warehouseId = warehouse.id
            } else {
                // Generate a temporary mock UUID if table is empty
                self.warehouseId = UUID(uuidString: "e889f951-769c-4ce9-9b2f-90928236e08a")
            }
        } catch {
            print("Bootstrap failed with error: \(error)")
            self.errorMessage = error.localizedDescription
            // Fallbacks for offline simulator testing
            self.userId = UUID(uuidString: "8f1a30f1-4df2-4752-953e-1082c5bf4f47")
            self.warehouseId = UUID(uuidString: "e889f951-769c-4ce9-9b2f-90928236e08a")
            // Do not clear the error so we can see the exact failure description on screen
        }
        isLoading = false
    }
    
    private func resolveSessionDetails() async {
        isLoading = true
        errorMessage = nil
        do {
            if warehouseId == nil {
                let warehouses = try await WarehouseService.shared.fetchWarehouses()
                if let warehouse = warehouses.first {
                    self.warehouseId = warehouse.id
                } else {
                    self.warehouseId = UUID(uuidString: "e889f951-769c-4ce9-9b2f-90928236e08a")
                }
            }
        } catch {
            print("Resolve session details failed with error: \(error)")
            self.warehouseId = UUID(uuidString: "e889f951-769c-4ce9-9b2f-90928236e08a")
        }
        isLoading = false
    }
}

#Preview {
    ContentView()
}
