//
//  AuditExportService.swift
//  RSMS_Project
//
//  Implements the "Export" block from the flow doc: PDF / Excel / CSV,
//  containing current filters, audit trail records, store performance
//  summary, and the AI audit summary.
//
//  PDF -> built natively with UIGraphicsPDFRenderer (no third-party deps).
//  CSV -> plain text, RFC4180-escaped.
//  Excel -> written as an HTML table saved with an .xls extension. Excel,
//    Numbers, and Google Sheets all open this correctly; it avoids pulling
//    in a full OOXML/zip writer for a single export button. If a real .xlsx
//    is required later, swap `makeExcel` for a proper OOXML writer — the
//    call site (`export(format:)`) won't need to change.
//

import Foundation
#if canImport(UIKit)
import UIKit
#endif

enum AuditExportFormat: String, CaseIterable, Identifiable {
    case pdf = "PDF"
    case excel = "Excel"
    case csv = "CSV"

    var id: String { rawValue }
    var icon: String {
        switch self {
        case .pdf: return "doc.richtext"
        case .excel: return "tablecells"
        case .csv: return "doc.plaintext"
        }
    }
    var fileExtension: String {
        switch self {
        case .pdf: return "pdf"
        case .excel: return "xls"
        case .csv: return "csv"
        }
    }
}

enum AuditExportService {

    static func export(
        format: AuditExportFormat,
        period: String,
        activeFilter: AuditModuleFilter,
        snapshots: [StorePerformanceSnapshot],
        entries: [AuditTrailEntry],
        executiveSummary: String
    ) throws -> URL {
        let fileName = "Audit_Report_\(period.replacingOccurrences(of: " ", with: "_"))_\(Int(Date().timeIntervalSince1970))"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName).appendingPathExtension(format.fileExtension)

