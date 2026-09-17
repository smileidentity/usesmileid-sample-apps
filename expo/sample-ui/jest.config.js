/** Test config for the shared UI package: the Expo preset supplies the React Native transform. */
module.exports = {
  preset: 'jest-expo',
  testEnvironment: 'node',
  roots: ['<rootDir>/test'],
  // The SDK is a peer the tests never call; stubbing it keeps a unit run off the native modules.
  moduleNameMapper: { '^@smileid/usesmileid$': '<rootDir>/test/stubs/usesmileid.ts' },
  snapshotResolver: '<rootDir>/test/snapshot-resolver.js',
  setupFiles: ['<rootDir>/test/setup.ts'],
  clearMocks: true,
};
