module.exports = {
  presets: ['module:@react-native/babel-preset'],
  plugins: [
    // Enable namespace export syntax used by the shared Voltra build output
    '@babel/plugin-transform-export-namespace-from',
    [
      'module-resolver',
      {
        root: ['./'],
        alias: {
          voltra: '../../build',
          'voltra/client': '../../build/client',
        },
      },
    ],
  ],
};
