import SwiftUI
import Supabase
import PhotosUI

struct StoreManagerOnboardingView: View {
    let user: GatewayUser
    var onComplete: (GatewayUser) -> Void
    var onLogout: () -> Void
    
    @State private var path = NavigationPath()
    
    var body: some View {
        NavigationStack(path: $path) {
            WelcomeScreen(path: $path)
                .navigationDestination(for: String.self) { value in
                    switch value {
                    case "Responsibilities":
                        ResponsibilitiesScreen(path: $path)
                    case "ProfileCompletion":
                        ProfileCompletionScreen(user: user, path: $path, onComplete: onComplete)
                    case "Success":
                        SuccessScreen(user: user, onComplete: onComplete)
                    default:
                        EmptyView()
                    }
                }
        }
    }
}

struct WelcomeScreen: View {
    @Binding var path: NavigationPath
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            Image(systemName: "person.crop.circle.badge.checkmark")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .foregroundColor(.blue)
            
            VStack(spacing: 16) {
                Text("Welcome to RSMS")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Welcome!\n\nYour account has been created successfully.\n\nLet's finish setting up your profile before you begin managing your store.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }
            
            Spacer()
            
            Button(action: {
                path.append("Responsibilities")
            }) {
                Text("Continue")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(Color.blue)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
        .navigationBarHidden(true)
    }
}

struct ResponsibilitiesScreen: View {
    @Binding var path: NavigationPath
    
    let responsibilities = [
        ("person.3.fill", "Manage Employees"),
        ("shippingbox.fill", "Monitor Store Inventory"),
        ("chart.bar.fill", "Monitor Sales Performance"),
        ("checklist", "Create and Assign Tasks"),
        ("arrow.3.trianglepath", "Request Stock Replenishment"),
        ("doc.text.fill", "View Store Reports")
    ]
    
    var body: some View {
        VStack(spacing: 24) {
            Text("Your Responsibilities")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.top, 40)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
            
            List {
                ForEach(responsibilities, id: \.1) { item in
                    HStack(spacing: 16) {
                        Image(systemName: item.0)
                            .foregroundColor(.blue)
                            .frame(width: 30)
                        Text(item.1)
                            .font(.headline)
                    }
                    .padding(.vertical, 8)
                }
            }
            .listStyle(PlainListStyle())
            
            Button(action: {
                path.append("ProfileCompletion")
            }) {
                Text("Continue")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(Color.blue)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
        .navigationBarHidden(true)
    }
}

struct ProfileCompletionScreen: View {
    let user: GatewayUser
    @Binding var path: NavigationPath
    var onComplete: (GatewayUser) -> Void
    
    @State private var username: String = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var showNewPassword = false
    @State private var showConfirmPassword = false
    
    @State private var phone = ""
    @State private var gender = "Male"
    @State private var dateOfBirth = Date()
    @State private var address = ""
    @State private var profileImageURL = ""
    
    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    @State private var selectedPhotoData: Data? = nil
    
    @State private var usernameError: String? = nil
    @State private var passwordError: String? = nil
    @State private var phoneError: String? = nil
    @State private var ageError: String? = nil
    @State private var addressError: String? = nil
    
    @State private var isLoading = false
    @State private var errorMessage: String? = nil
    @State private var showErrorAlert = false
    
    let genders = ["Male", "Female", "Other", "Prefer not to say"]
    
    init(user: GatewayUser, path: Binding<NavigationPath>, onComplete: @escaping (GatewayUser) -> Void) {
        self.user = user
        self._path = path
        self.onComplete = onComplete
        self._username = State(initialValue: user.username)
        self._phone = State(initialValue: user.phone ?? "")
        self._gender = State(initialValue: user.gender ?? "Male")
        self._address = State(initialValue: user.address ?? "")
        self._profileImageURL = State(initialValue: user.profileImageURL ?? "")
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        if let dobString = user.dateOfBirth, let dob = formatter.date(from: dobString) {
            self._dateOfBirth = State(initialValue: dob)
        } else {
            // Default to 18 years ago
            self._dateOfBirth = State(initialValue: Calendar.current.date(byAdding: .year, value: -18, to: Date())!)
        }
    }
    
    private var maxDate: Date {
        Calendar.current.date(byAdding: .year, value: -18, to: Date())!
    }
    
