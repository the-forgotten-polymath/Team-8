//
//  SessionManager.swift
//  RSMS_Project
//
//  Created by Antigravity on 01/07/26.
//

import Foundation
import Combine
import Supabase

public final class SessionManager: ObservableObject {
    public static let shared = SessionManager()
    
    @Published public var currentUser: User? = nil
    @Published public var isLoading = true
    @Published public var errorMessage: String? = nil
    
    private let client = SupabaseManager.shared.client
    private let dbService = DatabaseService.shared
    
    private init() {}
    
    @MainActor
    func resolveSession() async {
        isLoading = true
        errorMessage = nil
        do {
            let session = try? await client.auth.session
            
            var resolvedUser: User? = nil
            
            if let authUserId = session?.user.id {
                // 1. Fetch user matching active Supabase auth session
                let response = try await client
                    .from("users")
                    .select()
                    .eq("id", value: authUserId.uuidString)
                    .execute()
                let users = try JSONDecoder.supabaseDecoder.decodeSupabase([User].self, from: response.data)
                resolvedUser = users.first
            }
            
            // 2. Fallback: If no session or user not found, fetch the first available Boutique Manager/Manager profile
            if resolvedUser == nil {
                let roles: [Role] = try await dbService.fetch(from: "roles", as: Role.self)
                if let managerRole = roles.first(where: { $0.roleName.lowercased() == "manager" || $0.roleName.lowercased() == "boutique manager" }) {
                    let response = try await client
                        .from("users")
                        .select()
                        .eq("role_id", value: managerRole.id.uuidString)
                        .limit(1)
                        .execute()
                    let users = try JSONDecoder.supabaseDecoder.decodeSupabase([User].self, from: response.data)
                    resolvedUser = users.first
                }
            }
            
            // 3. Absolute Fallback: Fetch any user if Boutique Manager role fetch failed or table is empty
            if resolvedUser == nil {
                let response = try await client
                    .from("users")
                    .select()
                    .limit(1)
                    .execute()
                let users = try JSONDecoder.supabaseDecoder.decodeSupabase([User].self, from: response.data)
                resolvedUser = users.first
            }
            
            guard var manager = resolvedUser else {
                throw NSError(
                    domain: "SessionManager",
                    code: 404,
                    userInfo: [NSLocalizedDescriptionKey: "No valid user profiles found in the database. Please contact your system administrator."]
                )
            }
            
            // 4. Self-healing: If the resolved manager profile has no store assigned, assign the first available store
            if manager.storeId == nil {
                let stores: [Store] = try await dbService.fetch(from: "stores", as: Store.self)
                if let firstStore = stores.first {
                    manager = manager.copy(storeId: firstStore.id)
                    try await dbService.update(table: "users", value: manager, column: "id", equals: manager.id.uuidString)
                    print("SessionManager: Successfully assigned store \(firstStore.storeName) to user \(manager.fullName)")
                }
            }
            
            self.currentUser = manager
        } catch {
            print("SessionManager Error: \(error)")
            self.errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
