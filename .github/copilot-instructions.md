# Copilot instructions for Voltra

## Big picture
- Voltra is a React/React Native JSX-to-native-surface renderer for iOS Live Activities + Dynamic Island and Android Widgets/Glance. Public entrypoints are split into client, server, and platform namespaces (see [src/client.ts](src/client.ts), [src/server.ts](src/server.ts), [src/index.ts](src/index.ts)).
- Runtime flow: JSX components -> Voltra renderer -> compact JSON payload (see [src/renderer/renderer.ts](src/renderer/renderer.ts) and [src/live-activity/renderer.ts](src/live-activity/renderer.ts)), then optional Brotli compression on the server path (see [src/server.ts](src/server.ts)).
- Payload size is enforced for ActivityKit: a compressed base64 string must stay under the internal budget (see [src/payload.ts](src/payload.ts)).

## Codegen + schemas (critical workflow)
- Component definitions live in data/components.json and must conform to the schema in [schemas/components.schema.json](schemas/components.schema.json).
- Running npm run generate (see [package.json](package.json)) validates the schema and generates:
  - TS props + JSX exports in src/jsx/props (from generator output)
  - Payload short-name and component-id mappings in src/payload and src/android/payload
  - Swift parameters in ios/ui/Generated/Parameters and shared mappings in ios/shared
  - Kotlin parameters and mappings in android/src/main/java/voltra/...
- If you edit data/components.json or schema, regenerate before touching renderers or native code.

## Rendering constraints / conventions
- Only Voltra components created via createVoltraComponent are valid; host components and class components are rejected (see renderer checks in [src/renderer/renderer.ts](src/renderer/renderer.ts)).
- Text-only children rules mirror React Native: strings/numbers only inside Text-like components; booleans are ignored (see [src/renderer/renderer.ts](src/renderer/renderer.ts)).
- Live Activity variants are keyed into short JSON slots (ls, isl_exp_c, etc.) in [src/live-activity/renderer.ts](src/live-activity/renderer.ts).

## Build/test/dev workflows
- Core scripts: npm run build, test, lint, format:check, format:fix (see [package.json](package.json)).
- Example harness lives in example/ with helper scripts npm run harness:ios|harness:android that proxy into example (see [package.json](package.json)).
- The Expo config plugin wiring for native targets is in app.plugin.js and plugin/ (see [plugin/README.md](plugin/README.md)).

## Integration points
- Native module boundary is defined in [src/VoltraModule.ts](src/VoltraModule.ts) (Expo requireNativeModule).
- Public Voltra components are exported from [src/jsx/primitives.ts](src/jsx/primitives.ts); platform-specific Android primitives are in src/android/jsx.
