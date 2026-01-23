#!/usr/bin/env ruby

#
# add-widget-target.rb
#
# Adds the widget extension target to the Xcode project
# This requires the 'xcodeproj' gem: gem install xcodeproj
#
# Usage: ruby scripts/add-widget-target.rb
#

require 'xcodeproj'
require 'fileutils'
require 'json'

PROJECT_ROOT = File.expand_path('..', __dir__)
IOS_DIR = File.join(PROJECT_ROOT, 'ios')

# Read app name from app.json
def get_app_name
  app_json_path = File.join(PROJECT_ROOT, 'app.json')
  if File.exist?(app_json_path)
    app_json = JSON.parse(File.read(app_json_path))
    return app_json['name'] || File.basename(PROJECT_ROOT)
  end
  File.basename(PROJECT_ROOT)
end

APP_NAME = get_app_name
TARGET_NAME = "#{APP_NAME}LiveActivity"
BUNDLE_ID_SUFFIX = TARGET_NAME
DEPLOYMENT_TARGET = '17.0'

# Read group identifier from the generated entitlements file
def get_group_identifier
  entitlements_path = File.join(IOS_DIR, TARGET_NAME, "#{TARGET_NAME}.entitlements")
  if File.exist?(entitlements_path)
    content = File.read(entitlements_path)
    match = content.match(/<string>(group\.[^<]+)<\/string>/)
    return match[1] if match
  end
  nil
end

GROUP_IDENTIFIER = get_group_identifier

