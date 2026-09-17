const js = require('@eslint/js');
const expo = require('eslint-config-expo/flat');
const tseslint = require('typescript-eslint');

/** Flat config for both workspace packages; the Expo config supplies the React Native globals. */
module.exports = tseslint.config(
  { ignores: ['**/node_modules/**', '**/dist/**', '**/.expo/**', 'app/android/**', 'app/ios/**'] },
  js.configs.recommended,
  ...expo,
  ...tseslint.configs.recommended,
  {
    files: ['**/*.{ts,tsx}'],
    rules: {
      // The generated token files are the only place a hex literal may appear.
      'no-restricted-syntax': [
        'error',
        {
          selector: "Literal[value=/^#(?:[0-9a-fA-F]{3,4}|[0-9a-fA-F]{6}|[0-9a-fA-F]{8})$/]",
          message: 'A hex literal is a review failure: resolve the colour from a token instead.',
        },
      ],
      '@typescript-eslint/consistent-type-imports': ['error', { fixStyle: 'inline-type-imports' }],
      '@typescript-eslint/no-unused-vars': ['error', { argsIgnorePattern: '^_' }],
    },
  },
  {
    // A const and a type of one name occupy different declaration spaces in TypeScript, which is the
    // enum-like idiom these models use so a caller can name the same thing as a value and as a type.
    files: ['sample-ui/src/model/**'],
    rules: { '@typescript-eslint/no-redeclare': 'off' },
  },
  {
    // CommonJS by necessity: eslint and jest both load their config before any ESM loader exists.
    files: ['eslint.config.js', '**/jest.config.js', '**/metro.config.js', 'sample-ui/test/snapshot-resolver.js'],
    rules: { '@typescript-eslint/no-require-imports': 'off' },
  },
  {
    // Metro resolves a font asset through require; an import of a .ttf yields no module id.
    files: ['sample-ui/src/theme/smile-fonts.ts'],
    rules: { '@typescript-eslint/no-require-imports': 'off' },
  },
  {
    // GENERATED: the emitter owns these files and the hex values are the point of them.
    files: ['sample-ui/src/tokens.ts', 'sample-ui/src/smile-product-hues.ts'],
    rules: { 'no-restricted-syntax': 'off' },
  },
  {
    // The pinned goldens name the states whose two schemes match, which is prose, not colour.
    files: ['sample-ui/test/**'],
    rules: { '@typescript-eslint/no-non-null-assertion': 'off' },
  },
);
