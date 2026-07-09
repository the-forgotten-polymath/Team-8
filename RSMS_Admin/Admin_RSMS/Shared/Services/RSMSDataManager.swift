// RSMSDataManager.swift
// Admin_RSMS
//
// Central data manager — real-time Supabase reads, writes, and realtime
// subscriptions. Uses SupabaseManager.shared.client directly via the
// Services layer. Models: AdminStore (StoreModel.swift), Manager
// (ManagerModel.swift), Role (Models/Role.swift).
//

import Foundation
import SwiftUI
import Combine
import Supabase

// ─────────────────────────────────────────────────────────────────
// MARK: – AppUser payload (used when inserting a new user into `users` table)
// Matches the SRS `User` model columns subset required for creation.
// Full model is in Models/User.swift.
// ─────────────────────────────────────────────────────────────────
struct AppUser: Encodable {
    let id:         UUID
    let fullName:   String
    let username:   String
    let password:   String
    let email:      String
    let roleId:     UUID
    let storeId:    UUID?
    let designation: String?
    let createdBy:  UUID?
    let employeeStatus: String?

    enum CodingKeys: String, CodingKey {
        case id
        case fullName       = "full_name"
        case username
        case password
        case email
        case roleId         = "role_id"
        case storeId        = "store_id"
        case designation    = "designation"
        case createdBy      = "created_by"
        case employeeStatus = "employee_status"
    }
}

@MainActor
class RSMSDataManager: ObservableObject {

    static let shared = RSMSDataManager()

    // ── Published state ───────────────────────────────────────────
    @Published var stores:       [AdminStore]   = []
    @Published var managers: [Manager]  = []
    @Published var products: [Product]  = []
    @Published var targets: [RevenueTarget] = []
    @Published var categories: [Category] = []
    @Published var inventory: [InventoryItem] = []
    @Published var isLoading:    Bool           = false
    @Published var errorMessage: String?        = nil

    // Supabase client — single source of truth via SupabaseManager
    private let client = SupabaseManager.shared.client

    // Private realtime channel references
    private var storeChannel: RealtimeChannelV2?
    private var managerChannel: RealtimeChannelV2?
    private var productChannel: RealtimeChannelV2?
    
    // ─────────────────────────────────────────────────────────────
    // MARK: – TARGETS: Local Management (No Supabase yet)
    // ─────────────────────────────────────────────────────────────
    struct InsertStoreTarget: Codable {
        let store_id: UUID
        let target_month: Date
        let revenue_target: Double
    }

    @discardableResult
    func fetchTargets() async -> [RevenueTarget] {
        do {
            let result: [StoreTarget] = try await client
                .from("store_targets")
                .select()
                .execute()
                .value
                
            let grouped = Dictionary(grouping: result, by: { "\($0.targetMonth.timeIntervalSince1970)_\($0.revenueTarget)" })
            
            let mappedTargets = grouped.map { (key, group) -> RevenueTarget in
                let first = group.first!
                return RevenueTarget(
                    id: UUID(),
                    name: "Target for \(first.targetMonth.formatted(.dateTime.month(.wide).year()))",
                    amount: first.revenueTarget,
                    period: .monthly,
                    assignedStoreIDs: group.compactMap { $0.storeId },
                    startDate: first.targetMonth,
                    endDate: Calendar.current.date(byAdding: .month, value: 1, to: first.targetMonth) ?? first.targetMonth
                )
            }
            .sorted(by: { $0.startDate > $1.startDate })
            
            DispatchQueue.main.async {
                self.targets = mappedTargets
            }
            return mappedTargets
        } catch {
            print("[RSMS] fetchTargets error: \(error)")
            return []
        }
    }

    func addTarget(_ target: RevenueTarget) async throws {
        let inserts = target.assignedStoreIDs.map {
            InsertStoreTarget(store_id: $0, target_month: target.startDate, revenue_target: target.amount)
        }
        try await client
            .from("store_targets")
            .insert(inserts)
            .execute()
        await fetchTargets()
    }
    
    func updateTarget(oldTarget: RevenueTarget, newTarget: RevenueTarget) async throws {
        try await removeTarget(oldTarget)
        try await addTarget(newTarget)
    }
    
