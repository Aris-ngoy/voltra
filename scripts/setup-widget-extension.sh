#!/bin/bash

#
# setup-widget-extension.sh
#
# This script generates an iOS Widget Extension for Voltra Live Activities
# in a bare React Native project. It mimics what the Expo plugin does.
#
# Usage: ./scripts/setup-widget-extension.sh [options]
#
# Options:
#   --target-name       Name of the widget extension target (default: {AppName}LiveActivity)
#   --bundle-id         Bundle identifier suffix (default: same as target-name)
#   --group-id          App Group identifier for sharing data (required for widgets)
#   --deployment-target iOS deployment target (default: 17.0)
#   --url-scheme        URL scheme for deep linking (optional)
#   --enable-push       Enable push notifications support (optional)
#   --widgets           Comma-separated list of widget IDs (optional, for home screen widgets)
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Get script directory and project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Default to current working directory as project root (can be overridden with --project-root)
PROJECT_ROOT="$(pwd)"
IOS_DIR="$PROJECT_ROOT/ios"
VOLTRA_POD_PATH=""

# Default values
APP_NAME=""
TARGET_NAME=""
BUNDLE_ID_SUFFIX=""
GROUP_IDENTIFIER=""
DEPLOYMENT_TARGET="17.0"
URL_SCHEME=""
ENABLE_PUSH="false"
WIDGETS=""

# Resolve where the Voltra iOS sources live so the Podfile can reference them.
# Prioritize the app's node_modules, fall back to the monorepo root when running from this repo.
detect_voltra_ios_path() {
    local CANDIDATE

    # Standard node_modules location
    CANDIDATE="$IOS_DIR/../node_modules/voltra/ios"
    if [ -d "$CANDIDATE" ]; then
        VOLTRA_POD_PATH="../node_modules/voltra/ios"
        log_info "Found Voltra iOS sources in app node_modules"
        return
    fi

    # Workspace/monorepo node_modules
    CANDIDATE="$IOS_DIR/../../node_modules/voltra/ios"
    if [ -d "$CANDIDATE" ]; then
        VOLTRA_POD_PATH="../../node_modules/voltra/ios"
        log_info "Found Voltra iOS sources in workspace node_modules"
        return
    fi

    # Monorepo structure (running from packages/voltra)
    CANDIDATE="$IOS_DIR/../../../ios"
    if [ -d "$CANDIDATE" ]; then
        VOLTRA_POD_PATH="../../../ios"
        log_info "Using monorepo Voltra iOS sources"
        return
    fi

    # Local development (voltra repo root)
    CANDIDATE="$SCRIPT_DIR/../ios"
    if [ -d "$CANDIDATE" ]; then
        VOLTRA_POD_PATH="$SCRIPT_DIR/../ios"
        log_info "Using local Voltra iOS sources"
        return
    fi

    VOLTRA_POD_PATH="../node_modules/voltra/ios"
    log_warn "Could not locate voltra/ios; using default Pod path: $VOLTRA_POD_PATH"
}

# Parse app name from app.json or package.json
parse_app_name() {
    if [ -f "$PROJECT_ROOT/app.json" ]; then
        APP_NAME=$(grep -o '"name"[[:space:]]*:[[:space:]]*"[^"]*"' "$PROJECT_ROOT/app.json" | head -1 | sed 's/.*"name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/')
    fi
    
    if [ -z "$APP_NAME" ] && [ -f "$PROJECT_ROOT/package.json" ]; then
        APP_NAME=$(grep -o '"name"[[:space:]]*:[[:space:]]*"[^"]*"' "$PROJECT_ROOT/package.json" | head -1 | sed 's/.*"name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/')
    fi
    
    if [ -z "$APP_NAME" ]; then
        # Fallback to folder name
        APP_NAME=$(basename "$PROJECT_ROOT")
    fi
    
    log_info "App name: $APP_NAME"
}

