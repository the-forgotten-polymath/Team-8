import SwiftUI

struct WatchlistSheet: View {
    let snapshots: [StorePerformanceSnapshot]
    var onSelectStore: (StorePerformanceSnapshot) -> Void
    
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("CRITICAL ATTENTION WATCHLIST")
                        .font(.caption2.weight(.heavy))
                        .foregroundColor(.secondary)
                        .tracking(1.0)
                        .padding(.horizontal, 4)
                    
                    if snapshots.isEmpty {
                        HStack {
                            Spacer()
                            Text("No stores currently on the critical watchlist.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .padding(.top, 40)
                            Spacer()
                        }
                    } else {
                        VStack(spacing: 12) {
                            ForEach(snapshots) { snap in
                                Button(action: {
                                    onSelectStore(snap)
                                    dismiss()
                                }) {
                                    HStack(spacing: 14) {
                                        ZStack {
                                            Circle()
                                                .fill((snap.attentionReason?.color ?? .auditGreen).opacity(0.12))
                                                .frame(width: 40, height: 40)
                                            Image(systemName: "eye.fill")
                                                .font(.subheadline.bold())
                                                .foregroundColor(snap.attentionReason?.color ?? .auditGreen)
                                        }
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(snap.store.name)
                                                .font(.subheadline.bold())
                                                .foregroundColor(.primary)
                                            if let reason = snap.attentionReason {
                                                Text(reason.title)
                                                    .font(.caption.weight(.bold))
                                                    .foregroundColor(reason.color)
                                            }
                                        }
                                        
                                        Spacer()
                                        
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 11, weight: .bold))
                                            .foregroundColor(.secondary)
                                    }
                                    .padding(14)
                                    .background(Color.cardBG, in: RoundedRectangle(cornerRadius: 16))
                                    .cardShadow()
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .padding(24)
            }
            .background(Color.pageBG.ignoresSafeArea())
            .navigationTitle("Attention Watchlist")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
        }
    }
}

#Preview {
    WatchlistSheet(snapshots: [], onSelectStore: { _ in })
}
