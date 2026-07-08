import sys

def main():
    file_path = '/Users/abhistro/Desktop/Team-8/RSMS_Store_Manager/RSMS_Project/Views/DashboardView.swift'
    with open(file_path, 'r') as f:
        content = f.read()

    # The outer wrapper is:
    #     private var salesProgressChartCard: some View {
    #         Button(action: {
    #             // Navigate to SalesHistoryView (we can use a NavigationLink around this or programmatically)
    #             // But since NavigationLink is better, we'll wrap the inner content in a NavigationLink below
    #         }) {
    #             NavigationLink(destination: SalesHistoryView()) {
    #                 VStack(alignment: .leading, spacing: 16) {
    
    old_start = """    private var salesProgressChartCard: some View {
        Button(action: {
            // Navigate to SalesHistoryView (we can use a NavigationLink around this or programmatically)
            // But since NavigationLink is better, we'll wrap the inner content in a NavigationLink below
        }) {
            NavigationLink(destination: SalesHistoryView()) {
                VStack(alignment: .leading, spacing: 16) {"""
                
    new_start = """    private var salesProgressChartCard: some View {
        VStack(alignment: .leading, spacing: 16) {"""
        
    content = content.replace(old_start, new_start)
    
    # Now we need to remove the closing braces for Button and NavigationLink at the end of the card
    # The end of the card is:
    #         .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
    #         .padding(.horizontal, 20)
    #             }
    #         }
    #         .buttonStyle(PlainButtonStyle())
    #     }
    
    old_end = """        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
        .padding(.horizontal, 20)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }"""
    
    new_end = """        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
        .padding(.horizontal, 20)
    }"""
    
    content = content.replace(old_end, new_end)
    
    # Now fix the Header to include NavigationLink and chevron
    old_header = """                    // Header & Picker
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("TOTAL REVENUE")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(Color(.systemGray))
                                .textCase(.uppercase)
                            
                            headerRevenueView
                                .animation(.spring(), value: viewModel.todaySalesAmount)"""
                                
    new_header = """                    // Header & Picker
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 4) {
                            NavigationLink(destination: SalesHistoryView()) {
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack(spacing: 4) {
                                        Text("TOTAL REVENUE")
                                            .font(.caption)
                                            .fontWeight(.bold)
                                            .foregroundColor(Color(.systemGray))
                                            .textCase(.uppercase)
                                        
                                        Image(systemName: "chevron.right")
                                            .font(.caption)
                                            .fontWeight(.bold)
                                            .foregroundColor(Color(.systemGray))
                                    }
                                    
                                    headerRevenueView
                                        .animation(.spring(), value: viewModel.todaySalesAmount)
                                }
                            }
                            .buttonStyle(PlainButtonStyle())"""
                            
    content = content.replace(old_header, new_header)
    
    with open(file_path, 'w') as f:
        f.write(content)
        
    print("Fixed layout")

if __name__ == "__main__":
    main()
