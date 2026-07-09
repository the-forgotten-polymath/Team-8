// MockData.swift
// RSMS — Sales Associate Module

import Foundation

enum MockData {
    
    static let associateID = UUID(uuidString: "3211f020-f433-4b67-92a5-677f52ca5084")!
    static let storeID = UUID(uuidString: "f2182a92-1e3a-4ac9-b4c1-87a0a480667a")!
    static let otherStoreID = UUID(uuidString: "44444444-3333-3333-3333-333333333333")!
    
    static let staffProfile = StaffProfile(
        id: associateID,
        firstName: "Alex",
        lastName: "Mock",
        email: "alex.mock@boutique.com",
        role: .salesAssociate,
        storeID: storeID,
        avatarURL: nil,
        isActive: true,
        createdAt: Date()
    )
    
    nonisolated(unsafe) static var clients: [ClientDigitalTwin] = [
        ClientDigitalTwin(
            id: UUID(uuidString: "22222222-2222-2222-2222-222222222222")!,
            customerID: UUID(uuidString: "99999999-9999-9999-9999-999999999999")!,
            firstName: "Emma",
            lastName: "Watson",
            email: "emma@example.com",
            phone: "+1 555-0101",
            dateOfBirth: Calendar.current.date(from: DateComponents(year: 1990, month: 4, day: 15)),
            tier: .vip,
            lifetimeSpend: 150000.0,
            preferredStore: storeID,
            preferredAdvisor: associateID,
            createdAt: Date().addingTimeInterval(-86400 * 365),
            updatedAt: Date(),
            preferences: ClientPreferences(
                clientID: UUID(uuidString: "22222222-2222-2222-2222-222222222222")!,
                preferredBrands: ["In-House", "Partner"],
                preferredCategories: [.apparel, .jewellery],
                preferredColors: ["Black", "Gold"],
                preferredMaterials: ["Silk", "Leather"],
                communicationChannel: .email,
                languagePreference: "en",
                shoppingOccasions: [.everyday, .festive],
                anniversaryDate: nil,
                birthdayDate: Calendar.current.date(from: DateComponents(month: 4, day: 15)),
                notes: "Prefers understated elegance. Likes vintage styles.",
                sizes: SizeProfile(
                    clientID: UUID(uuidString: "22222222-2222-2222-2222-222222222222")!,
                    ring: "6",
                    dress: "S",
                    suit: nil,
                    shirt: nil,
                    shoes: "38",
                    wrist: "S",
                    custom: nil
                )
            ),
            events: [
                ClientDigitalTwinEvent(
                    id: UUID(),
                    clientID: UUID(uuidString: "22222222-2222-2222-2222-222222222222")!,
                    date: Date().addingTimeInterval(-86400 * 14),
                    type: .purchase,
                    title: "Purchased Evening Gown",
                    description: "Black silk evening gown from FW24 collection.",
                    location: "Main Boutique",
                    performedBy: associateID,
                    linkedProductDigitalTwinID: nil,
                    metadata: nil
                )
            ],
            ownedProducts: [
                OwnedProduct(
                    id: UUID(),
                    clientID: UUID(uuidString: "22222222-2222-2222-2222-222222222222")!,
                    twinID: UUID(),
                    productName: "Evening Gown",
                    serialNumber: "SN123456789",
                    purchaseDate: Date().addingTimeInterval(-86400 * 14),
                    purchaseStore: storeID,
                    purchasePrice: 2500.0,
                    currentWarrantyStatus: .active
                )
            ],
            wishlistItems: [
                WishlistItem(
                    id: UUID(),
                    clientID: UUID(uuidString: "22222222-2222-2222-2222-222222222222")!,
                    sku: "SKU123",
                    productName: "Diamond Necklace",
                    addedDate: Date().addingTimeInterval(-86400 * 30),
                    addedBy: associateID,
                    isAvailable: false,
                    availableStores: [],
                    notifyOnRestock: true,
                    notes: "Waiting for size S to be in stock"
                )
            ],
            consentStatus: ConsentRecord(
                clientID: UUID(uuidString: "22222222-2222-2222-2222-222222222222")!,
                marketingEmail: true,
                marketingSMS: true,
                marketingWhatsApp: true,
                marketingPush: true,
                dataProcessing: true,
                profilingForRecommendations: true,
                consentDate: Date(),
                consentVersion: "v1.0",
                withdrawnDate: nil
            ),
            gdprFlags: GDPRFlags(
                clientID: UUID(uuidString: "22222222-2222-2222-2222-222222222222")!,
                canStore: true,
                canProcess: true,
                canProfile: true,
                rightToErasureRequested: false,
                exportRequested: false
            )
        ),
        ClientDigitalTwin(
            id: UUID(uuidString: "22222222-2222-2222-2222-222222222223")!,
            customerID: nil,
            firstName: "James",
            lastName: "Bond",
            email: "james.bond@mi6.co.uk",
            phone: "+44 7700 900077",
            dateOfBirth: nil,
            tier: .vip,
            lifetimeSpend: 75000.0,
            preferredStore: storeID,
            preferredAdvisor: associateID,
            createdAt: Date().addingTimeInterval(-86400 * 600),
            updatedAt: Date(),
            preferences: nil,
            events: nil,
            ownedProducts: nil,
            wishlistItems: nil,
            consentStatus: ConsentRecord(
                clientID: UUID(uuidString: "22222222-2222-2222-2222-222222222223")!,
                marketingEmail: false,
                marketingSMS: false,
                marketingWhatsApp: false,
                marketingPush: false,
                dataProcessing: false,
                profilingForRecommendations: false,
                consentDate: Date().addingTimeInterval(-86400 * 365),
                consentVersion: "v1.0",
                withdrawnDate: Date().addingTimeInterval(-86400 * 2)
            ),
            gdprFlags: GDPRFlags(
                clientID: UUID(uuidString: "22222222-2222-2222-2222-222222222223")!,
                canStore: false,
                canProcess: false,
                canProfile: false,
                rightToErasureRequested: true,
                exportRequested: false
            )
        )
    ]
    