# Parse command line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --target-name)
                TARGET_NAME="$2"
                shift 2
                ;;
            --bundle-id)
                BUNDLE_ID_SUFFIX="$2"
                shift 2
                ;;
            --group-id)
                GROUP_IDENTIFIER="$2"
                shift 2
                ;;
            --deployment-target)
                DEPLOYMENT_TARGET="$2"
                shift 2
                ;;
            --url-scheme)
                URL_SCHEME="$2"
                shift 2
                ;;
            --enable-push)
                ENABLE_PUSH="true"
                shift
                ;;
            --widgets)
                WIDGETS="$2"
                shift 2
                ;;
            --project-root)
                PROJECT_ROOT="$2"
                IOS_DIR="$PROJECT_ROOT/ios"
                shift 2
                ;;
            --help)
                echo "Usage: $0 [options]"
                echo ""
                echo "Options:"
                echo "  --target-name       Name of the widget extension target"
                echo "  --bundle-id         Bundle identifier suffix"
                echo "  --group-id          App Group identifier (required for data sharing)"
                echo "  --deployment-target iOS deployment target (default: 17.0)"
                echo "  --url-scheme        URL scheme for deep linking"
                echo "  --enable-push       Enable push notifications support"
                echo "  --widgets           Comma-separated list of widget IDs"
                echo "  --project-root      Path to the React Native project root (default: current directory)"
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                exit 1
                ;;
        esac
    done
}

# Set default target name
set_defaults() {
    if [ -z "$TARGET_NAME" ]; then
        TARGET_NAME="${APP_NAME}LiveActivity"
    fi
    
    if [ -z "$BUNDLE_ID_SUFFIX" ]; then
        BUNDLE_ID_SUFFIX="$TARGET_NAME"
    fi
    
    log_info "Target name: $TARGET_NAME"
    log_info "Deployment target: $DEPLOYMENT_TARGET"
    detect_voltra_ios_path
    log_info "Voltra Pod path: $VOLTRA_POD_PATH"
    
    if [ -n "$GROUP_IDENTIFIER" ]; then
        log_info "App Group: $GROUP_IDENTIFIER"
    else
        log_warn "No App Group specified. Widget data sharing will not work."
        log_warn "Use --group-id to specify an App Group identifier."
    fi
}

# Create widget extension directory structure
create_extension_directory() {
    local TARGET_PATH="$IOS_DIR/$TARGET_NAME"
    
    log_info "Creating widget extension directory: $TARGET_PATH"
    
    mkdir -p "$TARGET_PATH"
    mkdir -p "$TARGET_PATH/Assets.xcassets"
}

# Generate Info.plist
generate_info_plist() {
    local PLIST_PATH="$IOS_DIR/$TARGET_NAME/Info.plist"
    
    log_info "Generating Info.plist..."
    
    cat > "$PLIST_PATH" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>NSExtension</key>
	<dict>
		<key>NSExtensionPointIdentifier</key>
		<string>com.apple.widgetkit-extension</string>
	</dict>
EOF

    # Add URL scheme if provided
    if [ -n "$URL_SCHEME" ]; then
        cat >> "$PLIST_PATH" << EOF
	<key>CFBundleURLTypes</key>
	<array>
		<dict>
			<key>CFBundleURLSchemes</key>
			<array>
				<string>${URL_SCHEME}</string>
			</array>
		</dict>
	</array>
EOF
    fi

    # Add group identifier if provided
    if [ -n "$GROUP_IDENTIFIER" ]; then
        cat >> "$PLIST_PATH" << EOF
	<key>Voltra_AppGroupIdentifier</key>
	<string>${GROUP_IDENTIFIER}</string>
EOF
    fi

    cat >> "$PLIST_PATH" << 'EOF'
</dict>
</plist>
EOF

    log_success "Generated Info.plist"
}

# Generate Assets.xcassets
generate_assets_catalog() {
    local ASSETS_PATH="$IOS_DIR/$TARGET_NAME/Assets.xcassets"
    
    log_info "Generating Assets.xcassets..."
    
    cat > "$ASSETS_PATH/Contents.json" << 'EOF'
{
  "info": {
    "author": "xcode",
    "version": 1
  }
}
EOF

    log_success "Generated Assets.xcassets"
}

