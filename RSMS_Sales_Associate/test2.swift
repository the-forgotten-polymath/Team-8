import Foundation

enum CustomerTier: String, Codable, CaseIterable { case vip }
enum ProductCategory: String, Codable, CaseIterable { case watches }
enum CommunicationChannel: String, Codable, CaseIterable { case email }
enum Occasion: String, Codable, CaseIterable { case birthday }
enum WarrantyStatus: String, Codable { case active }

struct SizeProfile: Codable, Sendable { let clientID: UUID }
struct ClientPreferences: Codable, Sendable { let clientID: UUID }
struct ClientDigitalTwinEvent: Codable, Identifiable, Sendable { let id: UUID }
struct OwnedProduct: Codable, Identifiable, Sendable { let id: UUID }
struct WishlistItem: Codable, Identifiable, Sendable { let id: UUID }
struct ConsentRecord: Codable, Sendable { let clientID: UUID }
struct GDPRFlags: Codable, Sendable { let clientID: UUID }

struct ClientDigitalTwin: Codable, Identifiable, Sendable {
    let id: UUID
    var firstName: String
    var preferences: ClientPreferences?
    var events: [ClientDigitalTwinEvent]?
    var ownedProducts: [OwnedProduct]?
    var wishlistItems: [WishlistItem]?
    var consentStatus: ConsentRecord?
    var gdprFlags: GDPRFlags?
}

actor TestActor {
    func test() {
        let d = ClientDigitalTwin(id: UUID(), firstName: "a")
        let _ = try? JSONEncoder().encode(d)
    }
}
