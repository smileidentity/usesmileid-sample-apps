const path = require('node:path');

/** Resolves the app's extension stub to `extension`, the add-on an SDK repo's source build names; unset, nothing changes. */
const withShellExtension = (resolveRequest, projectRoot, extension) => {
  if (!extension) return resolveRequest;
  const stub = path.join(projectRoot, 'src', 'extension.ts');
  return (context, moduleName, platform) => {
    const resolution = (resolveRequest ?? context.resolveRequest)(context, moduleName, platform);
    return resolution.type === 'sourceFile' && resolution.filePath === stub
      ? { type: 'sourceFile', filePath: path.resolve(extension) }
      : resolution;
  };
};

module.exports = { withShellExtension };
