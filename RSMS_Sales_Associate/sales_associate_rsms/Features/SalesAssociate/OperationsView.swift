// OperationsView.swift
// RSMS — Sales Associate Module

import SwiftUI
import Supabase
import Storage
import Foundation

struct OperationsView: View {
    @EnvironmentObject private var authVM: AuthViewModel
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Clean title without subtitle and profile avatar
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Operations")
                                .font(.system(size: 32, weight: .bold, design: .default))
                                .foregroundColor(.primary)
                        }
                        .padding(.horizontal)
                        .padding(.top)

                        // Vertical stack of 4 operation options
                        VStack(spacing: 16) {
                            
                            // 1. Client Hub
                            NavigationLink(destination: ClientHubView(isEmbedded: true)) {
                                OperationCard(
                                    title: "Client Hub",
                                    subtitle: "Profiles & Twin",
                                    systemImage: "person.2.fill",
                                    iconColor: .blue
                                )
                            }
                            
                            // 2. Appointments
                            NavigationLink(destination: AppointmentsView(isEmbedded: true)) {
                                OperationCard(
                                    title: "Appointments",
                                    subtitle: "Schedule & Tasks",
                                    systemImage: "calendar",
                                    iconColor: .orange
                                )
                            }
                            
                            // 3. Fulfillment
                            NavigationLink(destination: OmnichannelView(isEmbedded: true)) {
                                OperationCard(
                                    title: "Fulfillment",
                                    subtitle: "BOPIS Purchases",
                                    systemImage: "shippingbox.fill",
                                    iconColor: .green
                                )
                            }
                            
                            // 4. Purchases
                            NavigationLink(destination: OrdersDashboardView(isEmbedded: true)) {
                                OperationCard(
                                    title: "Purchases",
                                    subtitle: "Sales & Invoices",
                                    systemImage: "doc.text.fill",
                                    iconColor: .blue
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct OperationCard: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let iconColor: Color
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(iconColor.opacity(0.12))
                    .frame(width: 52, height: 52)
                
                Image(systemName: systemImage)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(iconColor)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 18, weight: .bold, design: .default))
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.system(size: 13, weight: .regular, design: .default))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(Color(.systemGray3))
                .padding(.trailing, 4)
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 16)
        .liquidGlass()
    }
}

