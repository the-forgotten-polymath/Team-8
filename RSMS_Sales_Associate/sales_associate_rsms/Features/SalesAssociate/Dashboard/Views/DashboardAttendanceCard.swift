// DashboardAttendanceCard.swift
// RSMS — Sales Associate Module

import SwiftUI
import CoreLocation
import Combine

// MARK: - Location Manager
class AttendanceLocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    
    @Published var authorizationStatus: CLAuthorizationStatus?
    @Published var lastLocation: CLLocation?
    
    private var locationContinuation: CheckedContinuation<CLLocation, Error>?
    
    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        self.authorizationStatus = manager.authorizationStatus
    }
    
    func requestPermission() {
        manager.requestWhenInUseAuthorization()
    }
    
    func getCurrentLocation() async throws -> CLLocation {
        return try await withCheckedThrowingContinuation { continuation in
            let status = manager.authorizationStatus
            if status == .denied || status == .restricted {
                continuation.resume(throwing: CLError(.denied))
                return
            }
            
            self.locationContinuation = continuation
            manager.startUpdatingLocation()
        }
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        self.authorizationStatus = manager.authorizationStatus
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        manager.stopUpdatingLocation()
        
        if let continuation = locationContinuation {
            continuation.resume(returning: location)
            locationContinuation = nil
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        if let clError = error as? CLError, clError.code == .locationUnknown {
            return
        }
        manager.stopUpdatingLocation()
        if let continuation = locationContinuation {
            continuation.resume(throwing: error)
            locationContinuation = nil
        }
    }
}

// MARK: - Attendance Card View
struct DashboardAttendanceCard: View {
    @EnvironmentObject var viewModel: DashboardViewModel
    @EnvironmentObject var authVM: AuthViewModel
    
    @StateObject private var locationManager = AttendanceLocationManager()
    @State private var isProcessing = false
    @State private var successPresented = false
    @State private var alertErrorMessage: String? = nil
    @State private var locationAlertPresented = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            if let shift = viewModel.userShift {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(shift.shiftName)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.primary)
                        
