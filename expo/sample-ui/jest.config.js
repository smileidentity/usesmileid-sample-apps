// Set before the config is exported, so every worker inherits it: Node reads the zone once at
// startup and a baseline holding a clock time otherwise pins the machine that recorded it.
// It also moves a job across a day boundary, which regroups the list and moves a date header.
process.env.TZ = 'UTC';
// The day header is formatted by locale, so en-GB would render "Wed, 15 Jul 2026" and red every
// grouped baseline. Android pins the same pair on its own test JVM for the same reason.
process.env.LC_ALL = 'en_US.UTF-8';

const preset = require('jest-expo/jest-preset');

/** Test config for the shared UI package: the Expo preset supplies the React Native transform. */
module.exports = {
  preset: 'jest-expo',
  testEnvironment: 'node',
  roots: ['<rootDir>/test'],
  // The layout engine and pixelmatch ship as ESM, so they must reach Babel.
  transformIgnorePatterns: [
    preset.transformIgnorePatterns[0].replace('(?!(', '(?!(yoga-layout|pixelmatch|'),
    ...preset.transformIgnorePatterns.slice(1),
  ],
  // The SDK is a peer the tests never call; stubbing it keeps a unit run off the native modules.
  moduleNameMapper: { '^@smileid/usesmileid$': '<rootDir>/test/stubs/usesmileid.ts' },
  snapshotResolver: '<rootDir>/test/snapshot-resolver.js',
  setupFiles: ['<rootDir>/test/setup.ts'],
  clearMocks: true,
};
