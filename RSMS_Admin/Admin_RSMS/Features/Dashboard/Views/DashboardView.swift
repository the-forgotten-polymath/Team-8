import SwiftUI

struct DashboardView: View {
    @StateObject private var viewModel = DashboardViewModel()
    
    @Environment(\.horizontalSizeClass) private var sizeClass
    
    
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(.red)
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.red.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
                }

                // Top Section: Revenue Chart (Left) + 2x2 KPI Grid (Right)
                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .top, spacing: 24) {
                        // Left: Revenue Chart Card
                        RevenueChartCard(salesSummary: viewModel.salesSummary, selectedPeriod: $viewModel.selectedRevenuePeriod)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        
                        
                        // Right: 2x2 Grid for Statistic Cards
                        DashboardGrid(spacing: 16) {
                            NavigationLink(destination: StoresView()) {
                                StatisticCard(
                                    category: "Network",
                                    title: "Stores",
                                    value: "\(viewModel.networkStoresActive)",
                                    footnoteLeft: "Active",
                                    footnoteRight: "of \(viewModel.networkStoresTotal) total",
                                    iconName: "building.2.fill",
                                    iconColor: .blue,
                                    iconBackground: .blue.opacity(0.15)
                                )
                            }
                            .buttonStyle(.plain)
                            
                            NavigationLink(destination: ProductsView()) {
                                StatisticCard(
                                    category: "Inventory",
                                    title: "Products",
                                    value: "\(viewModel.inventoryProductsCount)",
                                    footnoteLeft: "Stocked",
                                    footnoteRight: "items",
                                    iconName: "shippingbox.fill",
                                    iconColor: .green,
                                    iconBackground: .green.opacity(0.15)
                                )
                            }
                            .buttonStyle(.plain)
                            
                            NavigationLink(destination: ManagersView()) {
                                StatisticCard(
                                    category: "Staffing",
                                    title: "Managers",
                                    value: "\(viewModel.staffingManagersCount)",
                                    footnoteLeft: "Allocated",
                                    footnoteRight: "of \(viewModel.staffingManagersTotal) slots",
                                    iconName: "person.2.fill",
                                    iconColor: .orange,
                                    iconBackground: .orange.opacity(0.15)
                                )
                            }
                            .buttonStyle(.plain)
                            
                            NavigationLink(destination: PromotionsView()) {
                                StatisticCard(
                                    category: "Marketing",
                                    title: "Promos",
                                    value: "\(viewModel.marketingPromosCount)",
                                    footnoteLeft: "Live",
                                    footnoteRight: "campaigns",
                                    iconName: "tag.fill",
                                    iconColor: .purple,
                                    iconBackground: .purple.opacity(0.15)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    .fixedSize(horizontal: false, vertical: true)
                    
                    // Fallback to vertical stack on narrower screens
                    VStack(spacing: 24) {
                        RevenueChartCard(salesSummary: viewModel.salesSummary, selectedPeriod: $viewModel.selectedRevenuePeriod)
                        
                        DashboardGrid(spacing: 16) {
                            NavigationLink(destination: StoresView()) {
                                StatisticCard(
                                    category: "Network",
                                    title: "Stores",
                                    value: "\(viewModel.networkStoresActive)",
                                    footnoteLeft: "Active",
                                    footnoteRight: "of \(viewModel.networkStoresTotal) total",
                                    iconName: "building.2.fill",
                                    iconColor: .blue,
                                    iconBackground: .blue.opacity(0.15)
                                )
                            }
                            .buttonStyle(.plain)
                            
                            NavigationLink(destination: ProductsView()) {
                                StatisticCard(
                                    category: "Inventory",
                                    title: "Products",
                                    value: "\(viewModel.inventoryProductsCount)",
                                    footnoteLeft: "Approved",
                                    footnoteRight: "of \(viewModel.inventoryProductsTotal) total",
                                    iconName: "shippingbox.fill",
                                    iconColor: .green,
                                    iconBackground: .green.opacity(0.15)
                                )
                            }
                            .buttonStyle(.plain)
                            
                            NavigationLink(destination: ManagersView()) {
                                StatisticCard(
                                    category: "Staffing",
                                    title: "Managers",
                                    value: "\(viewModel.staffingManagersCount)",
                                    footnoteLeft: "Active",
                                    footnoteRight: "of \(viewModel.staffingManagersTotal) total",
                                    iconName: "person.2.fill",
                                    iconColor: .orange,
                                    iconBackground: .orange.opacity(0.15)
                                )
                            }
                            .buttonStyle(.plain)
                            
                            NavigationLink(destination: PromotionsView()) {
                                StatisticCard(
                                    category: "Marketing",
                                    title: "Promos",
                                    value: "\(viewModel.marketingPromosCount)",
                                    footnoteLeft: "Live",
                                    footnoteRight: "campaigns",
                                    iconName: "tag.fill",
                                    iconColor: .purple,
                                    iconBackground: .purple.opacity(0.15)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                
                // Bottom Section
                Group {
                    if sizeClass == .compact {
                        VStack(spacing: 24) {
                            bottomCardsView
                        }
                    } else {
                        HStack(spacing: 24) {
                            bottomCardsView
                        }
                        // Intrinsic vertical layout on HStack stretches all cards to the tallest one
                        .fixedSize(horizontal: false, vertical: true)
                    }
                }
                
                // Bottom padding
                Spacer().frame(height: 32)
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)
        }
        .background(Color.pageBG.ignoresSafeArea())
        .task {
            await viewModel.load()
        }
    }
    
    @ViewBuilder
    private var bottomCardsView: some View {
        // 1. Most Sold Products
        ActivityCard(
            title: "Most Selled Products",
            subtitle: "BY VOLUME"
        ) {
            VStack(spacing: 0) {
                ForEach(Array(viewModel.mostSoldProducts.prefix(3))) { product in
                    HStack(spacing: 16) {
                        Text("\(product.rank)")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(.primary)
                            .frame(width: 20, alignment: .leading)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(product.productName)
                                .font(.body.weight(.medium))
                                .foregroundStyle(.primary)
                                .lineLimit(1)
                            
                            Text(product.subtitle)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("\(product.unitsSold)")
                                .font(.body.weight(.semibold).monospacedDigit())
                                .foregroundStyle(.primary)
                            Text("UNITS")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(height: 68)
                    
                    if product.id != viewModel.mostSoldProducts.prefix(3).last?.id {
                        Divider().padding(.leading, 36)
                    }
                }
                Spacer(minLength: 0)
            }
        }
        
        // 2. Store Performance
        ActivityCard(
            title: "Store Performance",
            subtitle: "BY REVENUE",
            trailingContent: {
                Picker("Filter", selection: $viewModel.selectedStorePerformanceFilter) {
                    ForEach(StorePerformanceFilter.allCases) { filter in
                        Text(filter.rawValue).tag(filter)
                    }
                }
                .pickerStyle(.menu)
            }
        ) {
            VStack(spacing: 0) {
                ForEach(Array(viewModel.storePerformanceList.prefix(3))) { store in
                    HStack(spacing: 16) {
                        Text("\(store.rank)")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(.primary)
                            .frame(width: 20, alignment: .leading)
                        
                        Text(store.storeName)
                            .font(.body.weight(.medium))
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                        
                        Spacer()
                        
                        Text(store.revenueText)
                            .font(.body.weight(.semibold).monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                    .frame(height: 68)
                    
                    if store.id != viewModel.storePerformanceList.prefix(3).last?.id {
                        Divider().padding(.leading, 36)
                    }
                }
                Spacer(minLength: 0)
            }
        }
        
        // 3. Top Customers
        ActivityCard(
            title: "Premium Clients",
            subtitle: "BY SPEND"
        ) {
            VStack(spacing: 0) {
                ForEach(Array(viewModel.topCustomersList.prefix(3).indices), id: \.self) { index in
                    HStack(spacing: 16) {
                        Text("\(index + 1)")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(.primary)
                            .frame(width: 20, alignment: .leading)
                        
                        Text(viewModel.topCustomersList[index].customerName)
                            .font(.body.weight(.medium))
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                        
                        Spacer()
                        
                        Text(viewModel.topCustomersList[index].spendText)
                            .font(.body.weight(.semibold).monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                    .frame(height: 68)
                    
                    if index != viewModel.topCustomersList.prefix(3).count - 1 {
                        Divider().padding(.leading, 36)
                    }
                }
                Spacer(minLength: 0)
            }
        }
    }
}

#Preview {
    DashboardView()
}
