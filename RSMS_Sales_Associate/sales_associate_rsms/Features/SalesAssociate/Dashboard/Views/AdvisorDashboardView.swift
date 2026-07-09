// AdvisorDashboardView.swift
// RSMS — Sales Associate Module

import SwiftUI
import Charts

struct AdvisorDashboardView: View {
    @EnvironmentObject var viewModel: DashboardViewModel
    @State private var selectedContactClient: Opportunity? = nil
    @State private var showingAppointmentSheet = false
    @State private var timeFrame: TimeFrame = .week
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Sales Performance Analytics Header & Picker
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("Sales Performance")
                            .font(.headline)
                        Spacer()
                        Picker("TimeFrame", selection: $timeFrame.animation(.easeInOut)) {
                            ForEach(TimeFrame.allCases, id: \.self) { frame in
                                Text(frame.rawValue).tag(frame)
                            }
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 140)
                    }
                    .padding(.horizontal, 4)
                    

                    
                    // Sales Revenue Chart
                    WeeklySalesTrendCard(
                        data: timeFrame == .week ? viewModel.advisorWeeklyChartData : viewModel.advisorMonthlyChartData,
                        title: timeFrame == .week ? "Weekly Sales Trend" : "Monthly Sales Trend"
                    )
                    .padding(.horizontal, 4)
                }
                
                // Appointments
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Appointments")
                            .font(.headline)
                        Spacer()
                        NavigationLink(destination: AppointmentsView()) {
                            HStack(spacing: 4) {
                                Text("See All")
                                Image(systemName: "chevron.right")
                            }
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.blue)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color.blue.opacity(0.08))
                            .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal, 4)
                    
                    VStack(spacing: 0) {
                        if viewModel.todayAppointments.isEmpty {
                            Text("No appointments for today")
                                .foregroundColor(.secondary)
                                .padding(.vertical, 24)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .whiteCard()
                        } else {
                            VStack(spacing: 0) {
                                ForEach(Array(viewModel.todayAppointments.enumerated()), id: \.offset) { index, appointment in
                                    NavigationLink(destination: AppointmentDetailView(appointment: appointment)) {
                                        DashboardAppointmentRowView(appointment: appointment)
                                    }
                                    .buttonStyle(.plain)
                                    
                                    if index < viewModel.todayAppointments.count - 1 {
                                        Divider()
                                            .padding(.leading, 72)
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                            .whiteCard()
                        }
                    }
                }
                
                // Exclusive opportunities
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Exclusive opportunities")
                            .font(.headline)
                        Spacer()
                        NavigationLink(destination: ActiveOpportunitiesView().environmentObject(viewModel)) {
                            HStack(spacing: 4) {
                                Text("View All")
                                Image(systemName: "chevron.right")
                            }
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.blue)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color.blue.opacity(0.08))
                            .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal, 4)
                    
                    if viewModel.activeOpportunities.isEmpty {
                        VStack(spacing: 10) {
                            Image(systemName: "calendar.badge.clock")
                                .font(.system(size: 36))
                                .foregroundColor(.secondary.opacity(0.5))
                            Text("No upcoming events")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.secondary)
                            Text("Birthdays & anniversaries within 7 days will appear here")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary.opacity(0.7))
                                .multilineTextAlignment(.center)
                        }
                        .padding(.vertical, 24)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .whiteCard()
                    } else {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(viewModel.activeOpportunities) { opp in
                                    HorizontalOpportunityCard(opp: opp) {
                                        selectedContactClient = opp
                                    }
                                }
                            }
                            .padding(.horizontal, 4)
                            .padding(.vertical, 8)
                        }
                    }
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .sheet(item: $selectedContactClient) { opp in
            ContactDetailsSheet(opp: opp)
        }
        .sheet(isPresented: $showingAppointmentSheet) {
            CreateAppointmentView(appointments: .constant([]))
        }
    }
    
    private func formatCurrency(_ value: Double) -> String {
        if value >= 1_000_000 {
            return String(format: "₹%.1fM", value / 1_000_000.0)
        } else if value >= 1_000 {
            return String(format: "₹%.0fK", value / 1_000.0)
        } else {
            return String(format: "₹%.0f", value)
        }
    }
}

// MARK: - Weekly Sales Trend Card
struct WeeklySalesTrendCard: View {
    let data: [RevenueDataPoint]
    let title: String
    
    @State private var selectedPoint: RevenueDataPoint? = nil
    
