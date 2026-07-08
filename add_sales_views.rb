require 'xcodeproj'

project_path = '/Users/abhistro/Desktop/Team-8/RSMS.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Add to StoreManagerModule target
target = project.targets.find { |t| t.name == 'StoreManagerModule' }

if target
    # Find the group
    group = project.main_group.find_subpath(File.join('RSMS_Store_Manager', 'RSMS_Project', 'Views'), true)
    
    file_names = ['SalesHistoryView.swift', 'SaleDetailsView.swift']
    
    file_names.each do |file_name|
        file_path = File.join('/Users/abhistro/Desktop/Team-8/RSMS_Store_Manager/RSMS_Project/Views', file_name)
        
        # Check if file is already in group
        unless group.files.any? { |f| f.path == file_name || f.real_path.to_s == file_path }
            file_ref = group.new_reference(file_path)
            target.source_build_phase.add_file_reference(file_ref)
            puts "Added #{file_name} to project."
        else
            puts "#{file_name} is already in the project."
        end
    end
    
    project.save
else
    puts "Could not find StoreManagerModule target"
end
