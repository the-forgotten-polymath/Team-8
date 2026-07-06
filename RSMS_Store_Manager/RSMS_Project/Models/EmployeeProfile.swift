//
//  EmployeeProfile.swift
//  RSMS_Project
//
//  Created by Yatharth Mishra on 30/06/26.
//

import Foundation

struct EmployeeProfile: Codable, Identifiable {
    let id: UUID
    let gender: String
    let dateOfBirth: Date
    let mobileNumber: String
    let email: String
    let address: String
    let jobRole: String
    let shiftId: UUID?
    let profilePhotoData: Data?
}

final class EmployeeProfileStore {
    static let shared = EmployeeProfileStore()
    private let key = "employee_profiles_local"
    
    private init() {}
    
    func save(profile: EmployeeProfile) {
        var profiles = getAll()
        profiles[profile.id] = profile
        if let encoded = try? JSONEncoder().encode(profiles) {
            UserDefaults.standard.set(encoded, forKey: key)
        }
    }
    
    func get(id: UUID) -> EmployeeProfile? {
        return getAll()[id]
    }
    
    func delete(id: UUID) {
        var profiles = getAll()
        profiles.removeValue(forKey: id)
        if let encoded = try? JSONEncoder().encode(profiles) {
            UserDefaults.standard.set(encoded, forKey: key)
        }
    }
    
    func getAll() -> [UUID: EmployeeProfile] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode([UUID: EmployeeProfile].self, from: data) else {
            return [:]
        }
        return decoded
    }
}
