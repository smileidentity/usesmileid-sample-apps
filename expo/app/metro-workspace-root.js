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

module.exports = { outermostWorkspaceRoot };
