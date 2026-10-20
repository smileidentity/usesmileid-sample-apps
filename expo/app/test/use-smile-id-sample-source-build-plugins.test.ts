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

  it('says so when a build is no longer the registry build', () => {
    const warn = jest.spyOn(console, 'warn').mockImplementation(() => undefined);
    process.env.USESMILEID_SAMPLE_PLUGINS = './other.js';
    try {
      jest.isolateModules(() => {
        // eslint-disable-next-line @typescript-eslint/no-require-imports
        require('../app.config');
      });
      expect(warn).toHaveBeenCalledWith(expect.stringContaining('./other.js'));
    } finally {
      delete process.env.USESMILEID_SAMPLE_PLUGINS;
      warn.mockRestore();
    }
  });
});
