// Set before the config is exported, so every worker inherits it: Node reads the zone once, at startup.
process.env.TZ = 'UTC';
process.env.LC_ALL = 'en_US.UTF-8';

/** Test config for the shell: the Expo preset supplies the React Native transform. */
const preset = require('jest-expo/jest-preset');

module.exports = {
  preset: 'jest-expo',
  testEnvironment: 'node',
  roots: ['<rootDir>/test'],
  // The SDK ships ESM, so the preset's first pattern has to let it reach Babel like a source file.
  transformIgnorePatterns: [
    preset.transformIgnorePatterns[0].replace('(?!(', '(?!(@smileid/usesmileid|yoga-layout|'),
    ...preset.transformIgnorePatterns.slice(1),
  ],
  // The real SDK, not a stub: the flow host's gate calls its validators, and stubbing them would
  // make the one test that catches a configuration the SDK rejects assert nothing.
  setupFiles: ['<rootDir>/test/setup.ts'],
  clearMocks: true,
};
