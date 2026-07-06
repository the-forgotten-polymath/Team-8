// BOPISQueueView.swift
// RSMS — Sales Associate Module

import SwiftUI

struct BOPISQueueView: View {
    @EnvironmentObject var viewModel: OmnichannelViewModel
    
    var body: some View {
        List {
            if viewModel.isLoadingBOPIS {
                ProgressView("Loading Orders...")
            } else if viewModel.bopisOrders.isEmpty {
                Text("No pending BOPIS orders.")
                    .foregroundColor(.secondary)
            } else {
                ForEach(viewModel.bopisOrders) { order in
                    NavigationLink(destination: BOPISDetailView(order: order).environmentObject(viewModel)) {
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
        .animation(.easeInOut, value: viewModel.bopisOrders)
        .navigationTitle("BOPIS Queue")
        .task {
            await viewModel.fetchBOPISOrders()
        }
    }
    
    private func colorForStatus(_ status: FulfillmentStatus) -> Color {
        switch status {
        case .readyForPickup: return .green
        case .pending, .processing: return .orange
        case .pickedUp: return .blue
        case .cancelled: return .red
        default: return .secondary
        }
    }
}

struct BOPISDetailView: View {
    let order: FulfillmentOrder
    @EnvironmentObject var viewModel: OmnichannelViewModel
    @State private var showingSignature = false
    @State private var signatureData: Data?
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        Form {
            Section(header: Text("Order Info")) {
                LabeledContent("Order Number", value: order.orderNumber)
                LabeledContent("Client ID", value: String(order.clientID.uuidString.prefix(8)))
                LabeledContent("Status", value: order.status.rawValue)
            }
            
            Section(header: Text("Items")) {
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
            
            if order.status == .readyForPickup {
                Section {
                    Button(action: {
                        showingSignature = true
                    }) {
                        Text("Capture Client Signature")
                            .frame(maxWidth: .infinity)
                            .foregroundColor(.blue)
                    }
                }
            } else if order.status == .pickedUp {
                Section {
                    Text("Order picked up successfully.")
                        .foregroundColor(.green)
                }
            }
        }
        .navigationTitle("Order Details")
        .sheet(isPresented: $showingSignature) {
            SignatureCaptureView(signatureData: $signatureData)
        }
        .onChange(of: signatureData) { oldData, newData in
            if let data = newData {
                Task {
                    await viewModel.completeBOPISPickup(orderID: order.id, signature: data)
                    dismiss()
                }
            }
        }
    }
}
