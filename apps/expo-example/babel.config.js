const path = require('node:path')

module.exports = function (api) {
  api.cache(true)
  return {
    presets: ['babel-preset-expo'],
    plugins: [
      // Needed for local testing of widget pre-rendering
      [
        'module-resolver',
        {
          alias: {
            voltra: path.resolve(__dirname, '../build'),
          },
        },
      ],
    ],
  }
}
