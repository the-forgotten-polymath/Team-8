// SignatureCaptureView.swift
// RSMS — Sales Associate Module

import SwiftUI

struct Line {
    var points = [CGPoint]()
    var color: Color = .primary
    var lineWidth: CGFloat = 3.0
}

struct SignatureCaptureView: View {
    @Binding var signatureData: Data?
    @Environment(\.dismiss) var dismiss
    
    @State private var currentLine = Line()
    @State private var lines: [Line] = []
    
    var body: some View {
        VStack {
            HStack {
                Text("Client Signature")
                    .font(.headline)
                Spacer()
                Button("Clear") {
                    lines.removeAll()
                }
                .foregroundColor(.red)
            }
            .padding()
            
            Canvas { context, size in
                for line in lines {
                    var path = Path()
                    path.addLines(line.points)
                    context.stroke(path, with: .color(line.color), lineWidth: line.lineWidth)
                }
            }
            .gesture(DragGesture(minimumDistance: 0, coordinateSpace: .local)
                .onChanged { value in
                    let newPoint = value.location
                    currentLine.points.append(newPoint)
                    self.lines.append(currentLine)
                }
                .onEnded { value in
                    self.lines.append(currentLine)
                    self.currentLine = Line()
                }
            )
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.gray.opacity(0.5), lineWidth: 1)
            )
            .padding()
            .frame(height: 300)
            
            Button(action: saveSignature) {
                Text("Confirm & Sign")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(lines.isEmpty ? Color.gray : Color.black)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .disabled(lines.isEmpty)
            .padding()
            
            Spacer()
        }
        .background(Color(uiColor: .systemGroupedBackground))
    }
    
    private func saveSignature() {
        // In a real app, render Canvas to UIImage and convert to Data
        // For our mock, we'll just save dummy data if lines exist
        let dummyData = "Signed with \(lines.count) strokes".data(using: .utf8)
        self.signatureData = dummyData
        dismiss()
    }
}
