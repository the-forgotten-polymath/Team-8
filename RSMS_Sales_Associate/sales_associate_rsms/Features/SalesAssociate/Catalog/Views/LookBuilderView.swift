// LookBuilderView.swift
// RSMS — Sales Associate Module

import SwiftUI

struct LookBuilderView: View {
    let anchor: ProductDigitalTwin
    @State private var occasion: String?
    @State private var showingOccasionPicker = false
    @State private var lookItems: [ProductDigitalTwin] = []
    @State private var isLoading = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header / Anchor
                VStack(alignment: .leading, spacing: 12) {
                    Text("Anchor Item")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    CatalogProductCardView(product: anchor)
                        .frame(width: 220) // fixed width for anchor presentation
                }
                .padding(.horizontal)
                
                Divider()
                
                // Occasion Context
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Occasion Context")
                            .font(.headline)
                        Text(occasion ?? "No occasion selected")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    Spacer()
                    Button(action: {
                        showingOccasionPicker = true
                    }) {
                        Text(occasion == nil ? "Select" : "Change")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color(.systemGray6))
                            .clipShape(Capsule())
                    }
                }
                .padding(.horizontal)
                
                Divider()
                
                // Generated Look
                VStack(alignment: .leading, spacing: 12) {
                    Text("Complementary Items")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    if isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.top, 40)
                    } else if lookItems.isEmpty {
                        Text("No recommendations available.")
                            .foregroundColor(.gray)
                            .padding(.horizontal)
                    } else {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                ForEach(lookItems) { item in
                                    VStack(alignment: .leading) {
                                        CatalogProductCardView(product: item)
                                            .frame(width: 160)
                                        
                                        Button(action: {
                                            // Mock add to cart for this individual item
                                            print("Added \(item.title) to cart")
                                        }) {
                                            Text("Add to Cart")
                                                .font(.caption)
                                                .fontWeight(.bold)
                                                .frame(maxWidth: .infinity)
                                                .padding(.vertical, 8)
                                                .background(Color.black)
                                                .foregroundColor(.white)
                                                .cornerRadius(8)
                                        }
                                        .padding(.horizontal, 4)
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("Look Builder")
        .sheet(isPresented: $showingOccasionPicker) {
            OccasionPickerView { selectedOccasion in
                self.occasion = selectedOccasion
                Task {
                    await fetchLook()
                }
            }
        }
        .onAppear {
            if lookItems.isEmpty {
                Task {
                    await fetchLook()
                }
            }
        }
    }
    
    private func fetchLook() async {
        isLoading = true
        if let occasion = occasion {
            // Fetch look based on occasion
            lookItems = await RecommendationEngine.shared.recommendLook(forOccasion: occasion)
            // Ensure anchor isn't duplicated in the look items
            lookItems.removeAll { $0.id == anchor.id }
        } else {
            // Default complementary fetch
            lookItems = await RecommendationEngine.shared.recommendComplementary(for: anchor)
        }
        isLoading = false
    }
}
