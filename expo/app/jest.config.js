// Set before the config is exported, so every worker inherits it: Node reads the zone once, at startup.
process.env.TZ = 'UTC';
process.env.LC_ALL = 'en_US.UTF-8';

/** Test config for the shell: the Expo preset supplies the React Native transform. */
module.exports = {
  preset: 'jest-expo',
  testEnvironment: 'node',
  roots: ['<rootDir>/test'],
  // The SDK is a peer the tests never call; the library already ships the stub this points at.
  moduleNameMapper: { '^@smileid/usesmileid$': '<rootDir>/../sample-ui/test/stubs/usesmileid.ts' },
  setupFiles: ['<rootDir>/test/setup.ts'],
  clearMocks: true,
};
