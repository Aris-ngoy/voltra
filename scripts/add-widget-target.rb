#!/usr/bin/env ruby
# add-widget-target.rb
# Script to add a Live Activity widget extension target to an existing Xcode project
# 
# Usage: ruby scripts/add-widget-target.rb <xcodeproj_path> <target_name> <bundle_identifier> [group_identifier]
#
# Example:
#   ruby scripts/add-widget-target.rb ios/MyApp.xcodeproj MyAppLiveActivity com.myapp.liveactivity group.com.myapp

require 'xcodeproj'
require 'fileutils'
require 'json'

# Configuration
DEPLOYMENT_TARGET = '17.0'
SWIFT_VERSION = '5.0'

def main
  if ARGV.length < 3
    puts "Usage: ruby #{$0} <xcodeproj_path> <target_name> <bundle_identifier> [group_identifier]"
    puts ""
    puts "Example:"
    puts "  ruby #{$0} ios/MyApp.xcodeproj MyAppLiveActivity com.myapp.liveactivity group.com.myapp"
    exit 1
  end

  xcodeproj_path = ARGV[0]
  target_name = ARGV[1]
  bundle_identifier = ARGV[2]
  group_identifier = ARGV[3] # Optional

  unless File.exist?(xcodeproj_path)
    puts "Error: Xcode project not found at #{xcodeproj_path}"
    exit 1
  end

  project = Xcodeproj::Project.open(xcodeproj_path)
  
  # Check if target already exists
  existing_target = project.targets.find { |t| t.name == target_name }
  if existing_target
    puts "Target '#{target_name}' already exists. Skipping creation."
    exit 0
  end

  ios_project_path = File.dirname(xcodeproj_path)
  target_path = File.join(ios_project_path, target_name)
  
  # Create target directory if needed
  FileUtils.mkdir_p(target_path)

  # Generate required files only if they don't exist
  unless File.exist?(File.join(target_path, 'Info.plist'))
    generate_info_plist(target_path)
  else
    puts "Info.plist already exists, skipping..."
  end
  
  unless File.exist?(File.join(target_path, 'VoltraWidgetBundle.swift'))
    generate_widget_bundle(target_path)
  else
    puts "VoltraWidgetBundle.swift already exists, skipping..."
  end
  
  unless File.exist?(File.join(target_path, 'VoltraWidgetInitialStates.swift'))
    generate_initial_states(target_path)
  else
    puts "VoltraWidgetInitialStates.swift already exists, skipping..."
  end
  
  unless File.exist?(File.join(target_path, "#{target_name}.entitlements"))
    generate_entitlements(target_path, target_name, group_identifier)
  else
    puts "#{target_name}.entitlements already exists, skipping..."
  end
  
  unless File.exist?(File.join(target_path, 'Assets.xcassets'))
    generate_assets_catalog(target_path)
  else
    puts "Assets.xcassets already exists, skipping..."
  end

  # Add widget extension target to project
  add_widget_target(project, target_name, bundle_identifier, target_path, group_identifier)

  # Save the project
  project.save
  puts ""
  puts "✅ Successfully added widget extension target '#{target_name}'"
  puts ""
  puts "Next steps:"
  puts "1. Run 'pod install' in the ios directory"
  puts "2. Open the .xcworkspace file in Xcode"
  puts "3. Select the widget target and configure signing"
  if group_identifier
    puts "4. Enable App Groups capability for both main app and widget extension"
  end
end

def generate_info_plist(target_path)
  content = <<~PLIST
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
    <dict>
      <key>NSExtension</key>
      <dict>
        <key>NSExtensionPointIdentifier</key>
        <string>com.apple.widgetkit-extension</string>
      </dict>
    </dict>
    </plist>
  PLIST
  
  File.write(File.join(target_path, 'Info.plist'), content)
  puts "Generated Info.plist"
end

def generate_widget_bundle(target_path)
  content = <<~SWIFT
    //
    //  VoltraWidgetBundle.swift
    //
    //  Widget bundle for Live Activity support.
    //

    import SwiftUI
    import WidgetKit
    import VoltraWidget

    @main
    struct VoltraWidgetBundle: WidgetBundle {
      var body: some Widget {
        // Live Activity (with Watch/CarPlay support on iOS 18+)
        VoltraWidget()
      }
    }
  SWIFT
  
  File.write(File.join(target_path, 'VoltraWidgetBundle.swift'), content)
  puts "Generated VoltraWidgetBundle.swift"
end

def generate_initial_states(target_path)
  content = <<~SWIFT
    //
    //  VoltraWidgetInitialStates.swift
    //
    //  Pre-rendered initial states for widgets.
    //

    import Foundation

    public enum VoltraWidgetInitialStates {
      /// Get the bundled initial state JSON for a widget.
      /// Returns nil since no initial states are configured.
      public static func getInitialState(for widgetId: String) -> Data? {
        return nil
      }
    }
  SWIFT
  
  File.write(File.join(target_path, 'VoltraWidgetInitialStates.swift'), content)
  puts "Generated VoltraWidgetInitialStates.swift"
