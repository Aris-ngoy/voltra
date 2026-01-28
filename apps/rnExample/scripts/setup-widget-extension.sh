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
#   --group-id          App Group identifier for sharing data (optional)
#   --deployment-target iOS deployment target (default: 17.0)
#   --url-scheme        URL scheme for deep linking (optional)
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
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
IOS_DIR="$PROJECT_ROOT/ios"
VOLTRA_POD_PATH=""

# Default values
APP_NAME=""
TARGET_NAME=""
BUNDLE_ID_SUFFIX=""
GROUP_IDENTIFIER=""
DEPLOYMENT_TARGET="17.0"
URL_SCHEME=""

# Resolve where the Voltra iOS sources live so the Podfile can reference them.
# Prioritize the app's node_modules, fall back to the monorepo root when running from this repo.
detect_voltra_ios_path() {
    local CANDIDATE

    CANDIDATE="$IOS_DIR/../node_modules/voltra/ios"
    if [ -d "$CANDIDATE" ]; then
        VOLTRA_POD_PATH="../node_modules/voltra/ios"
        log_info "Found Voltra iOS sources in app node_modules"
        return
    fi

    CANDIDATE="$IOS_DIR/../../node_modules/voltra/ios"
    if [ -d "$CANDIDATE" ]; then
        VOLTRA_POD_PATH="../../node_modules/voltra/ios"
        log_info "Found Voltra iOS sources in workspace node_modules"
        return
    fi

    CANDIDATE="$IOS_DIR/../../../ios"
    if [ -d "$CANDIDATE" ]; then
        VOLTRA_POD_PATH="../../../ios"
        log_info "Using monorepo Voltra iOS sources"
        return
    fi

    VOLTRA_POD_PATH="../node_modules/voltra/ios"
    log_warn "Could not locate voltra/ios; using default Pod path: $VOLTRA_POD_PATH"
}

# Parse app name from app.json
parse_app_name() {
    if [ -f "$PROJECT_ROOT/app.json" ]; then
        APP_NAME=$(grep -o '"name"[[:space:]]*:[[:space:]]*"[^"]*"' "$PROJECT_ROOT/app.json" | head -1 | sed 's/.*"name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/')
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
            --help)
                echo "Usage: $0 [options]"
                echo ""
                echo "Options:"
                echo "  --target-name       Name of the widget extension target"
                echo "  --bundle-id         Bundle identifier suffix"
                echo "  --group-id          App Group identifier"
                echo "  --deployment-target iOS deployment target (default: 17.0)"
                echo "  --url-scheme        URL scheme for deep linking"
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

    log_success "Generated VoltraWidgetBundle.swift"
}

# Generate VoltraWidgetInitialStates.swift (empty since we don't have home widgets)
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

# Update Podfile to include widget extension target
update_podfile() {
    local PODFILE_PATH="$IOS_DIR/Podfile"
    
    log_info "Updating Podfile..."
    
    # Check if widget target already exists
    if grep -q "target '$TARGET_NAME'" "$PODFILE_PATH"; then
        log_warn "Widget target already exists in Podfile, skipping..."
        return
    fi
    
    # Check if use_frameworks! is already set globally
    if ! grep -q "^use_frameworks!" "$PODFILE_PATH"; then
        log_info "Adding use_frameworks! :linkage => :static globally for widget extension compatibility..."
        # Insert use_frameworks! after prepare_react_native_project!
        sed -i '' '/prepare_react_native_project!/a\
\
# Use static frameworks for compatibility with widget extension\
use_frameworks! :linkage => :static
' "$PODFILE_PATH"
    fi
    
    # Add widget target
    cat >> "$PODFILE_PATH" << EOF

# Voltra Widget Extension Target
# Auto-generated by setup-widget-extension.sh
target '$TARGET_NAME' do
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
    
    log_success "Updated main app Info.plist"
}

# Generate the Xcode project configuration (using Ruby script)
generate_xcode_config() {
    log_info "To complete the setup, you need to add the widget extension to your Xcode project manually."
    log_info ""
    log_info "Steps to add the extension in Xcode:"
    log_info "1. Open $IOS_DIR/$APP_NAME.xcworkspace in Xcode"
    log_info "2. File > Add Files to \"$APP_NAME\"..."
    log_info "3. Select the $TARGET_NAME folder"
    log_info "4. File > New > Target..."
    log_info "5. Search for 'Widget Extension' and select it"
    log_info "6. Name it '$TARGET_NAME' and configure as needed"
    log_info "7. Delete the auto-generated files and keep the ones we created"
    log_info ""
    log_info "Alternatively, run: ruby scripts/add-widget-target.rb"
}

# Check if Ruby script exists, if not log instruction
create_xcode_script() {
    local RUBY_SCRIPT="$SCRIPT_DIR/add-widget-target.rb"
    
    if [ -f "$RUBY_SCRIPT" ]; then
        log_success "add-widget-target.rb script already exists"
    else
        log_info "Creating add-widget-target.rb script placeholder..."
        log_warn "The add-widget-target.rb script was not found."
        log_warn "Please ensure it exists in the scripts directory."
    fi
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
    create_xcode_script
    
    print_summary
}

main "$@"
