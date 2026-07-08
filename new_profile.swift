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
                        TextField("New Password (Optional)", text: $newPassword)
                    } else {
                        SecureField("New Password (Optional)", text: $newPassword)
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
                            VStack {
                                Image(systemName: "person.crop.circle.fill")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 80, height: 80)
                                    .foregroundColor(.gray)
                                Text("Upload Photo").font(.caption).foregroundColor(.blue)
                            }
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
                
                TextField("Address", text: $address, axis: .vertical)
                    .lineLimit(2...5)
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
                    Text(fetchedStoreName).foregroundColor(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
            }
            .disabled(true)
            
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
        
        let usernameRegex = "^[a-zA-Z0-9_.]{4,25}$"
        if username.range(of: usernameRegex, options: .regularExpression) == nil {
            usernameError = "Username must be 4-25 characters."
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
        if trimmedAddress.count < 10 || trimmedAddress.count > 250 {
            addressError = "Address must be between 10 and 250 characters."
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
                var updateDict: [String: AnyJSON] = [
                    "username": .string(payload.username),
                    "phone": .string(payload.phone),
                    "gender": .string(payload.gender),
                    "date_of_birth": .string(payload.date_of_birth),
                    "address": .string(payload.address),
                    "profile_verified": .bool(payload.profile_verified)
                ]
                if let pass = payload.password {
                    updateDict["password"] = .string(pass)
                }
                if let pImage = payload.profile_image_url {
                    updateDict["profile_image_url"] = .string(pImage)
                } else {
                    updateDict["profile_image_url"] = .null
                }
                
                try await client.from("users")
                    .update(updateDict)
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
