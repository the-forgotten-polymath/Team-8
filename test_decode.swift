import Foundation

// Simulate the same decoding logic
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

// Copy JSONDecoder+Supabase logic
extension JSONDecoder {
    static var supabaseDecoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateStr = try container.decode(String.self)
            
            let formats = [
                "yyyy-MM-dd'T'HH:mm:ss.SSSSSS",
                "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ",
                "yyyy-MM-dd'T'HH:mm:ss.SSS",
                "yyyy-MM-dd'T'HH:mm:ssZZZZZ",
                "yyyy-MM-dd'T'HH:mm:ss",
                "yyyy-MM-dd"
            ]
            
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.timeZone = TimeZone(secondsFromGMT: 0)
            
            for format in formats {
                formatter.dateFormat = format
                if let date = formatter.date(from: dateStr) {
                    return date
                }
            }
            
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Cannot decode date string \(dateStr) with any expected formats."
            )
        }
        return decoder
    }
}

func testSalesDecode() {
    guard let keyMatch = try? String(contentsOfFile: "GatewayView.swift").range(of: "public static let supabaseKey = \"(.*?)\"", options: .regularExpression) else { return }
    let keyString = String(try! String(contentsOfFile: "GatewayView.swift")[keyMatch])
    let key = keyString.components(separatedBy: "\"")[1]
    
    let url = URL(string: "https://yldspqgtzyrbdnoromgv.supabase.co/rest/v1/sales?select=*")!
    var request = URLRequest(url: url)
    request.addValue(key, forHTTPHeaderField: "apikey")
    request.addValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
    
    let semaphore = DispatchSemaphore(value: 0)
    
    URLSession.shared.dataTask(with: request) { data, response, error in
        defer { semaphore.signal() }
        
        guard let data = data else {
            print("No data")
            return
        }
        
        do {
            let sales = try JSONDecoder.supabaseDecoder.decode([Sale].self, from: data)
            print("Successfully decoded \(sales.count) sales.")
        } catch {
            print("Error decoding sales: \(error)")
        }
    }.resume()
    
    semaphore.wait()
}

testSalesDecode()