        switch format {
        case .csv:
            let csv = makeCSV(period: period, activeFilter: activeFilter, snapshots: snapshots, entries: entries, executiveSummary: executiveSummary)
            try csv.write(to: url, atomically: true, encoding: .utf8)
        case .excel:
            let html = makeExcelHTML(period: period, activeFilter: activeFilter, snapshots: snapshots, entries: entries, executiveSummary: executiveSummary)
            try html.write(to: url, atomically: true, encoding: .utf8)
        case .pdf:
            #if canImport(UIKit)
            let data = makePDF(period: period, activeFilter: activeFilter, snapshots: snapshots, entries: entries, executiveSummary: executiveSummary)
            try data.write(to: url)
            #else
            let csv = makeCSV(period: period, activeFilter: activeFilter, snapshots: snapshots, entries: entries, executiveSummary: executiveSummary)
            try csv.write(to: url, atomically: true, encoding: .utf8)
            #endif
        }
        return url
    }

    // MARK: - CSV

    private static func csvEscape(_ field: String) -> String {
        guard field.contains(",") || field.contains("\"") || field.contains("\n") else { return field }
        return "\"\(field.replacingOccurrences(of: "\"", with: "\"\""))\""
    }

    private static func makeCSV(
        period: String,
        activeFilter: AuditModuleFilter,
        snapshots: [StorePerformanceSnapshot],
        entries: [AuditTrailEntry],
        executiveSummary: String
    ) -> String {
        var lines: [String] = []
        lines.append("Audit Report")
        lines.append("Period,\(csvEscape(period))")
        lines.append("Filter,\(csvEscape(activeFilter.rawValue))")
        lines.append("")
        lines.append("Executive Summary")
        lines.append(csvEscape(executiveSummary))
        lines.append("")
        lines.append("Store Performance Summary")
        lines.append("Store,Sales Achievement,Inventory Exceptions,Shipment Discrepancies,Cycle Count Accuracy,Status")
        for snap in snapshots {
            let achievement = snap.salesAchievementPct.map { "\(Int($0.rounded()))%" } ?? "—"
            let accuracy = snap.cycleCountAccuracyPct.map { "\(Int($0.rounded()))%" } ?? "—"
            let status = snap.attentionReason?.title ?? "Healthy"
            lines.append([snap.store.name, achievement, "\(snap.inventoryExceptionsOpenCount)", "\(snap.shipmentDiscrepancyCount)", accuracy, status]
                .map(csvEscape).joined(separator: ","))
        }
        lines.append("")
        lines.append("Audit Trail Records")
        lines.append("Timestamp,Module,Title,Store,Details")
        for entry in entries {
            lines.append([
                entry.timestamp.formatted(date: .abbreviated, time: .shortened),
                entry.module.rawValue,
                entry.title,
                entry.storeName,
                entry.subtitle
            ].map(csvEscape).joined(separator: ","))
        }
        return lines.joined(separator: "\n")
    }

    // MARK: - Excel (HTML table trick, opens natively in Excel/Numbers/Sheets)

    private static func makeExcelHTML(
        period: String,
        activeFilter: AuditModuleFilter,
        snapshots: [StorePerformanceSnapshot],
        entries: [AuditTrailEntry],
        executiveSummary: String
    ) -> String {
        func row(_ cells: [String]) -> String {
            "<tr>" + cells.map { "<td>\($0.replacingOccurrences(of: "&", with: "&amp;").replacingOccurrences(of: "<", with: "&lt;"))</td>" }.joined() + "</tr>"
        }
        var html = "<html><head><meta charset=\"utf-8\"></head><body>"
        html += "<h2>Audit Report — \(period)</h2>"
        html += "<p><b>Filter:</b> \(activeFilter.rawValue)</p>"
        html += "<p><b>Executive Summary:</b> \(executiveSummary)</p>"
        html += "<h3>Store Performance Summary</h3><table border=\"1\">"
        html += row(["Store", "Sales Achievement", "Inventory Exceptions", "Shipment Discrepancies", "Cycle Count Accuracy", "Status"])
        for snap in snapshots {
            let achievement = snap.salesAchievementPct.map { "\(Int($0.rounded()))%" } ?? "—"
            let accuracy = snap.cycleCountAccuracyPct.map { "\(Int($0.rounded()))%" } ?? "—"
            html += row([snap.store.name, achievement, "\(snap.inventoryExceptionsOpenCount)", "\(snap.shipmentDiscrepancyCount)", accuracy, snap.attentionReason?.title ?? "Healthy"])
        }
        html += "</table>"
        html += "<h3>Audit Trail Records</h3><table border=\"1\">"
        html += row(["Timestamp", "Module", "Title", "Store", "Details"])
        for entry in entries {
            html += row([entry.timestamp.formatted(date: .abbreviated, time: .shortened), entry.module.rawValue, entry.title, entry.storeName, entry.subtitle])
        }
        html += "</table></body></html>"
        return html
    }

    // MARK: - PDF

    #if canImport(UIKit)
    private static func makePDF(
        period: String,
        activeFilter: AuditModuleFilter,
        snapshots: [StorePerformanceSnapshot],
        entries: [AuditTrailEntry],
        executiveSummary: String
    ) -> Data {
        let pageWidth: CGFloat = 612  // US Letter
        let pageHeight: CGFloat = 792
        let margin: CGFloat = 40
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight))

        return renderer.pdfData { context in
            var y: CGFloat = margin

            func newPageIfNeeded(_ needed: CGFloat) {
                if y + needed > pageHeight - margin {
                    context.beginPage()
                    y = margin
                }
            }

            func drawText(_ text: String, font: UIFont, color: UIColor = .black, spacingAfter: CGFloat = 6) {
                let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: color]
                let rect = CGRect(x: margin, y: y, width: pageWidth - margin * 2, height: 1000)
                let bounding = (text as NSString).boundingRect(
                    with: CGSize(width: rect.width, height: .greatestFiniteMagnitude),
                    options: .usesLineFragmentOrigin, attributes: attrs, context: nil
                )
                newPageIfNeeded(bounding.height + spacingAfter)
                (text as NSString).draw(in: CGRect(x: margin, y: y, width: rect.width, height: bounding.height), withAttributes: attrs)
                y += bounding.height + spacingAfter
            }

            func drawSummaryBox(_ summary: String) {
                let attrs: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 10), .foregroundColor: UIColor.black]
                let rect = CGRect(x: margin, y: y, width: pageWidth - margin * 2, height: 1000)
                let bounding = (summary as NSString).boundingRect(
                    with: CGSize(width: rect.width - 24, height: .greatestFiniteMagnitude),
                    options: .usesLineFragmentOrigin, attributes: attrs, context: nil
                )
                
                let boxHeight = bounding.height + 24
                newPageIfNeeded(boxHeight + 12)
                
                let cg = context.cgContext
                cg.setFillColor(UIColor(red: 230/255, green: 245/255, blue: 245/255, alpha: 1.0).cgColor)
                let path = UIBezierPath(roundedRect: CGRect(x: margin, y: y, width: rect.width, height: boxHeight), cornerRadius: 8)
                cg.addPath(path.cgPath)
                cg.fillPath()
                
                (summary as NSString).draw(in: CGRect(x: margin + 12, y: y + 12, width: rect.width - 24, height: bounding.height), withAttributes: attrs)
                y += boxHeight + 16
            }

            func drawTable(headers: [String], widths: [CGFloat], rows: [[String]]) {
                let cellHeight: CGFloat = 20
                let totalWidth = widths.reduce(0, +)
                
                // Draw headers
                newPageIfNeeded(cellHeight + 10)
                let cg = context.cgContext
                cg.setFillColor(UIColor(red: 107/255, green: 175/255, blue: 26/255, alpha: 1.0).cgColor)
                cg.fill(CGRect(x: margin, y: y, width: totalWidth, height: cellHeight))
                
                var currentX = margin
                for i in 0..<headers.count {
                    let header = headers[i]
                    let width = widths[i]
                    let attrs: [NSAttributedString.Key: Any] = [.font: UIFont.boldSystemFont(ofSize: 9), .foregroundColor: UIColor.white]
                    header.draw(in: CGRect(x: currentX + 6, y: y + 4, width: width - 12, height: cellHeight - 8), withAttributes: attrs)
                    currentX += width
                }
                y += cellHeight
                
                // Draw rows
                for rIndex in 0..<rows.count {
                    let row = rows[rIndex]
                    newPageIfNeeded(cellHeight)
                    
                    cg.setFillColor(rIndex % 2 == 0 ? UIColor.white.cgColor : UIColor(red: 245/255, green: 245/255, blue: 240/255, alpha: 1.0).cgColor)
                    cg.fill(CGRect(x: margin, y: y, width: totalWidth, height: cellHeight))
                    
                    currentX = margin
                    for i in 0..<row.count {
                        let text = row[i]
                        let width = widths[i]
                        
                        var txtColor = UIColor.black
                        if i == row.count - 1 && headers.contains("Status") {
                            if text.contains("Below") || text.contains("Exceptions") || text.contains("Delays") {
                                txtColor = UIColor.red
                            } else if text.contains("Healthy") || text.contains("Compliant") {
                                txtColor = UIColor(red: 107/255, green: 175/255, blue: 26/255, alpha: 1.0)
                            }
                        }
                        
                        let attrs: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 9), .foregroundColor: txtColor]
                        text.draw(in: CGRect(x: currentX + 6, y: y + 4, width: width - 12, height: cellHeight - 8), withAttributes: attrs)
                        currentX += width
                    }
                    
                    cg.setStrokeColor(UIColor(red: 232/255, green: 232/255, blue: 228/255, alpha: 1.0).cgColor)
                    cg.setLineWidth(0.5)
                    cg.move(to: CGPoint(x: margin, y: y + cellHeight))
                    cg.addLine(to: CGPoint(x: margin + totalWidth, y: y + cellHeight))
                    cg.strokePath()
                    
                    y += cellHeight
                }
                y += 12
            }

            context.beginPage()
            
            // Header Title Card
            let cg = context.cgContext
            cg.setFillColor(UIColor(red: 107/255, green: 175/255, blue: 26/255, alpha: 1.0).cgColor)
            cg.fill(CGRect(x: margin, y: y, width: pageWidth - margin * 2, height: 44))
            
            let titleAttrs: [NSAttributedString.Key: Any] = [.font: UIFont.boldSystemFont(ofSize: 14), .foregroundColor: UIColor.white]
            ("AUDIT SUMMARY REPORT  •  \(period)").draw(in: CGRect(x: margin + 12, y: y + 15, width: pageWidth - margin * 2 - 24, height: 20), withAttributes: titleAttrs)
            y += 60
            
            drawText("AI Audit Insight Feedback", font: .boldSystemFont(ofSize: 13), spacingAfter: 8)
            drawSummaryBox(executiveSummary)
            
            drawText("Store Performance & Operational Status", font: .boldSystemFont(ofSize: 13), spacingAfter: 8)
            let storeHeaders = ["Store", "Sales Achievement", "Exceptions", "Shipment Issues", "Cycle Compliance", "Status"]
            let storeWidths: [CGFloat] = [132, 90, 70, 80, 80, 80]
            let storeRows = snapshots.map { snap in
                [
                    snap.store.name,
                    snap.salesAchievementPct.map { "\(Int($0.rounded()))%" } ?? "—",
                    "\(snap.inventoryExceptionsOpenCount)",
                    "\(snap.shipmentDiscrepancyCount)",
                    snap.cycleCountAccuracyPct.map { "\(Int($0.rounded()))%" } ?? "—",
                    snap.attentionReason?.title ?? "Healthy"
                ]
            }
            drawTable(headers: storeHeaders, widths: storeWidths, rows: storeRows)
            
            drawText("Audit Trail Activities Feed", font: .boldSystemFont(ofSize: 13), spacingAfter: 8)
            let trailHeaders = ["Timestamp", "Module", "Title", "Store", "Details"]
            let trailWidths: [CGFloat] = [90, 80, 100, 100, 162]
            let trailRows = entries.prefix(150).map { entry in
                [
                    entry.timestamp.formatted(date: .abbreviated, time: .shortened),
                    entry.module.rawValue,
                    entry.title,
                    entry.storeName,
                    entry.subtitle
                ]
            }
            drawTable(headers: trailHeaders, widths: trailWidths, rows: trailRows)
        }
    }
    #endif
}
