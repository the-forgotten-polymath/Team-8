// PDFReceiptGenerator.swift
// RSMS — Sales Associate Module

import Foundation
import UIKit

class PDFReceiptGenerator {
    
    struct ReceiptItem {
        let name: String
        let sku: String
        let quantity: Int
        let price: Double
        let total: Double
    }
    
    static func generatePDF(
        sale: Sale,
        customer: ClientDigitalTwin,
        items: [ReceiptItem],
        subtotal: Double,
        discount: Double,
        tax: Double,
        grandTotal: Double
    ) -> URL? {
        let pdfFilename = NSTemporaryDirectory().appendingFormat("Receipt-%@.pdf", sale.invoiceNumber ?? String(sale.id.uuidString.prefix(8)))
        let pdfURL = URL(fileURLWithPath: pdfFilename)
        
        let pageRect = CGRect(x: 0, y: 0, width: 595, height: 842) // A4 page dimensions
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: UIGraphicsPDFRendererFormat())
        
        do {
            try renderer.writePDF(to: pdfURL) { context in
                context.beginPage()
                
                // 1. Header (Boutique branding)
                let boutiqueName = "BOUTIQUE ROYAL"
                let boutiqueNameAttrs: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 24, weight: .bold),
                    .foregroundColor: UIColor.black
                ]
                boutiqueName.draw(at: CGPoint(x: 54, y: 54), withAttributes: boutiqueNameAttrs)
                
