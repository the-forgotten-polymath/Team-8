//
//  JSONDecoder+Supabase.swift
//  RSMS_Project
//
//  Created by Antigravity on 01/07/26.
//

import Foundation

extension JSONDecoder {
    
    /// A preconfigured JSONDecoder built to handle PostgREST/Supabase datetime and date formats.
    static var supabaseDecoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateStr = try container.decode(String.self)
            
            let formats = [
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
    
    /// Decodes a type from Supabase response data with detailed diagnostic logging on failure.
    func decodeSupabase<T: Decodable>(
        _ type: T.Type,
        from data: Data,
        file: String = #file,
        function: String = #function
    ) throws -> T {
        do {
            return try self.decode(type, from: data)
        } catch let error as DecodingError {
            let filename = (file as NSString).lastPathComponent
            print("--- 🔴 SUPABASE DECODING FAILURE IN \(filename) -> \(function) ---")
            
            // Print raw JSON string
            if let jsonString = String(data: data, encoding: .utf8) {
                print("• Raw JSON:\n\(jsonString)\n")
            }
            
            switch error {
            case .typeMismatch(let expectedType, let context):
                print("• Failure: Type Mismatch")
                print("• Expected Type: \(expectedType)")
                print("• Coding Path: \(context.codingPath.map { $0.stringValue }.joined(separator: "."))")
                print("• Description: \(context.debugDescription)")
            case .keyNotFound(let key, let context):
                print("• Failure: Key Not Found")
                print("• Missing Key: \(key.stringValue)")
                print("• Coding Path: \(context.codingPath.map { $0.stringValue }.joined(separator: "."))")
                print("• Description: \(context.debugDescription)")
            case .valueNotFound(let expectedType, let context):
                print("• Failure: Value Not Found")
                print("• Expected Type: \(expectedType)")
                print("• Coding Path: \(context.codingPath.map { $0.stringValue }.joined(separator: "."))")
                print("• Description: \(context.debugDescription)")
            case .dataCorrupted(let context):
                print("• Failure: Data Corrupted")
                print("• Coding Path: \(context.codingPath.map { $0.stringValue }.joined(separator: "."))")
                print("• Description: \(context.debugDescription)")
                if let underlying = context.underlyingError {
                    print("• Underlying Error: \(underlying)")
                }
            @unknown default:
                print("• Failure: Unknown DecodingError: \(error)")
            }
            print("-------------------------------------------------------------------")
            throw error
        } catch {
            let filename = (file as NSString).lastPathComponent
            print("--- 🔴 SUPABASE GENERAL DECODING FAILURE IN \(filename) -> \(function) ---")
            print("• Error: \(error.localizedDescription)")
            print("-------------------------------------------------------------------")
            throw error
        }
    }
}
