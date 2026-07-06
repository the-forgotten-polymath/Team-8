//
//  RSMS_ProjectApp.swift
//  RSMS_Project
//
//  Created by Yatharth Mishra on 30/06/26.
//

import SwiftUI

@main
struct RSMS_ProjectApp: App {
    init() {
        // Disable global HTTP caching to prevent stale/cached Supabase data
        URLCache.shared = URLCache(memoryCapacity: 0, diskCapacity: 0, diskPath: nil)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
