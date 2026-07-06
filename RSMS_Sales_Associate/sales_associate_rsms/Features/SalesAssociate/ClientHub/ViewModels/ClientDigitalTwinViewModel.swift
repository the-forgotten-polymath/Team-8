// ClientDigitalTwinViewModel.swift
// RSMS — Sales Associate Module

import Foundation
import Combine
import SwiftUI

@MainActor
class ClientDigitalTwinViewModel: ObservableObject {
    @Published var client: ClientDigitalTwin?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil

    func fetchFullTwin(clientID: UUID) {
        Task {
            do {
                isLoading = true
                errorMessage = nil
                
                let result = try await ClientDigitalTwinService.shared.fetchFullTwin(clientID: clientID)
                
                if !Task.isCancelled {
                    self.client = result
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
