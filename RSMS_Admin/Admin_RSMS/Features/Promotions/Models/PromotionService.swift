//
//  PromotionService.swift
//  Admin_RSMS
//
//  Created by Yatharth Mishra on 03/07/26.
//
import Foundation
import Supabase
import Combine

@MainActor
final class PromotionService: ObservableObject {

    static let shared = PromotionService()

    // MARK: - Published State

    @Published var promotions: [AdminPromotion] = []
    @Published var categories: [Category] = []
    @Published var stores: [AdminStore] = []

    @Published var isLoading = false
    @Published var errorMessage: String?

    private let client = SupabaseManager.shared.client

    private init() {}

    // MARK: - Promotions

    @discardableResult
    func fetchPromotions() async -> [AdminPromotion] {

        isLoading = true
        errorMessage = nil

        defer {
            isLoading = false
        }

        do {
            let result: [AdminPromotion] = try await client
                .from("promotions")
                .select()
                .order("created_at", ascending: false)
                .execute()
                .value

            promotions = result
            return result

        } catch {
            errorMessage = "Failed to load promotions."
            print("❌ Promotion fetch error:", error)
            return []
        }
    }

    // MARK: - Picker Data

    func fetchPickerData() async {

        do {

            async let categoryRequest: [Category] = client
                .from("categories")
                .select()
                .order("category_name")
                .execute()
                .value

            async let storeRequest: [AdminStore] = client
                .from("stores")
                .select()
                .order("name")
                .execute()
                .value

            categories = try await categoryRequest
            stores = try await storeRequest

        } catch {
            errorMessage = "Failed to load stores and categories."
            print("❌ Picker data fetch error:", error)
        }
    }

    // MARK: - Create Promotion

    @discardableResult
    func addPromotion(_ promotion: AdminPromotion) async -> Bool {

        do {

            let payload = AdminPromotionPayload(from: promotion)

            try await client
                .from("promotions")
                .insert(payload)
                .execute()

            // Invoke email edge function for creation
            struct PromoEmailPayload: Encodable {
                let promotionId: UUID
                let storeIds: [UUID]?
                let appliesToAllStores: Bool
                let sendOnDate: String?
            }
            
            // 1. Send immediately
            let immediatePayload = PromoEmailPayload(
                promotionId: promotion.id,
                storeIds: promotion.storeIds,
                appliesToAllStores: promotion.appliesToAllStores,
                sendOnDate: nil
            )
            _ = try? await client.functions.invoke("send-promotion-email", options: FunctionInvokeOptions(body: immediatePayload))
            
            // 2. Schedule for start date
            let scheduledPayload = PromoEmailPayload(
                promotionId: promotion.id,
                storeIds: promotion.storeIds,
                appliesToAllStores: promotion.appliesToAllStores,
                sendOnDate: promotion.startDate
            )
            _ = try? await client.functions.invoke("send-promotion-email", options: FunctionInvokeOptions(body: scheduledPayload))

            await fetchPromotions()

            return true

        } catch {
            errorMessage = "Failed to create promotion."
            print("❌ Create promotion error:", error)
            return false
        }
    }

    // MARK: - Update Promotion

    @discardableResult
    func updatePromotion(_ promotion: AdminPromotion) async -> Bool {

        do {

            let payload = AdminPromotionPayload(from: promotion)

            try await client
                .from("promotions")
                .update(payload)
                .eq("id", value: promotion.id.uuidString)
                .execute()

            await fetchPromotions()

            return true

        } catch {
            errorMessage = "Failed to update promotion."
            print("❌ Update promotion error:", error)
            return false
        }
    }

    // MARK: - Delete Promotion

    @discardableResult
    func deletePromotion(_ promotion: AdminPromotion) async -> Bool {

        do {

            try await client
                .from("promotions")
                .delete()
                .eq("id", value: promotion.id.uuidString)
                .execute()

            await fetchPromotions()

            return true

        } catch {
            errorMessage = "Failed to delete promotion."
            print("❌ Delete promotion error:", error)
            return false
        }
    }

    // MARK: - Banner Upload

    func uploadBannerImage(
        data: Data,
        promotionId: String
    ) async -> String? {

        // Using "store-images" bucket instead of "promotion-banners"
        // as a workaround for the RLS policy restrictions on the new bucket.
        let fileName = "promo_\(promotionId).jpg"
        let bucket = "store-images"

        do {
            // First, try to remove the existing file (if any) to avoid upsert RLS issues
            _ = try? await client.storage
                .from(bucket)
                .remove(paths: [fileName])

            _ = try await client.storage
                .from(bucket)
                .upload(
                    fileName,
                    data: data,
                    options: FileOptions(
                        contentType: "image/jpeg",
                        upsert: false
                    )
                )

            let publicURL = try client.storage
                .from(bucket)
                .getPublicURL(path: fileName)

            return publicURL.absoluteString

        } catch {
            print("❌ Banner upload error:", error)
            return nil
        }
    }
}