    func removeTarget(_ target: RevenueTarget) async throws {
        for storeId in target.assignedStoreIDs {
            try await client
                .from("store_targets")
                .delete()
                .eq("store_id", value: storeId)
                .eq("target_month", value: target.startDate)
                .eq("revenue_target", value: target.amount)
                .execute()
        }
        await fetchTargets()
    }

    // ─────────────────────────────────────────────────────────────
    // MARK: – Init: load data & start realtime
    // ─────────────────────────────────────────────────────────────
    private init() {
        Task {
            await fetchAll()
            await subscribeToRealtime()
        }
    }

    // ─────────────────────────────────────────────────────────────
    // MARK: – Fetch everything on launch
    // ─────────────────────────────────────────────────────────────
    func fetchAll() async {
        isLoading = true
        errorMessage = nil
        async let s = fetchStores()
        async let m = fetchManager()
        async let p = fetchProducts()
        async let t = fetchTargets()
        async let c = fetchCategories()
        async let i = fetchInventory()
        _ = await (s, m, p, t, c, i)
        calculateStoreCategoryQuantities()
        isLoading = false
    }

    // ─────────────────────────────────────────────────────────────
    // MARK: – STORES: Fetch
    // ─────────────────────────────────────────────────────────────
    @discardableResult
    func fetchStores() async -> [AdminStore] {
        do {
            let result: [AdminStore] = try await client
                .from("stores")
                .select("*, store_categories(category_id)")
                .order("name")
                .execute()
                .value
            stores = result
            calculateStoreCategoryQuantities()
            return result
        } catch {
            errorMessage = "Failed to load stores: \(error.localizedDescription)"
            print("[RSMS] fetchStores error: \(error)")
            return []
        }
    }

    // ─────────────────────────────────────────────────────────────
    // MARK: – PRODUCTS: Fetch
    // ─────────────────────────────────────────────────────────────
    @discardableResult
    func fetchProducts() async -> [Product] {
        do {
            let result: [Product] = try await client
                .from("products")
                .select()
                .order("product_name")
                .execute()
                .value
            products = result
            return result
        } catch {
            errorMessage = "Failed to load products: \(error.localizedDescription)"
            print("[RSMS] fetchProducts error: \(error)")
            return []
        }
    }
    
    // ─────────────────────────────────────────────────────────────
    // MARK: – CATEGORIES: Fetch
    // ─────────────────────────────────────────────────────────────
    @discardableResult
    func fetchCategories() async -> [Category] {
        do {
            let result: [Category] = try await client
                .from("categories")
                .select()
                .order("category_name")
                .execute()
                .value
            categories = result
            return result
        } catch {
            errorMessage = "Failed to load categories: \(error.localizedDescription)"
            print("[RSMS] fetchCategories error: \(error)")
            return []
        }
    }
    
    // ─────────────────────────────────────────────────────────────
    // MARK: – INVENTORY: Fetch
    // ─────────────────────────────────────────────────────────────
    @discardableResult
    func fetchInventory() async -> [InventoryItem] {
        do {
            let result: [InventoryItem] = try await client
                .from("inventory")
                .select()
                .execute()
                .value
            inventory = result
            calculateStoreCategoryQuantities()
            return result
        } catch {
            errorMessage = "Failed to load inventory: \(error.localizedDescription)"
            print("[RSMS] fetchInventory error: \(error)")
            return []
        }
    }
    
    // ─────────────────────────────────────────────────────────────
    // MARK: – CALCULATE STORE QUANTITIES
    // ─────────────────────────────────────────────────────────────
    func calculateStoreCategoryQuantities() {
        var updatedStores = stores
        for i in updatedStores.indices {
            let storeId = updatedStores[i].id
            let storeInventory = inventory.filter { $0.storeId == storeId }
            
            var catQuantities: [UUID: Int] = [:]
            for item in storeInventory {
                if let product = products.first(where: { $0.id == item.productId }),
                   let catId = product.categoryId {
                    // Average quantity per category (or just take the first we see)
                    catQuantities[catId] = item.quantity
                }
            }
            updatedStores[i].categoryQuantities = catQuantities
        }
        stores = updatedStores
    }

