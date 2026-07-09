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
    
    // Store Image properties
    @State private var selectedStorePhotoItem: PhotosPickerItem? = nil
    @State private var selectedStorePhotoData: Data? = nil
    @State private var storeImageError: String? = nil
    
    @State private var usernameError: String? = nil
    @State private var passwordError: String? = nil
    @State private var phoneError: String? = nil
    @State private var ageError: String? = nil
    @State private var addressError: String? = nil
    
    @State private var isLoading = false
    @State private var isFetchingStore = false
    @State private var errorMessage: String? = nil
    @State private var showErrorAlert = false
    
    @State private var fetchedStoreName: String = "Fetching..."
    
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
            self._dateOfBirth = State(initialValue: Calendar.current.date(byAdding: .year, value: -18, to: Date())!)
        }
    }
    


    private var maxDate: Date {
        var components = DateComponents()
        components.year = 2008
        components.month = 12
        components.day = 31
        return Calendar.current.date(from: components) ?? Date()
    }
    
    var body: some View {
        Form {
            Section(header: Text("Personal Information")) {
                // 1. Profile Photo
                VStack {
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
                    Text("Change Photo").font(.caption).foregroundColor(.blue)
                }
                .padding(.vertical, 8)
                
                // 2. Username
                VStack(alignment: .leading, spacing: 0) {
                    HStack {
                        Text("Username")
                        Spacer()
                        TextField("Enter Username", text: $username)
                            .multilineTextAlignment(.trailing)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                    }
                    if let error = usernameError {
                        Text(error).foregroundColor(.red).font(.caption).padding(.top, 4)
                    }
                }
                
                // 3. Employee ID
                HStack {
                    Text("Employee Code")
                    Spacer()
                    Text(user.employeeCode ?? "N/A").foregroundColor(.secondary)
                }
                
                // 4. Full Name
                HStack {
                    Text("Full Name")
                    Spacer()
                    Text(user.fullName).foregroundColor(.secondary)
                }
                
                // 5. Email Address
                HStack {
                    Text("Email")
                    Spacer()
                    Text(user.email).foregroundColor(.secondary)
                }
                
                // 6. Phone Number
                VStack(alignment: .leading, spacing: 0) {
                    HStack {
                        Text("Phone Number")
                        Spacer()
                        TextField("Enter Number", text: $phone)
                            .multilineTextAlignment(.trailing)
                            .keyboardType(.numberPad)
                    }
                    if let error = phoneError {
                        Text(error).foregroundColor(.red).font(.caption).padding(.top, 4)
                    }
                }
                
                // 7. Gender
                Picker("Gender", selection: $gender) {
                    ForEach(genders, id: \.self) { g in
                        Text(g).tag(g)
                    }
                }
                
                // 8. Date of Birth
                VStack(alignment: .leading, spacing: 0) {
                    DatePicker("Date of Birth", selection: $dateOfBirth, in: ...maxDate, displayedComponents: .date)
                    if let error = ageError {
                        Text(error).foregroundColor(.red).font(.caption).padding(.top, 4)
                    }
                }
                
                // 9. Address
                VStack(alignment: .leading, spacing: 0) {
                    HStack {
                        Text("Address")
                        Spacer()
                        TextField("Enter Address", text: $address, axis: .vertical)
                            .multilineTextAlignment(.trailing)
                            .lineLimit(1...5)
                    }
                    if let error = addressError {
                        Text(error).foregroundColor(.red).font(.caption).padding(.top, 4)
                    }
                }
                
                // 10. Designation
                HStack {
                    Text("Designation")
                    Spacer()
                    Text(user.designation ?? "N/A").foregroundColor(.secondary)
                }
            }
            
            Section(header: Text("Change Password")) {
                VStack(alignment: .leading, spacing: 0) {
                    HStack {
                        Text("New Password")
                        Spacer()
                        if showNewPassword {
                            TextField("", text: $newPassword)
                                .multilineTextAlignment(.trailing)
                        } else {
                            SecureField("", text: $newPassword)
                                .multilineTextAlignment(.trailing)
                        }
                        Button(action: { showNewPassword.toggle() }) {
                            Image(systemName: showNewPassword ? "eye.slash" : "eye")
                                .foregroundColor(.gray)
                        }
                    }
                }
                
                VStack(alignment: .leading, spacing: 0) {
                    HStack {
                        Text("Confirm Password")
                        Spacer()
                        if showConfirmPassword {
                            TextField("", text: $confirmPassword)
                                .multilineTextAlignment(.trailing)
                        } else {
                            SecureField("", text: $confirmPassword)
                                .multilineTextAlignment(.trailing)
                        }
                        Button(action: { showConfirmPassword.toggle() }) {
                            Image(systemName: showConfirmPassword ? "eye.slash" : "eye")
                                .foregroundColor(.gray)
                        }
                    }
                    if let error = passwordError {
                        Text(error).foregroundColor(.red).font(.caption).padding(.top, 4)
                    }
                }
            }
            
            Section(header: Text("Assigned Store")) {
                HStack {
                    Text("Store Name")
                    Spacer()
                    Text(fetchedStoreName).foregroundColor(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
            }
            
            Section(header: Text("Store Images"), footer: Text("Upload a photograph of your assigned store. Maximum size 5 MB. (JPG/PNG)")) {
                VStack(alignment: .leading, spacing: 12) {
                    PhotosPicker(selection: $selectedStorePhotoItem, matching: .images, photoLibrary: .shared()) {
                        HStack {
                            Image(systemName: "photo.badge.plus")
                            Text("Upload Store Image")
                        }
                        .foregroundColor(.blue)
                    }
                    .onChange(of: selectedStorePhotoItem) { oldValue, newValue in
                        Task {
                            if let data = try? await newValue?.loadTransferable(type: Data.self) {
                                if data.count > 5 * 1024 * 1024 {
                                    storeImageError = "Image exceeds 5 MB maximum size."
                                    selectedStorePhotoData = nil
                                } else {
                                    storeImageError = nil
                                    selectedStorePhotoData = data
                                }
                            }
                        }
                    }
                    
                    if let error = storeImageError {
                        Text(error).foregroundColor(.red).font(.caption)
                    }
                    
                    if let storeData = selectedStorePhotoData, let uiImage = UIImage(data: storeData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(height: 150)
                            .frame(maxWidth: .infinity)
                            .cornerRadius(12)
                            .clipped()
                            .padding(.top, 8)
                    }
                }
                .padding(.vertical, 8)
            }
            
            Section {
                Button(action: saveProfile) {
                    HStack {
                        Spacer()
                        if isLoading {
                            ProgressView()
                            Text("Saving...")
                                .foregroundColor(.secondary)
                                .padding(.leading, 8)
                        } else {
                            Text("Finish")
                                .fontWeight(.bold)
                        }
                        Spacer()
                    }
                }
                .disabled(isLoading || isFetchingStore)
            }
        }
        .navigationTitle("Complete Your Profile")
        .navigationBarBackButtonHidden(isLoading)
        .onAppear {
            fetchStoreName()
        }
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
    private func fetchStoreName() {
        guard let storeId = user.storeId else {
            fetchedStoreName = "Not Assigned"
            return
        }
        isFetchingStore = true
        Task {
            let client = SupabaseClient(
                supabaseURL: URL(string: GatewayConstants.supabaseURL)!,
                supabaseKey: GatewayConstants.supabaseKey
            )
            do {
                struct StoreResult: Decodable {
                    let name: String
                }
                let stores: [StoreResult] = try await client.from("stores")
                    .select("name")
                    .eq("id", value: storeId.uuidString)
                    .execute()
                    .value
                
                await MainActor.run {
                    if let store = stores.first {
                        self.fetchedStoreName = store.name
                    } else {
                        self.fetchedStoreName = "Unknown Store"
                    }
                    self.isFetchingStore = false
                }
            } catch {
                await MainActor.run {
                    self.fetchedStoreName = "Unknown Store"
                    self.isFetchingStore = false
                }
            }
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
        
        let usernameRegex = "^[a-zA-Z0-9_.]{3,25}$"
        if username.range(of: usernameRegex, options: .regularExpression) == nil {
            usernameError = "Username must be 3-25 characters."
            hasError = true
        }
        
        if !newPassword.isEmpty || !confirmPassword.isEmpty {
            if newPassword != confirmPassword {
                passwordError = "Passwords do not match."
                hasError = true
            } else if newPassword.count < 8 {
                passwordError = "Password must be at least 8 characters long."
                hasError = true
            }
        }
        
        let digitsCharacters = CharacterSet(charactersIn: "0123456789")
        if phone.count != 10 || phone.rangeOfCharacter(from: digitsCharacters.inverted) != nil {
            phoneError = "Phone number must be exactly 10 digits."
            hasError = true
        }
        
        let ageComponents = Calendar.current.dateComponents([.year], from: dateOfBirth, to: Date())
        if let age = ageComponents.year, age < 18 {
            ageError = "You must be at least 18 years old."
            hasError = true
        }
        
        let trimmedAddress = address.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedAddress.isEmpty {
            addressError = "Address is required."
            hasError = true
        }
        
        if storeImageError != nil {
            hasError = true
        }
        
        if hasError { return }
        
        isLoading = true
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dobString = formatter.string(from: dateOfBirth)
        
        Task {
            let client = SupabaseClient(
                supabaseURL: URL(string: GatewayConstants.supabaseURL)!,
                supabaseKey: GatewayConstants.supabaseKey
            )
            
            if username != user.username {
                do {
                    struct UsernameCheck: Codable { let id: UUID }
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
                    await MainActor.run {
                        self.errorMessage = error.localizedDescription
                        self.showErrorAlert = true
                        self.isLoading = false
                    }
                    return
                }
            }
            
            var finalProfileImageURL = profileImageURL.isEmpty ? nil : profileImageURL
            if let photoData = selectedPhotoData, let uiImage = UIImage(data: photoData) {
                if let jpegData = uiImage.jpegData(compressionQuality: 0.8) {
                    let path = "profiles/\(user.id.uuidString).jpg"
                    do {
                        try await client.storage
                            .from("store-images")
                            .upload(path: path, file: jpegData, options: FileOptions(contentType: "image/jpeg", upsert: true))
                        let publicUrl = try client.storage.from("store-images").getPublicURL(path: path)
                        finalProfileImageURL = publicUrl.absoluteString
                    } catch {
                        await MainActor.run {
                            self.errorMessage = "Profile image upload failed."
                            self.showErrorAlert = true
                            self.isLoading = false
                        }
                        return
                    }
                }
            }
            
            if let storeData = selectedStorePhotoData, let uiImage = UIImage(data: storeData), let storeId = user.storeId {
                if let jpegData = uiImage.jpegData(compressionQuality: 0.8) {
                    let path = "store-images/\(storeId.uuidString)/\(UUID().uuidString).jpg"
                    do {
                        try await client.storage
                            .from("store-images")
                            .upload(path: path, file: jpegData, options: FileOptions(contentType: "image/jpeg", upsert: true))
                        
                        let publicUrl = try client.storage.from("store-images").getPublicURL(path: path)
                        
                        struct StoreUpdatePayload: Codable { let image_url: String }
                        try await client.from("stores")
                            .update(StoreUpdatePayload(image_url: publicUrl.absoluteString))
                            .eq("id", value: storeId.uuidString)
                            .execute()
                    } catch {
                        await MainActor.run {
                            self.errorMessage = "Store image upload failed."
                            self.showErrorAlert = true
                            self.isLoading = false
                        }
                        return
                    }
                }
            }
            
            struct UpdatePayload: Encodable {
                let username: String
                let password: String?
                let phone: String
                let gender: String
                let date_of_birth: String
                let address: String
                let profile_image_url: String?
                let profile_verified: Bool
            }
            
            let payload = UpdatePayload(
                username: username,
                password: newPassword.isEmpty ? nil : newPassword,
                phone: phone,
                gender: gender,
                date_of_birth: dobString,
                address: address,
                profile_image_url: finalProfileImageURL,
                profile_verified: true
            )
            
            do {
                try await client.from("users")
                    .update(payload)
                    .eq("id", value: user.id.uuidString)
                    .execute()
                
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.showErrorAlert = true
                    self.isLoading = false
                }
                return
            }
            
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
