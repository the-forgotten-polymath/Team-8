//
//  SupabaseManager.swift
//  RSMS_Project
//
//  Created by Yatharth Mishra on 30/06/26.
//

import Foundation
import Supabase

final class SupabaseManager {

    static let shared = SupabaseManager()

    let client: SupabaseClient

    private init() {
        let decoder = JSONDecoder()

        let isoWithFractionalSeconds = ISO8601DateFormatter()
        isoWithFractionalSeconds.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        let isoWithoutFractionalSeconds = ISO8601DateFormatter()
        isoWithoutFractionalSeconds.formatOptions = [.withInternetDateTime]

        let dateOnlyFormatter = DateFormatter()
        dateOnlyFormatter.calendar = Calendar(identifier: .iso8601)
        dateOnlyFormatter.dateFormat = "yyyy-MM-dd"
        dateOnlyFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        dateOnlyFormatter.locale = Locale(identifier: "en_US_POSIX")

        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let raw = try container.decode(String.self)

            if !raw.contains("T") {
                if let date = dateOnlyFormatter.date(from: raw) {
                    return date
                }
            } else {
                let normalized = normalizeTimestamp(raw)
                if normalized.contains(".") {
                    if let date = isoWithFractionalSeconds.date(from: normalized) {
                        return date
                    }
                } else if let date = isoWithoutFractionalSeconds.date(from: normalized) {
                    return date
                }
            }

            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Invalid date format: \(raw)"
            )
        }

        func normalizeTimestamp(_ raw: String) -> String {
            var result = raw

            if let dotIndex = result.firstIndex(of: ".") {
                var digitsEnd = result.index(after: dotIndex)
                while digitsEnd < result.endIndex, result[digitsEnd].isNumber {
                    digitsEnd = result.index(after: digitsEnd)
                }
                let digits = result[result.index(after: dotIndex)..<digitsEnd]
                let normalizedDigits = String(digits.prefix(3)).padding(toLength: 3, withPad: "0", startingAt: 0)
                result.replaceSubrange(result.index(after: dotIndex)..<digitsEnd, with: normalizedDigits)
            }

            if let tIndex = result.firstIndex(of: "T") {
                let afterT = result[result.index(after: tIndex)...]
                let hasTimeZone = afterT.hasSuffix("Z") || afterT.contains("+") || afterT.contains("-")
                if !hasTimeZone {
                    result += "Z"
                }
            }

            return result
        }

        client = SupabaseClient(
            supabaseURL: URL(string: AppConstants.Supabase.projectURL)!,
            supabaseKey: AppConstants.Supabase.anonKey,
            options: SupabaseClientOptions(
                db: SupabaseClientOptions.DatabaseOptions(
                    decoder: decoder
                )
            )
        )
    }
}