    // ─────────────────────────────────────────────────────────────
    // MARK: – STORES: Add
    // ─────────────────────────────────────────────────────────────
    func addStore(_ store: AdminStore) {
        Task {
            do {
                var finalStore = store
                // Upload image if present
                if let data = store.imageData {
                    if let url = try? await uploadStoreImage(data: data, storeId: store.id.uuidString) {
                        finalStore.imageUrl = url
                    }
                }
                
                let payload = AdminStorePayload(from: finalStore)
                let inserted: [AdminStore] = try await client
                    .from("stores")
                    .insert(payload)
                    .select()
                    .execute()
                    .value
                if let newStore = inserted.first {
                    if let catQuantities = finalStore.categoryQuantities, !catQuantities.isEmpty {
                        let rels = catQuantities.map { ["store_id": newStore.id.uuidString, "category_id": $0.key.uuidString] }
                        try await client.from("store_categories").insert(rels).execute()
                        await pushInventoryForStore(storeId: newStore.id, quantities: catQuantities)
                    }
                    stores.append(newStore)
                    assignManagerIfNeeded(for: newStore)
                }
            } catch {
                errorMessage = "Failed to add store: \(error.localizedDescription)"
                print("[RSMS] addStore error: \(error)")
            }
        }
    }

    // ─────────────────────────────────────────────────────────────
    // MARK: – STORES: Update
    // ─────────────────────────────────────────────────────────────
    func updateStore(_ store: AdminStore) {
        Task {
            do {
                var finalStore = store
                if let data = store.imageData {
                    if let url = try? await uploadStoreImage(data: data, storeId: store.id.uuidString) {
                        finalStore.imageUrl = url
                    }
                }
                
                let payload = AdminStorePayload(from: finalStore)
                let updated: [AdminStore] = try await client
                    .from("stores")
                    .update(payload)
                    .eq("id", value: store.id.uuidString)
                    .select()
                    .execute()
                    .value
                if let updatedStore = updated.first {
                    if let catQuantities = finalStore.categoryQuantities, !catQuantities.isEmpty {
                        try await client.from("store_categories").delete().eq("store_id", value: store.id.uuidString).execute()
                        let rels = catQuantities.map { ["store_id": updatedStore.id.uuidString, "category_id": $0.key.uuidString] }
                        try await client.from("store_categories").insert(rels).execute()
                        await pushInventoryForStore(storeId: updatedStore.id, quantities: catQuantities)
                    }
                    if let idx = stores.firstIndex(where: { $0.id == store.id }) {
                        stores[idx] = updatedStore
                    }
                }
            } catch {
                errorMessage = "Failed to update store: \(error.localizedDescription)"
                print("[RSMS] updateStore error: \(error)")
            }
        }
    }

    // ─────────────────────────────────────────────────────────────
    // MARK: – STORES: Soft-delete (archive)
    // ─────────────────────────────────────────────────────────────
    func removeStore(_ store: AdminStore) {
        Task {
            do {
                var archived = store
                archived.isArchived = true
                let payload = AdminStorePayload(from: archived)
                let updated: [AdminStore] = try await client
                    .from("stores")
                    .update(payload)
                    .eq("id", value: store.id.uuidString)
                    .select()
                    .execute()
                    .value
                if let updatedStore = updated.first,
                   let idx = stores.firstIndex(where: { $0.id == store.id }) {
                    stores[idx] = updatedStore
                }
            } catch {
                errorMessage = "Failed to archive store: \(error.localizedDescription)"
                print("[RSMS] removeStore error: \(error)")
            }
        }
    }

    // ─────────────────────────────────────────────────────────────
    // MARK: – STORAGE: Upload Image
    // ─────────────────────────────────────────────────────────────
    private func uploadStoreImage(data: Data, storeId: String) async throws -> String? {
        let fileName = "\(storeId).jpg"
        let bucket = "store-images"
        
        do {
            _ = try await client.storage
                .from(bucket)
                .upload(
                    fileName,
                    data: data,
                    options: FileOptions(contentType: "image/jpeg", upsert: true)
                )
            
            let publicUrl = try client.storage.from(bucket).getPublicURL(path: fileName)
            return publicUrl.absoluteString
        } catch {
            print("[RSMS] Image upload failed: \(error)")
            throw error
        }
    }

