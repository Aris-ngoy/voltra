/* eslint-env node */
const path = require('path')
const { defineConfig } = require('eslint/config')
const tseslint = require('@typescript-eslint/eslint-plugin')
const tsParser = require('@typescript-eslint/parser')

const repoRoot = process.cwd()
const prettierConfig = require('eslint-config-prettier')
const simpleImportSort = require('eslint-plugin-simple-import-sort')

module.exports = defineConfig([
  prettierConfig,
  {
    ignores: ['build/*', 'plugin/build/*', 'website/doc_build/*', 'node_modules/*'],
  },
  {
    files: [
      'src/**/*.{ts,tsx}',
      'generator/**/*.{ts,tsx}',
      'apps/**/src/**/*.{ts,tsx}',
      'apps/**/app/**/*.{ts,tsx}',
    ],
    languageOptions: {
      parser: tsParser,
      ecmaVersion: 'latest',
      sourceType: 'module',
    },
    plugins: {
      '@typescript-eslint': tseslint,
      'simple-import-sort': simpleImportSort,
    },
    rules: {
      ...tseslint.configs.recommended.rules,
      'simple-import-sort/imports': 'error',
      'simple-import-sort/exports': 'error',
    },
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
    files: ['**/__tests__/**/*.{ts,tsx,js,jsx}'],
    rules: {
      '@typescript-eslint/no-explicit-any': 'off',
      '@typescript-eslint/ban-ts-comment': 'off',
      '@typescript-eslint/no-unused-vars': ['warn', { argsIgnorePattern: '^_' }],
    },
  },
  {
    files: [
      'src/renderer/**/*',
      'src/jsx/**/*',
      'src/payload/**/*',
      'src/live-activity/**/*',
      'src/widgets/**/*',
      'src/utils/**/*',
      'src/helpers.ts',
      'src/preload.ts',
    ],
    rules: {
      '@typescript-eslint/no-explicit-any': 'off',
    },
  },
  {
    files: ['src/VoltraModule.ts'],
    rules: {
      '@typescript-eslint/no-require-imports': 'off',
      '@typescript-eslint/no-explicit-any': 'off',
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
])
