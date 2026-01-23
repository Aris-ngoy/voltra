# Voltra Live Activity - Bare React Native Example

A minimal React Native 0.79 example demonstrating Voltra Live Activities with **old architecture** support.

## Features

- 🎯 Simple Timer Live Activity example
- 📱 Lock Screen and Dynamic Island support
- 🏗️ Old architecture (Bridge) compatible
- ⚡ Minimal setup

## Prerequisites

- Node.js >= 18
- Xcode 15+
- iOS 17.0+ device or simulator
- CocoaPods
- Ruby gem `xcodeproj` (for setup script)

## Setup

### 1. Install dependencies

```bash
npm install
```

### 2. Setup Widget Extension (first time only)

The widget extension is required for Live Activities to work. Run the setup script:

```bash
# Generate widget extension files
./scripts/setup-widget-extension.sh --group-id "group.your.app" --url-scheme "yourapp"

# Install xcodeproj gem (if not installed)
gem install xcodeproj

# Add widget target to Xcode project
ruby scripts/add-widget-target.rb
```

### 3. Install CocoaPods

```bash
cd ios && pod install && cd ..
```

### 4. Configure Signing in Xcode

1. Open `ios/rnExample.xcworkspace` in Xcode
2. Select the `rnExample` target and configure your team/signing
3. Select the `rnExampleLiveActivity` target and configure your team/signing
4. Both targets need the same development team

### 5. Run the app

```bash
npm run ios
```

## Project Structure

```
rnExample/
├── App.tsx                              # Main app with Live Activity controls
├── src/
│   └── components/
│       ├── TimerLiveActivity.tsx        # Live Activity hook
│       └── TimerLiveActivityUI.tsx      # UI components for the Live Activity
├── ios/
│   ├── Podfile                          # iOS dependencies
│   └── rnExampleLiveActivity/           # Widget extension (auto-generated)
│       ├── Info.plist
│       ├── VoltraWidgetBundle.swift
│       ├── VoltraWidgetInitialStates.swift
│       ├── rnExampleLiveActivity.entitlements
│       └── Assets.xcassets/
├── scripts/
│   ├── setup-widget-extension.sh        # Generates widget extension files
│   └── add-widget-target.rb             # Adds widget target to Xcode project
├── metro.config.js                      # Metro bundler config
├── babel.config.js                      # Babel config with module resolver
└── react-native.config.js               # RN config for Voltra linking
```

## How It Works

The example uses the `useLiveActivity` hook from Voltra to manage a Timer Live Activity:

```tsx
import { useLiveActivity } from 'voltra/client'

const { start, update, end, isActive } = useLiveActivity(
  {
    lockScreen: <TimerLockScreen />,
    island: {
      minimal: <TimerIslandMinimal />,
      compact: {
        leading: <TimerIslandCompactLeading />,
        trailing: <TimerIslandCompactTrailing />,
      },
      expanded: {
        leading: <TimerIslandExpandedLeading />,
        trailing: <TimerIslandExpandedTrailing />,
        bottom: <TimerIslandExpandedBottom />,
      },
    },
  },
  {
    activityName: 'timer',
    autoUpdate: true,
  }
)
```

## Scripts

### setup-widget-extension.sh

Generates all necessary files for the iOS widget extension:

```bash
./scripts/setup-widget-extension.sh [options]

Options:
  --target-name       Name of the widget extension target (default: {AppName}LiveActivity)
  --bundle-id         Bundle identifier suffix (default: same as target-name)
  --group-id          App Group identifier for sharing data (optional)
  --deployment-target iOS deployment target (default: 17.0)
  --url-scheme        URL scheme for deep linking (optional)
```

### add-widget-target.rb

Adds the widget extension target to the Xcode project:

```bash
ruby scripts/add-widget-target.rb
```

Requires the `xcodeproj` Ruby gem: `gem install xcodeproj`

## Architecture

This example uses the **old architecture** (Bridge) instead of the New Architecture (TurboModules/Fabric). This is configured in:

- `app.json`: `"newArchEnabled": false`

## Notes

- Live Activities require iOS 16.1+ and are best experienced on devices with Dynamic Island (iPhone 14 Pro and later)
- The Lock Screen widget works on all iOS 16.1+ devices
- Make sure to run on a physical device to test Dynamic Island features
- The widget extension requires proper code signing - make sure to configure your team in Xcode

## Step 3: Modify your app

Now that you have successfully run the app, let's make changes!

Open `App.tsx` in your text editor of choice and make some changes. When you save, your app will automatically update and reflect these changes — this is powered by [Fast Refresh](https://reactnative.dev/docs/fast-refresh).

When you want to forcefully reload, for example to reset the state of your app, you can perform a full reload:

- **Android**: Press the <kbd>R</kbd> key twice or select **"Reload"** from the **Dev Menu**, accessed via <kbd>Ctrl</kbd> + <kbd>M</kbd> (Windows/Linux) or <kbd>Cmd ⌘</kbd> + <kbd>M</kbd> (macOS).
- **iOS**: Press <kbd>R</kbd> in iOS Simulator.

## Congratulations! :tada:

You've successfully run and modified your React Native App. :partying_face:

### Now what?

- If you want to add this new React Native code to an existing application, check out the [Integration guide](https://reactnative.dev/docs/integration-with-existing-apps).
- If you're curious to learn more about React Native, check out the [docs](https://reactnative.dev/docs/getting-started).

# Troubleshooting

If you're having issues getting the above steps to work, see the [Troubleshooting](https://reactnative.dev/docs/troubleshooting) page.

# Learn More

To learn more about React Native, take a look at the following resources:

- [React Native Website](https://reactnative.dev) - learn more about React Native.
- [Getting Started](https://reactnative.dev/docs/environment-setup) - an **overview** of React Native and how setup your environment.
- [Learn the Basics](https://reactnative.dev/docs/getting-started) - a **guided tour** of the React Native **basics**.
- [Blog](https://reactnative.dev/blog) - read the latest official React Native **Blog** posts.
- [`@facebook/react-native`](https://github.com/facebook/react-native) - the Open Source; GitHub **repository** for React Native.
