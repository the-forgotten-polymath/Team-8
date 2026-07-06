// AuthViewModel.swift
// RSMS — Sales Associate Module
// Handles authentication state, login, logout, and current user profile

import Foundation
import Combine
import SwiftUI
import Supabase

@MainActor
public class AuthViewModel: ObservableObject {

    // MARK: - Published State

    @Published public var isAuthenticated: Bool = false
    @Published public var currentUser: StaffProfile? = nil
    @Published public var isLoading: Bool = false
    @Published public var errorMessage: String? = nil

    // MARK: - Computed Properties

    public var userRole: StaffRole { currentUser?.role ?? .salesAssociate }
    public var userFullName: String { currentUser?.fullName ?? "Associate" }
    public var userStoreID: UUID? { currentUser?.storeID }

    // MARK: - Init

    public init() {
        Task {
            await restoreSession()
        }
    }

    // MARK: - Session Restore

    func restoreSession() async {
        isLoading = true
        defer { isLoading = false }
        
        if AppConstants.useMockData {
            currentUser = MockData.staffProfile
            isAuthenticated = true
            return
        }
        
        do {
            let session = try await supabase.auth.session
            if session.user.id != UUID() {
                await loadProfile(for: session.user.id)
            }
        } catch {
            // No active session — show login
            isAuthenticated = false
        }
    }

    // MARK: - Login

    func login(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        if AppConstants.useMockData {
            currentUser = MockData.staffProfile
            isAuthenticated = true
            return
        }
        
        do {
            let session = try await supabase.auth.signIn(email: email, password: password)
            await loadProfile(for: session.user.id)
        } catch {
            errorMessage = "Login failed. Please check your credentials."
        }
    }

    // MARK: - Logout

    func logout() async {
        isLoading = true
        defer { isLoading = false }
        do {
            try await supabase.auth.signOut()
            currentUser = nil
            isAuthenticated = false
        } catch {
            errorMessage = "Logout failed. Please try again."
        }
    }

    // MARK: - Load Profile

    private func loadProfile(for userID: UUID) async {
        do {
            let profile: StaffProfile = try await supabase
                .from("profiles")
                .select()
                .eq("id", value: userID.uuidString)
                .single()
                .execute()
                .value
            currentUser = profile
            isAuthenticated = true
        } catch {
            errorMessage = "Failed to load your profile. Please contact your manager."
            isAuthenticated = false
        }
    }
}
