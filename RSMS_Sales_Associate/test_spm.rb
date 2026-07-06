require 'xcodeproj'
project_path = '/Users/sehgal18505/Documents/infy/sales_associate_rsms/sales_associate_rsms.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Print all packages to see if the gem recognizes my additions
puts "Packages:"
project.root_object.package_references.each do |pkg|
  puts pkg.repositoryURL
end
