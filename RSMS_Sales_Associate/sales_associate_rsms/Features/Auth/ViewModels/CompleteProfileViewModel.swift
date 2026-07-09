// CompleteProfileViewModel.swift
import Foundation
import Combine
import Supabase
import SwiftUI

@MainActor
public class CompleteProfileViewModel: ObservableObject {
    @Published public var currentUsername: String
    @Published public var newUsername: String = ""
    @Published public var newPassword: String = ""
    @Published public var confirmPassword: String = ""
    @Published public var isSaving: Bool = false
    @Published public var errorMessage: String? = nil
    
    private let authViewModel: AuthViewModel
    
    public init(authViewModel: AuthViewModel) {
        self.authViewModel = authViewModel
        self.currentUsername = authViewModel.currentUser?.email.split(separator: "@").first.map(String.init) ?? "Unknown"
        // In this system, email prefix might be the original generated username, but let's just fetch it if we had it. 
        // Wait, the true username might not be stored in StaffProfile. We can just leave it blank or show the name.
        self.currentUsername = authViewModel.currentUser?.fullName ?? "Your Account"
    }
    
    public var isValidUsername: Bool {
        let regex = "^[a-zA-Z0-9]{4,30}$"
        let predicate = NSPredicate(format:"SELF MATCHES %@", regex)
        return predicate.evaluate(with: newUsername) && !newUsername.contains(" ")
    }
    
    public var isValidPassword: Bool {
        let regex = "^(?=.*[a-z])(?=.*[A-Z])(?=.*\\d).{8,}$"
        let predicate = NSPredicate(format:"SELF MATCHES %@", regex)
        return predicate.evaluate(with: newPassword)
    }
    
    public var passwordsMatch: Bool {
        return !newPassword.isEmpty && newPassword == confirmPassword
    }
    
    public var canSave: Bool {
        return isValidUsername && isValidPassword && passwordsMatch
    }
    
    public func save() async -> Bool {
        isSaving = true
        errorMessage = nil
        defer { isSaving = false }
        
        guard canSave else {
            errorMessage = "Please ensure all fields are valid."
            return false
        }
        
        guard let userId = authViewModel.currentUser?.id else {
            errorMessage = "No active user session."
            return false
        }
        
        do {
            // 1. Check Username Uniqueness
            struct UserResult: Codable {
                let id: UUID
            }
            
            let existingUsers: [UserResult] = try await supabase
                .from("users")
                .select("id")
                .eq("username", value: newUsername)
                .execute()
                .value
            
            if !existingUsers.isEmpty {
                errorMessage = "Username already exists. Please choose another."
                return false
            }
            
            // Removed Supabase Auth password update as it causes "Auth session missing" if the session isn't synced across modules.
            // We will just update the custom users table below as requested.
            // 3. Update Custom users table
            struct UpdateProfileData: Encodable {
                let username: String
                let password: String
                let profile_verified: Bool
            }
            let updateData = UpdateProfileData(username: newUsername, password: newPassword, profile_verified: true)
            
            try await supabase
                .from("users")
                .update(updateData)
                .eq("id", value: userId.uuidString)
                .execute()
            
            // 4. Update the current session
            await authViewModel.restoreSession()
            
            return true
        } catch {
            errorMessage = "Failed to update profile: \(error.localizedDescription)"
            return false
        }
    }
}
