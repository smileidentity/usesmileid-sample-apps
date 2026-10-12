import { useSmileIDSampleShellExtension } from '../src/extension';

describe('the shell extension', () => {
  it('is absent from a registry build', () => {
    expect(useSmileIDSampleShellExtension).toBeNull();
  });
});
