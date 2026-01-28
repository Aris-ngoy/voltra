const path = require('path');

module.exports = {
  dependencies: {
    voltra: {
      root: path.resolve(__dirname, '../..'),
      platforms: {
        ios: {
          podspecPath: path.resolve(__dirname, '../../ios/Voltra.podspec'),
        },
        android: null, // Android not supported
      },
    },
  },
}
