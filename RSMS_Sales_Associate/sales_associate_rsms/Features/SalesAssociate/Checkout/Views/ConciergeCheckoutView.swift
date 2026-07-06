// ConciergeCheckoutView.swift
// RSMS — Sales Associate Module

import SwiftUI

struct ConciergeCheckoutView: View {
    @EnvironmentObject var checkoutEnv: CheckoutEnvironment
    
    var body: some View {
        Form {
            if checkoutEnv.activeCart != nil {
                Section(header: Text("Services")) {
                    Toggle("Gift Wrapping", isOn: Binding(
                        get: { checkoutEnv.activeCart?.giftWrap ?? false },
                        set: { checkoutEnv.activeCart?.giftWrap = $0 }
                    ))
                    
                    if checkoutEnv.activeCart?.giftWrap == true {
                        TextField("Gift Note (Optional)", text: Binding(
                            get: { checkoutEnv.activeCart?.giftNote ?? "" },
                            set: { checkoutEnv.activeCart?.giftNote = $0 }
                        ))
                    }
                }
                
                Section(header: Text("Warranty & Registration")) {
                    Text("Digital twin warranty records will be automatically generated and linked to the client's profile upon completion.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle("Concierge")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink(destination: SplitTenderView()) {
                    Text("Payment")
                }
            }
        }
    }
}
