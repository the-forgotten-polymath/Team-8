require 'xcodeproj'
require 'fileutils'

root_dir = File.expand_path(File.dirname(__FILE__))
dest_proj_path = File.join(root_dir, 'RSMS.xcodeproj')

# 1. Copy Admin_RSMS.xcodeproj to root as RSMS.xcodeproj
source_proj_path = File.join(root_dir, 'RSMS_Admin/Admin_RSMS.xcodeproj')
puts "Copying project file from #{source_proj_path} to #{dest_proj_path}..."
FileUtils.rm_rf(dest_proj_path) if File.exists?(dest_proj_path)
FileUtils.cp_r(source_proj_path, dest_proj_path)

# 2. Copy Assets.xcassets to root for main app target
assets_src = File.join(root_dir, 'RSMS_Admin/Admin_RSMS/Assets/Assets.xcassets')
assets_dest = File.join(root_dir, 'Assets.xcassets')
puts "Copying Assets.xcassets to root..."
FileUtils.rm_rf(assets_dest) if File.exists?(assets_dest)
FileUtils.cp_r(assets_src, assets_dest)

# 3. Load projects
project = Xcodeproj::Project.open(dest_proj_path)

sales_proj_path = File.join(root_dir, 'RSMS_Sales_Associate/sales_associate_rsms.xcodeproj')
sales_project = Xcodeproj::Project.open(sales_proj_path)

inventory_proj_path = File.join(root_dir, 'RSMS_Inventory/RSMS_Project.xcodeproj')
inventory_project = Xcodeproj::Project.open(inventory_proj_path)

store_proj_path = File.join(root_dir, 'RSMS_Store_Manager/RSMS_Project.xcodeproj')
store_project = Xcodeproj::Project.open(store_proj_path)

# 4. Copy Package References from other projects to root project
def copy_package_references(source_project, dest_project)
  source_project.root_object.package_references.each do |source_ref|
    exists = dest_project.root_object.package_references.any? { |ref| ref.repositoryURL == source_ref.repositoryURL }
    unless exists
      new_ref = dest_project.new(Xcodeproj::Project::Object::XCRemoteSwiftPackageReference)
      new_ref.repositoryURL = source_ref.repositoryURL
      new_ref.requirement = source_ref.requirement
      dest_project.root_object.package_references << new_ref
      puts "  Copied package reference: #{source_ref.repositoryURL}"
    end
  end
end

puts "Copying package references..."
copy_package_references(sales_project, project)
copy_package_references(inventory_project, project)
copy_package_references(store_project, project)

# 5. Configure target package product dependency helper
def copy_target_package_dependencies(source_target, dest_target, dest_project)
  source_target.package_product_dependencies.each do |source_dep|
    dest_pkg = dest_project.root_object.package_references.find { |pkg| pkg.repositoryURL == source_dep.package.repositoryURL }
    if dest_pkg
      is_supabase = source_dep.package.repositoryURL.include?("supabase-swift")
      products_to_link = is_supabase ? ["Auth", "Functions", "PostgREST", "Realtime", "Storage", "Supabase"] : [source_dep.product_name]
      
      products_to_link.each do |prod_name|
        already_linked = dest_target.package_product_dependencies.any? { |dep| dep.product_name == prod_name }
        unless already_linked
          dep = dest_project.new(Xcodeproj::Project::Object::XCSwiftPackageProductDependency)
          dep.product_name = prod_name
          dep.package = dest_pkg
          dest_target.package_product_dependencies << dep
          
          build_file = dest_project.new(Xcodeproj::Project::Object::PBXBuildFile)
          build_file.product_ref = dep
          dest_target.frameworks_build_phase.files << build_file
          puts "  Linked package product #{prod_name} to target #{dest_target.name}"
        end
      end
    end
  end
end

# 6. Configure build settings copy helper
def copy_build_settings(source_target, dest_target)
  source_configs = source_target.build_configurations
  dest_configs = dest_target.build_configurations
  
  source_configs.each do |source_config|
    dest_config = dest_configs.find { |c| c.name == source_config.name }
    if dest_config
      ['SWIFT_VERSION', 'TARGETED_DEVICE_FAMILY', 'SDKROOT', 'SUPPORTED_PLATFORMS'].each do |key|
        if source_config.build_settings.has_key?(key)
          dest_config.build_settings[key] = source_config.build_settings[key]
        end
      end
      # Force iOS 26.5 deployment target
      dest_config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '26.5'
      # Make sure it builds as dynamic framework and generates Info.plist
      dest_config.build_settings['MACH_O_TYPE'] = 'mh_dylib'
      dest_config.build_settings['GENERATE_INFOPLIST_FILE'] = 'YES'
      dest_config.build_settings['PRODUCT_BUNDLE_IDENTIFIER'] = "com.rsms.#{dest_target.name}"
      dest_config.build_settings['CURRENT_PROJECT_VERSION'] = '1'
      dest_config.build_settings['MARKETING_VERSION'] = '1.0'
      dest_config.build_settings['DYLIB_COMPATIBILITY_VERSION'] = '1'
      dest_config.build_settings['DYLIB_CURRENT_VERSION'] = '1'
      dest_config.build_settings['SKIP_INSTALL'] = 'YES'
    end
  end