struct ProfileView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var dbUser: User? = nil
    @State private var isLoadingProfile = false
    @State private var showingImageURLAlert = false
    @State private var newImageURL = ""
    @State private var storeName: String = "—"
    
    // Camera & Photo Library pickers
    @State private var showingSourceTypeDialog = false
    @State private var showingImagePicker = false
    @State private var selectedImageSource: UIImagePickerController.SourceType = .photoLibrary
    @State private var selectedUIImage: UIImage? = nil
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack(spacing: 16) {
                        // Profile Avatar with Change Option
                        Button(action: {
                            showingSourceTypeDialog = true
                        }) {
                            ZStack(alignment: .bottomTrailing) {
                                if let imgUrlStr = dbUser?.profileImageURL, let imgUrl = URL(string: imgUrlStr) {
                                    AsyncImage(url: imgUrl) { image in
                                        image.resizable()
                                             .aspectRatio(contentMode: .fill)
                                    } placeholder: {
                                        ProgressView()
                                    }
                                    .frame(width: 70, height: 70)
                                    .clipShape(Circle())
                                } else {
                                    Circle()
                                        .fill(Color.blue.opacity(0.12))
                                        .frame(width: 70, height: 70)
                                    Text(authVM.userFullName.initials)
                                        .font(.title2.bold())
                                        .foregroundColor(.blue)
                                }
                                
                                // Camera icon indicator overlay
                                Image(systemName: "camera.circle.fill")
                                    .font(.title3)
                                    .foregroundColor(.blue)
                                    .background(Color.white)
                                    .clipShape(Circle())
                                    .offset(x: 2, y: 2)
                            }
                        }
                        .buttonStyle(.plain)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(dbUser?.fullName ?? authVM.userFullName)
                                .font(.headline)
                            Text(dbUser?.designation ?? authVM.currentUser?.role.rawValue ?? "Sales Associate")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                Section(header: Text("Employment Details")) {
                    HStack {
                        Text("Employee Code")
                        Spacer()
                        Text(dbUser?.employeeCode ?? "—")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Designation")
                        Spacer()
                        Text(dbUser?.designation ?? "—")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Joining Date")
                        Spacer()
                        Text(dbUser?.joiningDate ?? "—")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Status")
                        Spacer()
                        Text(dbUser?.employeeStatus ?? "—")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Store")
                        Spacer()
                        Text(storeName)
                            .foregroundColor(.secondary)
                    }
                }
                
                Section(header: Text("Personal Details & Contact")) {
                    HStack {
                        Text("Email")
                        Spacer()
                        Text(dbUser?.email ?? authVM.currentUser?.email ?? "—")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Phone")
                        Spacer()
                        Text(dbUser?.phone ?? "—")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Gender")
                        Spacer()
                        Text(dbUser?.gender ?? "—")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Date of Birth")
                        Spacer()
                        Text(dbUser?.dateOfBirth ?? "—")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Address")
                        Spacer()
                        Text(dbUser?.address ?? "—")
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
                
                Section {
                    Button(role: .destructive, action: {
                        dismiss()
                        Task {
                            await authVM.logout()
                        }
                    }) {
                        Text("Log Out")
                            .frame(maxWidth: .infinity, alignment: .center)
                            .fontWeight(.semibold)
                    }
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .task {
                await loadUserProfile()
            }
            .confirmationDialog("Change Profile Picture", isPresented: $showingSourceTypeDialog, titleVisibility: .visible) {
                Button("Take Photo") {
                    if UIImagePickerController.isSourceTypeAvailable(.camera) {
                        selectedImageSource = .camera
                        showingImagePicker = true
                    }
                }
                Button("Choose from Library") {
                    selectedImageSource = .photoLibrary
                    showingImagePicker = true
                }
                Button("Enter Image URL") {
                    newImageURL = dbUser?.profileImageURL ?? ""
                    showingImageURLAlert = true
                }
                Button("Cancel", role: .cancel) { }
            }
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(sourceType: selectedImageSource, selectedImage: $selectedUIImage)
            }
            .onChange(of: selectedUIImage) { newImage in
                if let img = newImage {
                    if let jpegData = img.jpegData(compressionQuality: 0.75) {
                        Task {
                            await uploadProfileImage(data: jpegData)
                        }
                    }
                }
            }
            .alert("Change Profile Picture", isPresented: $showingImageURLAlert) {
                TextField("Profile Image URL", text: $newImageURL)
                Button("Save") {
                    Task {
                        await updateProfileImage(url: newImageURL)
                    }
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Enter a web URL for your profile picture avatar.")
            }
            .overlay(
                isLoadingProfile ?
                Color.black.opacity(0.15).ignoresSafeArea().overlay(ProgressView())
                : nil
            )
        }
    }
    
    private func loadUserProfile() async {
        guard let currentId = authVM.currentUser?.id else { return }
        isLoadingProfile = true
        do {
            let user: User = try await SupabaseManager.shared.client
                .from("users")
                .select()
                .eq("id", value: currentId.uuidString)
                .single()
                .execute()
                .value
            self.dbUser = user
            
            if let storeId = user.storeId {
                let store: Store = try await SupabaseManager.shared.client
                    .from("stores")
                    .select()
                    .eq("id", value: storeId.uuidString)
                    .single()
                    .execute()
                    .value
                self.storeName = store.name
            }
        } catch {
            print("ProfileView: Failed to load user profile or store: \(error)")
        }
        isLoadingProfile = false
    }
    
    private func updateProfileImage(url: String) async {
        guard let currentId = authVM.currentUser?.id else { return }
        isLoadingProfile = true
        do {
            struct AvatarUpdate: Encodable {
                let profile_image_url: String
            }
            try await SupabaseManager.shared.client
                .from("users")
                .update(AvatarUpdate(profile_image_url: url))
                .eq("id", value: currentId.uuidString)
                .execute()
            
            await loadUserProfile()
        } catch {
            print("ProfileView: Failed to update avatar url: \(error)")
        }
        isLoadingProfile = false
    }
    
    private func uploadProfileImage(data: Data) async {
        guard let currentId = authVM.currentUser?.id else { return }
        isLoadingProfile = true
        let bucket = "avatars"
        let fileName = "\(currentId.uuidString).jpg"
        
        do {
            _ = try await SupabaseManager.shared.client.storage
                .from(bucket)
                .upload(
                    fileName,
                    data: data,
                    options: FileOptions(contentType: "image/jpeg", upsert: true)
                )
            
            let publicUrl = try SupabaseManager.shared.client.storage.from(bucket).getPublicURL(path: fileName)
            let urlString = publicUrl.absoluteString
            
            struct AvatarUpdate: Encodable {
                let profile_image_url: String
            }
            try await SupabaseManager.shared.client
                .from("users")
                .update(AvatarUpdate(profile_image_url: urlString))
                .eq("id", value: currentId.uuidString)
                .execute()
            
            await loadUserProfile()
        } catch {
            print("Upload failed: \(error), falling back to Base64 encoding")
            let base64String = "data:image/jpeg;base64," + data.base64EncodedString()
            do {
                struct AvatarUpdate: Encodable {
                    let profile_image_url: String
                }
                try await SupabaseManager.shared.client
                    .from("users")
                    .update(AvatarUpdate(profile_image_url: base64String))
                    .eq("id", value: currentId.uuidString)
                    .execute()
                
                await loadUserProfile()
            } catch {
                print("Fallback Base64 save failed: \(error)")
            }
        }
        isLoadingProfile = false
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    var sourceType: UIImagePickerController.SourceType = .photoLibrary
    @Binding var selectedImage: UIImage?
    @Environment(\.dismiss) var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImage = image
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

#Preview {
    OperationsView()
        .environmentObject(AuthViewModel())
}