                let storeSub = "Shop Royal — Premium Luxury Retailer"
                let storeSubAttrs: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 10, weight: .medium),
                    .foregroundColor: UIColor.lightGray
                ]
                storeSub.draw(at: CGPoint(x: 54, y: 84), withAttributes: storeSubAttrs)
                
                // 2. Invoice Details block (Left Side)
                let dateString = DateFormatter.localizedString(from: sale.saleDate, dateStyle: .medium, timeStyle: .short)
                let invoiceDetails = """
                INVOICE DETAILS:
                Invoice #: \(sale.invoiceNumber ?? "N/A")
                Date: \(dateString)
                Payment Method: \(sale.paymentMethod)
                Status: Completed
                """
                let invoiceAttrs: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 10),
                    .foregroundColor: UIColor.darkGray
                ]
                invoiceDetails.draw(at: CGPoint(x: 54, y: 120), withAttributes: invoiceAttrs)
                
                // 3. Customer Billing info (Right Side)
                let customerDetails = """
                BILL TO CUSTOMER:
                Name: \(customer.fullName)
                Phone: \(customer.phone ?? "N/A")
                Address: \(customer.address ?? "Address Not Provided")
                """
                customerDetails.draw(at: CGPoint(x: 320, y: 120), withAttributes: invoiceAttrs)
                
                // 4. Draw horizontal divider
                let lineY: CGFloat = 190
                context.cgContext.setStrokeColor(UIColor.lightGray.cgColor)
                context.cgContext.setLineWidth(1)
                context.cgContext.move(to: CGPoint(x: 54, y: lineY))
                context.cgContext.addLine(to: CGPoint(x: 541, y: lineY))
                context.cgContext.strokePath()
                
                // 5. Table Headers
                let headersFont: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 10, weight: .bold),
                    .foregroundColor: UIColor.black
                ]
                "Item / SKU".draw(at: CGPoint(x: 54, y: 200), withAttributes: headersFont)
                "Qty".draw(at: CGPoint(x: 320, y: 200), withAttributes: headersFont)
                "Unit Price".draw(at: CGPoint(x: 380, y: 200), withAttributes: headersFont)
                "Total".draw(at: CGPoint(x: 480, y: 200), withAttributes: headersFont)
                
                context.cgContext.move(to: CGPoint(x: 54, y: 218))
                context.cgContext.addLine(to: CGPoint(x: 541, y: 218))
                context.cgContext.strokePath()
                
                // 6. Draw Items list
                var currentY: CGFloat = 230
                let itemFont: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 10),
                    .foregroundColor: UIColor.black
                ]
                let skuFont: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 9),
                    .foregroundColor: UIColor.gray
                ]
                
                for item in items {
                    // Check page height bound and insert new page if needed (A4 height is 842)
                    if currentY > 700 {
                        context.beginPage()
                        currentY = 54
                    }
                    
                    // Item Name
                    item.name.draw(at: CGPoint(x: 54, y: currentY), withAttributes: itemFont)
                    // SKU below name
                    "SKU: \(item.sku)".draw(at: CGPoint(x: 54, y: currentY + 14), withAttributes: skuFont)
                    
                    // Qty
                    "\(item.quantity)".draw(at: CGPoint(x: 320, y: currentY), withAttributes: itemFont)
                    
                    // Unit Price formatted in INR format
                    let priceText = String(format: "₹%.2f", item.price)
                    priceText.draw(at: CGPoint(x: 380, y: currentY), withAttributes: itemFont)
                    
                    // Total formatted in INR format
                    let totalText = String(format: "₹%.2f", item.total)
                    totalText.draw(at: CGPoint(x: 480, y: currentY), withAttributes: itemFont)
                    
                    currentY += 40
                }
                
                // 7. Summary / Totals block
                currentY += 10
                context.cgContext.move(to: CGPoint(x: 54, y: currentY))
                context.cgContext.addLine(to: CGPoint(x: 541, y: currentY))
                context.cgContext.strokePath()
                
                currentY += 16
                let summaryTitleFont: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 10, weight: .bold),
                    .foregroundColor: UIColor.darkGray
                ]
                let summaryValFont: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 10),
                    .foregroundColor: UIColor.black
                ]
                
                // Subtotal
                "Subtotal:".draw(at: CGPoint(x: 360, y: currentY), withAttributes: summaryTitleFont)
                String(format: "₹%.2f", subtotal).draw(at: CGPoint(x: 480, y: currentY), withAttributes: summaryValFont)
                
                currentY += 16
                
                // Discount
                if discount > 0 {
                    "Discount:".draw(at: CGPoint(x: 360, y: currentY), withAttributes: summaryTitleFont)
                    String(format: "-₹%.2f", discount).draw(at: CGPoint(x: 480, y: currentY), withAttributes: summaryValFont)
                    currentY += 16
                }
                
                // Tax
                "Tax (8.875%):".draw(at: CGPoint(x: 360, y: currentY), withAttributes: summaryTitleFont)
                String(format: "₹%.2f", tax).draw(at: CGPoint(x: 480, y: currentY), withAttributes: summaryValFont)
                
                currentY += 20
                context.cgContext.setStrokeColor(UIColor.black.cgColor)
                context.cgContext.setLineWidth(1.5)
                context.cgContext.move(to: CGPoint(x: 360, y: currentY))
                context.cgContext.addLine(to: CGPoint(x: 541, y: currentY))
                context.cgContext.strokePath()
                
                currentY += 10
                let totalTitleFont: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 12, weight: .bold),
                    .foregroundColor: UIColor.black
                ]
                
                // Grand Total
                "Grand Total:".draw(at: CGPoint(x: 360, y: currentY), withAttributes: totalTitleFont)
                String(format: "₹%.2f", grandTotal).draw(at: CGPoint(x: 480, y: currentY), withAttributes: totalTitleFont)
                
                // 8. Footer note
                let footerText = "Thank you for shopping with us! For return guidelines or questions, contact support@royalboutique.com"
                let footerFont: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 8, weight: .regular),
                    .foregroundColor: UIColor.lightGray
                ]
                footerText.draw(at: CGPoint(x: 54, y: 770), withAttributes: footerFont)
            }
            return pdfURL
        } catch {
            print("[PDFReceiptGenerator] Error generating PDF: \(error.localizedDescription)")
            return nil
        }
    }
}