    nonisolated(unsafe) static var products: [ProductDigitalTwin] = [
        ProductDigitalTwin(
            id: UUID(uuidString: "44444444-4444-4444-4444-444444444444")!,
            sku: "WAT-1001",
            title: "Oyster Perpetual Submariner Date",
            description: "The Oyster Perpetual Submariner Date in Oystersteel and yellow gold with a Cerachrom bezel insert in blue ceramic and a royal blue dial with large luminescent hour markers.",
            category: .watches,
            brand: "Rolex",
            collection: "Submariner",
            materials: ["Oystersteel", "Yellow Gold", "Ceramic"],
            price: 14750.00,
            currency: "INR",
            authenticityCertificateID: "AUTH-RLX-1001",
            dateOfManufacture: Calendar.current.date(from: DateComponents(year: 2023, month: 6)),
            origin: "Switzerland",
            imageURLs: [URL(string: "https://example.com/watch1.jpg")!],
            stockLevel: 2
        ),
        ProductDigitalTwin(
            id: UUID(uuidString: "44444444-4444-4444-4444-444444444445")!,
            sku: "JEW-2001",
            title: "Love Bracelet, Small Model",
            description: "Love bracelet, small model, 18K yellow gold (750/1000). Set with 6 brilliant-cut diamonds totaling 0.15 carat.",
            category: .jewellery,
            brand: "Cartier",
            collection: "LOVE",
            materials: ["18K Yellow Gold", "Diamonds"],
            price: 4950.00,
            currency: "INR",
            authenticityCertificateID: "AUTH-CRT-2001",
            dateOfManufacture: Calendar.current.date(from: DateComponents(year: 2024, month: 1)),
            origin: "France",
            imageURLs: [URL(string: "https://example.com/jewel1.jpg")!],
            stockLevel: 0 // Out of stock
        ),
        ProductDigitalTwin(
            id: UUID(uuidString: "44444444-4444-4444-4444-444444444446")!,
            sku: "BAG-3001",
            title: "Birkin 30",
            description: "Hermès Birkin 30 in Togo leather with gold hardware.",
            category: .leather,
            brand: "Hermès",
            collection: "Birkin",
            materials: ["Togo Leather", "Gold Hardware"],
            price: 11900.00,
            currency: "INR",
            authenticityCertificateID: "AUTH-HRM-3001",
            dateOfManufacture: Calendar.current.date(from: DateComponents(year: 2024, month: 3)),
            origin: "France",
            imageURLs: [URL(string: "https://example.com/bag1.jpg")!],
            stockLevel: 1
        )
    ]
    
    static let appointments: [Appointment] = [
        Appointment(
            id: UUID(),
            clientId: clients[0].id, // James Bond
            associateId: UUID(),
            date: Date().addingTimeInterval(3600 * 2), // 2 hours from now
            type: .inStore,
            notes: "Looking for an anniversary gift for Vesper."
        ),
        Appointment(
            id: UUID(),
            clientId: clients[1].id, // Bruce Wayne
            associateId: UUID(),
            date: Date().addingTimeInterval(86400 * 2), // 2 days from now
            type: .videoConsult,
            notes: "Wants a preview of the new Gotham collection via video."
        )
    ]
    