    var body: some View {
        Form {
            Section(header: Text("Account Information"), footer: Text("Your username is currently your email address. You may change it now or keep it as is.")) {
                TextField("Username", text: $username)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                if let error = usernameError {
                    Text(error).foregroundColor(.red).font(.caption)
                }
                
                HStack {
                    if showNewPassword {
                        TextField("New Password", text: $newPassword)
                    } else {
                        SecureField("New Password", text: $newPassword)
                    }
                    Button(action: { showNewPassword.toggle() }) {
                        Image(systemName: showNewPassword ? "eye.slash" : "eye")
                            .foregroundColor(.gray)
                    }
                }
                
                HStack {
                    if showConfirmPassword {
                        TextField("Confirm Password", text: $confirmPassword)
                    } else {
                        SecureField("Confirm Password", text: $confirmPassword)
                    }
                    Button(action: { showConfirmPassword.toggle() }) {
                        Image(systemName: showConfirmPassword ? "eye.slash" : "eye")
                            .foregroundColor(.gray)
                    }
                }
                if let error = passwordError {
                    Text(error).foregroundColor(.red).font(.caption)
                }
            }
            
            Section(header: Text("Personal Information")) {
                HStack {
                    Spacer()
                    PhotosPicker(selection: $selectedPhotoItem, matching: .images, photoLibrary: .shared()) {
                        if let selectedPhotoData, let uiImage = UIImage(data: selectedPhotoData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 80, height: 80)
                                .clipShape(Circle())
                        } else {
                            Image(systemName: "person.crop.circle.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 80, height: 80)
                                .foregroundColor(.gray)
                        }
                    }
                    .onChange(of: selectedPhotoItem) { oldValue, newValue in
                        Task {
                            if let data = try? await newValue?.loadTransferable(type: Data.self) {
                                selectedPhotoData = data
                            }
                        }
                    }
                    Spacer()
                }
                .padding(.vertical, 8)
                
                TextField("Phone Number", text: $phone)
                    .keyboardType(.numberPad)
                if let error = phoneError {
                    Text(error).foregroundColor(.red).font(.caption)
                }
                
                Picker("Gender", selection: $gender) {
                    ForEach(genders, id: \.self) { g in
                        Text(g).tag(g)
                    }
                }
                
                DatePicker("Date of Birth", selection: $dateOfBirth, in: ...maxDate, displayedComponents: .date)
                if let error = ageError {
                    Text(error).foregroundColor(.red).font(.caption)
                }
                
                TextField("Address", text: $address)
                if let error = addressError {
                    Text(error).foregroundColor(.red).font(.caption)
                }
            }
            
            Section(header: Text("Company Information")) {
                HStack {
                    Text("Full Name")
                    Spacer()
                    Text(user.fullName).foregroundColor(.secondary)
                }
                HStack {
                    Text("Email")
                    Spacer()
                    Text(user.email).foregroundColor(.secondary)
                }
                HStack {
                    Text("Employee Code")
                    Spacer()
                    Text(user.employeeCode ?? "N/A").foregroundColor(.secondary)
                }
                HStack {
                    Text("Designation")
                    Spacer()
                    Text(user.designation ?? "N/A").foregroundColor(.secondary)
                }
                HStack {
                    Text("Assigned Store")
                    Spacer()
                    Text(user.storeId?.uuidString ?? "Not Assigned").foregroundColor(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
            }
            
            Section {
                Button(action: saveProfile) {
                    HStack {
                        Spacer()
                        if isLoading {
                            ProgressView()
                            Text("Uploading...")
                                .foregroundColor(.secondary)
                                .padding(.leading, 8)
                        } else {
                            Text("Finish")
                                .fontWeight(.bold)
                        }
                        Spacer()
                    }
                }
                .disabled(isLoading)
            }
        }
        .navigationTitle("Complete Your Profile")
        .navigationBarBackButtonHidden(isLoading)
        .alert(isPresented: $showErrorAlert) {
            Alert(
                title: Text("Error"),
                message: Text(errorMessage ?? "An unknown error occurred."),
                primaryButton: .default(Text("Retry"), action: {
                    saveProfile()
                }),
                secondaryButton: .cancel()
            )
        }
    }
    
    private func saveProfile() {
        errorMessage = nil
        usernameError = nil
        passwordError = nil
        phoneError = nil
        ageError = nil
        addressError = nil
        var hasError = false
        
        // 1. Validation
        let usernameRegex = "^[a-zA-Z0-9_.]{4,25}$"
        if username.range(of: usernameRegex, options: .regularExpression) == nil {
            usernameError = "Username must be 4-25 characters and contain only letters, numbers, underscores, or periods."
            hasError = true
        }
        
        if newPassword.isEmpty || confirmPassword.isEmpty {
            passwordError = "Please enter and confirm your password."
            hasError = true
        } else if newPassword != confirmPassword {
            passwordError = "Passwords do not match."
            hasError = true
        } else if newPassword.count < 6 {
            passwordError = "Password must be at least 6 characters long."
            hasError = true
        }
        
        if phone.count != 10 || Int(phone) == nil {
            phoneError = "Phone number must be exactly 10 digits."
            hasError = true
        }
        
        let ageComponents = Calendar.current.dateComponents([.year], from: dateOfBirth, to: Date())
        if let age = ageComponents.year, age < 18 {
            ageError = "You must be at least 18 years old."
            hasError = true
        }
        
        if address.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            addressError = "Address cannot be empty."
            hasError = true
        }
        
        if hasError { return }
        
        isLoading = true
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dobString = formatter.string(from: dateOfBirth)
        
        print("Starting onboarding save...")
        
        Task {
            let client = SupabaseClient(
                supabaseURL: URL(string: GatewayConstants.supabaseURL)!,
                supabaseKey: GatewayConstants.supabaseKey
            )
            
            // Check username uniqueness
            if username != user.username {
                print("Checking username...")
                do {
                    struct UsernameCheck: Codable {
                        let id: UUID
                    }
                    let existingUsers: [UsernameCheck] = try await client.from("users")
                        .select("id")
                        .eq("username", value: username)
                        .execute()
                        .value
                    
                    if !existingUsers.isEmpty {
                        await MainActor.run {
                            self.errorMessage = "This username is already taken."
                            self.showErrorAlert = true
                            self.isLoading = false
                        }
                        return
                    }
                } catch {
                    print("========== ERROR ==========")
                    print("Error:", error)
                    print("Localized:", error.localizedDescription)
                    print("Reflection:", String(reflecting: error))
                    print("===========================")
                    if let pgError = error as? PostgrestError {
                        print("PostgrestError:", pgError)
                    }
                    
                    await MainActor.run {
                        let alertMsg = error.localizedDescription.isEmpty ? String(reflecting: error) : error.localizedDescription
                        self.errorMessage = alertMsg
                        self.showErrorAlert = true
                        self.isLoading = false
                    }
                    return
                }
            }
            
            // Upload image if selected
            var finalProfileImageURL = profileImageURL.isEmpty ? nil : profileImageURL
            if let photoData = selectedPhotoData, let uiImage = UIImage(data: photoData) {
                if let jpegData = uiImage.jpegData(compressionQuality: 0.8) {
                    let path = "profiles/\(user.id.uuidString).jpg"
                    print("Uploading profile image...")
                    do {
                        try await client.storage
                            .from("store-images")
                            .upload(path: path, file: jpegData, options: FileOptions(contentType: "image/jpeg", upsert: true))
                        
                        let publicUrl = try client.storage.from("store-images").getPublicURL(path: path)
                        finalProfileImageURL = publicUrl.absoluteString
                        print("Profile image uploaded.")
                    } catch {
                        print("========== ERROR ==========")
                        print("Error:", error)
                        print("Localized:", error.localizedDescription)
                        print("Reflection:", String(reflecting: error))
                        print("===========================")
                        if let pgError = error as? PostgrestError {
                            print("PostgrestError:", pgError)
                        }
                        
                        await MainActor.run {
                            let alertMsg = error.localizedDescription.isEmpty ? String(reflecting: error) : error.localizedDescription
                            self.errorMessage = alertMsg
                            self.showErrorAlert = true
                            self.isLoading = false
                        }
                        return
                    }
                }
            }
            
            // Perform Update
            struct UpdatePayload: Codable {
                let username: String
                let password: String
                let phone: String
                let gender: String
                let date_of_birth: String
                let address: String
                let profile_image_url: String?
                let profile_verified: Bool
            }
            
            let payload = UpdatePayload(
                username: username,
                password: newPassword,
                phone: phone,
                gender: gender,
                date_of_birth: dobString,
                address: address,
                profile_image_url: finalProfileImageURL,
                profile_verified: true
            )
            
            print("Updating users table...")
            print("Update Payload: user_id=\(user.id.uuidString), username=\(payload.username), phone=\(payload.phone), gender=\(payload.gender), date_of_birth=\(payload.date_of_birth), address=\(payload.address), profile_photo=\(payload.profile_image_url ?? "nil"), profile_verified=\(payload.profile_verified), store_id=\(user.storeId?.uuidString ?? "nil")")
            
            do {
                let response = try await client.from("users")
                    .update(payload)
                    .eq("id", value: user.id.uuidString)
                    .select()
                    .execute()
                
                let dataString = String(data: response.data, encoding: .utf8) ?? "[]"
                if dataString == "[]" {
                    print("WARNING: Users table update returned zero affected rows. Row was not updated.")
                }
                print("Users table updated.")
            } catch {
                print("========== ERROR ==========")
                print("Error:", error)
                print("Localized:", error.localizedDescription)
                print("Reflection:", String(reflecting: error))
                print("===========================")
                if let pgError = error as? PostgrestError {
                    print("PostgrestError:", pgError)
                }
                
                await MainActor.run {
                    let alertMsg = error.localizedDescription.isEmpty ? String(reflecting: error) : error.localizedDescription
                    self.errorMessage = alertMsg
                    self.showErrorAlert = true
                    self.isLoading = false
                }
                return
            }
            
            // (No Supabase Auth update needed since the app uses the public.users table for auth)
            
            await MainActor.run {
                self.isLoading = false
                path.append("Success")
            }
        }
    }
}

struct SuccessScreen: View {
    let user: GatewayUser
    var onComplete: (GatewayUser) -> Void
    @State private var isLoading = false
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            Image(systemName: "checkmark.circle.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .foregroundColor(.green)
            
            VStack(spacing: 16) {
                Text("Profile Completed")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Your account has been set up successfully.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }
            
            Spacer()
            
            Button(action: refetchAndComplete) {
                HStack {
                    Spacer()
                    if isLoading {
                        ProgressView().tint(.white)
                    } else {
                        Text("Continue")
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                    Spacer()
                }
                .frame(height: 54)
                .background(Color.green)
                .cornerRadius(12)
            }
            .disabled(isLoading)
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
        .navigationBarHidden(true)
    }
    
    private func refetchAndComplete() {
        isLoading = true
        
        print("Fetching updated user...")
        
        Task {
            let client = SupabaseClient(
                supabaseURL: URL(string: GatewayConstants.supabaseURL)!,
                supabaseKey: GatewayConstants.supabaseKey
            )
            
            do {
                let users: [GatewayUser] = try await client.from("users")
                    .select()
                    .eq("id", value: user.id.uuidString)
                    .execute()
                    .value
                
                guard let updatedUser = users.first else {
                    print("WARNING: Fetching updated user returned empty results.")
                    await MainActor.run {
                        self.isLoading = false
                    }
                    return
                }
                
                print("Fetching updated user...")
                print("Finished successfully.")
                
                await MainActor.run {
                    self.isLoading = false
                    self.onComplete(updatedUser)
                }
                
            } catch {
                print("========== ERROR ==========")
                print("Error:", error)
                print("Localized:", error.localizedDescription)
                print("Reflection:", String(reflecting: error))
                print("===========================")
                if let pgError = error as? PostgrestError {
                    print("PostgrestError:", pgError)
                }
                
                // Fallback to updating the current user object manually if refetch fails (for resilience)
                await MainActor.run {
                    let fallbackUser = GatewayUser(
                        id: user.id,
                        fullName: user.fullName,
                        username: user.username, // Might be stale but we proceed to dashboard/no-store
                        email: user.email,
                        roleId: user.roleId,
                        storeId: user.storeId,
                        designation: user.designation,
                        phone: user.phone,
                        profileImageURL: user.profileImageURL,
                        isProfileCompleted: true,
                        employeeCode: user.employeeCode,
                        gender: user.gender,
                        dateOfBirth: user.dateOfBirth,
                        address: user.address
                    )
                    self.isLoading = false
                    self.onComplete(fallbackUser)
                }
            }
        }
    }
}