    var body: some View {
        let activePoint = selectedPoint ?? data.first { isPointToday($0) } ?? data.first
        
        VStack(alignment: .leading, spacing: 16) {
            // Title
            Text(title)
                .font(.subheadline.bold())
                .foregroundColor(.secondary)
            
            // Stats detail overlay card
            if let point = activePoint {
                VStack(alignment: .leading, spacing: 12) {
                    Text(point.label)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 0) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Revenue")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.secondary)
                            Text(formatCurrency(point.amount))
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.primary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Divider()
                            .frame(height: 24)
                            .padding(.horizontal, 8)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Sales Done")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.secondary)
                            Text("\(point.salesCount) sales")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.primary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Divider()
                            .frame(height: 24)
                            .padding(.horizontal, 8)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Total Orders")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.secondary)
                            Text("\(point.salesCount) orders")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.primary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding()
                .whiteCard()
            }
            
            // Line Chart
            Chart(data) { point in
                AreaMark(
                    x: .value("Date", point.label),
                    y: .value("Revenue", point.amount)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.blue.opacity(0.25), Color.blue.opacity(0.0)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .interpolationMethod(.monotone)
                
                LineMark(
                    x: .value("Date", point.label),
                    y: .value("Revenue", point.amount)
                )
                .foregroundStyle(Color.blue)
                .lineStyle(StrokeStyle(lineWidth: 2.5))
                .interpolationMethod(.monotone)
                
                PointMark(
                    x: .value("Date", point.label),
                    y: .value("Revenue", point.amount)
                )
                .foregroundStyle(Color.blue)
                .symbol {
                    let isToday = isPointToday(point)
                    let isSelected = activePoint?.id == point.id
                    Circle()
                        .fill(isSelected ? Color.blue : (isToday ? Color.green : Color.white))
                        .frame(width: isSelected ? 10 : 8, height: isSelected ? 10 : 8)
                        .overlay(
                            Circle()
                                .stroke(isSelected ? Color.blue : (isToday ? Color.green : Color.blue), lineWidth: 2)
                        )
                }
            }
            .frame(height: 180)
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisValueLabel {
                        if let doubleValue = value.as(Double.self) {
                            Text(formatCurrencyYAxis(doubleValue))
                                .font(.caption2)
                        }
                    }
                }
            }
            .chartOverlay { proxy in
                GeometryReader { geometry in
                    Rectangle()
                        .fill(Color.clear)
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    let origin = geometry[proxy.plotFrame!].origin
                                    let location = CGPoint(
                                        x: value.location.x - origin.x,
                                        y: value.location.y - origin.y
                                    )
                                    if let label: String = proxy.value(atX: location.x) {
                                        if let point = data.first(where: { $0.label == label }) {
                                            if selectedPoint?.id != point.id {
                                                let generator = UIImpactFeedbackGenerator(style: .light)
                                                generator.impactOccurred()
                                                withAnimation(.spring()) {
                                                    selectedPoint = point
                                                }
                                            }
                                        }
                                    }
                                }
                        )
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground).opacity(0.5))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.black.opacity(0.04), lineWidth: 1)
        )
    }
    
    private func isPointToday(_ point: RevenueDataPoint) -> Bool {
        let calendar = Calendar.current
        let today = Date()
        
        // Handle monthly timeline weeks
        if point.label.lowercased().starts(with: "week") {
            let day = calendar.component(.day, from: today)
            if point.label == "Week 1" && day >= 1 && day <= 7 { return true }
            if point.label == "Week 2" && day >= 8 && day <= 14 { return true }
            if point.label == "Week 3" && day >= 15 && day <= 21 { return true }
            if point.label == "Week 4" && day >= 22 { return true }
            return false
        }
        
        // Handle weekly timeline days
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE" // "Mon", "Tue", etc.
        let todayLabel = formatter.string(from: today)
        return point.label.lowercased() == todayLabel.lowercased()
    }
    
    private func formatCurrencyYAxis(_ value: Double) -> String {
        if value == 0 { return "0" }
        return String(format: "%.1fE6", value / 1_000_000.0)
    }
    
    private func formatCurrency(_ value: Double) -> String {
        if value >= 1_000_000 {
            return String(format: "₹%.1fM", value / 1_000_000.0)
        } else if value >= 1_000 {
            return String(format: "₹%.0fK", value / 1_000.0)
        } else {
            return String(format: "₹%.0f", value)
        }
    }
}

// MARK: - Horizontal Opportunity Card
struct HorizontalOpportunityCard: View {
    let opp: Opportunity
    var onContact: () -> Void
    
