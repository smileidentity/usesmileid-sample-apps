import path from 'node:path';

// eslint-disable-next-line @typescript-eslint/no-require-imports
const { withHoistedEntry } = require('../metro-workspace-root') as {
  withHoistedEntry: (resolveRequest: Resolve | undefined, serverRoot: string) => Resolve;
};

type Resolution = { type: string; filePath?: string };
type Context = { originModulePath: string; resolveRequest: Resolve };
type Resolve = (context: Context, moduleName: string, platform: string | null) => Resolution;

const serverRoot = path.join('/repo', 'sample-apps', 'expo');
const entryOrigin = `${serverRoot}${path.sep}.`;
const echo: Resolve = (_context, moduleName) => ({ type: 'sourceFile', filePath: moduleName });
const from = (originModulePath: string): Context => ({ originModulePath, resolveRequest: echo });
const resolve = withHoistedEntry(undefined, serverRoot);

describe('withHoistedEntry', () => {
  it("resolves the dev server's entry request by package name, wherever the package is hoisted", () => {
    expect(resolve(from(entryOrigin), './node_modules/expo-router/entry', 'android').filePath).toBe(
      'expo-router/entry',
    );
  });

  it("leaves the export's relative entry alone", () => {
    expect(resolve(from(entryOrigin), './../../node_modules/expo-router/entry', 'android').filePath).toBe(
      './../../node_modules/expo-router/entry',
    );
  });

  it('leaves the same request from any other module alone', () => {
    const origin = path.join(serverRoot, 'app', 'index.ts');
    expect(resolve(from(origin), './node_modules/expo-router/entry', 'android').filePath).toBe(
      './node_modules/expo-router/entry',
    );
  });

  it('refuses a missing server root rather than silently rewriting nothing', () => {
    expect(() => withHoistedEntry(undefined, undefined as unknown as string)).toThrow(/server root/);
  });

  it('chains to an existing resolver', () => {
    const chained = withHoistedEntry((_context, moduleName) => ({ type: 'sourceFile', filePath: `chained:${moduleName}` }), serverRoot);
    expect(chained(from(entryOrigin), './node_modules/x', null).filePath).toBe('chained:x');
  });
});
