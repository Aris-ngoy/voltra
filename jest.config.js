module.exports = {
  projects: [
    {
      displayName: 'React Native',
      preset: 'react-native',
      testEnvironment: 'node',
      transformIgnorePatterns: [
        'node_modules/(?!(@react-native|react-native|react-clone-referenced-element)/)',
      ],
      testMatch: ['<rootDir>/src/**/*.test.ts?(x)'],
      moduleNameMapper: {
        '^(\\.{1,2}/.*)\\.js$': '$1',
      },
    },
    {
      displayName: 'Node.js',
      preset: 'react-native',
      testEnvironment: 'node',
      transformIgnorePatterns: [
        'node_modules/(?!(@react-native|react-native|react-clone-referenced-element)/)',
      ],
      testMatch: ['<rootDir>/src/**/*.node.test.ts?(x)'],
      moduleNameMapper: {
        voltra: '<rootDir>/src/server.ts',
        '^(\\.{1,2}/.*)\\.js$': '$1',
      },
    },
  ],
}
