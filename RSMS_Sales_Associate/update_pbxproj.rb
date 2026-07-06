require 'xcodeproj'
project_path = '/Users/sherlock/Documents/Team-8/RSMS_Sales_Associate/sales_associate_rsms.xcodeproj'
project = Xcodeproj::Project.open(project_path)
target = project.targets.first

group = project.main_group.find_subpath('sales_associate_rsms/Features/SalesAssociate/Omnichannel', true)

def add_file(group, target, name)
  # Check if exists
  return if group.children.find { |c| c.path == name }
  file_ref = group.new_file(name)
  unless target.source_build_phase.files_references.include?(file_ref)
    target.source_build_phase.add_file_reference(file_ref) 
  end
end

models = group.find_subpath('Models', true)
add_file(models, target, 'FulfillmentOrder.swift')
add_file(models, target, 'InventoryLevel.swift')

services = group.find_subpath('Services', true)
add_file(services, target, 'OmnichannelService.swift')

viewmodels = group.find_subpath('ViewModels', true)
add_file(viewmodels, target, 'OmnichannelViewModel.swift')

views = group.find_subpath('Views', true)
add_file(views, target, 'BOPISQueueView.swift')
add_file(views, target, 'SignatureCaptureView.swift')
add_file(views, target, 'ShipFromStoreView.swift')
add_file(views, target, 'EndlessAisleView.swift')
add_file(views, target, 'UnifiedInventoryView.swift')

project.save
