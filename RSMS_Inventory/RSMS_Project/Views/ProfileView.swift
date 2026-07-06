//
//  ProfileView.swift
//  RSMS_Project
//
//  Created for UI Refinement
//

import SwiftUI

// MARK: - ProfileView

struct ProfileView: View {
    let userId: UUID
    let warehouseId: UUID
    var onLogout: () -> Void

    @State private var user: User? = nil
    @State private var warehouse: Warehouse? = nil
    @State private var isLoading = true
    @State private var showEditProfile = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {

                    // MARK: - Avatar + Name Hero
                    avatarHero

                    // MARK: - Info Sections
                    VStack(spacing: 16) {

                        // Account Information
                        ProfileSection(title: "Account Information") {
                            if isLoading {
                                loadingRow
                            } else {
                                ProfileRow(
                                    icon: "person.text.rectangle.fill",
                                    iconColor: .blue,
                                    label: "Full Name",
                                    value: user?.fullName ?? "—"
                                )
                                Divider().padding(.leading, 52)
                                ProfileRow(
                                    icon: "person.fill",
                                    iconColor: .purple,
                                    label: "Username",
                                    value: user?.username ?? "—"
                                )
                                Divider().padding(.leading, 52)
                                ProfileRow(
                                    icon: "envelope.fill",
                                    iconColor: .orange,
                                    label: "Email",
                                    value: user?.email ?? "—"
                                )
                                Divider().padding(.leading, 52)
                                ProfileRow(
                                    icon: "location.fill",
                                    iconColor: .teal,
                                    label: "City",
                                    value: warehouse?.city ?? "—"
                                )
                            }
                        }

                        // Account Status
                        ProfileSection(title: "Account Status") {
                            if isLoading {
                                loadingRow
                            } else {
                                HStack(spacing: 14) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color.green.opacity(0.12))
                                            .frame(width: 36, height: 36)
                                        Image(systemName: "checkmark.seal.fill")
                                            .foregroundColor(.green)
                                    }
                                    Text("Verified Account")
                                        .font(.subheadline)
                                        .foregroundColor(.primary)
                                    Spacer()
                                    if user?.isVerified == true {
                                        Text("Active")
                                            .font(.caption)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.green)
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 4)
                                            .background(Color.green.opacity(0.12))
                                            .cornerRadius(8)
                                    }
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                            }
                        }

                        // Sign Out Button
                        Button(action: {
                            dismiss()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                onLogout()
                            }
                        }) {
                            HStack(spacing: 10) {
                                Image(systemName: "rectangle.portrait.and.arrow.right")
                                    .font(.headline)
                                Text("Sign Out")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                LinearGradient(
                                    colors: [Color.red.opacity(0.85), Color.red],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(14)
                            .shadow(color: Color.red.opacity(0.25), radius: 8, y: 4)
                        }
                        .padding(.horizontal)
                        .padding(.top, 8)
                        .padding(.bottom, 32)
                    }
                    .padding(.top, 20)
                }
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle("My Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Edit") {
                        showEditProfile = true
                    }
                    .fontWeight(.semibold)
                    .disabled(isLoading)
                }
            }
            .sheet(isPresented: $showEditProfile) {
                if let currentUser = user {
                    EditProfileView(user: currentUser, warehouseCity: warehouse?.city ?? "—")
                }
            }
            .task {
                await loadProfileData()
            }
        }
    }

    // MARK: - Subviews

    private var avatarHero: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.blue.opacity(0.8), Color.blue.opacity(0.4)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 96, height: 96)

                Image(systemName: "person.fill")
                    .font(.system(size: 44))
                    .foregroundColor(.white)
            }
            .shadow(color: Color.blue.opacity(0.3), radius: 12, y: 4)

            VStack(spacing: 4) {
                if isLoading {
                    ProgressView()
                        .padding(.top, 4)
                } else {
                    Text(user?.fullName ?? "Inventory Manager")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)

                    Text("Inventory Manager")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                }
            }
        }
        .padding(.vertical, 32)
        .frame(maxWidth: .infinity)
        .background(Color(UIColor.secondarySystemGroupedBackground))
    }

    private var loadingRow: some View {
        HStack {
            Spacer()
            ProgressView()
            Spacer()
        }
        .padding()
    }

    // MARK: - Data Loading

    private func loadProfileData() async {
        isLoading = true
        do {
            let users = try await UserService().fetchUsers()
            self.user = users.first(where: { $0.id == userId })

            let warehouses = try await WarehouseService.shared.fetchWarehouses()
            self.warehouse = warehouses.first(where: { $0.id == warehouseId })
                ?? warehouses.first
        } catch {
            print("ProfileView: Failed to load profile data: \(error)")
        }
        isLoading = false
    }
}

// MARK: - EditProfileView

struct EditProfileView: View {
    let user: User
    let warehouseCity: String

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                // Personal Information
                Section {
                    EditProfileReadOnlyRow(label: "Full Name", value: user.fullName)
                    EditProfileReadOnlyRow(label: "Username", value: user.username)
                    EditProfileReadOnlyRow(label: "Email", value: user.email ?? "—")
                    EditProfileReadOnlyRow(label: "City", value: warehouseCity)
                } header: {
                    Text("Personal Information")
                } footer: {
                    HStack(spacing: 6) {
                        Image(systemName: "lock.fill")
                            .font(.caption2)
                        Text("Profile details are managed by your system administrator. Contact your admin to request any changes.")
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)
                }

                // Account
                Section(header: Text("Account")) {
                    EditProfileReadOnlyRow(label: "Role", value: "Inventory Manager")
                    LabeledContent("Account Status") {
                        if user.isVerified {
                            Label("Verified", systemImage: "checkmark.seal.fill")
                                .font(.subheadline)
                                .foregroundColor(.green)
                        } else {
                            Text("Unverified")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
        }
    }
}

// MARK: - EditProfileReadOnlyRow

private struct EditProfileReadOnlyRow: View {
    let label: String
    let value: String

    var body: some View {
        LabeledContent(label) {
            Text(value)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.trailing)
        }
    }
}

// MARK: - Helper Components

private struct ProfileSection<Content: View>: View {
    let title: String
    let content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .font(.footnote)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
                .textCase(.uppercase)
                .tracking(0.5)
                .padding(.horizontal, 20)
                .padding(.bottom, 8)

            VStack(spacing: 0) {
                content
            }
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.appleBorder, lineWidth: 1)
            )
            .padding(.horizontal)
        }
    }
}

private struct ProfileRow: View {
    let icon: String
    let iconColor: Color
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(iconColor.opacity(0.12))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .foregroundColor(iconColor)
                    .font(.system(size: 15))
            }

            VStack(alignment: .leading, spacing: 1) {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.subheadline)
                    .foregroundColor(.primary)
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}
