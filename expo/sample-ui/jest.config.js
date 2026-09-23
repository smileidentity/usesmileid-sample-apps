// Set before the config is exported, so every worker inherits it: Node reads the zone once at
// startup and a baseline holding a clock time otherwise pins the machine that recorded it.
// It also moves a job across a day boundary, which regroups the list and moves a date header.
process.env.TZ = 'UTC';
// The day header is formatted by locale, so en-GB would render "Wed, 15 Jul 2026" and red every
// grouped baseline. Android pins the same pair on its own test JVM for the same reason.
process.env.LC_ALL = 'en_US.UTF-8';

const preset = require('jest-expo/jest-preset');

const BABEL = '\\.[jt]sx?$';

/// A platform preset, with the base preset's Babel root so this package's sources still transform.
const forPlatform = (platform) => {
  const platformPreset = { ...require(`jest-expo/${platform}/jest-preset`) };
  // A root-only option, so a project that inherits it warns on every run.
  delete platformPreset.watchPlugins;
  const [, baseOptions] = preset.transform[BABEL];
  const [, platformOptions] = platformPreset.transform[BABEL];
  return {
    ...platformPreset,
    transform: { ...platformPreset.transform, [BABEL]: ['babel-jest', { ...baseOptions, caller: platformOptions.caller }] },
    testEnvironment: 'node',
    roots: ['<rootDir>/test'],
    // The layout engine and pixelmatch ship as ESM, so they must reach Babel.
    transformIgnorePatterns: [
      platformPreset.transformIgnorePatterns[0].replace('(?!(', '(?!(yoga-layout|pixelmatch|'),
      ...platformPreset.transformIgnorePatterns.slice(1),
    ],
    // The SDK is a peer the tests never call; stubbing it keeps a unit run off the native modules.
    moduleNameMapper: {
      ...platformPreset.moduleNameMapper,
      '^@smileid/usesmileid$': '<rootDir>/test/stubs/usesmileid.ts',
    },
    snapshotResolver: '<rootDir>/test/snapshot-resolver.js',
    setupFiles: [...platformPreset.setupFiles, '<rootDir>/test/setup.ts'],
    clearMocks: true,
  };
};

/** Test config for the shared UI package: the goldens under iOS resolution, and Android's own branches under Android's. */
module.exports = {
  projects: [
    { ...forPlatform('ios'), displayName: 'ios', testPathIgnorePatterns: ['\\.android\\.test\\.tsx?$'] },
    // Android-only files and Platform.OS branches never resolve under the iOS preset, so they get a project of their own.
    { ...forPlatform('android'), displayName: 'android', testMatch: ['<rootDir>/test/**/*.android.test.ts?(x)'] },
  ],
};
