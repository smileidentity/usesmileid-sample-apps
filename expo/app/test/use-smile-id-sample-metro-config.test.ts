import path from 'node:path';

const mockSuperproject = path.resolve(__dirname, '..', '..', '..', '..');

jest.mock('../metro-workspace-root', () => ({
  ...jest.requireActual('../metro-workspace-root'),
  outermostWorkspaceRoot: () => mockSuperproject,
}));

type Resolution = { type: string; filePath?: string };
type Resolver = (context: ResolutionContext, moduleName: string, platform: string | null) => Resolution;
type ResolutionContext = { originModulePath: string; resolveRequest: Resolver };
type MetroConfig = {
  watchFolders: string[];
  server: { unstable_serverRoot: string };
  resolver: { resolveRequest?: Resolver | null };
};

// eslint-disable-next-line @typescript-eslint/no-require-imports
const config = require('../metro.config') as MetroConfig;

/// expo-font's entry where a submodule's install hoists it.
const hoistedFont = path.join(mockSuperproject, 'node_modules', 'expo-font', 'build', 'index');

/// Metro's own resolver in a submodule, which finds a hoisted package only by its path in the enclosing repo.
const enclosingOnly: Resolver = (_context, moduleName) => {
  if (moduleName === hoistedFont) return { type: 'sourceFile', filePath: moduleName };
  throw new Error(`Unable to resolve module ${moduleName}`);
};

/// Resolves `moduleName` from `origin` through the config's resolver.
const resolve = (origin: string, moduleName: string, metroResolver: Resolver = enclosingOnly): Resolution => {
  const resolveRequest = config.resolver.resolveRequest;
  if (!resolveRequest) throw new Error('metro.config sets no resolver in a submodule');
  return resolveRequest({ originModulePath: origin, resolveRequest: metroResolver }, moduleName, 'ios');
};

/// A resolver that finds every absolute path, so only the config's own guard can refuse one.
const anyAbsolutePath: Resolver = (_context, moduleName) => {
  if (path.isAbsolute(moduleName)) return { type: 'sourceFile', filePath: moduleName };
  throw new Error(`Unable to resolve module ${moduleName}`);
};

describe('metro.config in a submodule', () => {
  it("watches the enclosing workspace but keeps Expo's own server root, which export's entry path is relative to", () => {
    expect(config.watchFolders).toEqual([mockSuperproject]);
    expect(config.server.unstable_serverRoot).not.toBe(mockSuperproject);
  });

  it("resolves a lazy bundle's path from the server root in the enclosing workspace", () => {
    const serverRootOrigin = `${config.server.unstable_serverRoot}${path.sep}.`;

    expect(resolve(serverRootOrigin, './node_modules/expo-font/build/index')).toEqual({
      type: 'sourceFile',
      filePath: hoistedFont,
    });
  });

  it('reports the request Metro made when the enclosing workspace lacks the module too', () => {
    const serverRootOrigin = `${config.server.unstable_serverRoot}${path.sep}.`;

    expect(() => resolve(serverRootOrigin, './node_modules/missing/index')).toThrow(
      'Unable to resolve module ./node_modules/missing/index',
    );
  });

  it('never retries a request that climbs out of the enclosing workspace', () => {
    const serverRootOrigin = `${config.server.unstable_serverRoot}${path.sep}.`;

    expect(() => resolve(serverRootOrigin, './node_modules/../../../outside/index', anyAbsolutePath)).toThrow(
      'Unable to resolve module ./node_modules/../../../outside/index',
    );
  });

  it('retries a package whose folder name starts with two dots', () => {
    const serverRootOrigin = `${config.server.unstable_serverRoot}${path.sep}.`;

    expect(resolve(serverRootOrigin, './node_modules/..cache/index', anyAbsolutePath)).toEqual({
      type: 'sourceFile',
      filePath: path.join(mockSuperproject, 'node_modules', '..cache', 'index'),
    });
  });

  it('never retries a server-root request outside node_modules', () => {
    const serverRootOrigin = `${config.server.unstable_serverRoot}${path.sep}.`;

    expect(() => resolve(serverRootOrigin, './index', anyAbsolutePath)).toThrow('Unable to resolve module ./index');
  });

  it('leaves a request that fails from a source file failing', () => {
    const sourceFile = path.join(config.server.unstable_serverRoot, 'app', 'index.ts');

    expect(() => resolve(sourceFile, './missing')).toThrow('Unable to resolve module ./missing');
  });
});
