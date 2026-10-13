const fs = require('node:fs');
const path = require('node:path');

/** Resolves the app's extension stub to `extension`, the add-on an SDK repo's source build names; unset, nothing changes. */
const withShellExtension = (resolveRequest, projectRoot, extension) => {
  if (!extension) return resolveRequest;
  const stub = path.join(projectRoot, 'src', 'extension.ts');
  const addOn = path.resolve(projectRoot, extension);
  if (!fs.existsSync(addOn)) throw new Error(`USESMILEID_SAMPLE_EXTENSION names ${addOn}, which does not exist`);
  return (context, moduleName, platform) => {
    const resolution = (resolveRequest ?? context.resolveRequest)(context, moduleName, platform);
    return resolution.type === 'sourceFile' && resolution.filePath === stub
      ? { type: 'sourceFile', filePath: addOn }
      : resolution;
  };
};

module.exports = { withShellExtension };
