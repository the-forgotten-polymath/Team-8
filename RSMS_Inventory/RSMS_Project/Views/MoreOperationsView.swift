//
//  MoreOperationsView.swift
//  RSMS_Project
//
//  Created by Yatharth Mishra on 30/06/26.
//

import SwiftUI

struct MoreOperationsView: View {
    let warehouseId: UUID
    let userId: UUID
    var onLogout: () -> Void
    
    var body: some View {
        List {
            Section(header: Text("Audit & Compliance")) {
                // Cycle Count Audits moved to dedicated tab
            }
        }
        .listStyle(.grouped)
        .navigationTitle("More Operations")
        .navigationBarTitleDisplayMode(.inline)
    }
}
