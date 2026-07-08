import sys

def main():
    file_path = '/Users/abhistro/Desktop/Team-8/RSMS_Store_Manager/RSMS_Project/Views/StockManagementView.swift'
    with open(file_path, 'r') as f:
        content = f.read()

    old_modifiers = """        .onAppear {
            Swift.Task {
                await viewModel.loadData()
            }
        }
        .refreshable {
            await viewModel.loadData()
        }"""
        
    new_modifiers = """        .onAppear {
            Swift.Task {
                await viewModel.loadData()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            Swift.Task {
                await viewModel.loadData()
            }
        }
        .refreshable {
            await viewModel.loadData()
        }"""
        
    content = content.replace(old_modifiers, new_modifiers)
    
    with open(file_path, 'w') as f:
        f.write(content)
        
    print("Added willEnterForegroundNotification observer")

if __name__ == "__main__":
    main()
