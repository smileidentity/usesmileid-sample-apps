/** Metro for a pnpm workspace: the shared package is a sibling, so its source has to be watched. */
const path = require('node:path');

const { getDefaultConfig } = require('expo/metro-config');

const { outermostWorkspaceRoot } = require('./metro-workspace-root');

const projectRoot = __dirname;
// Outermost: in a submodule, node_modules is hoisted to the enclosing repo.
const workspaceRoot = outermostWorkspaceRoot(projectRoot);

const config = getDefaultConfig(projectRoot);

config.watchFolders = [workspaceRoot];
// Hoisted by .npmrc, so the app's own folder comes first and the workspace root is the fallback.
config.resolver.nodeModulesPaths = [
  path.resolve(projectRoot, 'node_modules'),
  path.resolve(workspaceRoot, 'node_modules'),
];

module.exports = config;
