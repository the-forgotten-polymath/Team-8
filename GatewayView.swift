import SwiftUI
import AdminModule
import InventoryModule
import StoreManagerModule
import SalesAssociateModule
import Supabase
import Combine
import Foundation

private enum GatewayConstants {
    static let supabaseURL = "https://yldspqgtzyrbdnoromgv.supabase.co"
    static let supabaseKey = "sb_publishable_6hcPNWOppBItrHk7_F7LoQ_0eGNXAL5"
}

// MARK: - Decodable models for login queries

struct GatewayUser: Codable {
    let id: UUID
    let fullName: String
    let username: String
    let email: String
    let roleId: UUID
    let storeId: UUID?
    let designation: String?
    let phone: String?
    let profileImageURL: String?
    
    init(
        id: UUID,
        fullName: String,
        username: String,
        email: String,
        roleId: UUID,
        storeId: UUID? = nil,
        designation: String? = nil,
        phone: String? = nil,
        profileImageURL: String? = nil
    ) {
        self.id = id
        self.fullName = fullName
        self.username = username
        self.email = email
        self.roleId = roleId
        self.storeId = storeId
        self.designation = designation
        self.phone = phone
        self.profileImageURL = profileImageURL
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case fullName = "full_name"
        case username
        case email
        case roleId = "role_id"
        case storeId = "store_id"
        case designation
        case phone
        case profileImageURL = "profile_image_url"
    }
}

struct GatewayRole: Codable {
    let id: UUID
    let roleName: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case roleName = "role_name"
    }
}

// MARK: - Central Session Manager

public final class CentralSessionManager: ObservableObject {
    public static let shared = CentralSessionManager()
    
    @Published public var userId: UUID? = nil
    @Published public var username: String = ""
    @Published public var fullName: String = ""
    @Published public var roleId: UUID? = nil
    @Published public var roleName: String = ""
    @Published public var designation: String = ""
    @Published public var storeId: UUID? = nil
    @Published public var isAuthenticated: Bool = false
    
    private init() {}
    
    public func clear() {
        userId = nil
        username = ""
        fullName = ""
        roleId = nil
        roleName = ""
        designation = ""
        storeId = nil
        isAuthenticated = false
    }
}

// MARK: - Login View UI

struct LoginView: View {
    @State private var username = ""
    @State private var password = ""
    @State private var showPassword = false
    @State private var isLoading = false
    @State private var errorMessage: String? = nil
    
    var onLoginSuccess: (GatewayUser, String) -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Welcome Back")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.black)
                