end

# 7. Rename the main target to RSMS
main_target = project.targets.find { |t| t.product_type == 'com.apple.product-type.application' }
main_target.name = 'RSMS'
main_target.product_name = 'RSMS'
main_target.build_configurations.each do |c|
  c.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '26.5'
end
puts "Configured main app target: #{main_target.name}"

# 8. Clear folder synchronized groups of the main target
main_target.file_system_synchronized_groups.clear

# Remove obsolete relative references carried over from Admin_RSMS.xcodeproj
project.main_group.children.select { |c| c.respond_to?(:path) && (c.path == 'Admin_RSMS' || c.path == 'schema.json') }.each do |child|
  child.remove_from_project
  puts "  Removed obsolete reference: #{child.path}"
end

# 9. Clean main target source files and reference root gateway files
main_target.source_build_phase.files.clear
main_target.resources_build_phase.files.clear

file_ref_app = project.main_group.new_file('RSMSApp.swift')
file_ref_gateway = project.main_group.new_file('GatewayView.swift')
file_ref_assets = project.main_group.new_file('Assets.xcassets')

main_target.source_build_phase.add_file_reference(file_ref_app)
main_target.source_build_phase.add_file_reference(file_ref_gateway)
main_target.resources_build_phase.add_file_reference(file_ref_assets)
puts "Wired root source files to main app target sources"

# 10. Helper: Create dynamic framework target and synchronize files
def create_module_framework(project, name, path, source_project)
  # Create framework target
  framework_target = project.new_target(:framework, name, :ios, '26.5', nil, :swift)
  
  # Configure File System Synchronized Root Group
  sync_group = project.new(Xcodeproj::Project::Object::PBXFileSystemSynchronizedRootGroup)
  sync_group.path = path
  sync_group.source_tree = '<group>'
  project.root_object.main_group.children << sync_group
  framework_target.file_system_synchronized_groups << sync_group
  
  # Copy package dependencies and build settings from source target
  source_target = source_project.targets.first
  copy_target_package_dependencies(source_target, framework_target, project)
  copy_build_settings(source_target, framework_target)
  
  puts "Created and configured target #{name} for path #{path}"
  framework_target
end

# 11. Create framework targets for the four modules
puts "Creating AdminModule..."
admin_framework = create_module_framework(project, 'AdminModule', 'RSMS_Admin/Admin_RSMS', Xcodeproj::Project.open(source_proj_path))

puts "Creating InventoryModule..."
inventory_framework = create_module_framework(project, 'InventoryModule', 'RSMS_Inventory/RSMS_Project', inventory_project)

puts "Creating StoreManagerModule..."
store_framework = create_module_framework(project, 'StoreManagerModule', 'RSMS_Store_Manager/RSMS_Project', store_project)

puts "Creating SalesAssociateModule..."
sales_framework = create_module_framework(project, 'SalesAssociateModule', 'RSMS_Sales_Associate/sales_associate_rsms', sales_project)

# 12. Link and embed framework helper
def add_framework_dependency(project, main_target, framework_target)
  # Add target dependency
  main_target.add_dependency(framework_target)
  
  # Add build file in Frameworks Build Phase
  build_file = project.new(Xcodeproj::Project::Object::PBXBuildFile)
  build_file.file_ref = framework_target.product_reference
  main_target.frameworks_build_phase.files << build_file
  
  # Add to Embed Frameworks Copy Phase
  embed_phase = main_target.build_phases.find { |b| b.is_a?(Xcodeproj::Project::Object::PBXCopyFilesBuildPhase) && b.name == 'Embed Frameworks' }
  unless embed_phase
    embed_phase = project.new(Xcodeproj::Project::Object::PBXCopyFilesBuildPhase)
    embed_phase.name = 'Embed Frameworks'
    embed_phase.symbol_dst_subfolder_spec = :frameworks
    main_target.build_phases << embed_phase
  end
  
  embed_build_file = project.new(Xcodeproj::Project::Object::PBXBuildFile)
  embed_build_file.file_ref = framework_target.product_reference
  embed_build_file.settings = { 'ATTRIBUTES' => ['CodeSignOnCopy', 'RemoveHeadersOnCopy'] }
  embed_phase.files << embed_build_file
  
  puts "  Linked and embedded framework target #{framework_target.name} to main app target"
end

# 13. Link and embed the 4 framework targets to main target
puts "Linking framework modules..."
add_framework_dependency(project, main_target, admin_framework)
add_framework_dependency(project, main_target, inventory_framework)
add_framework_dependency(project, main_target, store_framework)
add_framework_dependency(project, main_target, sales_framework)

# 14. Save root project
project.save
puts "Successfully saved integrated project RSMS.xcodeproj!"
