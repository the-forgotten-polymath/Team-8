////
////  ProductDetailView.swift
////  RSMS_Project
////
////  iOS Native 26 style details view for a selected product inventory item.
////  Allows editing of the Minimum Threshold (reorderLevel) and Quantity using
////  the existing updateInventoryQuantity method or generic DatabaseService.shared.update.
////
//
//import SwiftUI
//
//struct ProductDetailView: View {
//    let item: InventoryItem
//    let product: Product
//    let warehouseId: UUID
//
//    @State private var quantity: Int
//    @State private var reorderLevel: Int
//    @State private var categoryName: String = "Loading..."
//    @State private var warehouseName: String = "Loading..."
//    @State private var isSaving = false
//    @State private var saveSuccess = false
//    @State private var errorMessage: String? = nil
//
//    @Environment(\.dismiss) private var dismiss
//
//    init(item: InventoryItem, product: Product, warehouseId: UUID) {
//        self.item = item
//        self.product = product
//        self.warehouseId = warehouseId
//        self._quantity = State(initialValue: item.quantity)
//        self._reorderLevel = State(initialValue: item.reorderLevel)
//    }
//
//    var body: some View {
//        Form {
//            Section(header: Text("Product Info")) {
//                LabeledContent("Product Name", value: product.productName)
//                LabeledContent("SKU", value: product.sku)
//                LabeledContent("Category", value: categoryName)
//                LabeledContent("Brand", value: product.brand)
//                LabeledContent("Price", value: String(format: "$%.2f", product.price))
//                if let qr = product.qrValue {
//                    LabeledContent("QR Code Value", value: qr)
//                }
//            }
//
//            Section(header: Text("Inventory Settings")) {
//                HStack {
//                    Text("Quantity")
//                    Spacer()
//                    TextField("Quantity", value: $quantity, format: .number)
//                        .keyboardType(.numberPad)
//                        .multilineTextAlignment(.trailing)
//                        .frame(maxWidth: 100)
//                }
//                
//                HStack {
//                    Text("Minimum Threshold")
//                    Spacer()
//                    TextField("Minimum Threshold", value: $reorderLevel, format: .number)
//                        .keyboardType(.numberPad)
//                        .multilineTextAlignment(.trailing)
//                        .frame(maxWidth: 100)
//                }
//                
//                LabeledContent("Warehouse", value: warehouseName)
//                if let zone = item.zone {
//                    LabeledContent("Zone", value: zone)
//                }
//                if let lastVerified = item.lastVerifiedAt {
//                    LabeledContent("Last Verified", value: lastVerified.formatted(date: .abbreviated, time: .shortened))
//                }
//            }
//
//            if !product.description.isEmpty {
//                Section(header: Text("Description")) {
//                    Text(product.description)
//                        .font(.body)
//                        .foregroundColor(.secondary)
//                }
//            }
//        }
//        .navigationTitle(product.productName)
//        .navigationBarTitleDisplayMode(.inline)
//        .toolbar {
//            ToolbarItem(placement: .navigationBarTrailing) {
//                Button(action: saveChanges) {
//                    if isSaving {
//                        ProgressView()
//                    } else {
//                        Text("Save")
//                            .fontWeight(.semibold)
//                    }
//                }
//                .disabled(isSaving)
//            }
//        }
//        .task {
//            await loadDetails()
//        }
//        .alert("Status", isPresented: $saveSuccess) {
//            Button("OK") { dismiss() }
//        } message: {
//            Text("Inventory information updated successfully.")
//        }
//        .alert("Error", isPresented: Binding<Bool>(
//            get: { errorMessage != nil },
//            set: { show in if !show { errorMessage = nil } }
//        )) {
//            Button("OK") {}
//        } message: {
//            if let msg = errorMessage {
//                Text(msg)
//            }
//        }
//    }
//
//    private func loadDetails() async {
//        do {
//            // Load category
//            let categories: [Category] = try await DatabaseService.shared.fetch(from: "categories", as: Category.self)
//            if let cat = categories.first(where: { $0.id == product.categoryId }) {
//                categoryName = cat.categoryName
//            } else {
//                categoryName = "Unknown"
//            }
//
//            // Load warehouse
//            let warehouses = try await WarehouseService.shared.fetchWarehouses()
//            if let wh = warehouses.first(where: { $0.id == warehouseId }) {
//                warehouseName = wh.warehouseName
//            } else {
//                warehouseName = "Unknown"
//            }
//        } catch {
//            print("Failed to load details: \(error)")
//        }
//    }
//
//    private func saveChanges() {
//        guard !isSaving else { return }
//        isSaving = true
//        errorMessage = nil
//
//        Task {
//            do {
//                // Update quantity using standard method
//                try await WarehouseService.shared.updateInventoryQuantity(itemId: item.id, newQuantity: quantity)
//                
//                // Update reorder_level (minimum threshold) using generic update
//                struct UpdateReorderLevel: Encodable {
//                    let reorderLevel: Int
//                    enum CodingKeys: String, CodingKey {
//                        case reorderLevel = "reorder_level"
//                    }
//                }
//                
//                try await DatabaseService.shared.update(
//                    table: "inventory",
//                    value: UpdateReorderLevel(reorderLevel: reorderLevel),
//                    column: "id",
//                    equals: item.id.uuidString.lowercased()
//                )
//
//                // Log audit action
//                try? await WarehouseService.shared.logAction(
//                    userId: item.productId, // Fallback user id or system
//                    module: "Inventory",
//                    action: "Updated threshold and quantity for item \(product.productName)"
//                )
//
//                saveSuccess = true
//            } catch {
//                errorMessage = error.localizedDescription
//            }
//            isSaving = false
//        }
//    }
//}
//
//  ProductDetailView.swift
//  RSMS_Project
//
//  iOS Native 26 style details view for a selected product inventory item.
//  Allows editing of the Minimum Threshold (reorderLevel) and Quantity using
//  the existing updateInventoryQuantity method or generic DatabaseService.shared.update.
//

