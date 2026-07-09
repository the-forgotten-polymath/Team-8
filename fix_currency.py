import sys

def main():
    file_path = '/Users/abhistro/Desktop/Team-8/RSMS_Store_Manager/RSMS_Project/Views/SalesHistoryView.swift'
    with open(file_path, 'r') as f:
        content = f.read()

    # Move formatIndianCurrency outside to file scope at the top or bottom
    # We can just add it before MARK: - Analytics Header UI
    
    currency_func = """
fileprivate func formatIndianCurrency(amount: Double) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .currency
    formatter.locale = Locale(identifier: "en_IN")
    formatter.maximumFractionDigits = 0
    return formatter.string(from: NSNumber(value: amount)) ?? "₹0"
}
"""
    old_mark = "// MARK: - Analytics Header UI"
    new_mark = currency_func + "\n" + old_mark
    
    if old_mark in content:
        content = content.replace(old_mark, new_mark)
        
        # Now remove the internal one inside SalesHistoryCard to avoid ambiguity, though fileprivate shouldn't conflict with private inside.
        # Actually, it's safer to just replace `private func formatIndianCurrency(amount: Double) -> String { ... }` in SalesHistoryCard with nothing, 
        # or since it's private, it will prefer the local one. The external one will be used by the new structs.
        
        with open(file_path, 'w') as f:
            f.write(content)
        print("Fixed formatIndianCurrency")

if __name__ == "__main__":
    main()
