import SwiftUI

public struct InventoryRootView: View {
    var onBackToPortal: () -> Void
    var onLogout: (() -> Void)? = nil
    let initialSession: (isAuthenticated: Bool, userId: UUID?, warehouseId: UUID?)?
    
    public init(
        onBackToPortal: @escaping () -> Void,
        initialSession: (isAuthenticated: Bool, userId: UUID?, warehouseId: UUID?)? = nil,
        onLogout: (() -> Void)? = nil
    ) {
        self.onBackToPortal = onBackToPortal
        self.initialSession = initialSession
        self.onLogout = onLogout
    }
    
    public var body: some View {
        if let session = initialSession {
            ContentView(
                onBackToPortal: onBackToPortal,
                isAuthenticated: session.isAuthenticated,
                userId: session.userId,
                warehouseId: session.warehouseId,
                onLogout: onLogout ?? {}
            )
        } else {
            ContentView(onBackToPortal: onBackToPortal)
        }
    }
}
