import SwiftUI

@main
struct RSMSApp: App {
    init() {
        // Disable caching globally to prevent stale Supabase query data
        URLCache.shared = URLCache(memoryCapacity: 0, diskCapacity: 0, diskPath: nil)
    }
    
    var body: some Scene {
        WindowGroup {
            GatewayView()
        }
    }
}
