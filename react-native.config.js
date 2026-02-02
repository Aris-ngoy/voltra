module.exports = {
  dependency: {
    platforms: {
      ios: null,
      android: {
        sourceDir: './android',
        packageImportPath: 'import voltra.VoltraPackage;',
        packageInstance: 'new VoltraPackage()',
      },
    },
  },
}
