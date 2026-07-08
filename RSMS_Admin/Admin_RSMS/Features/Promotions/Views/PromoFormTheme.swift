// AddPromotionView.swift
// Admin_RSMS


import SwiftUI
import UIKit

// MARK: - Theme constants (scoped to this file)
private enum PromoFormTheme {
    static let navy = Color(red: 0.1, green: 0.2, blue: 0.4)
    static let cardBackground = Color(uiColor: .secondarySystemGroupedBackground)
    static let fieldBackground = Color(uiColor: .systemGray6)
    static let cornerRadius: CGFloat = 16
    static let fieldCornerRadius: CGFloat = 12
}

// MARK: - Reusable Section Card
private struct PromoFormSectionCard<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(PromoFormTheme.navy)
                    .frame(width: 32, height: 32)
                    .background(PromoFormTheme.navy.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                Text(title)
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
            }

            content()
        }
        .padding(24)
        .background(PromoFormTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: PromoFormTheme.cornerRadius, style: .continuous))
    }
}

// MARK: - Reusable Field Label
private struct PromoFieldLabel: View {
    let text: String

    var body: some View {
        Text(text.uppercased())
            .font(.system(size: 11, weight: .bold))
            .foregroundStyle(.secondary)
            .tracking(0.5)
    }
}

// MARK: - Native dropdown row (small iOS Menu, anchored to the value on the trailing edge —
// this is what makes it pop open from the right, the same way Files/Photos "Sort by" menus do)
private struct PromoMenuRow<MenuItems: View>: View {
    let label: String
    let value: String
    @ViewBuilder var menuItems: () -> MenuItems

    var body: some View {
        HStack(spacing: 8) {
            Text(label)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(.primary)

            Spacer()

            // Only this trailing cluster is the actual Menu control.
            // Keeping its tap target small and right-anchored is what makes
            // the popup itself open growing from the right side, instead of
            // stretching the whole row into the anchor and opening on the left.
            Menu {
                menuItems()
            } label: {
                HStack(spacing: 6) {
                    Text(value)
                        .font(.system(size: 15))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)

                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color.secondary.opacity(0.5))
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 13)
        .background(PromoFormTheme.fieldBackground)
        .clipShape(RoundedRectangle(cornerRadius: PromoFormTheme.fieldCornerRadius))
    }
}

// MARK: - Add / Edit Promotion View
struct AddPromotionView: View {
    @StateObject private var service = PromotionService.shared

    private let editingPromotion: AdminPromotion?
    var onDismiss: () -> Void
    var onSaved: (AdminPromotion) -> Void

    // ── Form state ─────────────────────────────────────────────────
    @State private var promotionName: String
    @State private var promotionType: PromotionType
    @State private var selectedCategoryId: UUID?
    @State private var description: String
    @State private var startDate: Date
    @State private var endDate: Date
    @State private var appliesToAllStores: Bool
    @State private var selectedStoreIds: Set<UUID>
    @State private var isStoreDropdownOpen = false

    // ── Banner image state ────────────────────────────────────────
    @State private var selectedImage: UIImage?
    @State private var existingBannerURL: String?
    @State private var showingImageSourceSheet = false
    @State private var showingImagePicker = false
    @State private var imageSourceType: UIImagePickerController.SourceType = .photoLibrary