import SwiftUI

struct ProductDetailView: View {
    let item: InventoryItem
    let product: Product
    let warehouseId: UUID

    @State private var quantity: Int
    @State private var reorderLevel: Int
    @State private var categoryName: String = "Loading..."
    @State private var warehouseName: String = "Loading..."
    @State private var isSaving = false
    @State private var saveSuccess = false
    @State private var errorMessage: String? = nil
    @ObservedObject private var certificateManager = CertificateManager.shared
    @State private var selectedCertificateInfo: CertificatePresentationInfo? = nil
    @State private var showAllCertified = false

    @Environment(\.dismiss) private var dismiss

    init(item: InventoryItem, product: Product, warehouseId: UUID) {
        self.item = item
        self.product = product
        self.warehouseId = warehouseId
        self._quantity = State(initialValue: item.quantity)
        self._reorderLevel = State(initialValue: item.reorderLevel)
    }

    var body: some View {
        Form {
            Section(header: Text("Product Info")) {
                LabeledContent("Product Name", value: product.productName)
                LabeledContent("SKU", value: product.sku)
                LabeledContent("Category", value: categoryName)
                LabeledContent("Brand", value: product.brand)
                LabeledContent("Price", value: String(format: "$%.2f", product.price))
                if let qr = product.qrValue {
                    LabeledContent("QR Code Value", value: qr)
                }
            }

            Section(header: Text("Inventory Settings")) {
                LabeledContent("Quantity", value: "\(quantity) units")
                
                HStack {
                    Text("Minimum Threshold")
                    Spacer()
                    TextField("Minimum Threshold", value: $reorderLevel, format: .number)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .frame(maxWidth: 100)
                }
                
                if let zone = item.zone {
                    LabeledContent("Zone", value: zone)
                }
                if let lastVerified = item.lastVerifiedAt {
                    LabeledContent("Last Verified", value: lastVerified.formatted(date: .abbreviated, time: .shortened))
                }
            }

            Section(header: Text("Certificates")) {
                let existingCerts = certificateManager.certificates.filter { $0.productId == product.id }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("\(existingCerts.count) of \(item.quantity) units certified")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    ProgressView(value: Double(existingCerts.count), total: Double(max(1, item.quantity)))
                        .tint(existingCerts.count >= item.quantity ? .green : .orange)
                        .accessibilityLabel("\(existingCerts.count) of \(item.quantity) units certified progress")
                }
                .padding(.vertical, 6)

                if !existingCerts.isEmpty {
                    DisclosureGroup("Certified Units (\(existingCerts.count))", isExpanded: $showAllCertified) {
                        ForEach(existingCerts) { cert in
                            HStack {
                                Text(cert.serialNumber)
                                    .font(.body)
                                Spacer()
                                Button(action: {
                                    selectedCertificateInfo = CertificatePresentationInfo(
                                        serialNumber: cert.serialNumber,
                                        product: product,
                                        destination: warehouseName
                                    )
                                }) {
                                    Image(systemName: "checkmark.seal.fill")
                                        .foregroundColor(.green)
                                }
                                .buttonStyle(.borderless)
                                .accessibilityLabel("Serial number \(cert.serialNumber), Certified. Tap to print.")
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }

                let remainingCount = max(0, item.quantity - existingCerts.count)
                if remainingCount > 0 {
                    ForEach(0..<remainingCount, id: \.self) { idx in
                        let prefix = product.qrValue ?? (product.sku.isEmpty ? "SN" : product.sku)
                        let serial = "\(prefix)-\(1001 + idx + existingCerts.count)"
                        
                        HStack {
                            Text(serial)
                                .font(.body)
                                .foregroundColor(.secondary)
                            Spacer()
                            Button("Link Certificate") {
                                selectedCertificateInfo = CertificatePresentationInfo(
                                    serialNumber: serial,
                                    product: product,
                                    destination: warehouseName
                                )
                            }
                            .buttonStyle(.bordered)
                            .tint(.blue)
                            .accessibilityLabel("Serial number \(serial), Uncertified. Tap to link.")
                        }
                        .padding(.vertical, 4)
                    }

                    Button(action: {
                        let prefix = product.qrValue ?? (product.sku.isEmpty ? "SN" : product.sku)
                        let details = certificateManager.getStoreDetailsAndLanguage(for: warehouseName)
                        for idx in 0..<remainingCount {
                            let serial = "\(prefix)-\(1001 + idx + existingCerts.count)"
                            _ = certificateManager.createCertificate(
                                serialNumber: serial,
                                product: product,
                                storeName: details.storeName,
                                storeLocation: details.storeLocation,
                                language: details.language
                            )
                        }
                    }) {
                        HStack {
                            Spacer()
                            Text("Link all certificates")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.blue)
                    .accessibilityLabel("Link all certificates")
                    .padding(.vertical, 4)
                }
            }

            if !product.description.isEmpty {
                Section(header: Text("Description")) {
                    Text(product.description)
                        .font(.body)
                        .foregroundColor(.secondary)
                }
            }
        }
        .sheet(item: $selectedCertificateInfo) { info in
            CertificateView(info: info, onPrintCompleted: {})
        }
        .navigationTitle("Product Detail")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: saveChanges) {
                    if isSaving {
                        ProgressView()
                    } else {
                        Text("Save")
                            .fontWeight(.semibold)
                    }
                }
                .disabled(isSaving)
            }
        }
        .task {
            await loadDetails()
        }
        .alert("Status", isPresented: $saveSuccess) {
            Button("OK") { dismiss() }
        } message: {
            Text("Inventory information updated successfully.")
        }
        .alert("Error", isPresented: Binding<Bool>(
            get: { errorMessage != nil },
            set: { show in if !show { errorMessage = nil } }
        )) {
            Button("OK") {}
        } message: {
            if let msg = errorMessage {
                Text(msg)
            }
        }
    }

