/** Finds the workspace Metro must watch: the outermost pnpm workspace above the app. */
const fs = require('node:fs');
const path = require('node:path');

/** The outermost ancestor holding a pnpm-workspace.yaml: `expo/` here, the enclosing repo when checked out as a submodule. */
const outermostWorkspaceRoot = (start) => {
  let found = null;
  for (let dir = start; ; dir = path.dirname(dir)) {
    if (fs.existsSync(path.join(dir, 'pnpm-workspace.yaml'))) found = dir;
    if (dir === path.dirname(dir)) return found ?? path.resolve(start, '..');
  }
};

module.exports = { outermostWorkspaceRoot };
