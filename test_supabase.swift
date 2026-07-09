import Foundation

struct UserResponse: Decodable {
    let id: UUID
    let fullName: String?
    let email: String?
    let roleId: UUID?
    let storeId: UUID?
    
    enum CodingKeys: String, CodingKey {
        case id
        case fullName = "full_name"
        case email
        case roleId = "role_id"
        case storeId = "store_id"
    }
}

let supabaseURL = "https://yldspqgtzyrbdnoromgv.supabase.co"
let supabaseKey = "sb_publishable_6hcPNWOppBItrHk7_F7LoQ_0eGNXAL5"

let url = URL(string: "\(supabaseURL)/rest/v1/users?select=*,roles(role_name),stores(name)")!
var request = URLRequest(url: url)
request.addValue("Bearer \(supabaseKey)", forHTTPHeaderField: "Authorization")
request.addValue(supabaseKey, forHTTPHeaderField: "apikey")

let sem = DispatchSemaphore(value: 0)
URLSession.shared.dataTask(with: request) { data, response, error in
    if let data = data {
        if let str = String(data: data, encoding: .utf8) {
            print(str)
        }
    }
    sem.signal()
}.resume()
sem.wait()