# Generate entitlements file
generate_entitlements() {
    local ENTITLEMENTS_PATH="$IOS_DIR/$TARGET_NAME/$TARGET_NAME.entitlements"
    
    log_info "Generating entitlements..."
    
    cat > "$ENTITLEMENTS_PATH" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
EOF

    if [ -n "$GROUP_IDENTIFIER" ]; then
        cat >> "$ENTITLEMENTS_PATH" << EOF
	<key>com.apple.security.application-groups</key>
	<array>
		<string>${GROUP_IDENTIFIER}</string>
	</array>
EOF
    fi

    # Add push notifications entitlement if enabled
    if [ "$ENABLE_PUSH" = "true" ]; then
        cat >> "$ENTITLEMENTS_PATH" << 'EOF'
	<key>aps-environment</key>
	<string>development</string>
EOF
    fi

    cat >> "$ENTITLEMENTS_PATH" << 'EOF'
</dict>
</plist>
EOF

    log_success "Generated $TARGET_NAME.entitlements"
}

# Generate VoltraWidgetBundle.swift
generate_widget_bundle() {
    local SWIFT_PATH="$IOS_DIR/$TARGET_NAME/VoltraWidgetBundle.swift"
    
    log_info "Generating VoltraWidgetBundle.swift..."

    # Check if we have home screen widgets configured
    if [ -n "$WIDGETS" ]; then
        # Generate with home screen widgets
        generate_widget_bundle_with_widgets "$SWIFT_PATH"
    else
        # Live Activity only
        cat > "$SWIFT_PATH" << 'EOF'
//
//  VoltraWidgetBundle.swift
//
//  Auto-generated by setup-widget-extension.sh
//  This file defines which Voltra widgets are available in your app.
//

import SwiftUI
import WidgetKit
import VoltraWidget  // Import Voltra widgets

@main
struct VoltraWidgetBundle: WidgetBundle {
  var body: some Widget {
    // Live Activity Widget (Dynamic Island + Lock Screen)
    VoltraWidget()
  }
}
EOF
    fi

    log_success "Generated VoltraWidgetBundle.swift"
}

