import path from 'node:path';

const mockExpoWorkspace = path.resolve(__dirname, '..', '..');

jest.mock('../metro-workspace-root', () => ({ outermostWorkspaceRoot: () => mockExpoWorkspace }));

// eslint-disable-next-line @typescript-eslint/no-require-imports
const config = require('../metro.config') as {
  server: { unstable_serverRoot: string };
  resolver: { resolveRequest?: unknown };
};

describe('metro.config in its own repository', () => {
  it("keeps Metro's own resolver when the workspace is the server root", () => {
    expect(config.server.unstable_serverRoot).toBe(mockExpoWorkspace);
    expect(config.resolver.resolveRequest ?? null).toBeNull();
  });
});
