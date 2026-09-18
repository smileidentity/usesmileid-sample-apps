/// The storage native module does not exist in a hostless runner, and the package ships this mock for it.
jest.mock('@react-native-async-storage/async-storage', () =>
  require('@react-native-async-storage/async-storage/jest/async-storage-mock'),
);