    // ─────────────────────────────────────────────────────────────
    // MARK: – STAFF: Fetch
    // ─────────────────────────────────────────────────────────────
    @discardableResult
    func fetchManager() async -> [Manager] {
        do {
            struct UserWithRole: Decodable {
                let id: UUID
                let full_name: String
                let email: String?
                let employee_status: String?
                let profile_image_url: String?
                let store_id: UUID?
                let designation: String?
                
                struct RoleData: Decodable {
                    let role_name: String
                }
                let roles: RoleData?
            }
            
            let result: [UserWithRole] = try await client
                .from("users")
                .select("id, full_name, email, employee_status, profile_image_url, store_id, designation, roles(role_name)")
                .execute()
                .value
            
            let fetchedManagers = result.compactMap { user -> Manager? in
                let roleName = user.roles?.role_name ?? "Unknown"
                let lowerRole = roleName.lowercased()
                guard lowerRole.contains("manager") else { return nil }
                
                let storeName = self.stores.first(where: { $0.id == user.store_id })?.name ?? "Unassigned"
                let isArchived = user.employee_status?.lowercased() == "inactive"
                let initials = String(user.full_name.prefix(2)).uppercased()
                
                return Manager(
                    id: user.id,
                    name: user.full_name,
                    email: user.email ?? "",
                    role: roleName,
                    location: storeName,
                    shift: user.designation ?? "Morning",
                    imageName: user.profile_image_url,
                    initials: initials,
                    isArchived: isArchived
                )
            }
            
            self.managers = fetchedManagers.sorted { $0.name < $1.name }
            return self.managers
        } catch {
            errorMessage = "Failed to load manager: \(error.localizedDescription)"
            print("[RSMS] fetchManager error: \(error)")
            return []
        }
    }

    // ─────────────────────────────────────────────────────────────
    // MARK: – STAFF: Add
    // Uses Role from Models/Role.swift for the role lookup.
    // ─────────────────────────────────────────────────────────────
    func addManager(_ member: Manager) {
        Task {
            do {
                if isManagerRole(member.role) {
                    // 1. Fetch matching role using Models/Role.swift (role_name column)
                    let roles: [Role] = try await client
                        .from("roles")
                        .select()
                        .ilike("role_name", pattern: "%\(member.role)%")
                        .execute()
                        .value
                    
                    if let role = roles.first {
                        // 2. Generate random 8-character secure password
                        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*"
                        let randomPassword = String((0..<8).map { _ in letters.randomElement()! })
                        
                        // 3. Find the store to get store_id
                        let store = self.stores.first(where: { $0.name == member.location })
                        
                        let generatedUsername = member.email.split(separator: "@").first.map(String.init)?.lowercased() ?? String(member.name.prefix(6)).lowercased()
                        
                        // 4. Insert into users table using AppUser payload
                        let newUser = AppUser(
                            id: UUID(),
                            fullName: member.name,
                            username: generatedUsername.replacingOccurrences(of: ".", with: ""),
                            password: randomPassword,
                            email: member.email,
                            roleId: role.id,
                            storeId: store?.id,
                            designation: "Manager",
                            createdBy: AuthManager.shared.currentUser?.id,
                            employeeStatus: "Active"
                        )
                        
                        _ = try await client
                            .from("users")
                            .insert(newUser)
                            .execute()
                            
                        // 4. Trigger send-credentials edge function
                        let emailParams = [
                            "userEmail": member.email,
                            "userName": member.name,
                            "username": newUser.username,
                            "password": randomPassword,
                            "role": member.role
                        ]
                        
                        do {
                            _ = try await client.functions.invoke(
                                "send-credentials",
                                options: FunctionInvokeOptions(body: emailParams)
                            )
                        } catch {
                            print("[RSMS] Warning: Failed to call edge function: \(error)")
                            print("[RSMS] DEBUG: Generated Password for \(member.email) is \(randomPassword)")
                        }
                    } else {
                        print("[RSMS] Warning: Could not find role_id for role: \(member.role)")
                    }
                }
                
                let payload = ManagerPayload(from: member)
                let inserted: [Manager] = try await client
                    .from("staff_members")
                    .insert(payload)
                    .select()
                    .execute()
                    .value
                if let newMember = inserted.first {
                    managers.append(newMember)
                    await syncManagerToStore(member: newMember)
                }
            } catch {
                errorMessage = "Failed to add manager member: \(error.localizedDescription)"
                print("[RSMS] addManager error: \(error)")
            }
        }
    }

