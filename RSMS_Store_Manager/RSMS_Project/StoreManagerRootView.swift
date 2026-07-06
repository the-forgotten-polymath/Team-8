import SwiftUI

public struct StoreManagerRootView: View {
    @ObservedObject private var sessionManager = SessionManager.shared
    var onBackToPortal: () -> Void
    
    public init(onBackToPortal: @escaping () -> Void) {
        self.onBackToPortal = onBackToPortal
    }
    
    public var body: some View {
        Group {
            if sessionManager.currentUser != nil {
                ContentView()
            } else {
                ZStack(alignment: .topLeading) {
                    StoreManagerLoginView()
                    
                    Button(action: onBackToPortal) {
                        HStack(spacing: 6) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 14, weight: .bold))
                            Text("Portal")
                                .font(.system(size: 15, weight: .semibold))
                        }
                        .foregroundColor(.blue)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.white.opacity(0.08))
                        .cornerRadius(20)
                        .shadow(color: Color.black.opacity(0.1), radius: 5)
                    }
                    .padding(.leading, 16)
                    .padding(.top, 60)
                }
            }
        }
    }
}
