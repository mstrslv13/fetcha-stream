#!/usr/bin/env ruby

require 'xcodeproj'

# Open the project
project_path = 'yt-dlp-MAX.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Get the main target
target = project.targets.first

# Get the main group (yt-dlp-MAX folder)
main_group = project.main_group['yt-dlp-MAX']

# Create or get the Services group
services_group = main_group['Services'] || main_group.new_group('Services')

# Create or get the Views group  
views_group = main_group['Views'] || main_group.new_group('Views')

# Files to add
files_to_add = [
  { path: 'yt-dlp-MAX/Services/DownloadQueue.swift', group: services_group },
  { path: 'yt-dlp-MAX/Views/QueueView.swift', group: views_group },
  { path: 'yt-dlp-MAX/Views/QueueSettingsView.swift', group: views_group }
]

# Add each file
files_to_add.each do |file_info|
  file_path = file_info[:path]
  group = file_info[:group]
  
  # Check if file already exists in project
  existing_ref = project.files.find { |f| f.real_path.to_s.end_with?(File.basename(file_path)) }
  
  if existing_ref.nil? && File.exist?(file_path)
    # Add file reference
    file_ref = group.new_file(file_path)
    
    # Add to build phase
    target.source_build_phase.add_file_reference(file_ref)
    
    puts "Added #{file_path} to project"
  elsif existing_ref
    puts "#{File.basename(file_path)} already in project"
  else
    puts "Warning: #{file_path} not found on disk"
  end
end

# Remove old DownloadQueueView if it exists
old_file = project.files.find { |f| f.real_path.to_s.end_with?('DownloadQueueView.swift') }
if old_file
  old_file.remove_from_project
  puts "Removed old DownloadQueueView.swift from project"
end

# Save the project
project.save
puts "Project saved successfully!"