//
//  OperationsView.swift
//  RSMS_Project
//
//  Unified container that merges Shipment Verification and Stock Allocation Requests
//  into a single screen with a native iOS segmented control.
//  No business logic changes — delegates to existing ViewModels.
//

import SwiftUI

struct OperationsView: View {
    let warehouseId: UUID
    let userId: UUID

    // MARK: - Segment State

    enum Segment: String, CaseIterable {
        case shipments = "Shipments"
        case requests  = "Requests"
    }

    @State private var selectedSegment: Segment = .shipments

    // MARK: - Shipments State (mirrors ShipmentListView)

    @StateObject private var shipmentVM = ShipmentVerificationViewModel()
    @State private var shipmentSearch: String = ""
    @State private var shipmentFilter: String = "all"

    private let shipmentAllowedStatuses: [String] = ["pending", "arrived", "verified"]
    private let shipmentFilterLabels: [(label: String, key: String)] = [
        ("All",     "all"),
        ("Pending", "pending"),
        ("Arrived", "arrived")
    ]

    private func displayStatus(for shipment: Shipment) -> String {
        let lower = shipment.status.lowercased()
        if lower == "verified" || lower == "arrived" {
            return "arrived"
        }
        return lower
    }

    // MARK: - Requests State (mirrors StockRequestView)

    @StateObject private var requestVM = StockRequestViewModel()
    @State private var requestSearch: String = ""
    @State private var requestFilter: RequestFilter = .all

    enum RequestFilter: String, CaseIterable {
        case all, pending, delivered, rejected

        var displayName: String {
            switch self {
            case .all:       return "All"
            case .pending:   return "Pending"
            case .delivered: return "Delivered"
            case .rejected:  return "Rejected"
            }
        }
    }

    // MARK: - Computed — Shipments

    private var filteredShipments: [Shipment] {
        let visible = shipmentVM.shipments.filter {
            let status = displayStatus(for: $0)
            return shipmentAllowedStatuses.contains(status)
        }
        let byStatus: [Shipment]
        if shipmentFilter == "all" {
            byStatus = visible
        } else {
            byStatus = visible.filter {
                let status = displayStatus(for: $0)
                return status == shipmentFilter
            }
        }
        let sorted = byStatus.sorted { a, b in
            let statusA = displayStatus(for: a)
            let statusB = displayStatus(for: b)
            
            let priorityA = statusA == "pending" ? 0 : ((statusA == "arrived" || statusA == "verified") ? 1 : 2)
            let priorityB = statusB == "pending" ? 0 : ((statusB == "arrived" || statusB == "verified") ? 1 : 2)
            
            if priorityA != priorityB {
                return priorityA < priorityB
            }
            
            if priorityA == 1 {
                let dateA = a.receivedDate ?? a.createdAt
                let dateB = b.receivedDate ?? b.createdAt
                return dateA > dateB
            }
            
            return a.createdAt > b.createdAt
        }
        if shipmentSearch.isEmpty { return sorted }
        return sorted.filter {
            ($0.asnNumber?.localizedCaseInsensitiveContains(shipmentSearch) ?? false) ||
            $0.source.localizedCaseInsensitiveContains(shipmentSearch) ||
            $0.destination.localizedCaseInsensitiveContains(shipmentSearch)
        }
    }

    // MARK: - Computed — Requests