    // ─────────────────────────────────────────────────────────────
    // MARK: – STAFF: Update
    // ─────────────────────────────────────────────────────────────
    func updateManager(_ member: Manager) {
        Task {
            do {
                let oldMember = managers.first(where: { $0.id == member.id })
                let storeId = self.stores.first(where: { $0.name == member.location })?.id
                let isArchived = member.isArchived ? "Inactive" : "Active"
                
                struct UserUpdate: Encodable {
                    let email: String
                    let fullName: String
                    let storeId: UUID?
                    let designation: String
                    let employeeStatus: String
                    
                    enum CodingKeys: String, CodingKey {
                        case email
                        case fullName = "full_name"
                        case storeId = "store_id"
                        case designation = "designation"
                        case employeeStatus = "employee_status"
                    }
                }
                
                let userUpdate = UserUpdate(
                    email: member.email,
                    fullName: member.name,
                    storeId: storeId,
                    designation: member.shift,
                    employeeStatus: isArchived
                )
                
                _ = try await client
                    .from("users")
                    .update(userUpdate)
                    .eq("id", value: member.id.uuidString)
                    .execute()
                
                if let idx = managers.firstIndex(where: { $0.id == member.id }) {
                    managers[idx] = member
                    if let old = oldMember, old.location != member.location {
                        await unassignManagerFromStore(location: old.location, managerName: old.name)
                    }
                    await syncManagerToStore(member: member)
                }
            } catch {
                errorMessage = "Failed to update manager member: \(error.localizedDescription)"
                print("[RSMS] updateManager error: \(error)")
            }
        }
    }

    // ─────────────────────────────────────────────────────────────
    // MARK: – STAFF: Soft-delete (archive)
    // ─────────────────────────────────────────────────────────────
    func removeManager(_ member: Manager) {
        Task {
            do {
                var archived = member
                archived.isArchived = true
                
                struct UserStatusUpdate: Encodable {
                    let employeeStatus: String
                    enum CodingKeys: String, CodingKey {
                        case employeeStatus = "employee_status"
                    }
                }
                
                _ = try await client
                    .from("users")
                    .update(UserStatusUpdate(employeeStatus: "Inactive"))
                    .eq("id", value: member.id.uuidString)
                    .execute()
                
                if let idx = managers.firstIndex(where: { $0.id == member.id }) {
                    managers[idx] = archived
                    await unassignManagerFromStore(location: member.location, managerName: member.name)
                }
            } catch {
                errorMessage = "Failed to archive manager member: \(error.localizedDescription)"
                print("[RSMS] removeManager error: \(error)")
            }
        }
    }

    // ─────────────────────────────────────────────────────────────
    // MARK: – Manager ↔ Store sync helpers
    // ─────────────────────────────────────────────────────────────
    private func isManagerRole(_ role: String) -> Bool {
        let lower = role.lowercased()
        return lower.contains("manager") || lower.contains("admin") || lower.contains("lead")
    }

    private func assignManagerIfNeeded(for store: AdminStore) {
        // Called after a store is added; no-op here since manager is set on save
    }

    private func syncManagerToStore(member: Manager) async {
        guard isManagerRole(member.role) else { return }
        guard let storeIdx = stores.firstIndex(where: {
            $0.name.localizedCaseInsensitiveCompare(member.location) == .orderedSame
        }) else { return }

        var updatedStore = stores[storeIdx]
        updatedStore.managerName     = member.name
        updatedStore.managerInitials = member.initials

        do {
            let payload = AdminStorePayload(from: updatedStore)
            let result: [AdminStore] = try await client
                .from("stores")
                .update(payload)
                .eq("id", value: updatedStore.id.uuidString)
                .select()
                .execute()
                .value
            if let s = result.first {
                stores[storeIdx] = s
            }
        } catch {
            print("[RSMS] syncManagerToStore error: \(error)")
        }
    }

    private func unassignManagerFromStore(location: String, managerName: String) async {
        guard let storeIdx = stores.firstIndex(where: {
            $0.name.localizedCaseInsensitiveCompare(location) == .orderedSame &&
            $0.managerName == managerName
        }) else { return }

        var updatedStore = stores[storeIdx]
        updatedStore.managerName     = "Unassigned"
        updatedStore.managerInitials = "--"

        do {
            let payload = AdminStorePayload(from: updatedStore)
            let result: [AdminStore] = try await client
                .from("stores")
                .update(payload)
                .eq("id", value: updatedStore.id.uuidString)
                .select()
                .execute()
                .value
            if let s = result.first {
                stores[storeIdx] = s
            }
        } catch {
            print("[RSMS] unassignManagerFromStore error: \(error)")
        }
    }

