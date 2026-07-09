// SharedModels.swift
// RSMS — Sales Associate Module
// Common value types used across multiple features

import Foundation

// MARK: - Address

struct Address: Codable, Equatable {
    var line1: String
    var line2: String?
    var city: String
    var state: String
    var postalCode: String
    var country: String

    var formatted: String {
        var parts = [line1]
        if let l2 = line2, !l2.isEmpty { parts.append(l2) }
        parts += [city, state, postalCode, country]
        return parts.joined(separator: ", ")
    }
}

// MARK: - Store

struct Store: Codable, Identifiable {
    let id: UUID
    let name: String
    let code: String       // e.g. "DLH", "MUM", "BLR"
    let address: Address
    let phone: String?
    let email: String?
    let isActive: Bool
    let latitude: Double?
    let longitude: Double?

    enum CodingKeys: String, CodingKey {
        case id, name, code, address, phone, email
        case isActive   = "is_active"
        case latitude, longitude
    }
}

// MARK: - Staff Profile

public struct StaffProfile: Codable, Identifiable {
    public let id: UUID                  // Matches auth.users.id
    public let firstName: String
    public let lastName: String
    public let email: String
    public let role: StaffRole
    public let storeID: UUID?
    public let avatarURL: String?
    public let isActive: Bool
    public let createdAt: Date
    public let isProfileCompleted: Bool

    public var fullName: String { "\(firstName) \(lastName)" }
    public var initials: String {
        let f = firstName.prefix(1)
        let l = lastName.prefix(1)
        return "\(f)\(l)".uppercased()
    }

    public enum CodingKeys: String, CodingKey {
        case id
        case firstName = "first_name"
        case lastName  = "last_name"
        case email, role
        case storeID   = "store_id"
        case avatarURL = "avatar_url"
        case isActive  = "is_active"
        case createdAt = "created_at"
        case isProfileCompleted = "profile_verified"
    }

    public init(
        id: UUID,
        firstName: String,
        lastName: String,
        email: String,
        role: StaffRole,
        storeID: UUID?,
        avatarURL: String? = nil,
        isActive: Bool = true,
        createdAt: Date = Date(),
        isProfileCompleted: Bool = false
    ) {
        self.id = id
        self.firstName = firstName
        self.lastName = lastName
        self.email = email
        self.role = role
        self.storeID = storeID
        self.avatarURL = avatarURL
        self.isActive = isActive
        self.createdAt = createdAt
        self.isProfileCompleted = isProfileCompleted
    }
}

// MARK: - Currency Helper

struct Money: Codable, Equatable, Comparable {
    let amount: Decimal
    let currencyCode: String

    init(_ amount: Decimal, currency: String = AppConstants.App.currencyCode) {
        self.amount = amount
        self.currencyCode = currency
    }

    var formatted: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode
        formatter.currencySymbol = AppConstants.App.currencySymbol
        formatter.maximumFractionDigits = 0
        return formatter.string(from: amount as NSDecimalNumber) ?? "\(AppConstants.App.currencySymbol)\(amount)"
    }

    static func < (lhs: Money, rhs: Money) -> Bool {
        return lhs.amount < rhs.amount
    }
}

// MARK: - Pagination

struct PaginationInfo {
    var page: Int = 0
    var pageSize: Int = AppConstants.App.pageSize
    var hasMore: Bool = true
    var isLoading: Bool = false

    var offset: Int { page * pageSize }

    mutating func nextPage() {
        page += 1
    }

    mutating func reset() {
        page = 0
        hasMore = true
        isLoading = false
    }
}

// MARK: - App Error

enum AppError: LocalizedError {
    case network(String)
    case auth(String)
    case database(String)
    case notFound(String)
    case unauthorized
    case offlineUnavailable
    case unknown(Error)

    var errorDescription: String? {
        switch self {
        case .network(let msg):    return "Network error: \(msg)"
        case .auth(let msg):       return "Authentication error: \(msg)"
        case .database(let msg):   return "Database error: \(msg)"
        case .notFound(let msg):   return "\(msg) not found"
        case .unauthorized:        return "You don't have permission to perform this action"
        case .offlineUnavailable:  return "This feature requires an internet connection"
        case .unknown(let error):  return error.localizedDescription
        }
    }
}

// MARK: - Async State

enum AsyncState<T> {
    case idle
    case loading
    case success(T)
    case failure(AppError)

    var isLoading: Bool {
        if case .loading = self { return true }
        return false
    }

    var value: T? {
        if case .success(let v) = self { return v }
        return nil
    }

    var error: AppError? {
        if case .failure(let e) = self { return e }
        return nil
    }
}

// MARK: - Reminder Log

struct ReminderLog: Codable, Identifiable {
    let id: UUID
    let sentAt: Date
    let channel: CommunicationChannel
    let message: String

    enum CodingKeys: String, CodingKey {
        case id
        case sentAt  = "sent_at"
        case channel, message
    }
}
