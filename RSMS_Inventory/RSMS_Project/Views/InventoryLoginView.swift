import SwiftUI
import Supabase

struct InventoryLoginView: View {
    @Binding var isAuthenticated: Bool
    @Binding var userId: UUID?
    @Binding var warehouseId: UUID?
    
    @State private var username = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage: String? = nil
    
    var body: some View {
        ZStack {
            // Dark luxury background with orange/gold accents
            backgroundGradient
            
            VStack(spacing: 0) {
                Spacer()
                
                brandingSection
                    .padding(.bottom, 40)
                
                loginCard
                    .padding(.horizontal, 24)
                
                Spacer()
                
                footerText
                    .padding(.bottom, 24)
            }
        }
        .ignoresSafeArea()
    }
    
    // MARK: - Background
    
    private var backgroundGradient: some View {
        ZStack {
            Color(red: 0.05, green: 0.05, blue: 0.08).ignoresSafeArea()
            
            LinearGradient(
                colors: [
                    Color(red: 0.08, green: 0.06, blue: 0.12),
                    Color(red: 0.04, green: 0.04, blue: 0.06)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Subtle amber glow (representing hardware/packages/inventory)
            Circle()
                .fill(Color.orange.opacity(0.06))
                .frame(width: 350, height: 350)
                .blur(radius: 70)
                .offset(x: -100, y: -150)
            
            Circle()
                .fill(Color.purple.opacity(0.05))
                .frame(width: 250, height: 250)
                .blur(radius: 60)
                .offset(x: 100, y: 150)
        }
    }
    
    // MARK: - Branding
    
    private var brandingSection: some View {
        VStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color.orange, Color.yellow],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 64, height: 64)
                    .shadow(color: Color.orange.opacity(0.3), radius: 15)
                
                Image(systemName: "shippingbox.fill")
                    .font(.system(size: 28))
                    .foregroundColor(.black)
            }
            
            Text("RSMS Inventory")
                .font(.system(size: 32, weight: .bold, design: .serif))
                .foregroundColor(.white)
            
            Text("Central Controller Hub")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.orange.opacity(0.8))
                .tracking(2)
                .textCase(.uppercase)
        }
    }
    
    // MARK: - Login Card
    
    private var loginCard: some View {
        VStack(spacing: 18) {
            Text("Sign In")
                .font(.title3.bold())
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // Username field
            HStack(spacing: 12) {
                Image(systemName: "person.fill")
                    .foregroundColor(.orange)
                    .frame(width: 20)
                
                TextField("Username", text: $username)
                    .font(.body)
                    .foregroundColor(.white)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
            }
            .padding(.horizontal, 16)
            .frame(height: 52)
            .background(Color.white.opacity(0.05))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
            
            // Password field
            HStack(spacing: 12) {
                Image(systemName: "lock.fill")
                    .foregroundColor(.orange)
                    .frame(width: 20)
                
                SecureField("Password", text: $password)
                    .font(.body)
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 16)
            .frame(height: 52)
            .background(Color.white.opacity(0.05))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
            
            if let error = errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding(.top, 4)
            }
            
            // Login button
            Button(action: attemptLogin) {
                ZStack {
                    if isLoading {
                        ProgressView()
                            .tint(.black)
                    } else {
                        HStack(spacing: 8) {
                            Text("Authenticate")
                                .font(.headline)
                            Image(systemName: "arrow.right")
                                .font(.headline)
                        }
                        .foregroundColor(.black)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(
                    LinearGradient(
                        colors: [Color.orange, Color.yellow],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(12)
                .shadow(color: Color.orange.opacity(0.3), radius: 10, y: 4)
            }
            .disabled(isLoading || username.isEmpty || password.isEmpty)
            .padding(.top, 8)
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white.opacity(0.03))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color.white.opacity(0.06), lineWidth: 1)
                )
        )
        .background(.ultraThinMaterial)
        .cornerRadius(20)
    }
    
    private var footerText: some View {
        Text("Secured by RSMS Central Auth")
            .font(.caption2)
            .foregroundColor(.white.opacity(0.3))
    }
    
    // MARK: - Actions
    
    private func attemptLogin() {
        isLoading = true
        errorMessage = nil
        
        Swift.Task {
            do {
                let client = SupabaseManager.shared.client
                let matchedUsers: [User] = try await client
                    .from("users")
                    .select()
                    .eq("username", value: username)
                    .eq("password", value: password)
                    .execute()
                    .value
                
                guard let user = matchedUsers.first else {
                    isLoading = false
                    errorMessage = "Invalid username or password."
                    return
                }
                
                let controllerRoleId = UUID(uuidString: "c0aa841a-7c57-43f9-b98a-523475ba43af")
                guard user.roleId == controllerRoleId else {
                    isLoading = false
                    errorMessage = "Access Denied: You must be an Inventory Controller."
                    return
                }
                
                // Fetch warehouses
                let warehouses = try await WarehouseService.shared.fetchWarehouses()
                
                await MainActor.run {
                    self.userId = user.id
                    self.warehouseId = warehouses.first?.id ?? UUID(uuidString: "e889f951-769c-4ce9-9b2f-90928236e08a")!
                    self.isAuthenticated = true
                    self.isLoading = false
                }
            } catch {
                print("Login error: \(error)")
                
                // Offline fallback for simulator / offline testing
                if username == "controller" && password == "password123" {
                    await MainActor.run {
                        self.userId = UUID(uuidString: "8f1a30f1-4df2-4752-953e-1082c5bf4f47")!
                        self.warehouseId = UUID(uuidString: "e889f951-769c-4ce9-9b2f-90928236e08a")!
                        self.isAuthenticated = true
                        self.isLoading = false
                    }
                } else {
                    await MainActor.run {
                        self.errorMessage = "Connection error. Please try again."
                        self.isLoading = false
                    }
                }
            }
        }
    }
}
