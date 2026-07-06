// ShipFromStoreView.swift
// RSMS — Sales Associate Module

import SwiftUI

struct ShipFromStoreView: View {
    @EnvironmentObject var viewModel: OmnichannelViewModel
    
    var body: some View {
        List {
            if viewModel.isLoadingSFS {
                ProgressView("Loading Orders...")
            } else if viewModel.sfsOrders.isEmpty {
                Text("No pending Ship From Store orders.")
                    .foregroundColor(.secondary)
            } else {
                ForEach(viewModel.sfsOrders) { order in
                    NavigationLink(destination: SFSDetailView(order: order).environmentObject(viewModel)) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Order \(order.orderNumber)")
                                .font(.headline)
                            Text("\(order.items.count) item(s)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            HStack {
                                Text("Status: \(order.status.rawValue)")
                                    .font(.caption)
                                    .foregroundColor(colorForStatus(order.status))
                                Spacer()
                                Text(order.orderDate, style: .date)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .navigationTitle("Ship From Store")
        .task {
            await viewModel.fetchSFSOrders()
        }
    }
    
    private func colorForStatus(_ status: FulfillmentStatus) -> Color {
        switch status {
        case .pending, .processing: return .orange
        case .shipping: return .blue
        case .completed: return .green
        case .cancelled: return .red
        default: return .secondary
        }
    }
}

struct SFSDetailView: View {
    let order: FulfillmentOrder
    @EnvironmentObject var viewModel: OmnichannelViewModel
    @State private var isProcessing = false
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        Form {
            Section(header: Text("Order Info")) {
                LabeledContent("Order Number", value: order.orderNumber)
                LabeledContent("Status", value: order.status.rawValue)
                if let carrier = order.carrier {
                    LabeledContent("Carrier", value: carrier)
                }
                if let tracking = order.trackingNumber {
                    LabeledContent("Tracking", value: tracking)
                }
            }
            
            Section(header: Text("Items to Pack")) {
                ForEach(order.items) { item in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(item.productTitle ?? "Unknown Product")
                                .font(.body)
                            Text(item.sku ?? "No SKU")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Text("Qty: \(item.quantity)")
                    }
                }
            }
            
            if order.status == .pending || order.status == .processing {
                Section {
                    Button(action: {
                        Task {
                            isProcessing = true
                            await viewModel.shipSFSOrder(orderID: order.id, trackingNumber: "TRK-\(Int.random(in: 1000...9999))")
                            isProcessing = false
                            dismiss()
                        }
                    }) {
                        HStack {
                            Spacer()
                            if isProcessing {
                                ProgressView()
                            } else {
                                Text("Generate Packing Slip & Ship")
                            }
                            Spacer()
                        }
                        .foregroundColor(.blue)
                    }
                    .disabled(isProcessing)
                }
            }
        }
        .navigationTitle("Order Details")
    }
}
