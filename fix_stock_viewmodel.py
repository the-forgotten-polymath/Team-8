import sys

def main():
    file_path = '/Users/abhistro/Desktop/Team-8/RSMS_Store_Manager/RSMS_Project/Services/StockViewModel.swift'
    with open(file_path, 'r') as f:
        content = f.read()

    # 1. Update loadData()
    old_load = """    @MainActor
    func loadData() async {
        isLoading = true
        errorMessage = nil"""
        
    new_load = """    @MainActor
    func loadData() async {
        if summary == nil {
            isLoading = true
        }
        errorMessage = nil"""
    content = content.replace(old_load, new_load)
    
    # 2. Don't clear data on error
    old_error = """        } catch {
            debugLog("[DEBUG] StockViewModel.loadData: ERROR loaded: \\(error)")
            self.errorMessage = error.localizedDescription
            // Fallback to empty state on error as per requirements
            self.summary = InventorySummary(totalValue: 0, totalProducts: 0, totalUnits: 0, pendingRequestsCount: 0, lowStockCount: 0, outOfStockCount: 0)
            self.stockList = []
        }"""
        
    new_error = """        } catch {
            debugLog("[DEBUG] StockViewModel.loadData: ERROR loaded: \\(error)")
            self.errorMessage = error.localizedDescription
            // If we have no data, fallback to empty state, otherwise keep previous data
            if self.summary == nil {
                self.summary = InventorySummary(totalValue: 0, totalProducts: 0, totalUnits: 0, pendingRequestsCount: 0, lowStockCount: 0, outOfStockCount: 0)
                self.stockList = []
            }
        }"""
    content = content.replace(old_error, new_error)
    
    # Also fix the initial session resolve error case
    old_session_err = """        guard let currentUser = SessionManager.shared.currentUser else {
            debugLog("[DEBUG] StockViewModel.loadData: FAILED to resolve currentUser. Showing empty state.")
            self.summary = InventorySummary(totalValue: 0, totalProducts: 0, totalUnits: 0, pendingRequestsCount: 0, lowStockCount: 0, outOfStockCount: 0)
            self.stockList = []
            self.isLoading = false
            return
        }
        
        guard let storeId = currentUser.storeId else {
            debugLog("[DEBUG] StockViewModel.loadData: currentUser has NIL storeId. User profile: \\(currentUser.fullName). Showing empty state.")
            self.summary = InventorySummary(totalValue: 0, totalProducts: 0, totalUnits: 0, pendingRequestsCount: 0, lowStockCount: 0, outOfStockCount: 0)
            self.stockList = []
            self.isLoading = false
            return
        }"""
        
    new_session_err = """        guard let currentUser = SessionManager.shared.currentUser else {
            debugLog("[DEBUG] StockViewModel.loadData: FAILED to resolve currentUser. Showing empty state.")
            if self.summary == nil {
                self.summary = InventorySummary(totalValue: 0, totalProducts: 0, totalUnits: 0, pendingRequestsCount: 0, lowStockCount: 0, outOfStockCount: 0)
                self.stockList = []
            }
            self.isLoading = false
            return
        }
        
        guard let storeId = currentUser.storeId else {
            debugLog("[DEBUG] StockViewModel.loadData: currentUser has NIL storeId. User profile: \\(currentUser.fullName). Showing empty state.")
            if self.summary == nil {
                self.summary = InventorySummary(totalValue: 0, totalProducts: 0, totalUnits: 0, pendingRequestsCount: 0, lowStockCount: 0, outOfStockCount: 0)
                self.stockList = []
            }
            self.isLoading = false
            return
        }"""
    content = content.replace(old_session_err, new_session_err)

    with open(file_path, 'w') as f:
        f.write(content)
        
    print("Fixed StockViewModel")

if __name__ == "__main__":
    main()
