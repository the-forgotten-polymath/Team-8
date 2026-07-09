//
//  CycleCountDetailView.swift
//  RSMS_Project
//
//  Created by Yatharth Mishra on 30/06/26.
//

import SwiftUI

struct CycleCountDetailView: View {
    let count: CycleCount
    let warehouseId: UUID
    let userId: UUID

    @StateObject private var viewModel = CycleCountViewModel()
    @State private var isShowingFinalize = false
    @State private var auditRemarks = ""
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack(alignment: .top) {
            VStack(spacing: 0) {
                zoneHeader
                    .padding()
                    .background(Color(UIColor.secondarySystemBackground))

                if viewModel.isLoading && viewModel.zoneInventory.isEmpty {
                    LoadingView(message: "Loading \(count.zone ?? "zone") inventory...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.zoneInventory.isEmpty {
                    EmptyStateView(
                        title: "No Items in \(count.zone ?? "Zone")",
                        message: "No inventory items are assigned to \(count.zone ?? "this zone"). Run the SQL zone setup in Supabase first.",
                        iconName: "shippingbox"
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    // Product audit list
                    List {
                        ForEach(viewModel.zoneInventory) { item in
                            CycleCountAuditRowView(
                                item: item,
                                count: count,
                                viewModel: viewModel
                            )
                        }
                    }
                    .listStyle(.plain)

                    // Action button: Keep only Finalize Audit
                    VStack(spacing: 10) {
                        Button(action: { isShowingFinalize = true }) {
                            HStack {
                                Text("Finalize Audit")
                                Image(systemName: "arrow.right")
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.green)
                            .foregroundColor(.white)
                            .fontWeight(.bold)
                            .cornerRadius(14)
                            .shadow(color: Color.green.opacity(0.25), radius: 6, y: 3)
                        }
                    }
                    .padding()
                    .background(Color(UIColor.systemBackground))
                }
            }

            // Loading overlay during submission
            if viewModel.isLoading && !viewModel.zoneInventory.isEmpty {
                Color.black.opacity(0.3).ignoresSafeArea()
                LoadingView(message: "Submitting audit…")
            }
        }
        .navigationTitle("\(count.zone ?? "Zone") Audit")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $isShowingFinalize) {
            finalizeSheet
        }
        .alert("Error", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("OK") { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .task {
            if viewModel.zoneInventory.isEmpty {
                await viewModel.loadAuditData(warehouseId: warehouseId, zone: count.zone ?? "")
            }
        }
        .onChange(of: viewModel.isAuditSubmitted) { _, submitted in
            if submitted { dismiss() }
        }
    }

    // MARK: - Zone Summary Header

    private var zoneHeader: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Label(count.zone ?? "Zone Audit", systemImage: "map.fill")
                    .font(.headline)
                Text("Scheduled: \(count.scheduledDate, style: .date)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("\(viewModel.zoneInventory.count) product(s) in zone")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            let s = viewModel.auditSummary
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(viewModel.auditedProductIds.count)/\(viewModel.zoneInventory.count) Audited")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)

                if viewModel.auditedProductIds.count > 0 {
                    Text("\(s.matched)/\(s.total) Matched")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                    if s.discrepancies > 0 {
                        Text("\(s.discrepancies) discrepancy(ies)")
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundColor(.red)
                    }
                }
            }
        }
    }

    // MARK: - (Row extracted to CycleCountAuditRowView below)

    // MARK: - Variance Badge

    @ViewBuilder
    private func varianceBadge(variance: Int) -> some View {
        if variance == 0 {
            Text("✓ Match")
                .font(.caption2).fontWeight(.bold).foregroundColor(.white)
                .padding(.horizontal, 8).padding(.vertical, 3)
                .background(Color.green).cornerRadius(6)
        } else if variance < 0 {
            Text("\(variance) units")
                .font(.caption2).fontWeight(.bold).foregroundColor(.white)
                .padding(.horizontal, 8).padding(.vertical, 3)
                .background(Color.red).cornerRadius(6)
        } else {
            Text("+\(variance) units")
                .font(.caption2).fontWeight(.bold).foregroundColor(.white)
                .padding(.horizontal, 8).padding(.vertical, 3)
                .background(Color.orange).cornerRadius(6)
        }
    }

    // MARK: - Finalize Sheet