    static let curatedCarts: [CuratedCart] = []
    
    nonisolated(unsafe) static var fulfillmentOrders: [FulfillmentOrder] = [
        FulfillmentOrder(
            id: UUID(),
            orderNumber: "ORD-998877",
            clientID: UUID(uuidString: "22222222-2222-2222-2222-222222222222")!, // Emma
            storeID: storeID,
            type: .bopis,
            status: .readyForPickup,
            orderDate: Date().addingTimeInterval(-86400 * 2),
            items: [
                FulfillmentItem(id: UUID(), productID: UUID(uuidString: "44444444-4444-4444-4444-444444444444")!, quantity: 1, productTitle: "Oyster Perpetual Submariner Date", sku: "WAT-1001")
            ]
        ),
        FulfillmentOrder(
            id: UUID(),
            orderNumber: "ORD-112233",
            clientID: UUID(uuidString: "22222222-2222-2222-2222-222222222223")!, // James
            storeID: storeID,
            type: .sfs,
            status: .pending,
            orderDate: Date().addingTimeInterval(-86400 * 1),
            items: [
                FulfillmentItem(id: UUID(), productID: UUID(uuidString: "44444444-4444-4444-4444-444444444446")!, quantity: 1, productTitle: "Birkin 30", sku: "BAG-3001")
            ]
        )
    ]
    
    nonisolated(unsafe) static var inventoryLevels: [InventoryLevel] = [
        InventoryLevel(id: UUID(), productID: UUID(uuidString: "44444444-4444-4444-4444-444444444444")!, storeID: storeID, quantityAvailable: 2, quantityReserved: 0, storeName: "Main Boutique"),
        InventoryLevel(id: UUID(), productID: UUID(uuidString: "44444444-4444-4444-4444-444444444445")!, storeID: storeID, quantityAvailable: 0, quantityReserved: 0, storeName: "Main Boutique"),
        InventoryLevel(id: UUID(), productID: UUID(uuidString: "44444444-4444-4444-4444-444444444445")!, storeID: otherStoreID, quantityAvailable: 1, quantityReserved: 0, storeName: "Downtown Branch"),
        InventoryLevel(id: UUID(), productID: UUID(uuidString: "44444444-4444-4444-4444-444444444446")!, storeID: storeID, quantityAvailable: 1, quantityReserved: 0, storeName: "Main Boutique"),
        InventoryLevel(id: UUID(), productID: UUID(uuidString: "44444444-4444-4444-4444-444444444446")!, storeID: otherStoreID, quantityAvailable: 3, quantityReserved: 1, storeName: "Downtown Branch")
    ]
    
    nonisolated(unsafe) static var opportunities: [Opportunity] = [
        Opportunity(
            id: UUID(),
            clientID: clients[0].id,
            associateID: associateID,
            type: .anniversary,
            title: "Upcoming Anniversary",
            description: "Emma's 10-year wedding anniversary is next month.",
            dateGenerated: Date().addingTimeInterval(-86400 * 2),
            status: .new,
            clientName: "Emma Watson"
        ),
        Opportunity(
            id: UUID(),
            clientID: clients[1].id,
            associateID: associateID,
            type: .wishlistInStock,
            title: "Wishlist Item In Stock",
            description: "Diamond Necklace is now available.",
            dateGenerated: Date().addingTimeInterval(-3600 * 4),
            status: .new,
            clientName: "James Bond"
        )
    ]
    
    nonisolated(unsafe) static var advisorMetrics = AdvisorMetrics(
        id: associateID,
        dailyGoal: 10000.0,
        currentSales: 6500.0,
        followUpsDue: 5,
        followUpsCompleted: 3
    )
    
    nonisolated(unsafe) static var storeMetrics = StoreMetrics(
        storeID: storeID,
        conversionRate: 14.5,
        averageOrderValue: 4500.0,
        clientRetentionRate: 85.0,
        appointmentConversion: 60.0,
        endlessAisleCaptureRate: 45.0,
        dailyConversionHistory: (1...7).map { day in
            DailyMetric(
                date: Calendar.current.date(byAdding: .day, value: -day, to: Date())!,
                value: Double.random(in: 10.0...20.0)
            )
        }.sorted(by: { $0.date < $1.date })
    )
}
