import path from 'node:path';

const mockSuperproject = path.resolve(__dirname, '..', '..', '..', '..');

jest.mock('../metro-workspace-root', () => ({
  ...jest.requireActual('../metro-workspace-root'),
  outermostWorkspaceRoot: () => mockSuperproject,
}));

// eslint-disable-next-line @typescript-eslint/no-require-imports
const config = require('../metro.config') as {
  watchFolders: string[];
  server: { unstable_serverRoot?: string };
  resolver: { resolveRequest?: unknown };
};

describe('metro.config in a submodule', () => {
  it("watches the enclosing workspace but keeps Expo's own server root, which export's entry path is relative to", () => {
    expect(config.watchFolders).toEqual([mockSuperproject]);
    expect(config.server.unstable_serverRoot).not.toBe(mockSuperproject);
    // No extension named, so Metro keeps its own resolver: the shell adds one only for a source build's add-on.
    expect(config.resolver.resolveRequest ?? null).toBeNull();
  });
});