    private var finalizeSheet: some View {
        NavigationView {
            Form {
                let s = viewModel.auditSummary

                Section(header: Text("Audit Summary")) {
                    LabeledContent("Zone", value: count.zone ?? "–")
                    LabeledContent("Date", value: count.scheduledDate.formatted(date: .abbreviated, time: .omitted))
                    HStack {
                        Label("Total Items", systemImage: "shippingbox")
                        Spacer()
                        Text("\(s.total)").fontWeight(.semibold)
                    }
                    HStack {
                        Label("Audited Items", systemImage: "checklist")
                            .foregroundColor(.blue)
                        Spacer()
                        Text("\(viewModel.auditedProductIds.count)/\(s.total)").fontWeight(.semibold).foregroundColor(.blue)
                    }
                    HStack {
                        Label("Matched", systemImage: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Spacer()
                        Text("\(s.matched)").fontWeight(.semibold).foregroundColor(.green)
                    }
                    HStack {
                        Label("Discrepancies", systemImage: "exclamationmark.triangle.fill")
                            .foregroundColor(s.discrepancies > 0 ? .red : .secondary)
                        Spacer()
                        Text("\(s.discrepancies)")
                            .fontWeight(.semibold)
                            .foregroundColor(s.discrepancies > 0 ? .red : .primary)
                    }
                }

                if s.discrepancies > 0 {
                    Section(header: Text("Discrepancy Details")) {
                        ForEach(viewModel.zoneInventory.filter { viewModel.variance(for: $0) != 0 }) { item in
                            let prod = viewModel.product(for: item)
                            let v = viewModel.variance(for: item)
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(prod?.productName ?? "Unknown")
                                        .font(.subheadline)
                                    Text("System: \(item.quantity)  →  Counted: \(viewModel.countedQty(for: item.productId))")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Text(v > 0 ? "+\(v)" : "\(v)")
                                    .font(.subheadline).fontWeight(.bold)
                                    .foregroundColor(v > 0 ? .orange : .red)
                            }
                        }
                    }
                }

                Section(header: Text("Audit Remarks (Optional)")) {
                    TextField("e.g. Physical recount confirmed, shelf B2 inspected…", text: $auditRemarks, axis: .vertical)
                        .lineLimit(3, reservesSpace: true)
                }

                if s.discrepancies > 0 {
                    Section {
                        HStack {
                            Image(systemName: "exclamationmark.shield.fill").foregroundColor(.orange)
                            Text("Submitting will update inventory quantities and log \(s.discrepancies) exception(s).")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Finalize Audit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { isShowingFinalize = false }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Submit Audit") {
                        Swift.Task {
                            await viewModel.submitAudit(
                                countId: count.id,
                                warehouseId: warehouseId,
                                remarks: auditRemarks.isEmpty ? nil : auditRemarks,
                                userId: userId
                            )
                            isShowingFinalize = false
                        }
                    }
                    .fontWeight(.bold)
                    .foregroundColor(.green)
                }
            }
        }
    }
}

// MARK: - Dedicated Audit Row View
// This MUST be a separate View struct (not a @ViewBuilder function) so that it
// independently observes the shared CycleCountViewModel via @ObservedObject.
// SwiftUI's List caches @ViewBuilder function results and does NOT re-render them
// when @Published properties change — a dedicated View struct re-renders correctly.
struct CycleCountAuditRowView: View {
    let item: InventoryItem
    let count: CycleCount
    @ObservedObject var viewModel: CycleCountViewModel

    var body: some View {
        let prod = viewModel.product(for: item)
        let isAudited = viewModel.auditedProductIds.contains(item.productId)
        let variance = viewModel.variance(for: item)
        let counted = viewModel.countedQty(for: item.productId)

        return NavigationLink(destination: CycleCountProductAuditView(
            item: item,
            count: count,
            viewModel: viewModel
        )) {
            HStack(alignment: .center, spacing: 14) {
                Image(systemName: isAudited ? "checkmark.circle.fill" : "circle.dashed")
                    .foregroundColor(isAudited ? .green : Color(.tertiaryLabel))
                    .font(.title2)

                VStack(alignment: .leading, spacing: 4) {
                    Text(prod?.productName ?? "Unknown Product")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    Text("\(prod?.brand ?? "") · SKU: \(prod?.sku ?? "–")")
                        .font(.caption2)
                        .foregroundColor(.secondary)

                    if isAudited {
                        HStack(spacing: 6) {
                            Text("System: \(item.quantity)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Text("→")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Text("Counted: \(counted)")
                                .font(.caption2)
                                .fontWeight(.semibold)
                                .foregroundColor(variance == 0 ? .green : (variance < 0 ? .red : .orange))
                        }
                        .padding(.top, 2)
                    } else {
                        Text("System Qty: \(item.quantity)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .padding(.top, 2)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    if isAudited {
                        Text("Completed")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.green.opacity(0.15))
                            .cornerRadius(6)

                        if variance != 0 {
                            Text(variance < 0 ? "\(variance) units" : "+\(variance) units")
                                .font(.caption2).fontWeight(.bold).foregroundColor(.white)
                                .padding(.horizontal, 8).padding(.vertical, 3)
                                .background(variance < 0 ? Color.red : Color.orange)
                                .cornerRadius(6)
                        }
                    } else {
                        Text("Pending")
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.secondary.opacity(0.15))
                            .cornerRadius(6)
                    }
                }
            }
            .padding(.vertical, 6)
        }
    }
}
