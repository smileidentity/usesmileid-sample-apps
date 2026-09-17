/** Goldens live beside the suite in test/goldens, one file per component, so a state is easy to find. */
const path = require('path');

module.exports = {
  resolveSnapshotPath: (testPath, extension) =>
    path.join(path.dirname(testPath), 'goldens', `${path.basename(testPath)}${extension}`),
  resolveTestPath: (snapshotPath, extension) =>
    path.join(
      path.dirname(path.dirname(snapshotPath)),
      path.basename(snapshotPath, extension),
    ),
  testPathForConsistencyCheck: path.join('test', 'some.test.tsx'),
};
