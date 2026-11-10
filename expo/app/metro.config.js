/** Metro for a pnpm workspace: the shared package is a sibling, so its source has to be watched. */
const path = require('node:path');

const { getDefaultConfig } = require('expo/metro-config');

const { withShellExtension } = require('./metro-shell-extension');
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

const serverRoot = config.server.unstable_serverRoot;

/** Retries a request Metro makes from the server root, as a debug build's lazy bundle does, in the enclosing workspace. */
const withEnclosingWorkspace = (resolveRequest) => (context, moduleName, platform) => {
  const resolve = resolveRequest ?? context.resolveRequest;
  try {
    return resolve(context, moduleName, platform);
  } catch (error) {
    if (path.resolve(context.originModulePath) !== serverRoot || !moduleName.startsWith('./')) throw error;
    return resolve(context, path.join(workspaceRoot, moduleName), platform);
  }
};

config.resolver.resolveRequest = withShellExtension(
  workspaceRoot === serverRoot ? config.resolver.resolveRequest : withEnclosingWorkspace(config.resolver.resolveRequest),
  projectRoot,
  process.env.USESMILEID_SAMPLE_EXTENSION,
);

module.exports = config;
