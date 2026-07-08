// ClientHubView.swift
// RSMS — Sales Associate Module

import SwiftUI

struct ClientHubView: View {
    var isEmbedded: Bool = false
    @StateObject private var viewModel = ClientHubViewModel()
    @State private var showingAddClient = false

    var body: some View {
        if isEmbedded {
            mainContent
        } else {
            NavigationStack {
                mainContent
            }
        }
    }

    private var mainContent: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Search clients by name, email, or phone...", text: $viewModel.searchQuery)
                        .foregroundColor(.primary)
                        .onChange(of: viewModel.searchQuery) { _ in
                            viewModel.searchClients()
                        }
                }
                .padding()
                .background(Color.appleSecondaryBackground)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.appleBorder, lineWidth: 1)
                )
                .padding(.horizontal)
                .padding(.top)
                
                // Tier Filters
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        FilterChip(
                            title: "All",
                            isSelected: viewModel.selectedTier == nil,
                            action: { viewModel.selectedTier = nil; viewModel.searchClients() }
                        )
                        
                        ForEach(CustomerTier.allCases, id: \.self) { tier in
                            FilterChip(
                                title: tier.displayName,
                                isSelected: viewModel.selectedTier == tier,
                                action: { viewModel.selectedTier = tier; viewModel.searchClients() }
                            )
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                    .padding(.top, 8)
                }
                
                if viewModel.isLoading {
                    Spacer()
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                        .scaleEffect(1.5)
                    Spacer()
                } else if let error = viewModel.errorMessage {
                    Spacer()
                    Text(error)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding()
                    Spacer()
                } else if viewModel.clients.isEmpty && !viewModel.searchQuery.isEmpty {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "person.crop.circle.badge.questionmark")
                            .font(.system(size: 40))
                            .foregroundColor(.secondary)
                        Text("No clients found")
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                } else {
                    List {
                        ForEach(viewModel.clients) { client in
                            ZStack {
                                NavigationLink(destination: ClientDigitalTwinView(clientID: client.id)) {
                                    EmptyView()
                                }.opacity(0)
                                
                                ClientRowView(client: client)
                            }
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                        }
                    }
                    .listStyle(PlainListStyle())
                    .refreshable {
                        viewModel.searchClients()
                    }
                }
            }
        }
        .navigationTitle("Client Hub")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingAddClient = true }) {
                    Image(systemName: "person.crop.circle.badge.plus")
                        .foregroundColor(.blue)
                }
            }
        }
        .onAppear {
            viewModel.searchClients()
        }
        .sheet(isPresented: $showingAddClient) {
            AddClientView()
        }
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.blue : Color.appleSecondaryBackground)
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.appleBorder, lineWidth: 1)
                )
        }
    }
}

struct ClientRowView: View {
    let client: ClientDigitalTwin
    
    var body: some View {
        HStack(spacing: 16) {
            // Avatar
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: [Color(.systemGray5), Color(.systemGray6)], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 50, height: 50)
                
                Text(client.initials)
                    .font(.system(size: 18, weight: .bold, design: .serif))
                    .foregroundColor(.blue)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(client.fullName)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                if let phone = client.maskedPhone {
                    Text(phone)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Tier Badge
            ClientTierBadgeView(tier: client.tier)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.appleBorder, lineWidth: 1)
        )
    }
}

