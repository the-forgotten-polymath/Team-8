import SwiftUI

struct TestMenu: View {
    var body: some View {
        NavigationView {
            Text("Hello")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        HStack {
                            Menu {
                                Button("Logout") {}
                            } label: {
                                Text("AM")
                                    .frame(width: 36, height: 36)
                                    .background(Color.orange)
                                    .clipShape(Circle())
                            }
                        }
                    }
                }
        }
    }
}
