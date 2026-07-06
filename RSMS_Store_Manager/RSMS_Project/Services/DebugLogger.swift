//
//  DebugLogger.swift
//  RSMS_Project
//
//  Created by Antigravity on 02/07/26.
//

import Foundation

func debugLog(_ message: String) {
    print(message)
    let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
    guard let docDir = paths.first else { return }
    let fileURL = docDir.appendingPathComponent("app_debug.txt")
    let formatted = "[\(Date())] \(message)\n"
    if let data = formatted.data(using: .utf8) {
        if FileManager.default.fileExists(atPath: fileURL.path) {
            if let fileHandle = try? FileHandle(forWritingTo: fileURL) {
                fileHandle.seekToEndOfFile()
                fileHandle.write(data)
                fileHandle.closeFile()
            }
        } else {
            try? data.write(to: fileURL)
        }
    }
}