# Generate widget bundle with home screen widgets
generate_widget_bundle_with_widgets() {
    local SWIFT_PATH="$1"
    
    # Parse widget IDs
    IFS=',' read -ra WIDGET_ARRAY <<< "$WIDGETS"
    
    # Generate widget instances
    local WIDGET_INSTANCES=""
    local WIDGET_STRUCTS=""
    
    for widget_id in "${WIDGET_ARRAY[@]}"; do
        # Trim whitespace
        widget_id=$(echo "$widget_id" | xargs)
        WIDGET_INSTANCES+="    VoltraWidget_${widget_id}()\n"
        
        WIDGET_STRUCTS+="
public struct VoltraWidget_${widget_id}: Widget {
  private let widgetId = \"${widget_id}\"

  public init() {}

  public var body: some WidgetConfiguration {
    StaticConfiguration(
      kind: \"Voltra_Widget_${widget_id}\",
      provider: VoltraHomeWidgetProvider(
        widgetId: widgetId,
        initialState: VoltraWidgetInitialStates.getInitialState(for: widgetId)
      )
    ) { entry in
      VoltraHomeWidgetView(entry: entry)
    }
    .configurationDisplayName(\"${widget_id}\")
    .description(\"Voltra Widget\")
    .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    .contentMarginsDisabled()
  }
}
"
    done

    cat > "$SWIFT_PATH" << EOF
//
//  VoltraWidgetBundle.swift
//
//  Auto-generated by setup-widget-extension.sh
//  This file defines which Voltra widgets are available in your app.
//

import SwiftUI
import WidgetKit
import VoltraWidget

@main
struct VoltraWidgetBundle: WidgetBundle {
  var body: some Widget {
    // Live Activity Widget (Dynamic Island + Lock Screen)
    VoltraWidget()

    // Home Screen Widgets
$(echo -e "$WIDGET_INSTANCES")
  }
}

// MARK: - Home Screen Widget Definitions
${WIDGET_STRUCTS}
EOF
}

# Generate VoltraWidgetInitialStates.swift
generate_initial_states() {
    local SWIFT_PATH="$IOS_DIR/$TARGET_NAME/VoltraWidgetInitialStates.swift"
    
    log_info "Generating VoltraWidgetInitialStates.swift..."
    
    cat > "$SWIFT_PATH" << 'EOF'
//
//  VoltraWidgetInitialStates.swift
//
//  Auto-generated by setup-widget-extension.sh
//  No widget initial states configured (Live Activity only).
//

import Foundation

public enum VoltraWidgetInitialStates {
  /// Get the bundled initial state JSON for a widget.
  /// Always returns nil since no home screen widgets are configured.
  public static func getInitialState(for widgetId: String) -> Data? {
    return nil
  }
}
EOF

    log_success "Generated VoltraWidgetInitialStates.swift"
}

# Update Podfile to include Voltra pod in the main app target
add_voltra_pod_to_main_target() {
    local PODFILE_PATH="$IOS_DIR/Podfile"
    
    log_info "Adding Voltra pod to main app target..."
    
    # Check if Voltra pod already exists
    if grep -q "pod 'Voltra'" "$PODFILE_PATH"; then
        log_warn "Voltra pod already exists in Podfile, skipping..."
        return
    fi
    
    # Find the main target and add Voltra pod after use_native_modules!
    # We look for use_native_modules! or use_react_native! as insertion point
    if grep -q "use_native_modules!" "$PODFILE_PATH"; then
        # Insert after use_native_modules! line
        sed -i '' "/use_native_modules!/a\\
\\
  # Manually add Voltra since react-native config doesn't detect iOS podspec\\
  pod 'Voltra', :path => '$VOLTRA_POD_PATH'
" "$PODFILE_PATH"
        log_success "Added Voltra pod to main app target"
    else
        log_warn "Could not find use_native_modules! in Podfile"
        log_info "Please manually add the following to your main app target:"
        log_info "  pod 'Voltra', :path => '$VOLTRA_POD_PATH'"
    fi
}

# Update Podfile to include widget extension target
update_podfile() {
    local PODFILE_PATH="$IOS_DIR/Podfile"
    
    log_info "Updating Podfile..."
    
    # First, add Voltra pod to the main app target
    add_voltra_pod_to_main_target
    
    # Check if widget target already exists
    if grep -q "target '$TARGET_NAME'" "$PODFILE_PATH"; then
        log_warn "Widget target already exists in Podfile, skipping..."
        return
    fi
    
    # Add widget target
    cat >> "$PODFILE_PATH" << EOF

# Voltra Widget Extension Target
# Auto-generated by setup-widget-extension.sh
target '$TARGET_NAME' do
  use_frameworks! :linkage => :static
  pod 'VoltraWidget', :path => '$VOLTRA_POD_PATH'
end
EOF

    log_success "Updated Podfile with widget extension target"
}

# Update main app Info.plist to support Live Activities
update_main_info_plist() {
    local MAIN_PLIST_PATH="$IOS_DIR/$APP_NAME/Info.plist"
    
    if [ ! -f "$MAIN_PLIST_PATH" ]; then
        log_warn "Main app Info.plist not found at $MAIN_PLIST_PATH"
        return
    fi
    
    log_info "Updating main app Info.plist for Live Activities support..."
    
    # Check if NSSupportsLiveActivities already exists
    if grep -q "NSSupportsLiveActivities" "$MAIN_PLIST_PATH"; then
        log_warn "NSSupportsLiveActivities already exists in Info.plist, skipping..."
        return
    fi
    
    # Use PlistBuddy to add Live Activities support
    /usr/libexec/PlistBuddy -c "Add :NSSupportsLiveActivities bool true" "$MAIN_PLIST_PATH" 2>/dev/null || true
    /usr/libexec/PlistBuddy -c "Add :NSSupportsLiveActivitiesFrequentUpdates bool false" "$MAIN_PLIST_PATH" 2>/dev/null || true
    
    # Add group identifier if provided
    if [ -n "$GROUP_IDENTIFIER" ]; then
        /usr/libexec/PlistBuddy -c "Add :Voltra_AppGroupIdentifier string $GROUP_IDENTIFIER" "$MAIN_PLIST_PATH" 2>/dev/null || true
    fi

    # Add push notification support if enabled
    if [ "$ENABLE_PUSH" = "true" ]; then
        /usr/libexec/PlistBuddy -c "Add :Voltra_EnablePushNotifications bool true" "$MAIN_PLIST_PATH" 2>/dev/null || true
    fi
    
    log_success "Updated main app Info.plist"
}

# Update main app entitlements
update_main_entitlements() {
    # Find the main app entitlements file
    local MAIN_ENTITLEMENTS=""
    
    if [ -f "$IOS_DIR/$APP_NAME/$APP_NAME.entitlements" ]; then
        MAIN_ENTITLEMENTS="$IOS_DIR/$APP_NAME/$APP_NAME.entitlements"
    elif [ -f "$IOS_DIR/$APP_NAME.entitlements" ]; then
        MAIN_ENTITLEMENTS="$IOS_DIR/$APP_NAME.entitlements"
    fi
    
    if [ -z "$MAIN_ENTITLEMENTS" ] || [ ! -f "$MAIN_ENTITLEMENTS" ]; then
        log_warn "Main app entitlements file not found"
        log_info "You may need to manually add App Group entitlements to your main app"
        return
    fi
    
    if [ -z "$GROUP_IDENTIFIER" ]; then
        return
    fi
    
    log_info "Updating main app entitlements..."
    
    # Check if app groups already exist
    if grep -q "com.apple.security.application-groups" "$MAIN_ENTITLEMENTS"; then
        log_warn "App groups already exist in main entitlements"
        log_info "Please verify $GROUP_IDENTIFIER is included"
        return
    fi
    
    # This is a simple check - for complex entitlements, manual editing may be needed
    log_warn "Please manually add the following to your main app entitlements:"
    log_info "  <key>com.apple.security.application-groups</key>"
    log_info "  <array>"
    log_info "    <string>$GROUP_IDENTIFIER</string>"
    log_info "  </array>"
}

# Print summary
print_summary() {
    echo ""
    log_success "Widget extension files generated successfully!"
    echo ""
    echo "Generated files:"
    echo "  - $IOS_DIR/$TARGET_NAME/Info.plist"
    echo "  - $IOS_DIR/$TARGET_NAME/Assets.xcassets/"
    echo "  - $IOS_DIR/$TARGET_NAME/$TARGET_NAME.entitlements"
    echo "  - $IOS_DIR/$TARGET_NAME/VoltraWidgetBundle.swift"
    echo "  - $IOS_DIR/$TARGET_NAME/VoltraWidgetInitialStates.swift"
    echo ""
    echo "Next steps:"
    echo "  1. Install xcodeproj gem: gem install xcodeproj"
    echo "  2. Run: ruby scripts/add-widget-target.rb"
    echo "  3. Run: cd ios && pod install"
    echo "  4. Open ios/$APP_NAME.xcworkspace in Xcode"
    echo "  5. Configure signing for the widget extension"
    echo ""
    if [ -n "$GROUP_IDENTIFIER" ]; then
        echo "Important: Make sure to add App Group '$GROUP_IDENTIFIER' to both:"
        echo "  - Main app capabilities"
        echo "  - Widget extension capabilities"
        echo ""
    fi
}

# Main execution
main() {
    log_info "Voltra Widget Extension Setup"
    log_info "=============================="
    echo ""
    
    parse_app_name
    parse_args "$@"
    set_defaults
    
    echo ""
    
    # Create files
    create_extension_directory
    generate_info_plist
    generate_assets_catalog
    generate_entitlements
    generate_widget_bundle
    generate_initial_states
    update_podfile
    update_main_info_plist
    update_main_entitlements
    
    print_summary
}

main "$@"
