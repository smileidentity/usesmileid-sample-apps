import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';

// eslint-disable-next-line @typescript-eslint/no-require-imports
const { withShellExtension } = require('../metro-shell-extension') as {
  withShellExtension: (
    resolveRequest: Resolve | undefined,
    projectRoot: string,
    extension: string | undefined,
  ) => Resolve | undefined;
};

type Resolution = { type: string; filePath?: string };
type Context = { resolveRequest: Resolve };
type Resolve = (context: Context, moduleName: string, platform: string | null) => Resolution;

const repo = fs.realpathSync(fs.mkdtempSync(path.join(os.tmpdir(), 'metro-extension-')));
const projectRoot = path.join(repo, 'sample-apps', 'expo', 'app');
const stub = path.join(projectRoot, 'src', 'extension.ts');
const addOn = path.join(repo, 'sample-app-dev', 'extension.ts');
fs.mkdirSync(path.dirname(addOn), { recursive: true });
fs.writeFileSync(addOn, 'export const useSmileIDSampleShellExtension = null;\n');

afterAll(() => fs.rmSync(repo, { recursive: true, force: true }));

const resolvingTo =
  (filePath: string): Resolve =>
  () => ({ type: 'sourceFile', filePath });
const context = (filePath: string): Context => ({ resolveRequest: resolvingTo(filePath) });

describe('withShellExtension', () => {
  it('leaves the resolver alone when no extension is named', () => {
    const resolveRequest = resolvingTo(stub);
    expect(withShellExtension(resolveRequest, projectRoot, undefined)).toBe(resolveRequest);
    expect(withShellExtension(undefined, projectRoot, '')).toBeUndefined();
  });

  it("resolves the app's extension stub to the named module", () => {
    const resolve = withShellExtension(undefined, projectRoot, addOn)!;
    expect(resolve(context(stub), '../src/extension', 'android')).toEqual({ type: 'sourceFile', filePath: addOn });
  });

  it('resolves a relative module name against the app, not the working directory', () => {
    const resolve = withShellExtension(undefined, projectRoot, '../../../sample-app-dev/extension.ts')!;
    expect(resolve(context(stub), '../src/extension', 'android')).toEqual({ type: 'sourceFile', filePath: addOn });
  });

  it('refuses a module that does not exist, naming it', () => {
    const missing = path.join(repo, 'sample-app-dev', 'missing.ts');
    expect(() => withShellExtension(undefined, projectRoot, missing)).toThrow(missing);
  });

  it('passes every other module through unchanged', () => {
    const other = path.join(projectRoot, 'src', 'other.ts');
    const resolve = withShellExtension(undefined, projectRoot, addOn)!;
    expect(resolve(context(other), './other', 'ios')).toEqual({ type: 'sourceFile', filePath: other });
  });

  it('builds on a resolver the config already has', () => {
    const resolve = withShellExtension(resolvingTo(stub), projectRoot, addOn)!;
    expect(resolve(context(path.join(projectRoot, 'x.ts')), '../src/extension', null)).toEqual({
      type: 'sourceFile',
      filePath: addOn,
    });
  });
});