end

def generate_entitlements(target_path, target_name, group_identifier)
  if group_identifier
    content = <<~PLIST
      <?xml version="1.0" encoding="UTF-8"?>
      <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
      <plist version="1.0">
      <dict>
        <key>com.apple.security.application-groups</key>
        <array>
          <string>#{group_identifier}</string>
        </array>
      </dict>
      </plist>
    PLIST
  else
    content = <<~PLIST
      <?xml version="1.0" encoding="UTF-8"?>
      <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
      <plist version="1.0">
      <dict>
      </dict>
      </plist>
    PLIST
  end
  
  File.write(File.join(target_path, "#{target_name}.entitlements"), content)
  puts "Generated #{target_name}.entitlements"
end

def generate_assets_catalog(target_path)
  assets_path = File.join(target_path, 'Assets.xcassets')
  FileUtils.mkdir_p(assets_path)
  
  contents = {
    'info' => {
      'author' => 'xcode',
      'version' => 1
    }
  }
  
  File.write(File.join(assets_path, 'Contents.json'), JSON.pretty_generate(contents))
  puts "Generated Assets.xcassets"
end

def add_widget_target(project, target_name, bundle_identifier, target_path, group_identifier)
  # Get the main app target to read settings from
  main_target = project.targets.first
  main_build_settings = main_target.build_configurations.first.build_settings
  
  # Create the widget extension target
  target = project.new_target(:app_extension, target_name, :ios, DEPLOYMENT_TARGET)
  
  # Configure build settings for each configuration
  target.build_configurations.each do |config|
    settings = config.build_settings
    
    settings['INFOPLIST_FILE'] = "#{target_name}/Info.plist"
    settings['PRODUCT_BUNDLE_IDENTIFIER'] = bundle_identifier
    settings['PRODUCT_NAME'] = '$(TARGET_NAME)'
    settings['SWIFT_VERSION'] = SWIFT_VERSION
    settings['IPHONEOS_DEPLOYMENT_TARGET'] = DEPLOYMENT_TARGET
    settings['GENERATE_INFOPLIST_FILE'] = 'YES'
    settings['CURRENT_PROJECT_VERSION'] = main_build_settings['CURRENT_PROJECT_VERSION'] || '1'
    settings['MARKETING_VERSION'] = main_build_settings['MARKETING_VERSION'] || '1.0'
    settings['CODE_SIGN_STYLE'] = main_build_settings['CODE_SIGN_STYLE'] || 'Automatic'
    settings['DEVELOPMENT_TEAM'] = main_build_settings['DEVELOPMENT_TEAM']
    settings['TARGETED_DEVICE_FAMILY'] = '1,2'
    settings['ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME'] = 'AccentColor'
    settings['ASSETCATALOG_COMPILER_WIDGET_BACKGROUND_COLOR_NAME'] = 'WidgetBackground'
    settings['SKIP_INSTALL'] = 'YES'
    
    if group_identifier
      settings['CODE_SIGN_ENTITLEMENTS'] = "#{target_name}/#{target_name}.entitlements"
    end
    
    # Debug-specific settings
    if config.name == 'Debug'
      settings['DEBUG_INFORMATION_FORMAT'] = 'dwarf'
      settings['MTL_ENABLE_DEBUG_INFO'] = 'INCLUDE_SOURCE'
    else
      settings['DEBUG_INFORMATION_FORMAT'] = 'dwarf-with-dsym'
      settings['MTL_ENABLE_DEBUG_INFO'] = 'NO'
    end
  end
  
  # Create PBXGroup for widget files using relative path
  widget_group = project.main_group.new_group(target_name, target_name)
  
  # Add files to the group and target using relative filenames only
  swift_files = Dir.glob(File.join(target_path, '*.swift'))
  swift_files.each do |file|
    file_name = File.basename(file)
    file_ref = widget_group.new_reference(file_name)
    target.source_build_phase.add_file_reference(file_ref)
  end
  
  # Add Info.plist
  plist_path = File.join(target_path, 'Info.plist')
  if File.exist?(plist_path)
    widget_group.new_reference('Info.plist')
  end
  
  # Add entitlements if exists
  entitlements_file = "#{target_name}.entitlements"
  entitlements_path = File.join(target_path, entitlements_file)
  if File.exist?(entitlements_path)
    widget_group.new_reference(entitlements_file)
  end
  
  # Add Assets.xcassets
  assets_path = File.join(target_path, 'Assets.xcassets')
  if File.exist?(assets_path)
    asset_ref = widget_group.new_reference('Assets.xcassets')
    target.resources_build_phase.add_file_reference(asset_ref)
  end
  
  # Add target dependency to main app
  main_target.add_dependency(target)
  
  # Add embed extension build phase
  embed_phase = main_target.new_copy_files_build_phase('Embed Foundation Extensions')
  embed_phase.dst_subfolder_spec = '13' # Plugins folder
  embed_phase.add_file_reference(target.product_reference)
  
  puts "Added widget extension target to Xcode project"
end

# Run main
main
