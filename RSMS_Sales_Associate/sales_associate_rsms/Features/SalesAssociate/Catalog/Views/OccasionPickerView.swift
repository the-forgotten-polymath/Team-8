// OccasionPickerView.swift
// RSMS — Sales Associate Module

import SwiftUI

struct OccasionPickerView: View {
    @Environment(\.dismiss) var dismiss
    
    let occasions = [
        "Wedding",
        "Gala",
        "Business / Formal",
        "Everyday / Casual",
        "Vacation / Resort"
    ]
    
    var onSelect: (String) -> Void
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(occasions, id: \.self) { occasion in
                    Button(action: {
                        onSelect(occasion)
                        dismiss()
                    }) {
                        HStack {
                            Text(occasion)
                                .foregroundColor(.primary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                        }
                    }
                }
            }
            .navigationTitle("Select Occasion")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}