def main
  project_path = File.join(IOS_DIR, "#{APP_NAME}.xcodeproj")
  
  unless File.exist?(project_path)
    puts "Error: Xcode project not found at #{project_path}"
    exit 1
  end
  
  project = Xcodeproj::Project.open(project_path)
  
  # Check if target already exists
  if project.targets.any? { |t| t.name == TARGET_NAME }
    puts "Widget target '#{TARGET_NAME}' already exists, skipping..."
    return
  end
  
  puts "Adding widget extension target: #{TARGET_NAME}"
  
  # Get the main app target to copy settings from
  main_target = project.targets.find { |t| t.name == APP_NAME }
  unless main_target
    puts "Error: Main app target '#{APP_NAME}' not found"
    exit 1
  end
  
  # Get main app bundle identifier and team
  main_build_settings = main_target.build_configurations.first.build_settings
  main_bundle_id = main_build_settings['PRODUCT_BUNDLE_IDENTIFIER']
  development_team = main_build_settings['DEVELOPMENT_TEAM']
  
  puts "Main app bundle ID: #{main_bundle_id}"
  puts "Development team: #{development_team || 'Not set'}"
  
  # Create the widget extension target
  widget_target = project.new_target(:app_extension, TARGET_NAME, :ios, DEPLOYMENT_TARGET)
  
  # Configure build settings
  widget_target.build_configurations.each do |config|
    config.build_settings['PRODUCT_NAME'] = '$(TARGET_NAME)'
    config.build_settings['PRODUCT_BUNDLE_IDENTIFIER'] = "#{main_bundle_id}.#{BUNDLE_ID_SUFFIX}"
    config.build_settings['INFOPLIST_FILE'] = "#{TARGET_NAME}/Info.plist"
    config.build_settings['CODE_SIGN_ENTITLEMENTS'] = "#{TARGET_NAME}/#{TARGET_NAME}.entitlements"
    config.build_settings['DEVELOPMENT_TEAM'] = development_team if development_team
    config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = DEPLOYMENT_TARGET
    config.build_settings['SWIFT_VERSION'] = '5.0'
    config.build_settings['GENERATE_INFOPLIST_FILE'] = 'NO'
    config.build_settings['CURRENT_PROJECT_VERSION'] = '1'
    config.build_settings['MARKETING_VERSION'] = '1.0'
    config.build_settings['ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME'] = 'AccentColor'
    config.build_settings['ASSETCATALOG_COMPILER_WIDGET_BACKGROUND_COLOR_NAME'] = 'WidgetBackground'
    config.build_settings['SKIP_INSTALL'] = 'YES'
    config.build_settings['LD_RUNPATH_SEARCH_PATHS'] = [
      '$(inherited)',
      '@executable_path/Frameworks',
      '@executable_path/../../Frameworks'
    ]
  end
  
  # Add source files to target
  target_path = File.join(IOS_DIR, TARGET_NAME)
  
  unless File.exist?(target_path)
    puts "Error: Widget extension files not found at #{target_path}"
    puts "Please run ./scripts/setup-widget-extension.sh first"
    exit 1
  end
  
  # Create or find the group for widget extension
  group = project.main_group.find_subpath(TARGET_NAME, false)
  if group.nil?
    group = project.main_group.new_group(TARGET_NAME, TARGET_NAME)
  end
  
  # Add Swift files
  Dir.glob(File.join(target_path, '*.swift')).each do |swift_file|
    file_name = File.basename(swift_file)
    existing = group.files.find { |f| f.path == file_name }
    unless existing
      file_ref = group.new_reference(file_name)
      widget_target.source_build_phase.add_file_reference(file_ref)
      puts "Added #{file_name} to sources"
    end
  end
  
  # Add Info.plist
  plist_file = 'Info.plist'
  if File.exist?(File.join(target_path, plist_file))
    unless group.files.find { |f| f.path == plist_file }
      group.new_reference(plist_file)
      puts "Added #{plist_file}"
    end
  end
  
  # Add entitlements
  entitlements_file = "#{TARGET_NAME}.entitlements"
  if File.exist?(File.join(target_path, entitlements_file))
    unless group.files.find { |f| f.path == entitlements_file }
      group.new_reference(entitlements_file)
      puts "Added #{entitlements_file}"
    end
  end
  
  # Add Assets.xcassets
  assets_folder = 'Assets.xcassets'
  assets_path = File.join(target_path, assets_folder)
  if File.exist?(assets_path)
    unless group.files.find { |f| f.path == assets_folder }
      assets_ref = group.new_reference(assets_folder)
      widget_target.resources_build_phase.add_file_reference(assets_ref)
      puts "Added #{assets_folder}"
    end
  end
  
  # Add dependency from main app to widget extension
  main_target.add_dependency(widget_target)
  puts "Added dependency from #{APP_NAME} to #{TARGET_NAME}"
  
  # Create embed extension build phase if it doesn't exist
  embed_phase = main_target.build_phases.find do |p| 
    p.is_a?(Xcodeproj::Project::Object::PBXCopyFilesBuildPhase) && 
    p.name == 'Embed Foundation Extensions'
  end
  
  unless embed_phase
    embed_phase = project.new(Xcodeproj::Project::Object::PBXCopyFilesBuildPhase)
    embed_phase.name = 'Embed Foundation Extensions'
    embed_phase.symbol_dst_subfolder_spec = :plug_ins
    main_target.build_phases << embed_phase
    puts "Created 'Embed Foundation Extensions' build phase"
  end
  
  # Add widget to embed phase
  product_ref = widget_target.product_reference
  unless embed_phase.files.any? { |f| f.file_ref == product_ref }
    build_file = embed_phase.add_file_reference(product_ref)
    build_file.settings = { 'ATTRIBUTES' => ['RemoveHeadersOnCopy'] }
    puts "Added #{TARGET_NAME}.appex to embed phase"
  end
  
  # Save project
  project.save
  
  puts ""
  puts "✅ Successfully added widget extension target: #{TARGET_NAME}"
  puts ""
  puts "Next steps:"
  puts "1. Run: cd ios && pod install"
  puts "2. Open ios/#{APP_NAME}.xcworkspace in Xcode"
  puts "3. Configure signing for the widget extension"
  puts "4. Build and run!"
end

main
