/* eslint-env node */
const path = require('path')
const { defineConfig } = require('eslint/config')

const repoRoot = process.cwd()
const prettierConfig = require('eslint-config-prettier')
const simpleImportSort = require('eslint-plugin-simple-import-sort')

module.exports = defineConfig([
  prettierConfig,
  {
    ignores: ['build/*', 'plugin/build/*', 'website/doc_build/*', 'node_modules/*'],
  },
  defineConfig([
    {
      basePath: 'example',
      settings: {
        'import/resolver': {
          alias: {
            map: [
              ['voltra', path.join(repoRoot, 'src')],
              ['~', path.join(repoRoot, 'example')],
            ],
            extensions: ['.ts', '.tsx', '.js', '.jsx'],
          },
        },
      },
    },
    {
      files: ['**/babel.config.js'],
      languageOptions: {
        globals: {
          __dirname: 'readonly',
        },
      },
    },
    {
      plugins: {
        'simple-import-sort': simpleImportSort,
      },
      rules: {
        'simple-import-sort/imports': 'error',
        'simple-import-sort/exports': 'error',
      },
    },
  ]),
])
