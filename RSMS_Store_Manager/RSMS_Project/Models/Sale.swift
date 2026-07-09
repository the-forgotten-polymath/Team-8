import Foundation

struct Sale: Codable, Identifiable {
    let id: UUID
    let customerId: UUID?
    let userId: UUID
    let storeId: UUID
    let totalAmount: Double
    let paymentMethod: String
    let saleStatus: String
    let saleDate: Date
    let createdAt: Date
    let invoiceNumber: String?
    let discountAmount: Double?
    let taxAmount: Double?

    enum CodingKeys: String, CodingKey {
        case id
        case customerId = "customer_id"
        case userId = "user_id"
        case storeId = "store_id"
        case totalAmount = "total_amount"
        case paymentMethod = "payment_method"
        case saleStatus = "sale_status"
        case saleDate = "sale_date"
        case createdAt = "created_at"
        case invoiceNumber = "invoice_number"
        case discountAmount = "discount_amount"
        case taxAmount = "tax_amount"
    }
}
