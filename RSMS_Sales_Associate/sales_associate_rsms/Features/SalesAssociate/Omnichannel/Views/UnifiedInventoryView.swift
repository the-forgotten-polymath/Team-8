// UnifiedInventoryView.swift
// RSMS — Sales Associate Module

import SwiftUI
import MapKit

struct UnifiedInventoryView: View {
    let product: ProductDigitalTwin
    @EnvironmentObject var viewModel: OmnichannelViewModel
    
    // Default region around mock store
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )
    
    var body: some View {
        VStack {
            HStack {
                if let firstImage = product.imageURLs?.first {
                    AsyncImage(url: firstImage) { phase in
                        if let image = phase.image {
                            image.resizable()
                                 .aspectRatio(contentMode: .fill)
                        } else {
                            Color.gray.opacity(0.3)
                        }
                    }
                    .frame(width: 80, height: 80)
                    .cornerRadius(8)
                }
                
                VStack(alignment: .leading) {
                    Text(product.title)
                        .font(.headline)
                    Text(product.sku)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text(product.price, format: .currency(code: product.currency))
                        .font(.subheadline.bold())
                }
                Spacer()
            }
            .padding()
            
            if viewModel.isSearchingInventory {
                Spacer()
                ProgressView("Searching Stores...")
                Spacer()
            } else {
                Map(coordinateRegion: $region, annotationItems: annotatedStores) { store in
                    MapAnnotation(coordinate: store.coordinate) {
                        VStack {
                            Image(systemName: "mappin.circle.fill")
                                .font(.title)
                                .foregroundColor(store.hasStock ? .green : .red)
                            
                            Text(store.name)
                                .font(.caption)
                                .padding(4)
                                .background(Color(uiColor: .systemBackground))
                                .cornerRadius(4)
                        }
                    }
                }
                .frame(height: 250)
                .cornerRadius(12)
                .padding(.horizontal)
                
                List {
                    Section(header: Text("Store Availability")) {
                        if viewModel.inventoryResults.isEmpty {
                            Text("No stock found in nearby stores.")
                        } else {
                            ForEach(viewModel.inventoryResults) { level in
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(level.storeName ?? "Unknown Store")
                                            .font(.body)
                                        Text("ID: \(String(level.storeID.uuidString.prefix(4)))")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    VStack(alignment: .trailing) {
                                        Text("\(level.quantityAvailable) In Stock")
                                            .foregroundColor(level.quantityAvailable > 0 ? .green : .red)
                                        
                                        if level.quantityAvailable > 0 {
                                            Button("Place Order") {
                                                Task {
                                                    await viewModel.placeEndlessAisleOrder(productID: product.id, toStore: level.storeID)
                                                }
                                            }
                                            .font(.caption)
                                            .buttonStyle(.borderedProminent)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Global Inventory")
        .task {
            await viewModel.searchInventory(for: product.id)
            setupMapRegion()
        }
    }
    
    private func setupMapRegion() {
        // Mocking coordinates for the map display
        // We'll set a static region around San Francisco for the demo
        region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
            span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        )
    }
    
    // Create map annotations based on inventory results
    private var annotatedStores: [StoreAnnotation] {
        // We'll just generate some mock coordinates near SF based on the inventory results
        viewModel.inventoryResults.enumerated().map { (index, level) in
            StoreAnnotation(
                id: level.storeID,
                name: level.storeName ?? "Store",
                hasStock: level.quantityAvailable > 0,
                coordinate: CLLocationCoordinate2D(
                    latitude: 37.7749 + (Double(index) * 0.02),
                    longitude: -122.4194 + (Double(index) * 0.02)
                )
            )
        }
    }
}

struct StoreAnnotation: Identifiable {
    let id: UUID
    let name: String
    let hasStock: Bool
    let coordinate: CLLocationCoordinate2D
}
