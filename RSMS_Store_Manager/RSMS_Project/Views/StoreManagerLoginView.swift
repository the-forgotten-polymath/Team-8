import SwiftUI
import Supabase

struct StoreManagerLoginView: View {
    @State private var username = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage: String? = nil
    
    var body: some View {
        ZStack {
            // Dark luxury background with blue/teal accents
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
                    Color(red: 0.05, green: 0.08, blue: 0.12),
                    Color(red: 0.04, green: 0.04, blue: 0.06)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Subtle teal glow (representing team management / stores)
            Circle()
                .fill(Color(red: 0.0, green: 0.5, blue: 0.5).opacity(0.07))
                .frame(width: 350, height: 350)
                .blur(radius: 70)
                .offset(x: -100, y: -150)
            
            Circle()
                .fill(Color.blue.opacity(0.05))
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
                            colors: [Color.blue, Color(red: 0.0, green: 0.8, blue: 0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 64, height: 64)
                    .shadow(color: Color.blue.opacity(0.3), radius: 15)
                
                Image(systemName: "person.2.fill")
                    .font(.system(size: 28))
                    .foregroundColor(.black)
            }
            
            Text("RSMS Boutique")
                .font(.system(size: 32, weight: .bold, design: .serif))
                .foregroundColor(.white)
            
            Text("Store Manager Platform")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.blue.opacity(0.8))
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
                    .foregroundColor(.blue)
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
                    .foregroundColor(.blue)
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
                            Text("Sign In")
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
                        colors: [Color.blue, Color(red: 0.0, green: 0.8, blue: 0.8)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(12)
                .shadow(color: Color.blue.opacity(0.3), radius: 10, y: 4)
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
        Text("Secured by RSMS Manager Auth")
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
                
                guard var user = matchedUsers.first else {
                    isLoading = false
                    errorMessage = "Invalid username or password."
                    return
                }
                
                // Fetch roles to verify user has a manager role
                let roles: [Role] = try await DatabaseService.shared.fetch(from: "roles", as: Role.self)
                let userRole = roles.first(where: { $0.id == user.roleId })
                
                let isManager = userRole?.roleName.lowercased().contains("manager") == true
                guard isManager else {
                    isLoading = false
                    errorMessage = "Access Denied: You must be a Store/Boutique Manager."
                    return
                }
                
                // Self-heal: If manager has no store, assign first available
                if user.storeId == nil {
                    let stores: [Store] = try await DatabaseService.shared.fetch(from: "stores", as: Store.self)
                    if let firstStore = stores.first {
                        user = user.copy(storeId: firstStore.id)
                        try await DatabaseService.shared.update(table: "users", value: user, column: "id", equals: user.id.uuidString)
                    }
                }
                
                await MainActor.run {
                    SessionManager.shared.currentUser = user
                    SessionManager.shared.isLoading = false
                    self.isLoading = false
                }
            } catch {
                print("Login error: \(error)")
                
                // Offline fallback for simulator / offline testing
                if username.starts(with: "manager_usr") && password == "password123" {
                    // Try to generate a mock user matching the name
                    await MainActor.run {
                        let mockUser = User(
                            id: UUID(uuidString: "4acff73d-efbe-5feb-a495-59e5a8663501")!,
                            fullName: "Manager \(username.uppercased())",
                            username: username,
                            email: "\(username)@rsms.com",
                            isVerified: true,
                            roleId: UUID(uuidString: "b24abda2-b031-4548-8641-8511ec2bfff0")!,
                            storeId: UUID(uuidString: "11111111-0000-0000-0000-000000000001")!
                        )
                        SessionManager.shared.currentUser = mockUser
                        SessionManager.shared.isLoading = false
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
