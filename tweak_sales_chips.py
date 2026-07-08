import sys

def main():
    file_path = '/Users/abhistro/Desktop/Team-8/RSMS_Store_Manager/RSMS_Project/Views/SalesHistoryView.swift'
    with open(file_path, 'r') as f:
        content = f.read()

    # 1. Remove the percentage complete label
    percentage_block = """                    if isTargetSet {
                        Text(String(format: "%.0f%% Complete", animatedPercentage))
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.green)
                            .padding(.top, 4)
                    } else {"""
                    
    percentage_replacement = """                    if isTargetSet {
                        // Removed % complete label
                    } else {"""
                    
    content = content.replace(percentage_block, percentage_replacement)
    
    # 2. Update Target Chip
    target_chip_block = """                    // Target Chip
                    VStack(spacing: 4) {
                        Text("🎯 Target")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Color(.secondaryLabel))"""
                            
    target_chip_replacement = """                    // Target Chip
                    VStack(spacing: 4) {
                        Text("SALES TARGET")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(Color(.secondaryLabel))
                            .tracking(1)"""
                            
    content = content.replace(target_chip_block, target_chip_replacement)
    
    # 3. Update Remaining Chip
    remaining_chip_block = """                    // Remaining Chip
                    VStack(spacing: 4) {
                        Text("⏳ Remaining")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Color(.secondaryLabel))"""
                            
    remaining_chip_replacement = """                    // Remaining Chip
                    VStack(spacing: 4) {
                        Text("REMAINING")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(Color(.secondaryLabel))
                            .tracking(1)"""
                            
    content = content.replace(remaining_chip_block, remaining_chip_replacement)
    
    with open(file_path, 'w') as f:
        f.write(content)
        
    print("Tweaked UI elements successfully")

if __name__ == "__main__":
    main()
