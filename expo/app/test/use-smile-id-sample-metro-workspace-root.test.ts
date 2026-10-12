import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';

// eslint-disable-next-line @typescript-eslint/no-require-imports
const { outermostWorkspaceRoot } = require('../metro-workspace-root') as {
  outermostWorkspaceRoot: (start: string) => string;
};

const made: string[] = [];

const repo = (dir: string): void => fs.mkdirSync(path.join(dir, '.git'));
const submodule = (dir: string): void => fs.writeFileSync(path.join(dir, '.git'), 'gitdir: ../.git/modules/x\n');

const tree = (...markers: string[]): { root: string; app: string } => {
  const root = fs.realpathSync(fs.mkdtempSync(path.join(os.tmpdir(), 'metro-root-')));
  made.push(root);
  const app = path.join(root, 'sdk', 'sample-apps', 'expo', 'app');
  fs.mkdirSync(app, { recursive: true });
  for (const dir of markers) fs.writeFileSync(path.join(root, dir, 'pnpm-workspace.yaml'), 'packages: []\n');
  return { root, app };
};

afterAll(() => {
  for (const root of made) fs.rmSync(root, { recursive: true, force: true });
});

describe('outermostWorkspaceRoot', () => {
  it('is the expo workspace in a standalone checkout', () => {
    const { root, app } = tree('sdk/sample-apps/expo');
    expect(outermostWorkspaceRoot(app)).toBe(path.join(root, 'sdk', 'sample-apps', 'expo'));
  });

  it('is the enclosing repo when checked out as a submodule of a pnpm workspace', () => {
    const { root, app } = tree('sdk/sample-apps/expo', 'sdk');
    expect(outermostWorkspaceRoot(app)).toBe(path.join(root, 'sdk'));
  });

  it('stops at the repository, ignoring a workspace marker above a standalone clone', () => {
    const { root, app } = tree('sdk/sample-apps/expo', '');
    repo(path.join(root, 'sdk', 'sample-apps'));
    expect(outermostWorkspaceRoot(app)).toBe(path.join(root, 'sdk', 'sample-apps', 'expo'));
  });

  it('walks through a submodule to its superproject, and no further', () => {
    const { root, app } = tree('sdk/sample-apps/expo', 'sdk', '');
    submodule(path.join(root, 'sdk', 'sample-apps'));
    repo(path.join(root, 'sdk'));
    expect(outermostWorkspaceRoot(app)).toBe(path.join(root, 'sdk'));
  });

  it('falls back to the parent folder when no workspace marker exists', () => {
    const { root, app } = tree();
    expect(outermostWorkspaceRoot(app)).toBe(path.join(root, 'sdk', 'sample-apps', 'expo'));
  });
});
