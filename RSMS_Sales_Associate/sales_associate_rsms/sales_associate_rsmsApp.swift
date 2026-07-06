// sales_associate_rsmsApp.swift
// RSMS — Sales Associate Module
// App entry point — wires auth and root navigation

import SwiftUI

@main
struct sales_associate_rsmsApp: App {

    @StateObject private var authVM = AuthViewModel()
    @StateObject private var checkoutEnv = CheckoutEnvironment()

    var body: some Scene {
        WindowGroup {
            Group {
                if authVM.isLoading {
                    SplashView()
                } else if authVM.isAuthenticated {
                    SalesAssociateTabView()
                        .environmentObject(authVM)
                        .environmentObject(checkoutEnv)
                } else {
                    LoginView()
                        .environmentObject(authVM)
                        .environmentObject(checkoutEnv)
                }
            }
            .animation(.easeInOut(duration: 0.4), value: authVM.isAuthenticated)
            .animation(.easeInOut(duration: 0.4), value: authVM.isLoading)
        }
    }
}

// MARK: - Splash Screen

struct SplashView: View {
    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()
            VStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "C9A84C"), Color(hex: "E8C96A")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 72, height: 72)
                        .shadow(color: Color(hex: "C9A84C").opacity(0.4), radius: 20)
                    Text("RS")
                        .font(.system(size: 28, weight: .bold, design: .serif))
                        .foregroundColor(.black)
                }
                ProgressView()
                    .tint(Color(hex: "C9A84C"))
            }
        }
    }
}
