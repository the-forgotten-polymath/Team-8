//
//  CycleCountView.swift
//  RSMS_Project
//
//  Created by Yatharth Mishra on 30/06/26.
//

import SwiftUI

struct CycleCountView: View {
    let warehouseId: UUID
    let userId: UUID

    @StateObject private var viewModel = CycleCountViewModel()

    // Schedule sheet state
    @State private var isShowingScheduler = false
    @State private var scheduledDate = Date()
    @State private var selectedZone = "Zone A"

    private let zones = ["Zone A", "Zone B", "Zone C", "Zone D", "Zone E"]

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // Header action card
                HStack {
                    Text("Inventory Counts")
                        .font(.headline)
                    Spacer()
                    Button(action: { isShowingScheduler = true }) {
                        Label("Schedule", systemImage: "calendar.badge.plus")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                }
                .padding()
                .background(Color(UIColor.secondarySystemBackground))

                if viewModel.isLoading && viewModel.cycleCounts.isEmpty {
                    LoadingView(message: "Loading cycle counts...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.cycleCounts.isEmpty {
                    EmptyStateView(
                        title: "No Audits Scheduled",
                        message: "Schedule a zone-based cycle count to keep warehouse inventory accurate.",
                        iconName: "calendar"
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(viewModel.cycleCounts) { count in
                            countRow(for: count)
                        }
                    }
                    .listStyle(.plain)
                }
            }

            if viewModel.isLoading && !viewModel.cycleCounts.isEmpty {
                LoadingView(message: "Saving…")
            }
        }
        .navigationTitle("Cycle Count Auditing")
        .navigationBarTitleDisplayMode(.inline)
        // Schedule new audit sheet
        .sheet(isPresented: $isShowingScheduler) {
            NavigationView {
                Form {
                    Section(header: Text("Zone Selection")) {
                        Picker("Warehouse Zone", selection: $selectedZone) {
                            ForEach(zones, id: \.self) { zone in
                                Text(zone).tag(zone)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(height: 120)
                    }

                    Section(header: Text("Audit Date")) {
                        DatePicker("Scheduled Date", selection: $scheduledDate, displayedComponents: .date)
                    }

                    Section(header: Text("Summary")) {
                        HStack {
                            Label("Zone", systemImage: "map.fill")
                            Spacer()
                            Text(selectedZone).foregroundColor(.secondary)
                        }
                        HStack {
                            Label("Date", systemImage: "calendar")
                            Spacer()
                            Text(scheduledDate, style: .date).foregroundColor(.secondary)
                        }
                    }
                }
                .navigationTitle("Schedule Audit")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") { isShowingScheduler = false }
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Confirm") {
                            Swift.Task {
                                await viewModel.scheduleCount(
                                    warehouseId: warehouseId,
                                    date: scheduledDate,
                                    zone: selectedZone,
                                    userId: userId
                                )
                                isShowingScheduler = false
                            }
                        }
                        .fontWeight(.semibold)
                    }
                }
            }
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
            await viewModel.loadData()
        }
        .onAppear {
            // Refresh list when returning from a completed audit
            if !viewModel.cycleCounts.isEmpty {
                Swift.Task { await viewModel.loadData() }
            }
        }
    }

    // MARK: - Count Row

    @ViewBuilder
    private func countRow(for count: CycleCount) -> some View {
        let isScheduled = count.status.lowercased() == "scheduled"

        HStack(spacing: 12) {
            // Status indicator strip
            RoundedRectangle(cornerRadius: 2)
                .fill(isScheduled ? Color.blue : Color.green)
                .frame(width: 4, height: 48)

            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Text(count.zone ?? "Unknown Zone")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Spacer()
                    StatusChip(status: count.status)
                }

                Text("Scheduled: \(count.scheduledDate, style: .date)")
                    .font(.caption)
                    .foregroundColor(.secondary)

                if let completed = count.completedDate {
                    Text("Completed: \(completed, style: .date)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                if let remarks = count.remarks, !remarks.isEmpty {
                    Text("Remarks: \(remarks)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .italic()
                        .lineLimit(1)
                }
            }

            // Navigate to detail only for scheduled audits
            if isScheduled {
                NavigationLink(destination: CycleCountDetailView(
                    count: count,
                    warehouseId: warehouseId,
                    userId: userId
                )) {
                    EmptyView()
                }
                .frame(width: 0)
                .opacity(0)
            }

            if isScheduled {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 6)
    }
}
