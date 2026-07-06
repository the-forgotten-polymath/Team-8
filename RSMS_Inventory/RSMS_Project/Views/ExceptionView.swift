//
//  ExceptionView.swift
//  RSMS_Project
//
//  Created by Yatharth Mishra on 30/06/26.
//

import SwiftUI

struct ExceptionView: View {
    let userId: UUID
    @StateObject private var viewModel = ExceptionViewModel()
    
    var body: some View {
        VStack(spacing: 0) {
            // Filter segmented controller
            Picker("Filter Status", selection: $viewModel.filterOption) {
                Text("All").tag(ExceptionViewModel.FilterOption.all)
                Text("Unresolved").tag(ExceptionViewModel.FilterOption.unresolved)
                Text("Resolved").tag(ExceptionViewModel.FilterOption.resolved)
            }
            .pickerStyle(.segmented)
            .padding()
            .background(Color(UIColor.systemBackground))
            
            if viewModel.isLoading {
                LoadingView(message: "Loading exceptions...")
            } else if viewModel.filteredExceptions.isEmpty {
                EmptyStateView(
                    title: "No Exceptions Logged",
                    message: "There are no mismatch notifications matching the chosen filter status.",
                    iconName: "exclamationmark.octagon"
                )
            } else {
                List {
                    ForEach(viewModel.filteredExceptions) { exception in
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text(exception.exceptionType.uppercased())
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(exception.exceptionType.lowercased().contains("short") ? Color.orange : Color.red)
                                    .cornerRadius(6)
                                
                                Spacer()
                                
                                StatusChip(status: exception.status)
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Product: \(viewModel.getProductName(for: exception.productId))")
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                
                                if let remarks = exception.remarks {
                                    Text(remarks)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            HStack {
                                Text("Reported: \(exception.createdAt, style: .date)")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                
                                Spacer()
                                
                                if exception.status.lowercased() == "unresolved" {
                                    Button(action: {
                                        Swift.Task {
                                            await viewModel.resolveException(exception: exception, userId: userId)
                                        }
                                    }) {
                                        Text("Mark Resolved")
                                            .font(.caption2)
                                            .fontWeight(.bold)
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 6)
                                            .background(Color.green)
                                            .cornerRadius(8)
                                    }
                                }
                            }
                        }
                        .padding(.vertical, 6)
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("Discrepancy Audit Log")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadData()
        }
    }
}
