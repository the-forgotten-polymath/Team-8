import sys

def main():
    file_path = '/Users/abhistro/Desktop/Team-8/RSMS_Store_Manager/RSMS_Project/Views/DashboardView.swift'
    with open(file_path, 'r') as f:
        content = f.read()

    start_str = "    private var salesProgressChartCard: some View {"
    start_idx = content.find(start_str)
    if start_idx != -1:
        balance = 0
        end_idx = -1
        in_method = False
        for i in range(start_idx, len(content)):
            if content[i] == '{':
                balance += 1
                in_method = True
            elif content[i] == '}':
                balance -= 1
                if in_method and balance == 0:
                    end_idx = i + 1
                    break
        print(content[start_idx:end_idx])
    else:
        print("Method not found")

if __name__ == "__main__":
    main()
