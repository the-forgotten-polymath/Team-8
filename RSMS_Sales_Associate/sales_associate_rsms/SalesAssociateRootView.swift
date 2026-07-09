import SwiftUI

public struct SalesAssociateRootView: View {
    @StateObject private var authVM: AuthViewModel
    @StateObject private var checkoutEnv = CheckoutEnvironment()
    var onBackToPortal: () -> Void
    
    public init(onBackToPortal: @escaping () -> Void, authVM: AuthViewModel? = nil) {
        self.onBackToPortal = onBackToPortal
        self._authVM = StateObject(wrappedValue: authVM ?? AuthViewModel())
    }
    
    public var body: some View {
        Group {
            if authVM.isLoading {
                SplashView()
            } else if authVM.isAuthenticated {
                if let user = authVM.currentUser, !user.isProfileCompleted {
                    CompleteProfileView(authViewModel: authVM)
                } else {
                    SalesAssociateTabView()
                        .environmentObject(authVM)
                        .environmentObject(checkoutEnv)
                }
            } else {
                ZStack(alignment: .topLeading) {
                    LoginView()
                        .environmentObject(authVM)
                        .environmentObject(checkoutEnv)
                    
                    Button(action: onBackToPortal) {
                        HStack(spacing: 6) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 14, weight: .bold))
                            Text("Portal")
                                .font(.system(size: 15, weight: .semibold))
                        }
                        .foregroundColor(Color(hex: "C9A84C"))
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
        .animation(.easeInOut(duration: 0.4), value: authVM.isAuthenticated)
        .animation(.easeInOut(duration: 0.4), value: authVM.isLoading)
    }
}
