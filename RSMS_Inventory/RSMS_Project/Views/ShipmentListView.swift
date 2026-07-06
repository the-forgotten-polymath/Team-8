//
//  ShipmentListView.swift
//  RSMS_Project
//
//  Created by Yatharth Mishra on 30/06/26.
//

import SwiftUI

struct ShipmentListView: View {
    let warehouseId: UUID
    let userId: UUID

    @StateObject private var viewModel = ShipmentVerificationViewModel()
    @State private var selectedStatus: String = "all"
    @State private var searchText: String = ""

    // The four allowed statuses (UI only — backend data is untouched)
    private let allowedStatuses: [String] = ["pending", "rejected", "arrived", "in_transit"]
    private let filterLabels: [(label: String, key: String)] = [
        ("All",        "all"),
        ("Pending",    "pending"),
        ("Rejected",   "rejected"),
        ("Arrived",    "arrived"),
        ("In Transit", "in_transit")
    ]

    /// First strip any statuses not in the allowed list, then apply status filter and search.
    var filteredShipments: [Shipment] {
        let visible = viewModel.shipments.filter { allowedStatuses.contains($0.status.lowercased()) }

        let byStatus: [Shipment]
        if selectedStatus == "all" {
            byStatus = visible
        } else {
            byStatus = visible.filter { $0.status.lowercased() == selectedStatus }
        }

        if searchText.isEmpty {
            return byStatus
        }
        return byStatus.filter { shipment in
            let asn = shipment.asnNumber?.localizedCaseInsensitiveContains(searchText) ?? false
            let src = shipment.source.localizedCaseInsensitiveContains(searchText)
            let dst = shipment.destination.localizedCaseInsensitiveContains(searchText)
            return asn || src || dst
        }
    }

    /// Human-readable label for the currently active filter.
    private var activeFilterLabel: String {
        filterLabels.first(where: { $0.key == selectedStatus })?.label ?? "All"
    }

    var body: some View {
        VStack(spacing: 0) {

            // MARK: - Search + Filter row
            HStack(spacing: 8) {
                // Full-width search bar
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                        .font(.system(size: 15))

                    TextField("Search shipments…", text: $searchText)
                        .font(.body)
                        .autocorrectionDisabled()
                        .autocapitalization(.none)
                        .submitLabel(.search)

                    if !searchText.isEmpty {
                        Button {
                            searchText = ""
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

                // Filter button
                Menu {
                    ForEach(filterLabels, id: \.key) { filter in
                        Button {
                            selectedStatus = filter.key
                        } label: {
                            if selectedStatus == filter.key {
                                Label(filter.label, systemImage: "checkmark")
                            } else {
                                Text(filter.label)
                            }
                        }
                    }
                } label: {
                    Image(systemName: selectedStatus == "all"
                          ? "line.3.horizontal.decrease.circle"
                          : "line.3.horizontal.decrease.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.blue)
                }
                .accessibilityLabel("Filter: \(activeFilterLabel)")
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color(UIColor.systemBackground))

            Divider()

            // MARK: - List
            if viewModel.isLoading {
                LoadingView(message: "Loading shipments list...")
            } else if filteredShipments.isEmpty {
                EmptyStateView(
                    title: "No Shipments Found",
                    message: "There are no shipments matching the active filter.",
                    iconName: "truck.box"
                )
            } else {
                List(filteredShipments) { shipment in
                    NavigationLink(destination: ShipmentDetailView(
                        shipment: shipment,
                        warehouseId: warehouseId,
                        userId: userId
                    )) {
                        HStack {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(shipment.asnNumber ?? "No ASN")
                                    .font(.subheadline)
                                    .fontWeight(.bold)

                                Text("From: \(shipment.source) ➔ \(shipment.destination)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            StatusChip(status: shipment.status)
                        }
                        .padding(.vertical, 4)
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("Shipment Verification")
        .navigationBarTitleDisplayMode(.inline)
        .refreshable {
            await viewModel.loadShipments()
        }
        .task {
            await viewModel.loadShipments()
        }
    }
}
