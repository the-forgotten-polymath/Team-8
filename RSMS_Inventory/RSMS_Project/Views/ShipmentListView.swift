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
    @Binding var selectedSegment: LogisticsSegment

    @StateObject private var viewModel = ShipmentVerificationViewModel()
    @State private var selectedStatus: String = "all"
    @State private var searchText: String = ""
    @State private var hasLoaded = false

    // The allowed statuses (UI only — backend data is untouched)
    private let allowedStatuses: [String] = ["pending", "arrived", "verified"]
    private let filterLabels: [(label: String, key: String)] = [
        ("All",        "all"),
        ("Pending",    "pending"),
        ("Arrived",    "arrived")
    ]

    /// First strip any statuses not in the allowed list, then apply status filter and search.
    var filteredShipments: [Shipment] {
        let visible = viewModel.shipments.filter { allowedStatuses.contains($0.status.lowercased()) }

        let byStatus: [Shipment]
        if selectedStatus == "all" {
            byStatus = visible
        } else if selectedStatus == "arrived" {
            byStatus = visible.filter { $0.status.lowercased() == "arrived" || $0.status.lowercased() == "verified" }
        } else {
            byStatus = visible.filter { $0.status.lowercased() == selectedStatus }
        }

        let sortedList = byStatus.sorted(by: { 
            let date0 = $0.receivedDate ?? $0.dispatchDate ?? $0.createdAt
            let date1 = $1.receivedDate ?? $1.dispatchDate ?? $1.createdAt
            return date0 > date1
        })

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
                                VStack(alignment: .leading, spacing: 12) {
                                    HStack(alignment: .top) {
                                        VStack(alignment: .leading, spacing: 6) {
                                            // Big bold ASN Number
                                            Text(shipment.asnNumber ?? "No ASN")
                                                .font(.system(size: 18, weight: .bold))
                                                .foregroundColor(.primary)
                                            
                                            // Subtitle matching bullet point style
                                            Text("• \(shipment.shipmentType.capitalized)")
                                                .font(.system(size: 14))
                                                .foregroundColor(.secondary)
                                        }
                                        
                                        Spacer()
                                        
                                        // Status Chip matching reference position
                                        StatusChip(status: shipment.status.lowercased() == "verified" ? "arrived" : shipment.status)
                                    }
                                    
                                    Divider()
                                    
                                    HStack {
                                        // Route with icon
                                        HStack(spacing: 8) {
                                            Image(systemName: "shippingbox.fill")
                                                .foregroundColor(.secondary)
                                                .font(.system(size: 16))
                                            Text("\(shipment.source) ➔ \(shipment.destination)")
                                                .font(.subheadline)
                                                .foregroundColor(.secondary)
                                                .multilineTextAlignment(.leading)
                                        }
                                        
                                        Spacer()
                                        
                                        // Right-aligned reference / tracking details
                                        if let ref = shipment.trackingReference, !ref.isEmpty {
                                            Text("Ref: \(ref)")
                                                .font(.subheadline)
                                                .fontWeight(.bold)
                                                .foregroundColor(.primary)
                                        }
                                    }
                                    
                                    HStack {
                                        Spacer()
                                        if let receivedDate = shipment.receivedDate {
                                            Text("Arrived: \(formatShipmentDate(receivedDate))")
                                                .font(.caption2)
                                                .foregroundColor(.secondary)
                                        } else if let dispatchDate = shipment.dispatchDate {
                                            Text("Dispatched: \(formatShipmentDate(dispatchDate))")
                                                .font(.caption2)
                                                .foregroundColor(.secondary)
                                        } else {
                                            Text(formatShipmentDate(shipment.createdAt))
                                                .font(.caption2)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                }
                                .padding()
                                .background(Color(UIColor.secondarySystemGroupedBackground))
                                .cornerRadius(16)
                                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.appleBorder, lineWidth: 1))
                                .shadow(color: Color.black.opacity(0.02), radius: 5, y: 2)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding()
                }
                .background(Color(UIColor.systemGroupedBackground))
            }
        }
        .refreshable {
            await viewModel.loadShipments()
        }
        .onAppear {
            loadDataIfNeeded()
        }
        .onChange(of: selectedSegment) { newValue in
            if newValue == .shipments {
                loadDataIfNeeded()
            }
        }
    }

    private func loadDataIfNeeded() {
        if selectedSegment == .shipments {
            Swift.Task {
                await viewModel.loadShipments()
            }
        }
    }
    
    private func formatShipmentDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd/yy, h:mm a"
        return formatter.string(from: date)
    }
}
