import SwiftUI
import Supabase

@MainActor
final class SaleDetailsViewModel: ObservableObject {
    @Published var sale: Sale?
    @Published var items: [SaleProductItem] = []
    @Published var customer: CustomerData?
    @Published var user: UserData?
    @Published var store: StoreData?
    
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    struct SaleProductItem: Identifiable {
        let id: UUID
        let productName: String
        let sku: String
        let brand: String?
        let price: Double
        let quantity: Int
        let imageURL: String?
    }
    
    struct CustomerData: Decodable {
        let firstName: String
        let lastName: String
        let phone: String?
        let email: String?
        
        enum CodingKeys: String, CodingKey {
            case firstName = "first_name"
            case lastName = "last_name"
            case phone, email
        }
    }
    
    struct UserData: Decodable {
        let firstName: String
        let lastName: String
        let employeeCode: String?
        let jobRole: String?
        
        enum CodingKeys: String, CodingKey {
            case firstName = "first_name"
            case lastName = "last_name"
            case employeeCode = "employee_code"
            case jobRole = "job_role"
        }
    }
    
    struct StoreData: Decodable {
        let name: String
    }
    
    func loadDetails(saleId: UUID) async {
        isLoading = true
        errorMessage = nil
        let client = SupabaseManager.shared.client
        
        do {
            // Fetch sale
            let saleResponse = try await client.from("sales").select().eq("id", value: saleId.uuidString).single().execute()
            let fetchedSale = try JSONDecoder.supabaseDecoder.decodeSupabase(Sale.self, from: saleResponse.data)
            self.sale = fetchedSale
            
            // Fetch customer
            if let custId = fetchedSale.customerId {
                if let custResponse = try? await client.from("customers").select().eq("id", value: custId.uuidString).single().execute() {
                    self.customer = try? JSONDecoder.supabaseDecoder.decodeSupabase(CustomerData.self, from: custResponse.data)
                }
            }
            
            // Fetch associate
            if let aId = fetchedSale.userId {
                if let userResponse = try? await client.from("users").select().eq("id", value: aId.uuidString).single().execute() {
                    self.user = try? JSONDecoder.supabaseDecoder.decodeSupabase(UserData.self, from: userResponse.data)
                }
            }
            
            // Fetch store
            if let storeResponse = try? await client.from("stores").select("name").eq("id", value: fetchedSale.storeId.uuidString).single().execute() {
                self.store = try? JSONDecoder.supabaseDecoder.decodeSupabase(StoreData.self, from: storeResponse.data)
            }
            
            // Fetch sale items
            let itemsResponse = try await client.from("sale_items").select().eq("sale_id", value: saleId.uuidString).execute()
            let fetchedItems = try JSONDecoder.supabaseDecoder.decodeSupabase([SaleItem].self, from: itemsResponse.data)
            
            if !fetchedItems.isEmpty {
                let productIds = fetchedItems.map { $0.productId.uuidString }
                let productsResponse = try await client.from("products").select().in("id", values: productIds).execute()
                let products = try JSONDecoder.supabaseDecoder.decodeSupabase([Product].self, from: productsResponse.data)
                let productMap = Dictionary(uniqueKeysWithValues: products.map { ($0.id, $0) })
                
                let imagesResponse = try? await client.from("product_images").select().in("product_id", values: productIds).eq("is_primary", value: true).execute()
                let images = (try? JSONDecoder.supabaseDecoder.decodeSupabase([ProductImage].self, from: imagesResponse?.data ?? Data())) ?? []
                let imageMap = Dictionary(uniqueKeysWithValues: images.map { ($0.productId, $0.imageURL) })
                
                var displayItems: [SaleProductItem] = []
                for item in fetchedItems {
                    let product = productMap[item.productId]
                    displayItems.append(SaleProductItem(
                        id: item.id,
                        productName: product?.productName ?? "Unknown Product",
                        sku: product?.sku ?? "N/A",
                        brand: product?.brand,
                        price: item.unitPrice,
                        quantity: item.quantity,
                        imageURL: imageMap[item.productId]
                    ))
                }
                self.items = displayItems
            }
            
        } catch {
            errorMessage = error.localizedDescription
            print("Failed to load sale details: \(error)")
        }
        
        isLoading = false
    }
}

