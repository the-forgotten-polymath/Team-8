import sys

new_body = """
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
                
                VStack(alignment: .leading) {
                    TextField("Username", text: $username)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                    if let error = usernameError {
                        Text(error).foregroundColor(.red).font(.caption)
                    }
                }
                
                HStack {
                    Text("Employee Code")
                    Spacer()
                    Text(user.employeeCode ?? "N/A").foregroundColor(.secondary)
                }
                .disabled(true)
                
                HStack {
                    Text("Full Name")
                    Spacer()
                    Text(user.fullName).foregroundColor(.secondary)
                }
                .disabled(true)
                
                HStack {
                    Text("Email")
                    Spacer()
                    Text(user.email).foregroundColor(.secondary)
                }
                .disabled(true)
                
                VStack(alignment: .leading) {
                    TextField("Phone Number", text: $phone)
                        .keyboardType(.numberPad)
                    if let error = phoneError {
                        Text(error).foregroundColor(.red).font(.caption)
                    }
                }
                
                Picker("Gender", selection: $gender) {
                    ForEach(genders, id: \.self) { g in
                        Text(g).tag(g)
                    }
                }
                
                VStack(alignment: .leading) {
                    DatePicker("Date of Birth", selection: $dateOfBirth, in: ...maxDate, displayedComponents: .date)
                    if let error = ageError {
                        Text(error).foregroundColor(.red).font(.caption)
                    }
                }
                
                VStack(alignment: .leading) {
                    TextField("Address", text: $address, axis: .vertical)
                        .lineLimit(2...5)
                    if let error = addressError {
                        Text(error).foregroundColor(.red).font(.caption)
                    }
                }
                
                HStack {
                    Text("Designation")
                    Spacer()
                    Text(user.designation ?? "N/A").foregroundColor(.secondary)
                }
                .disabled(true)
            }
            
            Section(header: Text("Change Password")) {
                VStack(alignment: .leading) {
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
                }
                
                VStack(alignment: .leading) {
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
            }
            
            Section(header: Text("Assigned Store")) {
                HStack {
                    Text("Store Name")
                    Spacer()
                    Text(fetchedStoreName).foregroundColor(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
                .disabled(true)
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
"""

with open('StoreManagerOnboardingView.swift', 'r') as f:
    lines = f.readlines()

start_idx = None
end_idx = None
for i, line in enumerate(lines):
    if "private var maxDate: Date {" in line:
        start_idx = i
    if "private func fetchStoreName() {" in line:
        end_idx = i
        break

if start_idx is not None and end_idx is not None:
    new_content = lines[:start_idx] + [new_body] + lines[end_idx:]
    with open('StoreManagerOnboardingView.swift', 'w') as f:
        f.writelines(new_content)
    print("Replaced body successfully.")
else:
    print(f"Could not find indices. start={start_idx}, end={end_idx}")

