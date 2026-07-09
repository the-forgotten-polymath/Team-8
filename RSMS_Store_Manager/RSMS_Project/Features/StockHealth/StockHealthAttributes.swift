import Foundation
import ActivityKit
import SwiftUI

public struct StockHealthAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        public let score: Int
        public let status: String
        public let healthyProducts: Int
        public let lowStockProducts: Int
        public let outOfStockProducts: Int
        public let totalProducts: Int
        public let description: String
        
        public init(score: Int, status: String, healthyProducts: Int, lowStockProducts: Int, outOfStockProducts: Int, totalProducts: Int, description: String) {
            self.score = score
            self.status = status
            self.healthyProducts = healthyProducts
            self.lowStockProducts = lowStockProducts
            self.outOfStockProducts = outOfStockProducts
            self.totalProducts = totalProducts
            self.description = description
        }
    }
    
    public let storeName: String
    
    public init(storeName: String) {
        self.storeName = storeName
    }
}
