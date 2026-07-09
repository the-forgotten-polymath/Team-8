import SwiftUI

public struct NoStoreAssignedView: View {
    var onLogout: () -> Void
    
    public init(onLogout: @escaping () -> Void) {
        self.onLogout = onLogout
    }
    
    public var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "building.2.crop.circle.badge.xmark")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .foregroundColor(.red)
            
            Text("No Store Assigned")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text("Your account has been created successfully, but no store has been assigned to you yet.\n\nPlease contact your Corporate Administrator.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            Spacer()
            
            Button(action: onLogout) {
                Text("Logout")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(Color.red)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 40)
        }
        .background(Color(UIColor.systemBackground).edgesIgnoringSafeArea(.all))
    }
}
