![voltra-banner](https://use-voltra.dev/voltra-baner.jpg)

### Build Live Activities with JSX in React Native

[![mit licence][license-badge]][license] [![npm downloads][npm-downloads-badge]][npm-downloads] [![PRs Welcome][prs-welcome-badge]][prs-welcome]

Voltra turns React Native JSX into SwiftUI so you can ship custom Live Activities, Dynamic Island layouts without touching Xcode. Author everything in React, keep hot reload, and let the config plugin handle the extension targets.

## Features

- **Ship Native iOS Surfaces**: Create Live Activities, Dynamic Island variants, and static widgets directly from React components - no Swift or Xcode required.

- **Fast Development Workflow**: Hooks respect Fast Refresh and both JS and native layers enforce ActivityKit payload budgets.

- **Production-Ready Push Notifications**: Collect ActivityKit push tokens and push-to-start tokens, stream lifecycle updates, and build server-driven refreshes.

- **Familiar Styling**: Use React Native style props and ordered SwiftUI modifiers in one place.

- **Type-Safe & Developer-Friendly**: The Voltra schema, hooks, and examples ship with TypeScript definitions, tests, and docs so AI coding agents stay productive.

- **Works With Your Setup**: Compatible with Expo Dev Client and bare React Native projects. The config plugin automatically wires iOS extension targets for you.

## Documentation

The documentation is available at [use-voltra.dev](https://use-voltra.dev). You can also use the following links to jump to specific topics:

- [Quick Start](https://use-voltra.dev/docs/getting-started/quick-start)
- [API Reference](https://use-voltra.dev/docs/api/overview)
- [Examples](https://use-voltra.dev/docs/examples)

## Getting started

> [!NOTE]  
> The library isn't supported in Expo Go. To set it up correctly, you need to use [Expo Dev Client](https://docs.expo.dev/versions/latest/sdk/dev-client/).

Install the package:

```sh
npm install voltra
```

Add the config plugin to your `app.json`:

```json
{
  "expo": {
    "plugins": ["voltra"]
  }
}
```

Then run `npx expo prebuild --clean` to generate the iOS extension target.

See the [documentation](https://use-voltra.dev/docs/getting-started/quick-start) for detailed setup instructions.

## Bare React Native (iOS) setup

1) Install Voltra in your app:

```sh
npm install voltra
```

2) Point Metro at a single copy of React/React Native (prevents the "Invalid hook call" error in monorepos or file-linked packages). Add this to your `metro.config.js`:

```js
const path = require('path')
const exclusionList = require('metro-config/src/defaults/exclusionList')
const { getDefaultConfig, mergeConfig } = require('@react-native/metro-config')

const projectRoot = __dirname
const workspaceRoot = path.resolve(projectRoot, '..') // adjust to your monorepo root
const escapeForRegex = (value) => value.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')

const config = {
  watchFolders: [workspaceRoot],
  resolver: {
    blockList: exclusionList([
      new RegExp(`${escapeForRegex(path.resolve(workspaceRoot, 'node_modules/react'))}/.*`),
      new RegExp(`${escapeForRegex(path.resolve(workspaceRoot, 'node_modules/react-native'))}/.*`),
    ]),
    nodeModulesPaths: [
      path.resolve(projectRoot, 'node_modules'),
      path.resolve(workspaceRoot, 'node_modules'),
    ],
    extraNodeModules: {
      react: path.resolve(projectRoot, 'node_modules/react'),
      'react-native': path.resolve(projectRoot, 'node_modules/react-native'),
      voltra: path.resolve(workspaceRoot, 'node_modules/voltra/build'),
      'voltra/client': path.resolve(workspaceRoot, 'node_modules/voltra/build/client'),
    },
  },
}

module.exports = mergeConfig(getDefaultConfig(__dirname), config)
```

3) Create the iOS Live Activity/Widget extension. A turnkey script lives in [apps/rnExample/scripts/setup-widget-extension.sh](apps/rnExample/scripts/setup-widget-extension.sh); copy it into your project (e.g., `scripts/`) and run:

```sh
chmod +x scripts/setup-widget-extension.sh
./scripts/setup-widget-extension.sh \
  --target-name MyAppLiveActivity \
  --bundle-id MyAppLiveActivity \
  --group-id group.com.mycompany.myapp   # optional, for shared data
```

Then add the target to your Xcode project (the script prints the exact steps) or run the helper Ruby script if you copied [apps/rnExample/scripts/add-widget-target.rb](apps/rnExample/scripts/add-widget-target.rb) (`gem install xcodeproj` required). Finally run `cd ios && pod install`, open the workspace, and configure signing for the new extension.

4) Build for iOS (Live Activities are iOS-only) and use the `useLiveActivity` hook as shown below.

## Quick example

```tsx
import { useLiveActivity } from 'voltra/client'
import { Voltra } from 'voltra'

export function OrderTracker({ orderId }: { orderId: string }) {
  const ui = (
    <Voltra.VStack style={{ padding: 16, borderRadius: 14, backgroundColor: '#111827' }}>
      <Voltra.Text style={{ color: 'white', fontSize: 18, fontWeight: '700' }}>Order #{orderId}</Voltra.Text>
      <Voltra.Text style={{ color: '#9CA3AF', marginTop: 6 }}>Driver en route · ETA 12 min</Voltra.Text>
    </Voltra.VStack>
  )

  const { start, update, end } = useLiveActivity(
    { lockScreen: ui },
    {
      activityName: `order-${orderId}`,
      autoStart: true,
      deepLinkUrl: `/orders/${orderId}`,
    }
  )

  return null
}
```

## Platform compatibility

**Note:** This module is intended for use on **iOS devices only**.

## Authors

`voltra` is an open source collaboration between [Saúl Sharma](https://github.com/saul-sharma) and [Szymon Chmal](https://github.com/szymonchmal) at [Callstack][callstack-readme-with-love].

If you think it's cool, please star it 🌟. This project will always remain free to use.

[Callstack][callstack-readme-with-love] is a group of React and React Native geeks, contact us at [hello@callstack.com](mailto:hello@callstack.com) if you need any help with these or just want to say hi!

Like the project? ⚛️ [Join the Callstack team](https://callstack.com/careers/?utm_campaign=Senior_RN&utm_source=github&utm_medium=readme) who does amazing stuff for clients and drives React Native Open Source! 🔥

[callstack-readme-with-love]: https://callstack.com/?utm_source=github.com&utm_medium=referral&utm_campaign=voltra&utm_term=readme-with-love
[license-badge]: https://img.shields.io/npm/l/voltra?style=for-the-badge
[license]: https://github.com/callstackincubator/voltra/blob/main/LICENSE.txt
[npm-downloads-badge]: https://img.shields.io/npm/dm/voltra?style=for-the-badge
[npm-downloads]: https://www.npmjs.com/package/voltra
[prs-welcome-badge]: https://img.shields.io/badge/PRs-welcome-brightgreen.svg?style=for-the-badge
[prs-welcome]: ./CONTRIBUTING.md