    var body: some View {
        let typeColor  = colorForType(opp.type)
        let bgColor    = bgColorForType(opp.type)
        let codeUsed   = opp.promoCodeUsed ?? false
        let promoCode  = opp.promoCode ?? "—"
        let discount   = opp.type == .birthday ? "10% OFF" : "12% OFF"
        
        VStack(spacing: 8) {
            // Icon Circle
            ZStack {
                Circle()
                    .fill(Color.white)
                    .frame(width: 44, height: 44)
                    .shadow(color: Color.black.opacity(0.04), radius: 2, x: 0, y: 1)
                Image(systemName: iconForType(opp.type))
                    .foregroundColor(typeColor)
                    .font(.system(size: 18, weight: .semibold))
            }
            .padding(.top, 8)
            
            // Dynamic title from server
            Text(opp.title)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(typeColor)
                .multilineTextAlignment(.center)
            
            // Countdown badge
            countdownBadge
            
            // Client avatar + name
            HStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(typeColor.opacity(0.15))
                        .frame(width: 24, height: 24)
                    Text(opp.clientName?.initials ?? "??")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(typeColor)
                }
                Text(opp.clientName ?? "Unknown")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.primary)
                    .lineLimit(1)
            }
            
            // Discount label
            Text(discount)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.primary)
            
            // Promo code badge
            if codeUsed {
                HStack(spacing: 4) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.gray)
                    Text(promoCode)
                        .font(.system(size: 10, weight: .bold))
                        .strikethrough(true, color: .gray)
                        .foregroundColor(.gray)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Color.gray.opacity(0.08))
                .cornerRadius(8)
                
                Text("Code Used")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundColor(.gray)
            } else {
                Text(promoCode)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(typeColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(typeColor.opacity(0.12))
                    .cornerRadius(8)
                
                // Action text
                HStack(spacing: 4) {
                    Text("Offer Code")
                        .font(.system(size: 11, weight: .bold))
                    Image(systemName: "arrow.right")
                        .font(.system(size: 9, weight: .bold))
                }
                .foregroundColor(typeColor)
                .padding(.top, 2)
            }
        }
        .padding(12)
        .frame(width: 165)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 3)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.12), lineWidth: 1)
        )
        .opacity(codeUsed ? 0.65 : 1.0)
        .contentShape(Rectangle())
        .onTapGesture {
            guard !codeUsed else { return }
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            onContact()
        }
    }
    
    // MARK: – Countdown badge
    @ViewBuilder
    private var countdownBadge: some View {
        let days = opp.daysUntilEvent ?? {
            guard let d = opp.eventDate else { return -1 }
            let cal = Calendar.current
            return cal.dateComponents([.day], from: cal.startOfDay(for: Date()), to: cal.startOfDay(for: d)).day ?? -1
        }()
        
        Group {
            if days == 0 {
                Text("🎉 Today!")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.orange)
                    .cornerRadius(8)
            } else if days == 1 {
                Text("⏰ Tomorrow")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.orange)
            } else if days > 1 {
                Text("⏳ \(days) days left")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.orange)
            } else {
                EmptyView()
            }
        }
    }
    
    private func colorForType(_ type: OpportunityType) -> Color {
        switch type {
        case .birthday:   return Color(hex: "7C4DFF")
        case .anniversary: return Color(hex: "FF2D55")
        default:          return .blue
        }
    }
    
    private func bgColorForType(_ type: OpportunityType) -> Color {
        switch type {
        case .birthday:   return Color(hex: "F5F3FF")
        case .anniversary: return Color(hex: "FFF0F2")
        default:          return Color(hex: "F0F8FF")
        }
    }
    
    private func iconForType(_ type: OpportunityType) -> String {
        switch type {
        case .birthday:   return "birthday.cake"
        case .anniversary: return "heart.fill"
        default:          return "sparkles"
        }
    }
}

// MARK: - Appointment Row View
struct DashboardAppointmentRowView: View {
    let appointment: Appointment
    
    var body: some View {
        HStack(spacing: 16) {
            // Time Section (Left)
            VStack(alignment: .leading, spacing: 2) {
                Text(formatTimeOnly(appointment.date))
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Color(hex: "0A2540"))
                Text(formatAMPM(appointment.date))
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(Color(hex: "0A2540").opacity(0.7))
            }
            .frame(width: 55, alignment: .leading)
            
            // Vertical Divider
            Rectangle()
                .fill(Color.gray.opacity(0.2))
                .frame(width: 1, height: 36)
            
            // Avatar (Circular Image / Initials)
            ZStack {
                if appointment.clientName == "Priya Mehta" {
                    Image(systemName: "person.crop.circle.fill")
                        .resizable()
                        .foregroundColor(.blue.opacity(0.6))
                        .frame(width: 44, height: 44)
                } else if appointment.clientName == "Rahul Kapoor" {
                    Image(systemName: "person.crop.circle.fill")
                        .resizable()
                        .foregroundColor(.green.opacity(0.6))
                        .frame(width: 44, height: 44)
                } else {
                    Circle()
                        .fill(Color.blue.opacity(0.12))
                        .frame(width: 44, height: 44)
                    Text(appointment.clientName?.initials ?? "??")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.blue)
                }
            }
            
            // Details (Center)
            VStack(alignment: .leading, spacing: 4) {
                Text(appointment.clientName ?? "Unknown Client")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.primary)
                
                Text(appointment.notes ?? appointment.type.displayName)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                HStack(spacing: 4) {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 10))
                        .foregroundColor(Color(hex: "C9A84C"))
                    Text(appointment.customerTier ?? "VIP Client")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(Color(hex: "C9A84C"))
                }
            }
            
            Spacer()
            
            // Chevron (Right)
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Color(.systemGray4))
        }
        .padding(.vertical, 12)
    }
    
    private func formatTimeOnly(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "hh:mm"
        return formatter.string(from: date)
    }
    
    private func formatAMPM(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "a"
        return formatter.string(from: date)
    }
}