    private var filteredRequests: [GroupedStockRequest] {
        let list: [GroupedStockRequest]
        switch requestFilter {
        case .all:       list = requestVM.groupedStockRequests
        case .pending:   list = requestVM.groupedStockRequests.filter { $0.status.lowercased() == "pending" }
        case .delivered: list = requestVM.groupedStockRequests.filter { $0.status.lowercased() == "delivered" }
        case .rejected:  list = requestVM.groupedStockRequests.filter { $0.status.lowercased() == "rejected" }
        }
        let sorted = list.sorted { $0.createdAt > $1.createdAt }
        if requestSearch.isEmpty { return sorted }
        return sorted.filter { group in
            group.items.contains { item in
                guard let product = requestVM.getProduct(for: item.productId) else { return false }
                return product.productName.localizedCaseInsensitiveContains(requestSearch) ||
                       product.sku.localizedCaseInsensitiveContains(requestSearch)
            }
        }
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {

            // Segmented Control
            Picker("Segment", selection: $selectedSegment) {
                ForEach(Segment.allCases, id: \.self) { segment in
                    Text(segment.rawValue).tag(segment)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 4)

            // Shared Search + Filter
            searchAndFilterBar
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color(UIColor.systemBackground))

            Divider()

            // Content
            Group {
                switch selectedSegment {
                case .shipments:
                    shipmentsContent
                case .requests:
                    requestsContent
                }
            }
            .animation(.easeInOut(duration: 0.2), value: selectedSegment)
        }
        .background(Color(UIColor.systemGroupedBackground))
        .navigationTitle("Operations")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await shipmentVM.loadShipments()
            await requestVM.loadData(warehouseId: warehouseId)
        }
        .refreshable {
            switch selectedSegment {
            case .shipments:
                await shipmentVM.loadShipments()
            case .requests:
                await requestVM.loadData(warehouseId: warehouseId)
            }
        }
        .alert("Error", isPresented: Binding(
            get: { requestVM.errorMessage != nil },
            set: { if !$0 { requestVM.errorMessage = nil } }
        )) {
            Button("OK") { requestVM.errorMessage = nil }
        } message: {
            Text(requestVM.errorMessage ?? "")
        }
    }

    // MARK: - Search + Filter Bar

    private var searchAndFilterBar: some View {
        HStack(spacing: 8) {
            // Search bar
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                    .font(.system(size: 15))

                TextField(
                    selectedSegment == .shipments ? "Search shipments…" : "Search by Order ID…",
                    text: selectedSegment == .shipments ? $shipmentSearch : $requestSearch
                )
                .font(.body)
                .autocorrectionDisabled()
                .autocapitalization(.none)
                .submitLabel(.search)

                let activeSearch = selectedSegment == .shipments ? shipmentSearch : requestSearch
                if !activeSearch.isEmpty {
                    Button {
                        if selectedSegment == .shipments {
                            shipmentSearch = ""
                        } else {
                            requestSearch = ""
                        }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 9)
            .background(Color(.systemGray6))
            .cornerRadius(10)

            // Filter menu
            filterMenu
        }
    }

    @ViewBuilder
    private var filterMenu: some View {
        switch selectedSegment {
        case .shipments:
            Menu {
                ForEach(shipmentFilterLabels, id: \.key) { filter in
                    Button {
                        shipmentFilter = filter.key
                    } label: {
                        if shipmentFilter == filter.key {
                            Label(filter.label, systemImage: "checkmark")
                        } else {
                            Text(filter.label)
                        }
                    }
                }
            } label: {
                Image(systemName: shipmentFilter == "all"
                      ? "line.3.horizontal.decrease.circle"
                      : "line.3.horizontal.decrease.circle.fill")
                    .font(.system(size: 22))
                    .foregroundColor(.blue)
            }
            .accessibilityLabel("Filter shipments")

        case .requests:
            Menu {
                ForEach(RequestFilter.allCases, id: \.self) { filter in
                    Button {
                        requestFilter = filter
                    } label: {
                        if requestFilter == filter {
                            Label(filter.displayName, systemImage: "checkmark")
                        } else {
                            Text(filter.displayName)
                        }
                    }
                }
            } label: {
                Image(systemName: requestFilter == .all
                      ? "line.3.horizontal.decrease.circle"
                      : "line.3.horizontal.decrease.circle.fill")
                    .font(.system(size: 22))
                    .foregroundColor(.blue)
            }
            .accessibilityLabel("Filter requests")
        }
    }

    // MARK: - Shipments Content

    @ViewBuilder
    private var shipmentsContent: some View {
        if shipmentVM.isLoading {
            LoadingView(message: "Loading shipments…")
        } else if filteredShipments.isEmpty {
            EmptyStateView(
                title: "No Shipments Found",
                message: "There are no shipments matching the active filter.",
                iconName: "truck.box"
            )
            .frame(maxHeight: .infinity)
        } else {
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(filteredShipments) { shipment in
                        NavigationLink(destination: ShipmentDetailView(
                            shipment: shipment,
                            warehouseId: warehouseId,
                            userId: userId
                        )) {
                            shipmentCard(shipment)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
            }
            .background(Color(UIColor.systemGroupedBackground))
        }
    }

    private func shipmentCard(_ shipment: Shipment) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center) {
                HStack(spacing: 12) {
                    Image(systemName: "shippingbox.fill")
                        .font(.title3)
                        .foregroundColor(.blue)
                        .padding(8)
                        .background(Color.blue.opacity(0.1))
                        .clipShape(Circle())
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(shipment.asnNumber ?? "No ASN")
                            .font(.system(.headline, design: .rounded))
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Text(shipment.shipmentType.capitalized)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                StatusChip(status: displayStatus(for: shipment))
            }
            
            Divider()
                .background(Color.secondary.opacity(0.2))
            
            HStack {
                if let ref = shipment.trackingReference, !ref.isEmpty {
                    Label(ref, systemImage: "number.square")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    Label("Direct Delivery", systemImage: "arrow.down.right.and.arrow.up.left")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Label(formatDate(shipment.createdAt, format: "MM/dd/yy, h:mm a"), systemImage: "calendar")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.appleBorder, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 3)
    }

    // MARK: - Requests Content

    @ViewBuilder
    private var requestsContent: some View {
        if requestVM.isLoading {
            LoadingView(message: "Loading stock requests…")
        } else if filteredRequests.isEmpty {
            EmptyStateView(
                title: "No Stock Requests",
                message: "There are no incoming boutique requests matching this filter.",
                iconName: "doc.text"
            )
            .frame(maxHeight: .infinity)
        } else {
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(filteredRequests) { request in
                        let store = requestVM.getStore(for: request.storeId)
                        let totalQty = request.items.reduce(0) { $0 + $1.requestedQuantity }

                        NavigationLink(destination: StockRequestDetailView(
                            groupedRequest: request,
                            warehouseId: warehouseId,
                            userId: userId
                        )) {
                            requestCard(request, store: store, totalQty: totalQty)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
            }
            .background(Color(UIColor.systemGroupedBackground))
        }
    }

    private func requestCard(_ request: GroupedStockRequest, store: Store?, totalQty: Int) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(request.orderId)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)

                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(request.items) { item in
                            let p = requestVM.getProduct(for: item.productId)
                            Text("• \(p?.productName ?? "Loading Product...")")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.leading)
                        }
                    }
                }
                Spacer()
                StatusChip(status: getDisplayStatus(request.status))
            }

            Divider()

            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "storefront.fill")
                        .foregroundColor(.secondary)
                    Text(store?.storeName ?? "Store")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Text("Qty: \(totalQty)")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
            }

            HStack {
                Spacer()
                Text(formatDate(request.createdAt, format: "dd/MM/yy, h:mm a"))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.appleBorder, lineWidth: 1))
        .shadow(color: Color.black.opacity(0.02), radius: 5, y: 2)
    }

    // MARK: - Helpers

    private func formatDate(_ date: Date, format: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        return formatter.string(from: date)
    }

    private func getDisplayStatus(_ status: String) -> String {
        let lower = status.lowercased()
        if lower == "approved" || lower == "preparing shipment" || lower == "in transit" {
            return "fulfilled"
        } else if lower == "delivered" {
            return "delivered"
        } else {
            return lower
        }
    }
}
