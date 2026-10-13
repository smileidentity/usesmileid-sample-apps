import path from 'node:path';

const mockSuperproject = path.resolve(__dirname, '..', '..', '..', '..');

jest.mock('../metro-workspace-root', () => ({ outermostWorkspaceRoot: () => mockSuperproject }));

// eslint-disable-next-line @typescript-eslint/no-require-imports
const config = require('../metro.config') as {
  watchFolders: string[];
  server: { unstable_serverRoot?: string };
};

describe('metro.config in a submodule', () => {
  it('serves from the enclosing workspace it watches, where the hoisted entry lives', () => {
    expect(config.watchFolders).toEqual([mockSuperproject]);
    expect(config.server.unstable_serverRoot).toBe(mockSuperproject);
  });
});
