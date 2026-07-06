// OmnichannelView.swift
// RSMS — Sales Associate Module

import SwiftUI

struct OmnichannelView: View {
    var isEmbedded: Bool = false
    @StateObject private var viewModel = OmnichannelViewModel()
    @State private var orderSearchQuery: String = ""
    
    var body: some View {
        if isEmbedded {
            mainContent
        } else {
            NavigationStack {
                mainContent
            }
        }
    }
    
    private var mainContent: some View {
        List {
            Section(header: Text("Fulfillment Queues")) {
                NavigationLink(destination: BOPISQueueView().environmentObject(viewModel)) {
                    HStack {
                        Image(systemName: "bag.fill")
                            .foregroundColor(.blue)
                            .frame(width: 30)
                        Text("BOPIS Orders")
                        Spacer()
                        if viewModel.bopisOrders.count > 0 {
                            Text("\(viewModel.bopisOrders.count)")
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .clipShape(Capsule())
                        }
                    }
                }
                
                NavigationLink(destination: ShipFromStoreView().environmentObject(viewModel)) {
                    HStack {
                        Image(systemName: "shippingbox.fill")
                            .foregroundColor(.orange)
                            .frame(width: 30)
                        Text("Ship From Store")
                        Spacer()
                        if viewModel.sfsOrders.count > 0 {
                            Text("\(viewModel.sfsOrders.count)")
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color.orange)
                                .foregroundColor(.white)
                                .clipShape(Capsule())
                        }
                    }
                }
            }
            
            Section(header: Text("Inventory & Order Management")) {
                NavigationLink(destination: EndlessAisleView().environmentObject(viewModel)) {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.blue)
                            .frame(width: 30)
                        Text("Endless Aisle / Global Stock")
                    }
                }
            }
            
            Section(header: Text("Track Product Order")) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        TextField("Enter Order Number (e.g. 1001, 1002)...", text: $orderSearchQuery)
                            .keyboardType(.numberPad)
                    }
                    .padding(.vertical, 6)
                    
                    if !orderSearchQuery.isEmpty {
                        if matchedOrders.isEmpty {
                            Text("No order found matching '\(orderSearchQuery)'")
                                .font(.caption)
                                .foregroundColor(.red)
                        } else {
                            ForEach(matchedOrders) { order in
                                VStack(alignment: .leading, spacing: 6) {
                                    Divider()
                                        .padding(.vertical, 4)
                                    
                                    HStack {
                                        Text("Order #\(order.orderNumber)")
                                            .font(.headline)
                                        Spacer()
                                        Text(order.status.rawValue.uppercased())
                                            .font(.caption.bold())
                                            .foregroundColor(order.status == .pickedUp || order.status == .completed || order.status == .readyForPickup ? .green : .orange)
                                    }
                                    
                                    Text("Fulfillment Type: \(order.type == .bopis ? "BOPIS (In-Store Pickup)" : "SFS (Ship From Store)")")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    if let carrier = order.carrier, let tracking = order.trackingNumber {
                                        Text("Carrier: \(carrier) | Tracking: \(tracking)")
                                            .font(.caption)
                                            .foregroundColor(.blue)
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Omnichannel")
        .toolbar(.hidden, for: .tabBar)
        .task {
            await viewModel.fetchBOPISOrders()
            await viewModel.fetchSFSOrders()
        }
        .refreshable {
            await viewModel.fetchBOPISOrders()
            await viewModel.fetchSFSOrders()
        }
    }
    
    private var matchedOrders: [FulfillmentOrder] {
        guard !orderSearchQuery.isEmpty else { return [] }
        return MockData.fulfillmentOrders.filter { $0.orderNumber.contains(orderSearchQuery) }
    }
}


#Preview {
    OmnichannelView()
}
