//
//  LogisticsView.swift
//  RSMS_Project
//
//  Created on 2026-07-08.
//

import SwiftUI

enum LogisticsSegment: String, CaseIterable, Identifiable {
    case shipments = "shipments"
    case requests = "requests"
    
    var id: String { self.rawValue }
    
    var displayName: String {
        switch self {
        case .shipments: return "Shipments"
        case .requests: return "Requests"
        }
    }
}

struct LogisticsView: View {
    let warehouseId: UUID
    let userId: UUID
    
    @AppStorage("last_selected_logistics_segment") private var selectedSegment: LogisticsSegment = .shipments
    
    var body: some View {
        VStack(spacing: 0) {
            // Segmented Picker Header
            Picker("Logistics Segment", selection: $selectedSegment) {
                ForEach(LogisticsSegment.allCases) { segment in
                    Text(segment.displayName).tag(segment)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.vertical, 10)
            .background(Color(UIColor.systemBackground))
            
            Divider()
            
            // ZStack to keep states preserved, with lazy loading triggered when active
            ZStack {
                ShipmentListView(
                    warehouseId: warehouseId,
                    userId: userId,
                    selectedSegment: $selectedSegment
                )
                .opacity(selectedSegment == .shipments ? 1 : 0)
                .disabled(selectedSegment != .shipments)
                
                StockRequestView(
                    warehouseId: warehouseId,
                    userId: userId,
                    selectedSegment: $selectedSegment
                )
                .opacity(selectedSegment == .requests ? 1 : 0)
                .disabled(selectedSegment != .requests)
            }
        }
        .navigationTitle("Logistics")
        .navigationBarTitleDisplayMode(.inline)
    }
}
