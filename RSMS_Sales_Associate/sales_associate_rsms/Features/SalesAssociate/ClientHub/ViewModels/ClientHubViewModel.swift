// ClientHubViewModel.swift
// RSMS — Sales Associate Module

import Foundation
import Combine
import SwiftUI

@MainActor
class ClientHubViewModel: ObservableObject {
    @Published var searchQuery: String = ""
    @Published var clients: [ClientDigitalTwin] = []
    @Published var selectedTier: CustomerTier? = nil
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil

    private var searchTask: Task<Void, Never>?

    func searchClients() {
        searchTask?.cancel()
        searchTask = Task {
            do {
                isLoading = true
                errorMessage = nil
                
                // Add a small debounce if typing
                try await Task.sleep(nanoseconds: 300_000_000)
                
                let results = try await ClientDigitalTwinService.shared.searchClients(query: searchQuery)
                
                if !Task.isCancelled {
                    if let tier = self.selectedTier {
                        self.clients = results.filter { $0.tier == tier }
                    } else {
                        self.clients = results
                    }
                    self.isLoading = false
                }
            } catch {
                if !Task.isCancelled {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }
}

