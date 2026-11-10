// eslint-disable-next-line @typescript-eslint/no-require-imports
const { TestEnvironment: ExpoEnvironment } = require('jest-expo/src/preset/nativeEnvironment');

/** jest-expo's environment, which leaves Expo's lazy globals unread at teardown, resolving packages as Node does. */
class UseSmileIDSampleTestEnvironment extends ExpoEnvironment {
  customExportConditions = ['node', 'node-addons'];
}

module.exports = UseSmileIDSampleTestEnvironment;
