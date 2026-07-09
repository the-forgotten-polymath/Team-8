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

    // The two allowed statuses (UI only — backend data is untouched)
    private let allowedStatuses: [String] = ["pending", "arrived", "verified"]
    private let filterLabels: [(label: String, key: String)] = [
        ("All",        "all"),
        ("Pending",    "pending"),
        ("Arrived",    "arrived")
    ]

    private func displayStatus(for shipment: Shipment) -> String {
        let lower = shipment.status.lowercased()
        if lower == "verified" || lower == "arrived" {
            return "arrived"
        }
        return lower
    }

    /// First strip any statuses not in the allowed list, then apply status filter and search.
    var filteredShipments: [Shipment] {
        let visible = viewModel.shipments.filter {
            let status = displayStatus(for: $0)
            return allowedStatuses.contains(status)
        }

        let byStatus: [Shipment]
        if selectedStatus == "all" {
            byStatus = visible
        } else {
            byStatus = visible.filter {
                let status = displayStatus(for: $0)
                return status == selectedStatus
            }
        }

        let sortedList = byStatus.sorted(by: { $0.createdAt > $1.createdAt })

        if searchText.isEmpty {
            return sortedList
        }
        return sortedList.filter { shipment in
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

            // MARK: - Cards
            if viewModel.isLoading {
                LoadingView(message: "Loading shipments list...")
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
                                        
                                        Label(formatShipmentDate(shipment.createdAt), systemImage: "calendar")
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
                            .buttonStyle(.plain)
                        }
                    }
                    .padding()
                }
                .background(Color(UIColor.systemGroupedBackground))
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
    
    private func formatShipmentDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd/yy, h:mm a"
        return formatter.string(from: date)
    }
}
