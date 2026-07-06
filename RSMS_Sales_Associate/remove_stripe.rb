require 'xcodeproj'
project_path = 'sales_associate_rsms.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Remove the package reference
project.root_object.package_references.each do |pkg|
  if pkg.repositoryURL.include?('stripe-ios')
    pkg.remove_from_project
  end
end

# Remove from framework build phases
project.targets.each do |target|
  target.frameworks_build_phase.files.each do |file|
    if file.display_name.include?('Stripe')
      file.remove_from_project
    end
  end
  # Remove package product dependencies
  target.package_product_dependencies.each do |dep|
    if dep.product_name == 'Stripe'
      dep.remove_from_project
    end
  end
end

project.save
