// CheckoutView.swift
// RSMS — Sales Associate Module

import SwiftUI

struct CheckoutView: View {
    var isEmbedded: Bool = false
    @EnvironmentObject var checkoutEnv: CheckoutEnvironment
    
    var body: some View {
        CartReviewView(isEmbedded: isEmbedded)
    }
}
