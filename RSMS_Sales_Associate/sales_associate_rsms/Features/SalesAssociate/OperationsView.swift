// OperationsView.swift
// RSMS — Sales Associate Module

import SwiftUI

struct OperationsView: View {
    @EnvironmentObject private var authVM: AuthViewModel
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Clean title without subtitle and profile avatar
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Operations")
                                .font(.system(size: 32, weight: .bold, design: .default))
                                .foregroundColor(.primary)
                        }
                        .padding(.horizontal)
                        .padding(.top)

                        // Vertical stack of 4 operation options
                        VStack(spacing: 16) {
                            
                            // 1. Client Hub
                            NavigationLink(destination: ClientHubView(isEmbedded: true)) {
                                OperationCard(
                                    title: "Client Hub",
                                    subtitle: "Profiles & Twin",
                                    systemImage: "person.2.fill",
                                    iconColor: .blue
                                )
                            }
                            
                            // 2. Appointments
                            NavigationLink(destination: AppointmentsView(isEmbedded: true)) {
                                OperationCard(
                                    title: "Appointments",
                                    subtitle: "Schedule & Tasks",
                                    systemImage: "calendar",
                                    iconColor: .orange
                                )
                            }
                            
                            // 3. Fulfillment
                            NavigationLink(destination: OmnichannelView(isEmbedded: true)) {
                                OperationCard(
                                    title: "Fulfillment",
                                    subtitle: "BOPIS & SFS",
                                    systemImage: "shippingbox.fill",
                                    iconColor: .green
                                )
                            }
                            
                            // 4. Checkout
                            NavigationLink(destination: CheckoutView(isEmbedded: true)) {
                                OperationCard(
                                    title: "Checkout",
                                    subtitle: "Cart & Tender",
                                    systemImage: "creditcard.fill",
                                    iconColor: .blue
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct OperationCard: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let iconColor: Color
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(iconColor.opacity(0.12))
                    .frame(width: 52, height: 52)
                
                Image(systemName: systemImage)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(iconColor)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 18, weight: .bold, design: .default))
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.system(size: 13, weight: .regular, design: .default))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(Color(.systemGray3))
                .padding(.trailing, 4)
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 16)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.appleBorder, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 4)
    }
}

struct ProfileView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(Color.blue.opacity(0.12))
                                .frame(width: 60, height: 60)
                            Text(authVM.userFullName.initials)
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(.blue)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(authVM.userFullName)
                                .font(.headline)
                            Text(authVM.currentUser?.role.rawValue ?? "Sales Associate")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                Section(header: Text("Account Details")) {
                    HStack {
                        Text("Email")
                        Spacer()
                        Text(authVM.currentUser?.email ?? "Not logged in")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Contact No")
                        Spacer()
                        Text("+91 98765 43210")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("User ID")
                        Spacer()
                        Text(authVM.currentUser?.id.uuidString ?? UUID().uuidString)
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                }
                
                Section(header: Text("Actions")) {
                    NavigationLink(destination: Text("Mock Order History").font(.headline).padding()) {
                        Label("Orders", systemImage: "cart.fill")
                    }
                    
                    NavigationLink(destination: Text("Mock Activity History").font(.headline).padding()) {
                        Label("History", systemImage: "clock.fill")
                    }
                    
                    NavigationLink(destination: Text("Mock App Settings").font(.headline).padding()) {
                        Label("Settings", systemImage: "gearshape.fill")
                    }
                }
                
                Section {
                    Button(role: .destructive, action: {
                        dismiss()
                        Task {
                            await authVM.logout()
                        }
                    }) {
                        Text("Log Out")
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    OperationsView()
        .environmentObject(AuthViewModel())
}
