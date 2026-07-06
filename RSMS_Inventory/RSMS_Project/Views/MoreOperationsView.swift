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
                NavigationLink(destination: CycleCountView(warehouseId: warehouseId, userId: userId)) {
                    Label("Cycle Count Audits", systemImage: "calendar.badge.clock")
                }
                
                NavigationLink(destination: ExceptionView(userId: userId)) {
                    Label("Discrepancy Audit Log", systemImage: "exclamationmark.octagon.fill")
                        .foregroundColor(.red)
                }
            }
        }
        .listStyle(.grouped)
        .navigationTitle("More Operations")
        .navigationBarTitleDisplayMode(.inline)
    }
}
