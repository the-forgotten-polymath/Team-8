// AttendanceHistoryView.swift
// RSMS — Sales Associate Module

import SwiftUI

struct AttendanceHistoryView: View {
    @EnvironmentObject private var authVM: AuthViewModel
    @State private var records: [Attendance] = []
    @State private var isLoading = false
    @State private var errorMessage: String? = nil
    
    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()
            
            VStack {
                if isLoading {
                    ProgressView("Loading attendance logs...")
                        .padding()
                } else if let error = errorMessage {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 42))
                            .foregroundColor(.orange)
                        Text(error)
                            .font(.headline)
                            .multilineTextAlignment(.center)
                        Button("Retry") {
                            Task {
                                await loadLogs()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                } else if records.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "calendar.badge.exclamationmark")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        Text("No attendance logs found in database.")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                } else {
                    List {
                        ForEach(records) { record in
                            HStack {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(formatDate(record.attendanceDate))
                                        .font(.system(size: 16, weight: .bold))
                                    
                                    if let checkIn = record.checkIn {
                                        Text("Check In: \(formatTime(checkIn))")
                                            .font(.system(size: 13))
                                            .foregroundColor(.secondary)
                                    }
                                }
                                
                                Spacer()
                                
                                Text(record.status)
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(record.status.lowercased() == "present" ? .green : .orange)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(record.status.lowercased() == "present" ? Color.green.opacity(0.12) : Color.orange.opacity(0.12))
                                    .cornerRadius(12)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
        }
        .navigationTitle("Attendance History")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadLogs()
        }
        .refreshable {
            await loadLogs()
        }
    }
    
    private func loadLogs() async {
        guard let employeeId = authVM.currentUser?.id else {
            errorMessage = "No active associate session found."
            return
        }
        isLoading = true
        errorMessage = nil
        do {
            self.records = try await SalesAssociateService.shared.fetchAttendanceHistory(employeeId: employeeId)
        } catch {
            errorMessage = "Failed to load logs: \(error.localizedDescription)"
        }
        isLoading = false
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "hh:mm a"
        return formatter.string(from: date)
    }
}
