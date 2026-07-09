import SwiftUI
import AdminModule
import InventoryModule
import StoreManagerModule
import SalesAssociateModule
import Supabase
import Combine
import Foundation

// MARK: - Gateway Constants

public enum GatewayConstants {
    public static let supabaseURL = "https://yldspqgtzyrbdnoromgv.supabase.co"
    public static let supabaseKey = "sb_publishable_6hcPNWOppBItrHk7_F7LoQ_0eGNXAL5"
}


// MARK: - Gateway User

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

    /// Maps directly to the `profile_verified`
    /// column in the Supabase users table.
    let isProfileCompleted: Bool?

    let employeeCode: String?
    let gender: String?
    let dateOfBirth: String?
    let address: String?

    init(
        id: UUID,
        fullName: String,
        username: String,
        email: String,
        roleId: UUID,
        storeId: UUID? = nil,
        designation: String? = nil,
        phone: String? = nil,
        profileImageURL: String? = nil,
        isProfileCompleted: Bool? = nil,
        employeeCode: String? = nil,
        gender: String? = nil,
        dateOfBirth: String? = nil,
        address: String? = nil
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
        self.isProfileCompleted = isProfileCompleted
        self.employeeCode = employeeCode
        self.gender = gender
        self.dateOfBirth = dateOfBirth
        self.address = address
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

        // IMPORTANT:
        // profile_verified from Supabase becomes
        // isProfileCompleted inside the application.
        case isProfileCompleted = "profile_verified"

        case employeeCode = "employee_code"
        case gender
        case dateOfBirth = "date_of_birth"
        case address
    }
}

extension GatewayUser {
    func toStoreManagerUser() -> StoreManagerModule.User {
        return StoreManagerModule.User(
            id: self.id,
            fullName: self.fullName,
            username: self.username,
            email: self.email,
            isVerified: true,
            roleId: self.roleId,
            storeId: self.storeId,
            employeeCode: self.employeeCode,
            designation: self.designation,
            phone: self.phone,
            gender: self.gender,
            dateOfBirth: self.dateOfBirth,
            address: self.address,
            profileImageURL: self.profileImageURL,
            isProfileCompleted: self.isProfileCompleted ?? false
        )
    }
}

extension StoreManagerModule.User {
    func toGatewayUser() -> GatewayUser {
        return GatewayUser(
            id: self.id,
            fullName: self.fullName,
            username: self.username,
            email: self.email,
            roleId: self.roleId,
            storeId: self.storeId,
            designation: self.designation,
            phone: self.phone,
            profileImageURL: self.profileImageURL,
            isProfileCompleted: self.isProfileCompleted,
            employeeCode: self.employeeCode,
            gender: self.gender,
            dateOfBirth: self.dateOfBirth,
            address: self.address
        )
    }
}



// MARK: - Gateway Role

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


// MARK: - Login View

struct LoginView: View {

    @State private var username = ""
    @State private var password = ""

    @State private var showPassword = false
    @State private var isLoading = false

    @State private var errorMessage: String? = nil

    var onLoginSuccess: (GatewayUser, String) -> Void


    // MARK: Device Detection