    // ── UI state ───────────────────────────────────────────────────
    @State private var isSaving = false
    @State private var validationError: String?
    @Environment(\.horizontalSizeClass) private var sizeClass

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.calendar = Calendar(identifier: .gregorian)
        f.timeZone = TimeZone(secondsFromGMT: 0)
        return f
    }()

    init(
        editingPromotion: AdminPromotion? = nil,
        onDismiss: @escaping () -> Void,
        onSaved: @escaping (AdminPromotion) -> Void = { _ in }
    ) {
        self.editingPromotion = editingPromotion
        self.onDismiss = onDismiss
        self.onSaved = onSaved

        _promotionName = State(initialValue: editingPromotion?.promotionName ?? "")
        _promotionType = State(initialValue: PromotionType(rawValue: editingPromotion?.promotionType ?? "") ?? .seasonalCampaign)
        _selectedCategoryId = State(initialValue: editingPromotion?.categoryId)
        _description = State(initialValue: editingPromotion?.description ?? "")
        _appliesToAllStores = State(initialValue: editingPromotion?.appliesToAllStores ?? true)
        _selectedStoreIds = State(initialValue: Set(editingPromotion?.storeIds ?? []))

        _existingBannerURL = State(initialValue: editingPromotion?.bannerImageUrl)

        if let start = editingPromotion?.startDate, let date = Self.dateFormatter.date(from: start) {
            _startDate = State(initialValue: date)
        } else {
            _startDate = State(initialValue: Date())
        }

        if let end = editingPromotion?.endDate, let date = Self.dateFormatter.date(from: end) {
            _endDate = State(initialValue: date)
        } else {
            _endDate = State(initialValue: Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date())
        }
    }

    private var useWideLayout: Bool { sizeClass == .regular }

    private var categoryDisplayName: String {
        guard let selectedCategoryId else { return "None" }
        return service.categories.first(where: { $0.id == selectedCategoryId })?.categoryName ?? "None"
    }

    private var storeDisplayName: String {
        if appliesToAllStores { return "All Stores" }
        if selectedStoreIds.isEmpty { return "Select Store" }
        let names = selectedStoreIds.compactMap { id in
            service.stores.first(where: { $0.id == id })?.name
        }
        return names.isEmpty ? "Select Store" : names.joined(separator: ", ")
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                if useWideLayout {
                    wideLayout
                } else {
                    compactLayout
                }
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle(editingPromotion == nil ? "New Promotion" : "Edit Promotion")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        onDismiss()
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: save) {
                        Text(editingPromotion == nil ? "Save" : "Update")
                            .fontWeight(.bold)
                    }
                    .disabled(isSaving)
                }
            }
        }
        .onAppear {
            Task { await service.fetchPickerData() }
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(image: $selectedImage, sourceType: imageSourceType)
        }
        .alert("Error", isPresented: Binding(
            get: { service.errorMessage != nil },
            set: { if !$0 { service.errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) { service.errorMessage = nil }
        } message: {
            Text(service.errorMessage ?? "")
        }
        .alert("Missing Information", isPresented: Binding(
            get: { validationError != nil },
            set: { if !$0 { validationError = nil } }
        )) {
            Button("OK", role: .cancel) { validationError = nil }
        } message: {
            Text(validationError ?? "")
        }
    }

    // Native Toolbars replaced topBar and bottomBar
    // MARK: - Layouts

    private var wideLayout: some View {
        HStack(alignment: .top, spacing: 24) {
            VStack(spacing: 20) {
                basicInfoSection
                descriptionSection
                scheduleSection
            }
            .frame(maxWidth: .infinity)

            VStack(spacing: 20) {
                storeAvailabilitySection
                creativeAssetSection
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .padding(28)
    }

    private var compactLayout: some View {
        VStack(spacing: 20) {
            basicInfoSection
            descriptionSection
            scheduleSection
            storeAvailabilitySection
            creativeAssetSection
        }
        .padding(20)
    }

    // MARK: - Section: Basic Information

    private var basicInfoSection: some View {
        PromoFormSectionCard(title: "Basic Information", icon: "tag") {
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    PromoFieldLabel(text: "Promotion Name")
                    TextField("e.g. Summer Flash Sale", text: $promotionName)
                        .font(.system(size: 15))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 13)
                        .background(PromoFormTheme.fieldBackground)
                        .clipShape(RoundedRectangle(cornerRadius: PromoFormTheme.fieldCornerRadius))
                }

                PromoMenuRow(label: "Type", value: promotionType.rawValue) {
                    Picker("Type", selection: $promotionType) {
                        ForEach(PromotionType.allCases) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                }

                PromoMenuRow(label: "Category", value: categoryDisplayName) {
                    Picker(
                        "Category",
                        selection: Binding(
                            get: { selectedCategoryId },
                            set: { selectedCategoryId = $0 }
                        )
                    ) {
                        Text("None").tag(UUID?.none)
                        ForEach(service.categories) { category in
                            Text(category.categoryName).tag(UUID?.some(category.id))
                        }
                    }
                }
            }
        }
    }

    // MARK: - Section: Description

    private var descriptionSection: some View {
        PromoFormSectionCard(title: "Description", icon: "text.alignleft") {
                ZStack(alignment: .topLeading) {
                    if description.isEmpty {
                        Text("Enter promotion details, terms, and conditions…")
                            .font(.system(size: 15))
                            .foregroundStyle(.secondary.opacity(0.6))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 13)
                    }
                    TextEditor(text: $description)
                        .font(.system(size: 15))
                        .scrollContentBackground(.hidden)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .frame(minHeight: 160)
                }
            .background(PromoFormTheme.fieldBackground)
            .clipShape(RoundedRectangle(cornerRadius: PromoFormTheme.fieldCornerRadius))
        }
    }

    // MARK: - Section: Schedule

    private var scheduleSection: some View {
        PromoFormSectionCard(title: "Schedule", icon: "calendar") {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    PromoFieldLabel(text: "Start Date")
                    
                    HStack {
                        DatePicker("Start Date", selection: $startDate, displayedComponents: [.date])
                            .labelsHidden()
                        Spacer()
                    }
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    PromoFieldLabel(text: "End Date")
                    
                    HStack {
                        DatePicker("End Date", selection: $endDate, displayedComponents: [.date])
                            .labelsHidden()
                        Spacer()
                    }
                }
            }
        }
    }

    // MARK: - Section: Store Availability

    private var storeAvailabilitySection: some View {
        PromoFormSectionCard(title: "Store Availability", icon: "storefront") {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    PromoFieldLabel(text: "Select Stores")
                    Spacer()
                    if !service.stores.isEmpty {
                        Button(action: {
                            if selectedStoreIds.count == service.stores.count {
                                selectedStoreIds.removeAll()
                                appliesToAllStores = false
                            } else {
                                selectedStoreIds = Set(service.stores.map { $0.id })
                                appliesToAllStores = true
                            }
                        }) {
                            Text(selectedStoreIds.count == service.stores.count ? "Deselect All" : "Select All")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(PromoFormTheme.navy)
                        }
                    }
                }
                
                if service.stores.isEmpty {
                    Text("No stores available.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(service.stores, id: \.id) { store in
                        Button(action: {
                            if selectedStoreIds.contains(store.id) {
                                selectedStoreIds.remove(store.id)
                            } else {
                                selectedStoreIds.insert(store.id)
                            }
                            appliesToAllStores = (selectedStoreIds.count == service.stores.count)
                        }) {
                            HStack {
                                Text(store.name)
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundStyle(.primary)
                                Spacer()
                                if selectedStoreIds.contains(store.id) || appliesToAllStores {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.blue)
                                        .font(.system(size: 20))
                                } else {
                                    Image(systemName: "circle")
                                        .foregroundStyle(.secondary.opacity(0.3))
                                        .font(.system(size: 20))
                                }
                            }
                            .padding()
                            .background(PromoFormTheme.fieldBackground)
                            .clipShape(RoundedRectangle(cornerRadius: PromoFormTheme.fieldCornerRadius))
                            .overlay(
                                RoundedRectangle(cornerRadius: PromoFormTheme.fieldCornerRadius)
                                    .stroke((selectedStoreIds.contains(store.id) || appliesToAllStores) ? Color.blue : Color.clear, lineWidth: 2)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    // MARK: - Section: Creative Asset

    private var creativeAssetSection: some View {
        PromoFormSectionCard(title: "Creative Asset", icon: "photo.on.rectangle") {
            Group {
                if let selectedImage {
                    bannerPreview(image: Image(uiImage: selectedImage))
                } else if let urlString = existingBannerURL, let url = URL(string: urlString) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            bannerPreview(image: image)
                        case .failure:
                            uploadPlaceholder
                        default:
                            ProgressView().frame(maxWidth: .infinity, minHeight: 160)
                        }
                    }
                } else {
                    uploadPlaceholder
                }
            }
            .confirmationDialog("Select Image Source", isPresented: $showingImageSourceSheet, titleVisibility: .visible) {
                Button("Choose from Gallery") {
                    imageSourceType = .photoLibrary
                    showingImagePicker = true
                }
                if UIImagePickerController.isSourceTypeAvailable(.camera) {
                    Button("Take Photo") {
                        imageSourceType = .camera
                        showingImagePicker = true
                    }
                }
                Button("Cancel", role: .cancel) {}
            }
        }
    }

    private func bannerPreview(image: Image) -> some View {
        ZStack(alignment: .topTrailing) {
            image
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity)
                .frame(height: 180)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .clipped()

            HStack(spacing: 8) {
                Button(action: { showingImageSourceSheet = true }) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.system(size: 10))
                        Text("Change Photo")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(.ultraThinMaterial.opacity(0.9))
                    .background(Color.black.opacity(0.3))
                    .clipShape(Capsule())
                }

                Button(action: {
                    withAnimation {
                        selectedImage = nil
                        existingBannerURL = nil
                    }
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.4), radius: 4)
                }
            }
            .padding(12)
        }
    }

    private var uploadPlaceholder: some View {
        Button(action: { showingImageSourceSheet = true }) {
            VStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(PromoFormTheme.navy.opacity(0.06))
                        .frame(width: 56, height: 56)
                    Image(systemName: "photo.badge.plus")
                        .font(.system(size: 24))
                        .foregroundStyle(PromoFormTheme.navy.opacity(0.7))
                }
                VStack(spacing: 4) {
                    Text("Upload Banner Image")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.primary)
                    Text("PNG or JPG, up to 10 MB")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 36)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [6, 4]))
                    .foregroundStyle(Color.secondary.opacity(0.25))
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Save

    private func save() {
        let trimmedName = promotionName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            validationError = "Please enter a promotion name."
            return
        }
        guard endDate >= startDate else {
            validationError = "End date must be on or after the start date."
            return
        }
        if !appliesToAllStores && selectedStoreIds.isEmpty {
            validationError = "Select a store, or turn on \"Applies to All Stores\"."
            return
        }

        isSaving = true

        Task {
            let promotionId = editingPromotion?.id ?? UUID()

            var promotion = AdminPromotion(
                id: promotionId,
                promotionName: trimmedName,
                promotionType: promotionType.rawValue,
                categoryId: selectedCategoryId,
                description: description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : description,
                startDate: Self.dateFormatter.string(from: startDate),
                endDate: Self.dateFormatter.string(from: endDate),
                appliesToAllStores: appliesToAllStores,
                storeIds: appliesToAllStores ? nil : Array(selectedStoreIds),
                bannerImageUrl: existingBannerURL,
                createdBy: editingPromotion?.createdBy ?? AuthManager.shared.currentUser?.id
            )

            let success: Bool
            if editingPromotion == nil {
                success = await service.addPromotion(promotion)
            } else {
                success = await service.updatePromotion(promotion)
            }

            if success {
                if let image = selectedImage, let data = image.jpegData(compressionQuality: 0.8) {
                    if let uploadedURL = await service.uploadBannerImage(data: data, promotionId: promotionId.uuidString) {
                        promotion.bannerImageUrl = uploadedURL
                        await service.updatePromotion(promotion) // Update the record with the URL
                    }
                }

                isSaving = false
                onSaved(promotion)
                onDismiss()
            } else {
                isSaving = false
            }
        }
    }
}

#Preview {
    AddPromotionView(onDismiss: {})
}