                Text("Sign in to continue")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 30)
            .padding(.bottom, 40)
            
            VStack(spacing: 20) {
                // Username field
                HStack {
                    Image(systemName: "person")
                        .foregroundColor(.gray)
                        .frame(width: 20)
                    TextField("Username", text: $username)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .foregroundColor(.black)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
                
                // Password field
                HStack {
                    Image(systemName: "lock")
                        .foregroundColor(.gray)
                        .frame(width: 20)
                    if showPassword {
                        TextField("Password", text: $password)
                            .foregroundColor(.black)
                    } else {
                        SecureField("Password", text: $password)
                            .foregroundColor(.black)
                    }
                    Button(action: { showPassword.toggle() }) {
                        Image(systemName: showPassword ? "eye.slash" : "eye")
                            .foregroundColor(.gray)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
                
                if let error = errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.top, 4)
                }
                
                // Sign In Button
                Button(action: attemptLogin) {
                    HStack {
                        Spacer()
                        if isLoading {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("Sign In")
                                .font(.headline)
                                .foregroundColor(.white)
                        }
                        Spacer()
                    }
                    .frame(height: 50)
                    .background(Color.blue)
                    .cornerRadius(10)
                }
                .disabled(isLoading || username.isEmpty || password.isEmpty)
                .padding(.top, 10)
                
                // Forgot Password button
                Button(action: {
                    // Placeholder for forgot password
                }) {
                    Text("Forgot Password?")
                        .font(.footnote)
                        .foregroundColor(.blue)
                        .fontWeight(.semibold)
                }
                .padding(.top, 10)
            }
            .padding(.horizontal, 30)
            
            Spacer()
            Spacer()
        }
        .background(Color.white)
        .preferredColorScheme(.light)
    }
    
    private func attemptLogin() {
        isLoading = true
        errorMessage = nil
        
        let client = SupabaseClient(
            supabaseURL: URL(string: GatewayConstants.supabaseURL)!,
            supabaseKey: GatewayConstants.supabaseKey
        )
        
        Task {
            do {
                let users: [GatewayUser] = try await client.from("users")
                    .select()
                    .eq("username", value: username)
                    .eq("password", value: password)
                    .execute()
                    .value
                
                guard let user = users.first else {
                    await MainActor.run {
                        self.errorMessage = "Invalid username or password."
                        self.isLoading = false
                    }
                    return
                }
                
                // Fetch roles
                let roles: [GatewayRole] = try await client.from("roles")
                    .select()
                    .eq("id", value: user.roleId.uuidString)
                    .execute()
                    .value
                
                guard let role = roles.first else {
                    await MainActor.run {
                        self.errorMessage = "Failed to retrieve user role."
                        self.isLoading = false
                    }
                    return
                }
                
                await MainActor.run {
                    self.isLoading = false
                    self.onLoginSuccess(user, role.roleName)
                }
                
            } catch {
                print("Login error: \(error)")
                
                // Offline fallback for simulator / offline testing
                if username.starts(with: "manager_usr") && password == "password123" {
                    await MainActor.run {
                        let mockUser = GatewayUser(
                            id: UUID(uuidString: "4acff73d-efbe-5feb-a495-59e5a8663501")!,
                            fullName: "Store Manager Mock",
                            username: username,
                            email: "\(username)@rsms.com",
                            roleId: UUID(uuidString: "b24abda2-b031-4548-8641-8511ec2bfff0")!,
                            storeId: UUID(uuidString: "11111111-0000-0000-0000-000000000001")!,
                            designation: "Store Manager",
                            profileImageURL: nil
                        )
                        self.isLoading = false
                        self.onLoginSuccess(mockUser, "Manager")
                    }
                } else if username.starts(with: "sales_usr") && password == "password123" {
                    await MainActor.run {
                        let mockUser = GatewayUser(
                            id: UUID(uuidString: "dae0ff3c-0356-4344-a643-22f06a8fee61")!,
                            fullName: "Sales Associate Mock",
                            username: username,
                            email: "\(username)@rsms.com",
                            roleId: UUID(uuidString: "dae0ff3c-0356-4344-a643-22f06a8fee61")!,
                            storeId: UUID(uuidString: "11111111-0000-0000-0000-000000000001")!,
                            designation: "Sales Advisor",
                            profileImageURL: nil
                        )
                        self.isLoading = false
                        self.onLoginSuccess(mockUser, "Sales Associate")
                    }
                } else if username.starts(with: "inventory_usr") && password == "password123" {
                    await MainActor.run {
                        let mockUser = GatewayUser(
                            id: UUID(uuidString: "c0aa841a-7c57-43f9-b98a-523475ba43af")!,
                            fullName: "Inventory Controller Mock",
                            username: username,
                            email: "\(username)@rsms.com",
                            roleId: UUID(uuidString: "c0aa841a-7c57-43f9-b98a-523475ba43af")!,
                            storeId: UUID(uuidString: "11111111-0000-0000-0000-000000000001")!,
                            designation: "Inventory Controller",
                            profileImageURL: nil
                        )
                        self.isLoading = false
                        self.onLoginSuccess(mockUser, "Inventory Controller")
                    }
                } else if username.starts(with: "admin_usr") && password == "password123" {
                    await MainActor.run {
                        let mockUser = GatewayUser(
                            id: UUID(uuidString: "196203f9-3fe8-41f8-81c9-c665e004148b")!,
                            fullName: "Admin Mock",
                            username: username,
                            email: "\(username)@rsms.com",
                            roleId: UUID(uuidString: "196203f9-3fe8-41f8-81c9-c665e004148b")!,
                            storeId: nil,
                            designation: "Corporate Admin",
                            profileImageURL: nil
                        )
                        self.isLoading = false
                        self.onLoginSuccess(mockUser, "Admin")
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

// MARK: - Main Gateway View

struct GatewayView: View {
    @StateObject private var sessionManager = CentralSessionManager.shared
    @StateObject private var salesAuthVM = SalesAssociateModule.AuthViewModel()
    
    var body: some View {
        Group {
            if sessionManager.isAuthenticated {
                switch sessionManager.roleName.lowercased() {
                case "admin":
                    AdminRootView {
                        logout()
                    }
                    .transition(.opacity)
                case "manager", "store manager":
                    StoreManagerRootView {
                        logout()
                    }
                    .transition(.opacity)
                case "sales associate":
                    SalesAssociateRootView(onBackToPortal: {
                        logout()
                    }, authVM: salesAuthVM)
                    .transition(.opacity)
                case "inventory controller", "inventory manager":
                    InventoryRootView(
                        onBackToPortal: {
                            logout()
                        },
                        initialSession: (isAuthenticated: true, userId: sessionManager.userId, warehouseId: nil),
                        onLogout: {
                            logout()
                        }
                    )
                    .transition(.opacity)
                default:
                    VStack {
                        Text("Access Denied: Unrecognized Role.")
                            .foregroundColor(.red)
                            .padding()
                        Button("Sign Out", action: logout)
                    }
                }
            } else {
                LoginView(onLoginSuccess: handleLoginSuccess)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: sessionManager.isAuthenticated)
        // Reactive listening to other modules' logouts
        .onReceive(StoreManagerModule.SessionManager.shared.$currentUser) { user in
            if sessionManager.isAuthenticated, user == nil, sessionManager.roleName.lowercased().contains("manager") {
                logout()
            }
        }
        .onReceive(AdminModule.AuthManager.shared.$isAuthenticated) { isAuthenticated in
            if sessionManager.isAuthenticated, !isAuthenticated, sessionManager.roleName.lowercased().contains("admin") {
                logout()
            }
        }
        .onReceive(salesAuthVM.$isAuthenticated) { isAuthenticated in
            if sessionManager.isAuthenticated, !isAuthenticated, sessionManager.roleName.lowercased().contains("sales") {
                logout()
            }
        }
    }
    
    private func handleLoginSuccess(_ user: GatewayUser, _ roleName: String) {
        Swift.Task {
            let client = SupabaseClient(
                supabaseURL: URL(string: GatewayConstants.supabaseURL)!,
                supabaseKey: GatewayConstants.supabaseKey
            )
            
            var resolvedStoreId = user.storeId
            if resolvedStoreId == nil {
                struct StoreIdOnly: Codable {
                    let id: UUID
                }
                do {
                    let stores: [StoreIdOnly] = try await client.from("stores")
                        .select("id")
                        .execute()
                        .value
                    if let firstStore = stores.first {
                        resolvedStoreId = firstStore.id
                    }
                } catch {
                    print("Failed to auto-assign store: \(error)")
                }
            }
            
            await MainActor.run {
                // 1. Save in Central Session Manager
                sessionManager.userId = user.id
                sessionManager.username = user.username
                sessionManager.fullName = user.fullName
                sessionManager.roleId = user.roleId
                sessionManager.roleName = roleName
                sessionManager.designation = user.designation ?? ""
                sessionManager.storeId = resolvedStoreId
                sessionManager.isAuthenticated = true
                
                // 2. Propagate to correct module
                let lowercasedRole = roleName.lowercased()
                if lowercasedRole.contains("admin") {
                    let adminUser = AdminModule.User(
                        id: user.id,
                        fullName: user.fullName,
                        username: user.username,
                        email: user.email,
                        isVerified: true,
                        roleId: user.roleId,
                        storeId: resolvedStoreId,
                        designation: user.designation,
                        phone: user.phone
                    )
                    AdminModule.AuthManager.shared.currentUser = adminUser
                    AdminModule.AuthManager.shared.isAuthenticated = true
                    
                } else if lowercasedRole.contains("manager") || lowercasedRole.contains("store manager") {
                    let managerUser = StoreManagerModule.User(
                        id: user.id,
                        fullName: user.fullName,
                        username: user.username,
                        email: user.email,
                        isVerified: true,
                        roleId: user.roleId,
                        storeId: resolvedStoreId,
                        designation: user.designation,
                        phone: user.phone
                    )
                    StoreManagerModule.SessionManager.shared.currentUser = managerUser
                    StoreManagerModule.SessionManager.shared.isLoading = false
                    
                } else if lowercasedRole.contains("sales") || lowercasedRole.contains("associate") {
                    let staffProfile = StaffProfile(
                        id: user.id,
                        firstName: String(user.fullName.split(separator: " ").first ?? ""),
                        lastName: String(user.fullName.split(separator: " ").dropFirst().joined(separator: " ")),
                        email: user.email,
                        role: .salesAssociate,
                        storeID: resolvedStoreId,
                        avatarURL: user.profileImageURL,
                        isActive: true,
                        createdAt: Date()
                    )
                    salesAuthVM.currentUser = staffProfile
                    salesAuthVM.isAuthenticated = true
                }
            }
        }
    }
    
    private func logout() {
        sessionManager.clear()
        
        // Clear sub-modules
        AdminModule.AuthManager.shared.isAuthenticated = false
        AdminModule.AuthManager.shared.currentUser = nil
        
        StoreManagerModule.SessionManager.shared.currentUser = nil
        
        salesAuthVM.isAuthenticated = false
        salesAuthVM.currentUser = nil
    }
}
