import { sourceBuildPlugins } from '../app.config';

describe('sourceBuildPlugins', () => {
  it('adds nothing when no source build names a plugin', () => {
    expect(sourceBuildPlugins(undefined)).toEqual([]);
    expect(sourceBuildPlugins('')).toEqual([]);
  });

  it('adds each plugin a source build names, in order', () => {
    expect(sourceBuildPlugins('./modules/usesmileid_testing/app.plugin.js, ./other.js')).toEqual([
      './modules/usesmileid_testing/app.plugin.js',
      './other.js',
    ]);
  });
});
