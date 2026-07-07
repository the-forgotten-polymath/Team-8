// StoreModel.swift
// Admin_RSMS
//
// AdminStore maps 1-to-1 with the `stores` Supabase table (the working
// admin UI table). The SRS-canonical `Store` type lives in Models/Store.swift.

import Foundation

// ─────────────────────────────────────────────────────────────────
// MARK: – AdminStore  (maps 1-to-1 with the `stores` Supabase table)
// ─────────────────────────────────────────────────────────────────
struct AdminStore: Identifiable, Codable {
    var id:               UUID
    var storeID:          String?
    var name:             String
    var address:          String
    var managerName:      String
    var managerInitials:  String
    var status:           StoreStatus
    var imageData:        Data?      // local-only; not persisted to Supabase
    var imageUrl:         String?
    var latitude:         Double?
    var longitude:        Double?
    var isArchived:       Bool
    var categoryQuantities: [UUID: Int]?

    // ── Coding keys: snake_case ↔ camelCase ──────────────────────
    enum CodingKeys: String, CodingKey {
        case id
        case storeID          = "store_id"
        case name
        case address
        case managerName      = "manager_name"
        case managerInitials  = "manager_initials"
        case status
        case imageUrl         = "image_url"
        case latitude
        case longitude
        case isArchived       = "is_archived"
        case storeCategories  = "store_categories"
        // imageData is intentionally excluded — stored locally only
    }
    
    struct StoreCategoryRelation: Codable {
        let categoryId: UUID
        
        enum CodingKeys: String, CodingKey {
            case categoryId = "category_id"
        }
    }

    // ── Custom init so imageData survives even though it's not in CodingKeys ──
    init(
        id:              UUID     = UUID(),
        storeID:         String?  = nil,
        name:            String,
        address:         String,
        managerName:     String,
        managerInitials: String,
        status:          StoreStatus,
        imageData:       Data?    = nil,
        imageUrl:        String?  = nil,
        latitude:        Double?  = nil,
        longitude:       Double?  = nil,
        isArchived:      Bool     = false,
        categoryQuantities: [UUID: Int]? = nil
    ) {
        self.id              = id
        self.storeID         = storeID
        self.name            = name
        self.address         = address
        self.managerName     = managerName
        self.managerInitials = managerInitials
        self.status          = status
        self.imageData       = imageData
        self.imageUrl        = imageUrl
        self.latitude        = latitude
        self.longitude       = longitude
        self.isArchived      = isArchived
        self.categoryQuantities = categoryQuantities
    }

    // ── Decode (from Supabase JSON) ──────────────────────────────
    init(from decoder: Decoder) throws {
        let c        = try decoder.container(keyedBy: CodingKeys.self)
        id              = try c.decode(UUID.self,        forKey: .id)
        storeID         = try c.decodeIfPresent(String.self, forKey: .storeID)
        name            = try c.decode(String.self,      forKey: .name)
        address         = try c.decode(String.self,      forKey: .address)
        managerName     = try c.decode(String.self,      forKey: .managerName)
        managerInitials = try c.decode(String.self,      forKey: .managerInitials)
        let rawStatus   = try c.decode(String.self,      forKey: .status)
        status          = StoreStatus(rawValue: rawStatus) ?? .active
        imageUrl        = try c.decodeIfPresent(String.self,  forKey: .imageUrl)
        latitude        = try c.decodeIfPresent(Double.self,  forKey: .latitude)
        longitude       = try c.decodeIfPresent(Double.self, forKey: .longitude)
        isArchived      = try c.decodeIfPresent(Bool.self, forKey: .isArchived) ?? false
        
        // Extract categoryQuantities from joined store_categories
        if let relations = try c.decodeIfPresent([StoreCategoryRelation].self, forKey: .storeCategories) {
            var dict: [UUID: Int] = [:]
            for rel in relations {
                dict[rel.categoryId] = 1 // Default to 1 since DB doesn't store quantity at category level
            }
            categoryQuantities = dict
        } else {
            categoryQuantities = nil
        }
        imageData       = nil   // never comes from Supabase
    }
    
    // ── Encode (to Supabase JSON) ──────────────────────────────
    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encodeIfPresent(storeID, forKey: .storeID)
        try c.encode(name, forKey: .name)
        try c.encode(address, forKey: .address)
        try c.encode(managerName, forKey: .managerName)
        try c.encode(managerInitials, forKey: .managerInitials)
        try c.encode(status.rawValue, forKey: .status)
        try c.encodeIfPresent(imageUrl, forKey: .imageUrl)
        try c.encodeIfPresent(latitude, forKey: .latitude)
        try c.encodeIfPresent(longitude, forKey: .longitude)
        try c.encode(isArchived, forKey: .isArchived)
        
        if let catDict = categoryQuantities {
            let relations = catDict.map { StoreCategoryRelation(categoryId: $0.key) }
            try c.encode(relations, forKey: .storeCategories)
        }
    }
}

// ─────────────────────────────────────────────────────────────────
// MARK: – Payload used when inserting / updating to Supabase
// (excludes id, created_at, updated_at so Supabase generates them)
// ─────────────────────────────────────────────────────────────────
struct AdminStorePayload: Encodable {
    let storeID:         String?
    let name:            String
    let address:         String
    let managerName:     String
    let managerInitials: String
    let status:          String
    let imageUrl:        String?
    let latitude:        Double?
    var longitude:        Double?
    var isArchived:       Bool
    
    // Coding keys
    enum CodingKeys: String, CodingKey {
        case storeID          = "store_id"
        case name
        case address
        case managerName      = "manager_name"
        case managerInitials  = "manager_initials"
        case status
        case imageUrl         = "image_url"
        case latitude
        case longitude
        case isArchived       = "is_archived"
    }

    init(from store: AdminStore) {
        storeID         = store.storeID
        name            = store.name
        address         = store.address
        managerName     = store.managerName
        managerInitials = store.managerInitials
        status          = store.status.rawValue
        imageUrl        = store.imageUrl
        latitude        = store.latitude
        longitude       = store.longitude
        isArchived      = store.isArchived
    }
}

// ─────────────────────────────────────────────────────────────────
// MARK: – StoreStatus
// ─────────────────────────────────────────────────────────────────
enum StoreStatus: String, Codable, CaseIterable {
    case active      = "ACTIVE"
    case maintenance = "MAINTENANCE"
    case inventory   = "INVENTORY"
}
