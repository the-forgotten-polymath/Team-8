// LoginView.swift
// RSMS — Sales Associate Module
// Premium luxury login screen for Client Advisor

import SwiftUI

struct LoginView: View {

    @EnvironmentObject private var authVM: AuthViewModel

    @State private var email: String    = ""
    @State private var password: String = ""
    @State private var showPassword: Bool = false
    @FocusState private var focusedField: Field?

    private enum Field { case email, password }

    var body: some View {
        ZStack {
            // Background gradient
            backgroundGradient

            VStack(spacing: 0) {
                Spacer()

                // Logo & Branding
                brandingSection
                    .padding(.bottom, 48)

                // Card
                loginCard
                    .padding(.horizontal, 24)

                Spacer()
                footerText
                    .padding(.bottom, 32)
            }
        }
        .ignoresSafeArea()
        .alert("Login Error", isPresented: .constant(authVM.errorMessage != nil)) {
            Button("OK") { authVM.errorMessage = nil }
        } message: {
            Text(authVM.errorMessage ?? "")
        }
    }

    // MARK: - Background

    private var backgroundGradient: some View {
        ZStack {
            Color(hex: "0A0A0F").ignoresSafeArea()
            LinearGradient(
                colors: [
                    Color(hex: "1A1028"),
                    Color(hex: "0D0D18"),
                    Color(hex: "0A0A0F")
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // Subtle gold accent orbs
            Circle()
                .fill(Color(hex: "C9A84C").opacity(0.08))
                .frame(width: 400, height: 400)
                .blur(radius: 80)
                .offset(x: -80, y: -180)

            Circle()
                .fill(Color(hex: "9B59B6").opacity(0.06))
                .frame(width: 300, height: 300)
                .blur(radius: 60)
                .offset(x: 120, y: 200)
        }
    }

    // MARK: - Branding

    private var brandingSection: some View {
        VStack(spacing: 12) {
            // Logo mark
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

            Text("RSMS")
                .font(.system(size: 36, weight: .bold, design: .serif))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color(hex: "C9A84C"), Color(hex: "E8D87A")],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )

            Text("Client Advisor Platform")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.5))
                .tracking(2)
                .textCase(.uppercase)
        }
    }

    // MARK: - Login Card

    private var loginCard: some View {
        VStack(spacing: 20) {
            Text("Sign In")
                .font(.title2.bold())
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Email field
            floatingField(
                label: "Work Email",
                icon: "envelope.fill",
                text: $email,
                isSecure: false
            )
            .focused($focusedField, equals: .email)
            .keyboardType(.emailAddress)
            .textContentType(.emailAddress)
            .autocapitalization(.none)
            .submitLabel(.next)
            .onSubmit { focusedField = .password }

            // Password field
            floatingField(
                label: "Password",
                icon: "lock.fill",
                text: $password,
                isSecure: !showPassword,
                trailingAction: {
                    Button(action: { showPassword.toggle() }) {
                        Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                            .foregroundColor(.white.opacity(0.5))
                    }
                }
            )
            .focused($focusedField, equals: .password)
            .textContentType(.password)
            .submitLabel(.go)
            .onSubmit { attemptLogin() }

            // Login button
            Button(action: attemptLogin) {
                ZStack {
                    if authVM.isLoading {
                        ProgressView()
                            .tint(.black)
                    } else {
                        HStack(spacing: 8) {
                            Text("Sign In")
                                .font(.headline)
                            Image(systemName: "arrow.right")
                                .font(.headline)
                        }
                        .foregroundColor(.black)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(
                    LinearGradient(
                        colors: [Color(hex: "C9A84C"), Color(hex: "E8C96A")],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(14)
                .shadow(color: Color(hex: "C9A84C").opacity(0.35), radius: 12, y: 4)
            }
            .disabled(authVM.isLoading || email.isEmpty || password.isEmpty)
            .animation(.easeInOut(duration: 0.2), value: authVM.isLoading)
        }
        .padding(28)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
    }

    // MARK: - Floating Field

    @ViewBuilder
    private func floatingField<Trailing: View>(
        label: String,
        icon: String,
        text: Binding<String>,
        isSecure: Bool,
        @ViewBuilder trailingAction: () -> Trailing = { EmptyView() }
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(Color(hex: "C9A84C"))
                .frame(width: 20)

            if isSecure {
                SecureField(label, text: text)
                    .font(.body)
                    .foregroundColor(.white)
            } else {
                TextField(label, text: text)
                    .font(.body)
                    .foregroundColor(.white)
            }

            trailingAction()
        }
        .padding(.horizontal, 16)
        .frame(height: 54)
        .background(Color.white.opacity(0.06))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }

    // MARK: - Footer

    private var footerText: some View {
        Text("Secured by RSMS Enterprise Auth · v\(AppConstants.App.version)")
            .font(.caption2)
            .foregroundColor(.white.opacity(0.25))
    }

    // MARK: - Actions

    private func attemptLogin() {
        guard !email.isEmpty, !password.isEmpty else { return }
        focusedField = nil
        Task { await authVM.login(email: email, password: password) }
    }
}

// MARK: - Color Hex Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

#Preview {
    LoginView()
        .environmentObject(AuthViewModel())
}