    private var isIPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }


    // MARK: Body

    var body: some View {

        ZStack {

            // Dark background
            Color(
                red: 0.11,
                green: 0.11,
                blue: 0.11
            )
            .ignoresSafeArea()


            if isIPad {

                // MARK: iPad Layout

                HStack(spacing: 0) {

                    heroImage
                        .padding(24)

                    VStack {

                        Spacer()

                        formArea

                        Spacer()
                    }
                    .frame(maxWidth: 450)
                    .padding(.horizontal, 40)
                }

            } else {

                // MARK: iPhone Layout

                VStack(spacing: 0) {

                    heroImage
                        .frame(
                            height: UIScreen.main.bounds.height * 0.45
                        )
                        .ignoresSafeArea(edges: .top)

                    formArea
                }
            }
        }
        .preferredColorScheme(.dark)
    }


    // MARK: Hero Image

    private var heroImage: some View {

        GeometryReader { geometry in

            ZStack {

                Image("WhatsApp Image 2026-07-09 at 11.11.01")
                    .resizable()
                    .scaledToFill()
                    .frame(
                        width: geometry.size.width,
                        height: geometry.size.height
                    )
                    .clipShape(
                        UnevenRoundedRectangle(
                            topLeadingRadius: isIPad ? 40 : 0,
                            bottomLeadingRadius: 40,
                            bottomTrailingRadius: 40,
                            topTrailingRadius: isIPad ? 40 : 0
                        )
                    )
                    .clipped()


                if !isIPad {

                    VStack {

                        HStack {

                            Text("Sutraa")
                                .font(
                                    .system(
                                        size: 44,
                                        weight: .bold
                                    )
                                )
                                .foregroundColor(.white)

                            Spacer()
                        }

                        Spacer()
                    }
                    .padding(.top, 70)
                    .padding(.leading, 30)
                }
            }
        }
    }


    // MARK: Login Form

    private var formArea: some View {

        VStack(spacing: 24) {

            if isIPad {

                Text("Sutraa")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .frame(
                        maxWidth: .infinity,
                        alignment: .leading
                    )
                    .padding(.bottom, 8)
            }


            // MARK: Username

            VStack(
                alignment: .leading,
                spacing: 8
            ) {

                Text("Email address")
                    .font(.subheadline)
                    .foregroundColor(.gray)


                TextField(
                    "Enter your username",
                    text: $username
                )
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(
                    Color(
                        red: 0.16,
                        green: 0.16,
                        blue: 0.17
                    )
                )
                .clipShape(Capsule())
                .foregroundColor(.white)
                .autocapitalization(.none)
                .disableAutocorrection(true)
            }


            // MARK: Password

            VStack(
                alignment: .leading,
                spacing: 8
            ) {

                Text("Password")
                    .font(.subheadline)
                    .foregroundColor(.gray)


                HStack {

                    if showPassword {

                        TextField(
                            "Enter password",
                            text: $password
                        )
                        .foregroundColor(.white)

                    } else {

                        SecureField(
                            "Enter password",
                            text: $password
                        )
                        .foregroundColor(.white)
                    }


                    Button {
                        showPassword.toggle()
                    } label: {

                        Image(
                            systemName:
                                showPassword
                                ? "eye.slash"
                                : "eye"
                        )
                        .foregroundColor(.gray)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(
                    Color(
                        red: 0.16,
                        green: 0.16,
                        blue: 0.17
                    )
                )
                .clipShape(Capsule())
            }


            // MARK: Error

            if let error = errorMessage {

                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
            }


            // MARK: Continue Button

            Button(action: attemptLogin) {

                HStack {

                    Spacer()

                    if isLoading {

                        ProgressView()
                            .tint(.black)

                    } else {

                        Text("Continue")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.black)
                    }

                    Spacer()
                }
                .padding(.vertical, 16)
                .background(Color.white)
                .clipShape(Capsule())
            }
            .disabled(
                isLoading
                || username.isEmpty
                || password.isEmpty
            )
            .opacity(
                isLoading
                || username.isEmpty
                || password.isEmpty
                ? 0.6
                : 1
            )
            .padding(.top, 8)


            if !isIPad {
                Spacer()
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, isIPad ? 0 : 30)
    }


    // MARK: Login Logic

    private func attemptLogin() {

        isLoading = true
        errorMessage = nil


        let client = SupabaseClient(
            supabaseURL: URL(
                string: GatewayConstants.supabaseURL
            )!,
            supabaseKey: GatewayConstants.supabaseKey
        )


        Task {

            do {

                // Fetch user using username + password.
                //
                // The returned GatewayUser automatically maps:
                //
                // profile_verified
                //       ↓
                // isProfileCompleted

                let users: [GatewayUser] = try await client
                    .from("users")
                    .select()
                    .eq(
                        "username",
                        value: username
                    )
                    .eq(
                        "password",
                        value: password
                    )
                    .execute()
                    .value


                guard let user = users.first else {

                    await MainActor.run {

                        errorMessage =
                            "Invalid username or password."

                        isLoading = false
                    }

                    return
                }


                // Fetch user's role.

                let roles: [GatewayRole] = try await client
                    .from("roles")
                    .select()
                    .eq(
                        "id",
                        value: user.roleId.uuidString
                    )
                    .execute()
                    .value


                guard let role = roles.first else {

                    await MainActor.run {

                        errorMessage =
                            "Failed to retrieve user role."

                        isLoading = false
                    }

                    return
                }


                await MainActor.run {

                    isLoading = false

                    onLoginSuccess(
                        user,
                        role.roleName
                    )
                }


            } catch {

                print(
                    "Login error: \(error)"
                )

                await handleOfflineFallback()
            }
        }
    }


    // MARK: Offline Development Fallback

    @MainActor
    private func handleOfflineFallback() {

        if username.starts(with: "manager_usr"),
           password == "password123" {

            let mockUser = GatewayUser(
                id: UUID(
                    uuidString:
                        "4acff73d-efbe-5feb-a495-59e5a8663501"
                )!,
                fullName: "Store Manager Mock",
                username: username,
                email: "\(username)@rsms.com",
                roleId: UUID(
                    uuidString:
                        "b24abda2-b031-4548-8641-8511ec2bfff0"
                )!,
                storeId: UUID(
                    uuidString:
                        "11111111-0000-0000-0000-000000000001"
                )!,
                designation: "Store Manager",
                profileImageURL: nil,
                isProfileCompleted: false
            )

            isLoading = false

            onLoginSuccess(
                mockUser,
                "Manager"
            )

        } else if username.starts(with: "sales_usr"),
                  password == "password123" {

            let mockUser = GatewayUser(
                id: UUID(
                    uuidString:
                        "dae0ff3c-0356-4344-a643-22f06a8fee61"
                )!,
                fullName: "Sales Associate Mock",
                username: username,
                email: "\(username)@rsms.com",
                roleId: UUID(
                    uuidString:
                        "dae0ff3c-0356-4344-a643-22f06a8fee61"
                )!,
                storeId: UUID(
                    uuidString:
                        "11111111-0000-0000-0000-000000000001"
                )!,
                designation: "Sales Advisor",
                profileImageURL: nil,

                // Set false to test first-time
                // Sales Associate onboarding.
                isProfileCompleted: false
            )

            isLoading = false

            onLoginSuccess(
                mockUser,
                "Sales Associate"
            )

        } else if username.starts(with: "inventory_usr"),
                  password == "password123" {

            let mockUser = GatewayUser(
                id: UUID(
                    uuidString:
                        "c0aa841a-7c57-43f9-b98a-523475ba43af"
                )!,
                fullName: "Inventory Controller Mock",
                username: username,
                email: "\(username)@rsms.com",
                roleId: UUID(
                    uuidString:
                        "c0aa841a-7c57-43f9-b98a-523475ba43af"
                )!,
                storeId: UUID(
                    uuidString:
                        "11111111-0000-0000-0000-000000000001"
                )!,
                designation: "Inventory Controller",
                profileImageURL: nil,
                isProfileCompleted: true
            )

            isLoading = false

            onLoginSuccess(
                mockUser,
                "Inventory Controller"
            )

        } else if username.starts(with: "admin_usr"),
                  password == "password123" {

            let mockUser = GatewayUser(
                id: UUID(
                    uuidString:
                        "196203f9-3fe8-41f8-81c9-c665e004148b"
                )!,
                fullName: "Admin Mock",
                username: username,
                email: "\(username)@rsms.com",
                roleId: UUID(
                    uuidString:
                        "196203f9-3fe8-41f8-81c9-c665e004148b"
                )!,
                storeId: nil,
                designation: "Corporate Admin",
                profileImageURL: nil,
                isProfileCompleted: true
            )

            isLoading = false

            onLoginSuccess(
                mockUser,
                "Admin"
            )

        } else {

            errorMessage =
                "Connection error. Please try again."

            isLoading = false
        }
    }
}


// MARK: - Main Gateway View

struct GatewayView: View {

    @StateObject private var sessionManager =
        CentralSessionManager.shared

    @StateObject private var salesAuthVM =
        SalesAssociateModule.AuthViewModel()


    @State private var showManagerOnboarding = false

    @State private var pendingManagerUser: GatewayUser? = nil


    var body: some View {

        Group {

            if sessionManager.isAuthenticated {

                authenticatedDestination

            } else if showManagerOnboarding,
                      let user = pendingManagerUser {

                managerOnboardingView(for: user)

            } else {

                LoginView(
                    onLoginSuccess:
                        handleLoginSuccessInterceptor
                )
                .transition(.opacity)
            }
        }
        .animation(
            .easeInOut(duration: 0.3),
            value: sessionManager.isAuthenticated
        )

        // MARK: Listen for Store Manager logout

        .onReceive(
            StoreManagerModule
                .SessionManager
                .shared
                .$currentUser
        ) { user in

            let role =
                sessionManager.roleName.lowercased()

            if sessionManager.isAuthenticated,
               user == nil,
               (
                    role == "manager"
                    || role == "store manager"
               ) {

                logout()
            }
        }


        // MARK: Listen for Admin logout

        .onReceive(
            AdminModule
                .AuthManager
                .shared
                .$isAuthenticated
        ) { isAuthenticated in

            if sessionManager.isAuthenticated,
               !isAuthenticated,
               sessionManager
                    .roleName
                    .lowercased()
                    .contains("admin") {

                logout()
            }
        }


        // MARK: Listen for Sales Associate logout

        .onReceive(
            salesAuthVM.$isAuthenticated
        ) { isAuthenticated in

            if sessionManager.isAuthenticated,
               !isAuthenticated,
               sessionManager
                    .roleName
                    .lowercased()
                    .contains("sales") {

                logout()
            }
        }
    }


    // MARK: - Authenticated Destination

    @ViewBuilder
    private var authenticatedDestination: some View {

        switch sessionManager.roleName.lowercased() {

        case "admin":

            AdminRootView {
                logout()
            }
            .transition(.opacity)


        case "manager", "store manager":

            if sessionManager.storeId == nil {

                NoStoreAssignedView {
                    logout()
                }
                .transition(.opacity)

            } else {

                StoreManagerRootView {
                    logout()
                }
                .transition(.opacity)
            }


        case "sales associate":

            SalesAssociateRootView(
                onBackToPortal: {
                    logout()
                },
                authVM: salesAuthVM
            )
            .transition(.opacity)


        case "inventory controller",
             "inventory manager":

            InventoryRootView(
                onBackToPortal: {
                    logout()
                },
                initialSession: (
                    isAuthenticated: true,
                    userId: sessionManager.userId,
                    warehouseId: nil
                ),
                onLogout: {
                    logout()
                }
            )
            .transition(.opacity)


        default:

            VStack(spacing: 20) {

                Text(
                    "Access Denied: Unrecognized Role."
                )
                .foregroundColor(.red)

                Button(
                    "Sign Out",
                    action: logout
                )
            }
            .padding()
        }
    }


    // MARK: - Store Manager Onboarding

    @ViewBuilder
    private func managerOnboardingView(
        for user: GatewayUser
    ) -> some View {

        StoreManagerOnboardingView(
            user: user.toStoreManagerUser(),

            onComplete: { updatedUser in
                showManagerOnboarding = false
                handleLoginSuccessInterceptor(
                    updatedUser.toGatewayUser(),
                    "Store Manager"
                )
            },

            onLogout: {
                logout()
            }
        )
        .transition(.opacity)
    }


    // MARK: - Login Interceptor

    private func handleLoginSuccessInterceptor(
        _ user: GatewayUser,
        _ roleName: String
    ) {

        let role = roleName.lowercased()


        // Store Manager onboarding interception.

        if role == "manager"
            || role == "store manager" {

            if !(user.isProfileCompleted ?? false) {

                pendingManagerUser = user

                showManagerOnboarding = true

                return
            }
        }


        // Sales Associate does NOT need to be
        // intercepted here.
        //
        // Its profile_verified state is propagated
        // into StaffProfile.isProfileCompleted.
        //
        // SalesAssociateRootView can therefore
        // force CompleteProfileView when false.

        handleLoginSuccess(
            user,
            roleName
        )
    }


    // MARK: - Complete Login

    private func handleLoginSuccess(
        _ user: GatewayUser,
        _ roleName: String
    ) {

        Task {

            let client = SupabaseClient(
                supabaseURL: URL(
                    string:
                        GatewayConstants.supabaseURL
                )!,
                supabaseKey:
                    GatewayConstants.supabaseKey
            )


            var resolvedStoreId = user.storeId


            let role = roleName.lowercased()


            let isManagerRole =
                role == "manager"
                || role == "store manager"


            // Preserve the existing fallback behaviour:
            // if a non-manager has no store,
            // use the first available store.

            if resolvedStoreId == nil,
               !isManagerRole {

                struct StoreIdOnly: Codable {
                    let id: UUID
                }


                do {

                    let stores: [StoreIdOnly] =
                        try await client
                            .from("stores")
                            .select("id")
                            .execute()
                            .value


                    if let firstStore = stores.first {
                        resolvedStoreId =
                            firstStore.id
                    }

                } catch {

                    print(
                        "Failed to auto-assign store: \(error)"
                    )
                }
            }


            await MainActor.run {

                // MARK: Central Session

                sessionManager.userId = user.id

                sessionManager.username =
                    user.username

                sessionManager.fullName =
                    user.fullName

                sessionManager.roleId =
                    user.roleId

                sessionManager.roleName =
                    roleName

                sessionManager.designation =
                    user.designation ?? ""

                sessionManager.storeId =
                    resolvedStoreId

                sessionManager.isAuthenticated =
                    true


                // MARK: Admin Module

                if role.contains("admin") {

                    let adminUser =
                        AdminModule.User(
                            id: user.id,
                            fullName:
                                user.fullName,
                            username:
                                user.username,
                            email:
                                user.email,
                            isVerified: true,
                            roleId:
                                user.roleId,
                            storeId:
                                resolvedStoreId,
                            designation:
                                user.designation,
                            phone:
                                user.phone
                        )


                    AdminModule
                        .AuthManager
                        .shared
                        .currentUser = adminUser


                    AdminModule
                        .AuthManager
                        .shared
                        .isAuthenticated = true
                }


                // MARK: Store Manager Module

                else if role == "manager"
                    || role == "store manager" {

                    let managerUser =
                        StoreManagerModule.User(
                            id: user.id,
                            fullName:
                                user.fullName,
                            username:
                                user.username,
                            email:
                                user.email,
                            isVerified: true,
                            roleId:
                                user.roleId,
                            storeId:
                                resolvedStoreId,
                            employeeCode:
                                user.employeeCode,
                            designation:
                                user.designation,
                            phone:
                                user.phone,
                            gender:
                                user.gender,
                            dateOfBirth:
                                user.dateOfBirth,
                            address:
                                user.address,
                            profileImageURL:
                                user.profileImageURL,
                            isProfileCompleted:
                                user.isProfileCompleted
                                ?? false
                        )


                    StoreManagerModule
                        .SessionManager
                        .shared
                        .currentUser = managerUser


                    StoreManagerModule
                        .SessionManager
                        .shared
                        .isLoading = false
                }


                // MARK: Sales Associate Module

                else if role.contains("sales")
                    || role.contains("associate") {

                    let nameParts =
                        user.fullName.split(
                            separator: " "
                        )


                    let firstName =
                        String(
                            nameParts.first ?? ""
                        )


                    let lastName =
                        String(
                            nameParts
                                .dropFirst()
                                .joined(
                                    separator: " "
                                )
                        )


                    let staffProfile = StaffProfile(
                        id: user.id,

                        firstName: firstName,

                        lastName: lastName,

                        email: user.email,

                        role: .salesAssociate,

                        storeID: resolvedStoreId,

                        avatarURL:
                            user.profileImageURL,

                        isActive: true,

                        createdAt: Date(),

                        isProfileCompleted: user.isProfileCompleted ?? false
                    )


                    salesAuthVM.currentUser =
                        staffProfile


                    salesAuthVM.isAuthenticated =
                        true
                }
            }
        }
    }


    // MARK: - Logout

    private func logout() {

        // Clear gateway session.

        sessionManager.clear()


        // Clear manager onboarding.

        showManagerOnboarding = false

        pendingManagerUser = nil


        // Clear Admin module.

        AdminModule
            .AuthManager
            .shared
            .isAuthenticated = false


        AdminModule
            .AuthManager
            .shared
            .currentUser = nil


        // Clear Store Manager module.

        StoreManagerModule
            .SessionManager
            .shared
            .currentUser = nil


        // Clear Sales Associate module.

        salesAuthVM.isAuthenticated = false

        salesAuthVM.currentUser = nil
    }
}