                        Text("\(formatTimeStr(shift.startTime)) – \(formatTimeStr(shift.endTime))")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "clock.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.blue.opacity(0.8))
                }
                
                Divider()
                
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Today's Status")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.secondary)
                            .textCase(.uppercase)
                        
                        if let attendance = viewModel.todayAttendance {
                            let checkInTimeStr = formatCheckInTime(attendance.checkIn)
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(attendance.status.lowercased() == "present" ? Color.green : Color.orange)
                                    .frame(width: 8, height: 8)
                                Text("\(attendance.status) • \(checkInTimeStr)")
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundColor(attendance.status.lowercased() == "present" ? .green : .orange)
                            }
                        } else {
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(Color.secondary)
                                    .frame(width: 8, height: 8)
                                Text("Not Checked In")
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    Spacer()
                    
                    if viewModel.todayAttendance == nil {
                        Button(action: {
                            Task {
                                await triggerCheckIn()
                            }
                        }) {
                            if isProcessing {
                                HStack(spacing: 8) {
                                    ProgressView()
                                        .tint(.white)
                                    Text("Marking...")
                                        .font(.system(size: 14, weight: .bold))
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                .background(Color.blue.opacity(0.6))
                                .cornerRadius(18)
                            } else {
                                Text("Check In")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 10)
                                    .background(Color.blue)
                                    .cornerRadius(18)
                                    .shadow(color: Color.blue.opacity(0.3), radius: 4, x: 0, y: 2)
                            }
                        }
                        .disabled(isProcessing)
                        .buttonStyle(.plain)
                    } else {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text(viewModel.todayAttendance?.status.lowercased() == "present" ? "Checked In" : "Late")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.green)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(18)
                    }
                }
            } else {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("No Shift Assigned")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.primary)
                        Text("Please contact your manager.")
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                }
            }
        }
        .padding(16)
        .whiteCard()
        .alert(isPresented: $locationAlertPresented) {
            Alert(
                title: Text("Location Required"),
                message: Text("Location access is required to verify your presence at your assigned store before marking attendance."),
                primaryButton: .default(Text("Open Settings"), action: {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }),
                secondaryButton: .cancel()
            )
        }
        .alert(item: Binding<AlertError?>(
            get: { alertErrorMessage.map { AlertError(message: $0) } },
            set: { alertErrorMessage = $0?.message }
        )) { err in
            Alert(
                title: Text(err.message.contains("permitted") ? "Attendance Failed" : "Error"),
                message: Text(err.message),
                dismissButton: .default(Text("OK"))
            )
        }
        .sheet(isPresented: $successPresented) {
            AttendanceSuccessView {
                successPresented = false
            }
        }
    }
    
    struct AlertError: Identifiable {
        let id = UUID()
        let message: String
    }
    
    private func formatTimeStr(_ timeStr: String) -> String {
        let clean = timeStr.trimmingCharacters(in: .whitespacesAndNewlines)
        let formatters = ["HH:mm:ss", "HH:mm", "hh:mm a", "h:mm a"]
        let tempFormatter = DateFormatter()
        tempFormatter.locale = Locale(identifier: "en_US_POSIX")
        
        for format in formatters {
            tempFormatter.dateFormat = format
            if let parsed = tempFormatter.date(from: clean) {
                let displayFormatter = DateFormatter()
                displayFormatter.dateFormat = "hh:mm a"
                return displayFormatter.string(from: parsed)
            }
        }
        return timeStr
    }
    
    private func formatCheckInTime(_ date: Date?) -> String {
        guard let date = date else { return "—" }
        let formatter = DateFormatter()
        formatter.dateFormat = "hh:mm a"
        return formatter.string(from: date)
    }
    
    private func triggerCheckIn() async {
        isProcessing = true
        defer { isProcessing = false }
        
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        let status = locationManager.authorizationStatus
        if status == nil || status == .notDetermined {
            locationManager.requestPermission()
            return
        }
        
        if status == .denied || status == .restricted {
            locationAlertPresented = true
            return
        }
        
        do {
            let employeeLocation = try await locationManager.getCurrentLocation()
            
            guard let employeeId = authVM.currentUser?.id else {
                alertErrorMessage = "No active associate session found."
                return
            }
            
            let user = try await SalesAssociateService.shared.fetchUser(userId: employeeId)
            
            // Check for duplicate attendance
            if let _ = try await SalesAssociateService.shared.fetchTodayAttendance(employeeId: employeeId) {
                alertErrorMessage = "Already Checked In\nYour attendance has already been recorded for today."
                viewModel.todayAttendance = try? await SalesAssociateService.shared.fetchTodayAttendance(employeeId: employeeId)
                return
            }
            
            guard let storeId = user.storeId else {
                alertErrorMessage = "No store assigned to this associate profile."
                return
            }
            
            let store = try await SalesAssociateService.shared.fetchStore(storeId: storeId)
            
            guard let storeLat = store.latitude, let storeLng = store.longitude else {
                alertErrorMessage = "Store location coordinates are not configured in database."
                return
            }
            
            // Calculate Distance
            let storeLoc = CLLocation(latitude: storeLat, longitude: storeLng)
            let distance = employeeLocation.distance(from: storeLoc)
            
            if distance > 50.0 {
                alertErrorMessage = "You are outside the permitted attendance area.\nPlease move closer to your assigned store before checking in."
                return
            }
            
            guard let shiftId = user.shiftId else {
                alertErrorMessage = "No shift assigned to this associate profile."
                return
            }
            
            let shift = try await SalesAssociateService.shared.fetchShift(shiftId: shiftId)
            let attendanceStatus = checkAttendanceStatus(shiftStartTimeStr: shift.startTime)
            
            let record = try await SalesAssociateService.shared.insertAttendance(employeeId: employeeId, status: attendanceStatus)
            viewModel.todayAttendance = record
            
            successPresented = true
            
        } catch {
            alertErrorMessage = "Error: \(error.localizedDescription)"
        }
    }
    
    private func checkAttendanceStatus(shiftStartTimeStr: String) -> String {
        let calendar = Calendar.current
        let now = Date()
        let cleanTimeStr = shiftStartTimeStr.trimmingCharacters(in: .whitespacesAndNewlines)
        
        let formatters = ["HH:mm:ss", "HH:mm", "hh:mm a", "h:mm a"]
        var shiftComponents: DateComponents? = nil
        
        let tempFormatter = DateFormatter()
        tempFormatter.locale = Locale(identifier: "en_US_POSIX")
        
        for format in formatters {
            tempFormatter.dateFormat = format
            if let parsedDate = tempFormatter.date(from: cleanTimeStr) {
                shiftComponents = calendar.dateComponents([.hour, .minute], from: parsedDate)
                break
            }
        }
        
        guard let comps = shiftComponents, let hour = comps.hour, let minute = comps.minute else {
            return "Present"
        }
        
        var targetComponents = calendar.dateComponents([.year, .month, .day], from: now)
        targetComponents.hour = hour
        targetComponents.minute = minute
        targetComponents.second = 0
        
        guard let shiftStartDate = calendar.date(from: targetComponents) else {
            return "Present"
        }
        
        let gracePeriodSeconds: TimeInterval = 15 * 60
        let lateCutoffDate = shiftStartDate.addingTimeInterval(gracePeriodSeconds)
        
        return now <= lateCutoffDate ? "Present" : "Late"
    }
}

// MARK: - Success View
struct AttendanceSuccessView: View {
    var onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.15))
                    .frame(width: 100, height: 100)
                
                Image(systemName: "checkmark")
                    .font(.system(size: 42, weight: .bold))
                    .foregroundColor(.green)
            }
            
            VStack(spacing: 8) {
                Text("Attendance Recorded")
                    .font(.title2.bold())
                    .foregroundColor(.primary)
                
                Text("Welcome!\nYour attendance has been marked successfully.")
                    .font(.system(size: 15))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
            
            Button(action: {
                onDismiss()
            }) {
                Text("Done")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.green)
                    .cornerRadius(25)
                    .padding(.horizontal, 24)
            }
            .buttonStyle(.plain)
            .padding(.bottom, 24)
        }
        .padding()
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                onDismiss()
            }
        }
    }
}
