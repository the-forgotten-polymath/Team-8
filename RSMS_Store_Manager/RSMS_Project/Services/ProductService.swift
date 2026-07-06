//
//  ProductService.swift
//  RSMS_Project
//
//  Created by Yatharth Mishra on 30/06/26.
//

import Foundation
import Supabase

final class ProductService {

    private let client = SupabaseManager.shared.client

    func fetchProducts() async throws -> [Product] {

        let response = try await client
            .from("products")
            .select()
            .execute()
        return try JSONDecoder.supabaseDecoder.decodeSupabase([Product].self, from: response.data)
    }
}
