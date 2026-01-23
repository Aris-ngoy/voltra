const path = require('path');
const exclusionList = require('metro-config/src/defaults/exclusionList');
const {getDefaultConfig, mergeConfig} = require('@react-native/metro-config');

const projectRoot = __dirname;
const monorepoRoot = path.resolve(projectRoot, '../..');

const escapeForRegex = (value) => value.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');

/**
 * Metro configuration
 * https://reactnative.dev/docs/metro
 *
 * @type {import('@react-native/metro-config').MetroConfig}
 */
const config = {
  watchFolders: [monorepoRoot],
  resolver: {
    // Avoid bundling duplicate React/React Native copies from the monorepo root
    blockList: exclusionList([
      new RegExp(`${escapeForRegex(path.resolve(monorepoRoot, 'node_modules/react'))}/.*`),
      new RegExp(`${escapeForRegex(path.resolve(monorepoRoot, 'node_modules/react-native'))}/.*`),
    ]),
    nodeModulesPaths: [
      path.resolve(projectRoot, 'node_modules'),
      path.resolve(monorepoRoot, 'node_modules'),
    ],
    extraNodeModules: {
      react: path.resolve(projectRoot, 'node_modules/react'),
      'react-native': path.resolve(projectRoot, 'node_modules/react-native'),
      voltra: path.resolve(monorepoRoot, 'build'),
      'voltra/client': path.resolve(monorepoRoot, 'build/client'),
    },
  },
};

module.exports = mergeConfig(getDefaultConfig(__dirname), config);