struct SaleDetailsView: View {
    let saleId: UUID
    @StateObject private var viewModel = SaleDetailsViewModel()
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()
            
            if viewModel.isLoading {
                VStack(spacing: 16) {
                    ProgressView()
                    Text("Loading sale details...").font(.subheadline).foregroundColor(.secondary)
                }
            } else if let error = viewModel.errorMessage {
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle").font(.system(size: 36)).foregroundColor(.orange)
                    Text(error).font(.subheadline).foregroundColor(.secondary).multilineTextAlignment(.center).padding(.horizontal, 40)
                }
            } else if let sale = viewModel.sale {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        invoiceSummaryCard(sale: sale)
                        customerInformationCard(sale: sale)
                        purchasedProductsCard()
                        paymentDetailsCard(sale: sale)
                        salesAssociateCard(sale: sale)
                        saleInformationCard(sale: sale)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 40)
                }
                .refreshable {
                    await viewModel.loadDetails(saleId: saleId)
                }
            }
        }
        .navigationTitle(viewModel.sale?.invoiceNumber ?? "Sale Details")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            Swift.Task {
                await viewModel.loadDetails(saleId: saleId)
            }
        }
    }
    
    // MARK: - Sections
    
    private func invoiceSummaryCard(sale: Sale) -> some View {
        VStack(spacing: 16) {
            HStack {
                Text("INVOICE SUMMARY").font(.caption).fontWeight(.bold).foregroundColor(.secondary)
                Spacer()
                Text(sale.saleStatus)
                    .font(.caption).fontWeight(.bold)
                    .foregroundColor(sale.saleStatus.lowercased() == "completed" ? .green : .orange)
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background((sale.saleStatus.lowercased() == "completed" ? Color.green : Color.orange).opacity(0.12))
                    .cornerRadius(6)
            }
            
            Divider()
            
            HStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(viewModel.items.count)").font(.title2).fontWeight(.bold)
                    Text("Products").font(.caption).foregroundColor(.secondary)
                }
                VStack(alignment: .leading, spacing: 4) {
                    let totalUnits = viewModel.items.reduce(0) { $0 + $1.quantity }
                    Text("\(totalUnits)").font(.title2).fontWeight(.bold)
                    Text("Total Units").font(.caption).foregroundColor(.secondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text(formatIndianCurrency(amount: sale.totalAmount)).font(.title2).fontWeight(.bold)
                    Text("Total Amount").font(.caption).foregroundColor(.secondary)
                }
            }
        }
        .padding(16).background(Color(.secondarySystemGroupedBackground)).cornerRadius(12)
    }
    
    private func customerInformationCard(sale: Sale) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("CUSTOMER INFORMATION").font(.caption).fontWeight(.bold).foregroundColor(.secondary)
            Divider()
            
            if let customer = viewModel.customer {
                DetailRow(icon: "person.fill", title: "Name", value: "\(customer.firstName) \(customer.lastName)")
                if let phone = customer.phone {
                    DetailRow(icon: "phone.fill", title: "Phone", value: phone)
                }
                if let email = customer.email {
                    DetailRow(icon: "envelope.fill", title: "Email", value: email)
                }
            } else {
                Text("Walk-in Customer").font(.subheadline).foregroundColor(.secondary)
            }
        }
        .padding(16).background(Color(.secondarySystemGroupedBackground)).cornerRadius(12)
    }
    
    private func purchasedProductsCard() -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("PURCHASED PRODUCTS").font(.caption).fontWeight(.bold).foregroundColor(.secondary)
            Divider()
            
            if viewModel.items.isEmpty {
                Text("No products found.").font(.subheadline).foregroundColor(.secondary)
            } else {
                ForEach(viewModel.items) { item in
                    HStack(alignment: .top, spacing: 12) {
                        if let urlStr = item.imageURL, let url = URL(string: urlStr) {
                            AsyncImage(url: url) { phase in
                                if let image = phase.image {
                                    image.resizable().scaledToFill()
                                } else {
                                    Color(.systemGray5)
                                }
                            }
                            .frame(width: 60, height: 60)
                            .cornerRadius(8)
                        } else {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(.systemGray5))
                                .frame(width: 60, height: 60)
                                .overlay(Image(systemName: "photo").foregroundColor(.secondary))
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            if let brand = item.brand {
                                Text(brand).font(.caption2).fontWeight(.bold).foregroundColor(.secondary).textCase(.uppercase)
                            }
                            Text(item.productName).font(.subheadline).fontWeight(.semibold).lineLimit(2)
                            Text("SKU: \(item.sku)").font(.caption).foregroundColor(.secondary)
                            
                            HStack {
                                Text("Qty: \(item.quantity)").font(.caption).foregroundColor(.secondary)
                                Spacer()
                                Text(formatIndianCurrency(amount: item.price * Double(item.quantity))).font(.subheadline).fontWeight(.bold)
                            }
                        }
                    }
                    if item.id != viewModel.items.last?.id { Divider().padding(.vertical, 4) }
                }
            }
        }
        .padding(16).background(Color(.secondarySystemGroupedBackground)).cornerRadius(12)
    }
    
    private func paymentDetailsCard(sale: Sale) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("PAYMENT DETAILS").font(.caption).fontWeight(.bold).foregroundColor(.secondary)
            Divider()
            
            DetailRow(title: "Payment Method", value: sale.paymentMethod)
            if let discount = sale.discountAmount, discount > 0 {
                DetailRow(title: "Discount", value: "-\(formatIndianCurrency(amount: discount))")
            }
            if let tax = sale.taxAmount, tax > 0 {
                DetailRow(title: "Tax", value: formatIndianCurrency(amount: tax))
            }
            Divider()
            HStack {
                Text("Final Amount").font(.headline)
                Spacer()
                Text(formatIndianCurrency(amount: sale.totalAmount)).font(.headline)
            }
        }
        .padding(16).background(Color(.secondarySystemGroupedBackground)).cornerRadius(12)
    }
    
    private func salesAssociateCard(sale: Sale) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("SALES ASSOCIATE").font(.caption).fontWeight(.bold).foregroundColor(.secondary)
            Divider()
            
            if let user = viewModel.user {
                DetailRow(icon: "briefcase.fill", title: "Name", value: "\(user.firstName) \(user.lastName)")
                if let code = user.employeeCode {
                    DetailRow(icon: "number.square.fill", title: "Employee Code", value: code)
                }
                if let role = user.jobRole {
                    DetailRow(icon: "tag.fill", title: "Designation", value: role)
                }
            } else {
                Text("Loading associate details...").font(.subheadline).foregroundColor(.secondary)
            }
        }
        .padding(16).background(Color(.secondarySystemGroupedBackground)).cornerRadius(12)
    }
    
    private func saleInformationCard(sale: Sale) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("SALE INFORMATION").font(.caption).fontWeight(.bold).foregroundColor(.secondary)
            Divider()
            
            DetailRow(title: "Invoice Number", value: sale.invoiceNumber ?? "N/A")
            DetailRow(title: "Date", value: formattedDate(sale.saleDate))
            DetailRow(title: "Time", value: formattedTime(sale.saleDate))
            if let store = viewModel.store {
                DetailRow(title: "Store Name", value: store.name)
            }
            DetailRow(title: "POS Terminal", value: "Terminal 1") // Hardcoded or fetched if available
        }
        .padding(16).background(Color(.secondarySystemGroupedBackground)).cornerRadius(12)
    }
    
    // MARK: - Helpers
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMMM yyyy"
        return formatter.string(from: date)
    }
    
    private func formattedTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date).lowercased()
    }
    
    private func formatIndianCurrency(amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "en_IN")
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "₹0"
    }
}

fileprivate struct DetailRow: View {
    var icon: String? = nil
    let title: String
    let value: String
    
    var body: some View {
        HStack(alignment: .top) {
            if let icon = icon {
                Image(systemName: icon).frame(width: 20).foregroundColor(.secondary).font(.caption)
            }
            Text(title).font(.subheadline).foregroundColor(.secondary)
            Spacer(minLength: 16)
            Text(value).font(.subheadline).foregroundColor(.primary).multilineTextAlignment(.trailing)
        }
    }
}
