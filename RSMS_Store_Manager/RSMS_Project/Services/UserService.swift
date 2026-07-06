//
//  UserService.swift
//  RSMS_Project
//
//  Created by Yatharth Mishra on 30/06/26.
//

import Foundation
import Supabase

final class UserService {

    private let client = SupabaseManager.shared.client

    func fetchUsers() async throws -> [User] {

        let response = try await client
            .from("users")
            .select()
            .execute()
        return try JSONDecoder.supabaseDecoder.decodeSupabase([User].self, from: response.data)
    }
}
