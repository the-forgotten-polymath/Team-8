//
//  ExportSheet.swift
//  RSMS_Project
//

import SwiftUI

struct ExportSheet: View {
    let period: String
    let activeFilter: AuditModuleFilter
    let onExport: (AuditExportFormat) -> URL?

    @Environment(\.dismiss) private var dismiss
    @State private var shareURL: URL?
    @State private var exportError: String?

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Export Audit Report")
                        .font(.system(size: 18, weight: .bold))
                    Text("\(period) • \(activeFilter.rawValue) • includes performance summary and AI insight")
                        .font(.system(size: 13))
                        .foregroundColor(.auditLabel2)
                }
                .padding(.horizontal, AuditDS.pagePad)
                .padding(.top, 8)

                VStack(spacing: 12) {
                    ForEach(AuditExportFormat.allCases) { format in
                        Button {
                            if let url = onExport(format) {
                                shareURL = url
                            } else {
                                exportError = "Couldn't generate the \(format.rawValue) file. Please try again."
                            }
                        } label: {
                            HStack(spacing: 14) {
                                ZStack {
                                    Circle().fill(Color.blue.opacity(0.14)).frame(width: 44, height: 44)
                                    Image(systemName: format.icon)
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(.blue)
                                }
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(format.rawValue)
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.auditLabel)
                                    Text(".\(format.fileExtension) file")
                                        .font(.system(size: 12))
                                        .foregroundColor(.auditLabel2)
                                }
                                Spacer()
                                Image(systemName: "square.and.arrow.up")
                                    .foregroundColor(.auditLabel3)
                            }
                            .padding(14)
                            .glassCard(radius: AuditDS.smallRadius)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, AuditDS.pagePad)

                if let exportError {
                    Text(exportError)
                        .font(.system(size: 12))
                        .foregroundColor(.auditRed)
                        .padding(.horizontal, AuditDS.pagePad)
                }

                Spacer()
            }
            .padding(.top, 12)
            .background(Color.auditPageBG.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") { dismiss() }
                }
            }
            .sheet(item: $shareURL) { url in
                ShareSheet(activityItems: [url])
            }
        }
    }
}

// MARK: - URL Identifiable conformance for `.sheet(item:)`

extension URL: @retroactive Identifiable {
    public var id: String { absoluteString }
}

// MARK: - UIActivityViewController wrapper

#if canImport(UIKit)
import UIKit

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
#endif

#Preview {
    ExportSheet(period: "July 2026", activeFilter: .all, onExport: { _ in nil })
}
