// The root view hosts gesture handler, whose native module Jest has no build of.
import 'react-native-gesture-handler/jestSetup';

/// The storage native module does not exist in a hostless runner, and the package ships this mock for it.
jest.mock('@react-native-async-storage/async-storage', () =>
  require('@react-native-async-storage/async-storage/jest/async-storage-mock'),
);
