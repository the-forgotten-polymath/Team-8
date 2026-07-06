// AppConstants.swift
// RSMS — Sales Associate Module

import Foundation

enum AppConstants: Sendable {
    
    // MARK: - App Config
    static let useMockData: Bool = true

    // MARK: - Supabase
    enum Supabase {
        /// Replace with your Supabase project URL
        static let projectURL = "https://YOUR_PROJECT_ID.supabase.co"
        /// Replace with your Supabase anon (public) key
        static let anonKey    = "YOUR_SUPABASE_ANON_KEY"
    }

    // MARK: - Gemini AI
    enum Gemini {
        /// Replace with your Google AI Studio API key
        static let apiKey     = "YOUR_GEMINI_API_KEY"
        static let modelID    = "gemini-2.0-flash"
        static let baseURL    = "https://generativelanguage.googleapis.com/v1beta/models"
    }

    // MARK: - App
    enum App {
        static let name               = "RSMS Client Advisor"
        static let version            = "1.0.0"
        static let currencyCode       = "INR"
        static let currencySymbol     = "₹"
        static let defaultLocale      = "en_IN"
        static let searchDebounceMS   = 300
        static let pageSize           = 20
        static let cacheExpirySeconds = 300
    }

    // MARK: - BOPIS & Omnichannel
    enum Omnichannel {
        static let reservationHoldHours  = 24
        static let bopisReadyWindowMins  = 120
    }

    // MARK: - Discounts
    enum Discount {
        static let associateMaxPercent  = 10.0   // Requires manager approval above this
        static let managerMaxPercent    = 25.0
    }

    // MARK: - Tiers
    enum ClientTier {
        static let vipThreshold  : Decimal = 1_000_000   // ₹10 Lakh
        static let vvipThreshold : Decimal = 5_000_000   // ₹50 Lakh
    }

    // MARK: - Appointment Reminders
    enum Reminders {
        static let firstReminderHours  = 24
        static let secondReminderHours = 2
    }

    // MARK: - Wishlist
    enum Wishlist {
        static let notificationDelaySeconds = 60
    }
}
