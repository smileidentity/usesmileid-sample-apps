/** Finds the workspace Metro must watch: the outermost pnpm workspace above the app. */
const fs = require('node:fs');
const path = require('node:path');

/** The outermost pnpm-workspace.yaml up to the enclosing repository: `expo/` here, the superproject when checked out as a submodule. */
const outermostWorkspaceRoot = (start) => {
  let found = null;
  for (let dir = start; ; dir = path.dirname(dir)) {
    if (fs.existsSync(path.join(dir, 'pnpm-workspace.yaml'))) found = dir;
    // A submodule's .git is a file, so the walk continues to the superproject; a repository's is a folder.
    const atRepository = fs.statSync(path.join(dir, '.git'), { throwIfNoEntry: false })?.isDirectory();
    if (atRepository || dir === path.dirname(dir)) return found ?? path.resolve(start, '..');
  }
};

module.exports = { outermostWorkspaceRoot };
