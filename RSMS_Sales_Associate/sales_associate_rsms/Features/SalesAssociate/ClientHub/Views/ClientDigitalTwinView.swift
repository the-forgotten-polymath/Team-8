// ClientDigitalTwinView.swift
// RSMS — Sales Associate Module

import SwiftUI

enum ClientTab: String, CaseIterable {
    case overview = "Overview"
    case timeline = "Timeline"
    case owned = "Owned"
    case wishlist = "Wishlist"
}

struct ClientDigitalTwinView: View {
    let clientID: UUID
    @StateObject private var viewModel = ClientDigitalTwinViewModel()
    @State private var selectedTab: ClientTab = .overview
    
    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()
            
            if viewModel.isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                    .scaleEffect(1.5)
            } else if let error = viewModel.errorMessage {
                VStack {
                    Text("Failed to load client")
                        .foregroundColor(.red)
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Button("Retry") {
                        viewModel.fetchFullTwin(clientID: clientID)
                    }
                    .padding(.top)
                }
            } else if let client = viewModel.client {
                VStack(spacing: 0) {
                    // Header
                    ClientHeaderView(client: client)
                    
                    // Tab Picker
                    Picker("Tabs", selection: $selectedTab) {
                        ForEach(ClientTab.allCases, id: \.self) { tab in
                            Text(tab.rawValue).tag(tab)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding()
                    
                    // Tab Content
                    ScrollView {
                        switch selectedTab {
                        case .overview:
                            ClientOverviewView(client: client)
                        case .timeline:
                            ClientDigitalTwinTimelineView(events: client.events ?? [])
                        case .owned:
                            OwnedProductsListView(products: client.ownedProducts ?? [])
                        case .wishlist:
                            WishlistView(items: client.wishlistItems ?? [])
                        }
                    }
                }
            }
        }
        .navigationTitle(viewModel.client?.fullName ?? "Client Profile")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.fetchFullTwin(clientID: clientID)
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    // Edit Client Logic
                }) {
                    Text("Edit")
                        .foregroundColor(.blue)
                }
            }
        }
    }
}

struct ClientHeaderView: View {
    let client: ClientDigitalTwin
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: [Color(.systemGray5), Color(.systemGray6)], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 80, height: 80)
                
                Text(client.initials)
                    .font(.system(size: 28, weight: .bold, design: .serif))
                    .foregroundColor(.blue)
            }
            
            Text(client.fullName)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            HStack(spacing: 16) {
                ClientTierBadgeView(tier: client.tier)
                
                Text(Money(client.lifetimeSpend).formatted)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                if let phone = client.maskedPhone {
                    HStack(spacing: 4) {
                        Image(systemName: "phone.fill")
                        Text(phone)
                    }
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.secondarySystemGroupedBackground))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Client Profile Header")
        .accessibilityValue("\(client.fullName), Tier \(client.tier.rawValue), Lifetime spend \(Money(client.lifetimeSpend).formatted). Phone number \(client.maskedPhone ?? "not available").")
    }
}
