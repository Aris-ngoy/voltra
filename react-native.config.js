module.exports = {
  dependency: {
    platforms: {
      ios: {
        // iOS pod is manually added to Podfile since auto-linking doesn't work
        // with the library's structure (podspec in ios/ subfolder)
      },
      android: {
        sourceDir: './android',
        packageImportPath: 'import voltra.VoltraPackage;',
        packageInstance: 'new VoltraPackage()',
      },
    },
  },
}