    // ─────────────────────────────────────────────────────────────
    // MARK: – Realtime subscriptions (live updates across devices)
    // ─────────────────────────────────────────────────────────────
    private func subscribeToRealtime() async {
        // ── Stores channel ────────────────────────────────────────
        let storesCh = client.realtimeV2.channel("stores-changes")
        let storesChanges = storesCh.postgresChange(
            AnyAction.self,
            schema: "public",
            table:  "stores"
        )
        try? await storesCh.subscribeWithError()
        storeChannel = storesCh

        Task {
            for await _ in storesChanges {
                await fetchStores()
            }
        }

        // ── Manager channel ─────────────────────────────────────────
        let managerCh = client.realtimeV2.channel("users-manager-changes")
        let managerChanges = managerCh.postgresChange(
            AnyAction.self,
            schema: "public",
            table:  "users"
        )
        try? await managerCh.subscribeWithError()
        managerChannel = managerCh

        Task {
            for await _ in managerChanges {
                await fetchManager()
            }
        }
        
        // ── Products channel ────────────────────────────────────────
        let productCh = client.realtimeV2.channel("products-changes")
        let productChanges = productCh.postgresChange(
            AnyAction.self,
            schema: "public",
            table:  "products"
        )
        try? await productCh.subscribeWithError()
        productChannel = productCh

        Task {
            for await _ in productChanges {
                await fetchProducts()
            }
        }
    }
    
    // ─────────────────────────────────────────────────────────────
    // MARK: – INVENTORY: Bulk Push
    // ─────────────────────────────────────────────────────────────
    private func pushInventoryForStore(storeId: UUID, quantities: [UUID: Int]) async {
        do {
            // Find products matching the selected categories
            let matchingProducts = products.filter { product in
                guard let catId = product.categoryId else { return false }
                return quantities.keys.contains(catId)
            }
            
            var inventoryPayloads: [InventoryPayload] = []
            
            for product in matchingProducts {
                guard let catId = product.categoryId else { continue }
                let qty = quantities[catId] ?? 1
                let payload = InventoryPayload(
                    productId: product.id,
                    storeId: storeId,
                    locationType: "Store",
                    quantity: qty,
                    reorderLevel: Int(Double(qty) * 0.2) // simple 20% reorder level
                )
                inventoryPayloads.append(payload)
            }
            
            if !inventoryPayloads.isEmpty {
                // Fetch existing inventory for this store to avoid inserting duplicates
                // Since there is no unique constraint on (store_id, product_id) in the DB,
                // we must manually filter out existing products before inserting.
                let existingInventory: [InventoryItem] = try await client.from("inventory")
                    .select()
                    .eq("store_id", value: storeId.uuidString)
                    .execute()
                    .value
                
                let existingDict = Dictionary(uniqueKeysWithValues: existingInventory.map { ($0.productId, $0) })
                
                var newPayloads: [InventoryPayload] = []
                
                for payload in inventoryPayloads {
                    if let existing = existingDict[payload.productId] {
                        // If it exists, check if quantity is different and update it
                        if existing.quantity != payload.quantity {
                            try await client.from("inventory")
                                .update(["quantity": payload.quantity])
                                .eq("id", value: existing.id.uuidString)
                                .execute()
                        }
                    } else {
                        // It's a new product for this store, insert it
                        newPayloads.append(payload)
                    }
                }
                
                if !newPayloads.isEmpty {
                    try await client.from("inventory")
                        .insert(newPayloads)
                        .execute()
                    print("[RSMS] Successfully pushed \(newPayloads.count) new inventory items for store \(storeId)")
                } else {
                    print("[RSMS] No new inventory items to push for store \(storeId) (updates may have occurred)")
                }
                
                // Refresh inventory list so UI reflects the change
                await fetchInventory()
            }
        } catch {
            print("[RSMS] Failed to push inventory for store: \(error.localizedDescription)")
        }
    }
}
