import SwiftUI

struct AuditTrailFeed: View {
    let entries: [AuditTrailEntry]
    let isLoading: Bool
    let onSelect: (AuditTrailEntry) -> Void
    let onViewFullHistory: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if isLoading {
                VStack(spacing: 0) {
                    ForEach(0..<5, id: \.self) { _ in
                        AuditTrailRowSkeleton()
                    }
                }
            } else if entries.isEmpty {
                emptyState
            } else {
                VStack(spacing: 0) {
                    let prefixEntries = Array(entries.prefix(5))
                    ForEach(0..<prefixEntries.count, id: \.self) { index in
                        let entry = prefixEntries[index]
                        AuditTimelineItemView(
                            entry: entry,
                            isFirst: index == 0,
                            isLast: index == prefixEntries.count - 1,
                            onSelect: { onSelect(entry) }
                        )
                    }
                }

                Spacer().frame(height: 12)

                // View Full Audit History CTA
                Button(action: onViewFullHistory) {
                    HStack(spacing: 8) {
                        Text("View Full Audit History")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(Color.auditBlue)
                        Image(systemName: "arrow.right")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(Color.auditBlue)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .glassCard(material: .secondary, tint: .auditBlue)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "tray")
                .font(.system(size: 32))
                .foregroundColor(.auditLabel3)
            Text("No activity for this filter yet.")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.auditLabel2)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .glassCard(material: .secondary)
    }
}

struct AuditTimelineItemView: View {
    let entry: AuditTrailEntry
    let isFirst: Bool
    let isLast: Bool
    let onSelect: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Timeline line & node column
            VStack(spacing: 0) {
                // Top line segment
                if isFirst {
                    Spacer().frame(height: 22)
                } else {
                    Rectangle()
                        .fill(Color.secondary.opacity(0.18))
                        .frame(width: 2, height: 22)
                }
                
                // Icon Node
                ZStack(alignment: .bottomTrailing) {
                    Circle()
                        .fill(entry.tint.opacity(0.12))
                        .frame(width: 38, height: 38)
                        .overlay(Circle().stroke(entry.tint.opacity(0.3), lineWidth: 1))
                    Image(systemName: entry.icon)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(entry.tint)
                }
                
                // Bottom line segment
                if isLast {
                    Spacer().frame(height: 22)
                } else {
                    Rectangle()
                        .fill(Color.secondary.opacity(0.18))
                        .frame(width: 2)
                }
            }
            .frame(width: 40)
            
            // Log details card (Liquid Glass!)
            Button(action: onSelect) {
                HStack(spacing: 14) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(entry.title)
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.auditLabel)
                        Text(entry.subtitle)
                            .font(.system(size: 13))
                            .foregroundColor(.auditLabel2)
                            .lineLimit(2)
                    }
                    
                    Spacer(minLength: 8)
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(relativeTime(entry.timestamp))
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.auditLabel2)
                        Text(entry.storeName)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.auditLabel)
                            .lineLimit(1)
                    }
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.auditLabel3)
                }
                .padding(14)
                .glassCard(material: .secondary) // Liquid Glass Card!
            }
            .buttonStyle(.plain)
            .padding(.bottom, 12)
        }
    }

    private func relativeTime(_ date: Date) -> String {
        if Calendar.current.isDateInToday(date) {
            return date.formatted(date: .omitted, time: .shortened)
        } else if Calendar.current.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            return date.formatted(.dateTime.day().month(.abbreviated).year())
        }
    }
}

private struct AuditTrailRowSkeleton: View {
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack {
                Circle()
                    .fill(Color.secondary.opacity(0.08))
                    .frame(width: 36, height: 36)
                Rectangle()
                    .fill(Color.secondary.opacity(0.08))
                    .frame(width: 2, height: 40)
            }
            .frame(width: 40)
            
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.secondary.opacity(0.08))
                        .frame(width: 140, height: 16)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.secondary.opacity(0.08))
                        .frame(width: 220, height: 12)
                }
                Spacer()
            }
            .padding(14)
            .glassCard()
        }
        .padding(.bottom, 12)
    }
}

struct AuditTrailRow: View {
    let entry: AuditTrailEntry

    var body: some View {
        HStack(spacing: 14) {
            ZStack(alignment: .bottomTrailing) {
                ZStack {
                    Circle()
                        .fill(entry.tint.opacity(0.12))
                        .frame(width: 44, height: 44)
                        .overlay(Circle().stroke(entry.tint.opacity(0.3), lineWidth: 1))
                    Image(systemName: entry.icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(entry.tint)
                }
                if let dot = entry.statusDotColor {
                    Circle()
                        .fill(dot)
                        .frame(width: 10, height: 10)
                        .overlay(Circle().stroke(Color.cardBG, lineWidth: 2))
                }
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(entry.title)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.auditLabel)
                Text(entry.subtitle)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(.auditLabel2)
                    .lineLimit(1)
            }

            Spacer(minLength: 8)

            VStack(alignment: .trailing, spacing: 3) {
                Text(relativeTime(entry.timestamp))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.auditLabel2)
                Text(entry.storeName)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.auditLabel)
                    .lineLimit(1)
            }

            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.auditLabel3)
        }
        .padding(14)
        .glassCard(material: .secondary) // Liquid Glass!
    }

    private func relativeTime(_ date: Date) -> String {
        if Calendar.current.isDateInToday(date) {
            return date.formatted(date: .omitted, time: .shortened)
        } else if Calendar.current.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            return date.formatted(.dateTime.day().month(.abbreviated).year())
        }
    }
}
