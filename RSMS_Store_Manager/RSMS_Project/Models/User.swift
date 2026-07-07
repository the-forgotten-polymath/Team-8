//
//  User.swift
//  RSMS_Project
//
//  Created by Yatharth Mishra on 30/06/26.
//

import Foundation

public struct User: Codable, Identifiable {
    public let id: UUID

    // Basic Information
    public let fullName: String
    public let username: String
    public let email: String
    public let password: String?

    // Authentication
    public let isVerified: Bool
    public let lastLogin: String?

    // Organization
    public let roleId: UUID
    public let storeId: UUID?
    public let shiftId: UUID?

    // Employee Information
    public let employeeCode: String?
    public let designation: String?

    public let phone: String?
    public let gender: String?

    public let dateOfBirth: String?
    public let address: String?

    public let joiningDate: String?
    public let employeeStatus: String?

    public let profileImageURL: String?
    public let isProfileCompleted: Bool

    // Audit
    public let createdBy: UUID?
    public let createdAt: String

    public enum CodingKeys: String, CodingKey {
        case id

        case fullName = "full_name"
        case username
        case email
        case password

        case isVerified = "is_verified"
        case lastLogin = "last_login"

        case roleId = "role_id"
        case storeId = "store_id"
        case shiftId = "shift_id"

        case employeeCode = "employee_code"
        case designation

        case phone
        case gender

        case dateOfBirth = "date_of_birth"
        case address

        case joiningDate = "joining_date"
        case employeeStatus = "employee_status"

        case profileImageURL = "profile_image_url"
        case isProfileCompleted = "profile_verified"

        case createdBy = "created_by"
        case createdAt = "created_at"
    }

    // Convenience Initializer with defaults
    public init(
        id: UUID,
        fullName: String,
        username: String,
        email: String,
        password: String? = nil,
        isVerified: Bool,
        lastLogin: String? = nil,
        roleId: UUID,
        storeId: UUID? = nil,
        shiftId: UUID? = nil,
        employeeCode: String? = nil,
        designation: String? = nil,
        phone: String? = nil,
        gender: String? = nil,
        dateOfBirth: String? = nil,
        address: String? = nil,
        joiningDate: String? = nil,
        employeeStatus: String? = nil,
        profileImageURL: String? = nil,
        isProfileCompleted: Bool = false,
        createdBy: UUID? = nil,
        createdAt: String = ISO8601DateFormatter().string(from: Date())
    ) {
        self.id = id
        self.fullName = fullName
        self.username = username
        self.email = email
        self.password = password
        self.isVerified = isVerified
        self.lastLogin = lastLogin
        self.roleId = roleId
        self.storeId = storeId
        self.shiftId = shiftId
        self.employeeCode = employeeCode
        self.designation = designation
        self.phone = phone
        self.gender = gender
        self.dateOfBirth = dateOfBirth
        self.address = address
        self.joiningDate = joiningDate
        self.employeeStatus = employeeStatus
        self.profileImageURL = profileImageURL
        self.isProfileCompleted = isProfileCompleted
        self.createdBy = createdBy
        self.createdAt = createdAt
    }

    // Copy helper
    public func copy(
        fullName: String? = nil,
        username: String? = nil,
        email: String? = nil,
        password: String?? = nil,
        isVerified: Bool? = nil,
        lastLogin: String?? = nil,
        roleId: UUID? = nil,
        storeId: UUID?? = nil,
        shiftId: UUID?? = nil,
        employeeCode: String?? = nil,
        designation: String?? = nil,
        phone: String?? = nil,
        gender: String?? = nil,
        dateOfBirth: String?? = nil,
        address: String?? = nil,
        joiningDate: String?? = nil,
        employeeStatus: String?? = nil,
        profileImageURL: String?? = nil,
        isProfileCompleted: Bool? = nil,
        createdBy: UUID?? = nil,
        createdAt: String? = nil
    ) -> User {
        User(
            id: self.id,
            fullName: fullName ?? self.fullName,
            username: username ?? self.username,
            email: email ?? self.email,
            password: password != nil ? password! : self.password,
            isVerified: isVerified ?? self.isVerified,
            lastLogin: lastLogin != nil ? lastLogin! : self.lastLogin,
            roleId: roleId ?? self.roleId,
            storeId: storeId != nil ? storeId! : self.storeId,
            shiftId: shiftId != nil ? shiftId! : self.shiftId,
            employeeCode: employeeCode != nil ? employeeCode! : self.employeeCode,
            designation: designation != nil ? designation! : self.designation,
            phone: phone != nil ? phone! : self.phone,
            gender: gender != nil ? gender! : self.gender,
            dateOfBirth: dateOfBirth != nil ? dateOfBirth! : self.dateOfBirth,
            address: address != nil ? address! : self.address,
            joiningDate: joiningDate != nil ? joiningDate! : self.joiningDate,
            employeeStatus: employeeStatus != nil ? employeeStatus! : self.employeeStatus,
            profileImageURL: profileImageURL != nil ? profileImageURL! : self.profileImageURL,
            isProfileCompleted: isProfileCompleted ?? self.isProfileCompleted,
            createdBy: createdBy != nil ? createdBy! : self.createdBy,
            createdAt: createdAt ?? self.createdAt
        )
    }
}