    private func loadDetails() async {
        do {
            // Load category
            let categories: [Category] = try await DatabaseService.shared.fetch(from: "categories", as: Category.self)
            if let cat = categories.first(where: { $0.id == product.categoryId }) {
                categoryName = cat.categoryName
            } else {
                categoryName = "Unknown"
            }

            // Load warehouse
            let warehouses = try await WarehouseService.shared.fetchWarehouses()
            if let wh = warehouses.first(where: { $0.id == warehouseId }) {
                warehouseName = wh.warehouseName
            } else {
                warehouseName = "Unknown"
            }
        } catch {
            print("Failed to load details: \(error)")
        }
    }

    private func saveChanges() {
        guard !isSaving else { return }
        isSaving = true
        errorMessage = nil

        _Concurrency.Task {
            do {
                // Update reorder_level (minimum threshold) using generic update
                struct UpdateReorderLevel: Encodable {
                    let reorderLevel: Int
                    enum CodingKeys: String, CodingKey {
                        case reorderLevel = "reorder_level"
                    }
                }
                
                try await DatabaseService.shared.update(
                    table: "inventory",
                    value: UpdateReorderLevel(reorderLevel: reorderLevel),
                    column: "id",
                    equals: item.id.uuidString.lowercased()
                )

                // Log audit action
                try? await WarehouseService.shared.logAction(
                    userId: item.productId, // Fallback user id or system
                    module: "Inventory",
                    action: "Updated threshold for item \(product.productName)"
                )

                saveSuccess = true
            } catch {
                errorMessage = error.localizedDescription
            }
            isSaving = false
        }
    }
}
