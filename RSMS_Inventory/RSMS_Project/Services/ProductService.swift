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

        try await client
            .from("products")
            .select()
            .eq("approval_status", value: "Approved")
            .execute()
            .value
    }
}
