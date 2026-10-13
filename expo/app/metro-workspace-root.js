const fs = require('node:fs');
const path = require('node:path');

/** The outermost pnpm workspace up to the enclosing repository: `expo/`, or the superproject of a submodule. */
const outermostWorkspaceRoot = (start) => {
  let found = null;
  for (let dir = start; ; dir = path.dirname(dir)) {
    if (fs.existsSync(path.join(dir, 'pnpm-workspace.yaml'))) found = dir;
    // A submodule's .git is a file; a repository's is a folder.
    const atRepository = fs.statSync(path.join(dir, '.git'), { throwIfNoEntry: false })?.isDirectory();
    if (atRepository || dir === path.dirname(dir)) return found ?? path.resolve(start, '..');
  }
};

const HOISTED = './node_modules/';

/** Resolves the dev server's `./node_modules/<pkg>` entry by package name, since a submodule's packages are hoisted above its server root. */
const withHoistedEntry = (resolveRequest, serverRoot) => (context, moduleName, platform) => {
  const resolve = resolveRequest ?? context.resolveRequest;
  const entry = path.dirname(context.originModulePath) === serverRoot && moduleName.startsWith(HOISTED);
  return resolve(context, entry ? moduleName.slice(HOISTED.length) : moduleName, platform);
};

module.exports = { outermostWorkspaceRoot, withHoistedEntry };
