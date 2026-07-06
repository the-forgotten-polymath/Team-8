//
//  PasswordGenerator.swift
//  RSMS_Project
//
//  Created by Antigravity on 01/07/26.
//

import Foundation

struct PasswordGenerator {
    /// Generates a temporary password for new employee registration.
    /// Currently returns "password123", but can easily be refactored
    /// to generate secure random passwords in the future.
    static func generateTemporaryPassword() -> String {
        return "password123"
    }
}
