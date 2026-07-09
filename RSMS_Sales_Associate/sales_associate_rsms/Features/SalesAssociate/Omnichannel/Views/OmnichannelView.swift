// OmnichannelView.swift
// RSMS — Sales Associate Module

import SwiftUI

struct OmnichannelView: View {
    var isEmbedded: Bool = false
    @StateObject private var viewModel = OmnichannelViewModel()
    
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
            
            Section(header: Text("Track Order")) {
                let combined = viewModel.bopisOrders + viewModel.sfsOrders
                if combined.isEmpty {
                    Text("No recent orders.")
                        .foregroundColor(.secondary)
                        .font(.system(size: 14))
                        .padding(.vertical, 4)
                } else {
                    ForEach(combined.sorted(by: { $0.orderDate > $1.orderDate })) { order in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Order #\(order.orderNumber)")
                                    .font(.system(size: 15, weight: .bold))
                                
                                Text(getCustomerName(for: order.clientID))
                                    .font(.system(size: 13))
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 6) {
                                Text(order.status.rawValue.uppercased())
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(statusColor(order.status))
                                
                                Text(order.type == .bopis ? "Pickup" : "Delivery")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(order.type == .bopis ? Color.blue : Color.orange)
                                    .cornerRadius(8)
                            }
                        }
                        .padding(.vertical, 4)
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
    
    private func statusColor(_ status: FulfillmentStatus) -> Color {
        switch status {
        case .pending, .processing: return .orange
        case .readyForPickup, .shipping: return .blue
        case .completed, .pickedUp: return .green
        case .cancelled: return .red
        }
    }
    
    private func getCustomerName(for clientID: UUID) -> String {
        if let client = MockData.clients.first(where: { $0.id == clientID }) {
            return "\(client.firstName) \(client.lastName)"
        }
        return "Emma Watson"
    }
}


#Preview {
    OmnichannelView()
}
