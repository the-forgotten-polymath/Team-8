import sys

def main():
    file_path = '/Users/abhistro/Desktop/Team-8/RSMS_Store_Manager/RSMS_Project/Views/SalesHistoryView.swift'
    with open(file_path, 'r') as f:
        content = f.read()

    # Step 1: Add the new variables and init logic
    old_vm_start = """@MainActor
final class SalesHistoryViewModel: ObservableObject {
    @Published var sales: [SaleSummary] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    struct SaleSummary: Identifiable {"""
    
    new_vm_start = """import Combine

@MainActor
final class SalesHistoryViewModel: ObservableObject {
    @Published var sales: [SaleSummary] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // New analytics properties
    @Published var monthlyTarget: Double = 0
    @Published var currentRevenue: Double = 0
    @Published var totalUnitsSold: Int = 0
    @Published var averageOrderValue: Double = 0
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        NotificationCenter.default.publisher(for: NSNotification.Name("InventoryDidUpdate"))
            .sink { [weak self] _ in
                Swift.Task { @MainActor [weak self] in
                    await self?.loadSales()
                }
            }
            .store(in: &cancellables)
            
        NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)
            .sink { [weak self] _ in
                Swift.Task { @MainActor [weak self] in
                    await self?.loadSales()
                }
            }
            .store(in: &cancellables)
    }
    
    struct SaleSummary: Identifiable {"""
    
    content = content.replace(old_vm_start, new_vm_start)
    
    # Step 2: Update loadSales logic to compute these values and fetch from store_targets
    # Current loadSales:
    #             if !allSales.isEmpty { ... loop over all sales ...
    #             self.sales = summaries
    #         } catch {
    
    old_load = """            self.sales = summaries
        } catch {
            errorMessage = error.localizedDescription"""
            
    new_load = """            self.sales = summaries
            
            // Analytics logic
            var revenue: Double = 0
            var units: Int = 0
            
            for summary in summaries {
                revenue += summary.totalAmount
                units += summary.totalUnits
            }
            
            self.currentRevenue = revenue
            self.totalUnitsSold = units
            self.averageOrderValue = summaries.isEmpty ? 0 : revenue / Double(summaries.count)
            
            // Fetch target
            do {
                let currentDate = Date()
                let calendar = Calendar.current
                // Get the first day of the current month
                let components = calendar.dateComponents([.year, .month], from: currentDate)
                if let firstDayOfMonth = calendar.date(from: components) {
                    let formatter = DateFormatter()
                    formatter.dateFormat = "yyyy-MM-dd"
                    let targetMonthString = formatter.string(from: firstDayOfMonth)
                    
                    let targetResponse = try await client
                        .from("store_targets")
                        .select("revenue_target")
                        .eq("store_id", value: storeId.uuidString)
                        .eq("target_month", value: targetMonthString)
                        .execute()
                    
                    struct StoreTargetPartial: Decodable {
                        let revenue_target: Double
                    }
                    
                    let targets = try JSONDecoder.supabaseDecoder.decodeSupabase([StoreTargetPartial].self, from: targetResponse.data)
                    self.monthlyTarget = targets.first?.revenue_target ?? 0
                }
            } catch {
                print("Failed to fetch store targets: \\(error)")
                self.monthlyTarget = 0
            }
            
        } catch {
            errorMessage = error.localizedDescription"""
    
    content = content.replace(old_load, new_load)
    
    with open(file_path, 'w') as f:
        f.write(content)
        
    print("Updated ViewModel")

if __name__ == "__main__":
    main()
