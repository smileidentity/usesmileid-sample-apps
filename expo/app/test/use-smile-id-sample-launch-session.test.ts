import type { UseSmileIDSampleTokenSession } from '@smileid/sample-ui';

import { linkLaunchSession } from '../src/use-smile-id-sample-shell-extension';

const session = { id: 'launch-session' } as unknown as UseSmileIDSampleTokenSession;

describe('linkLaunchSession', () => {
  it('links the session the extension offers at launch', async () => {
    const link = jest.fn(() => Promise.resolve());
    await linkLaunchSession({ launchSession: () => session }, link);
    expect(link).toHaveBeenCalledWith(session);
  });

  it('links nothing without an extension or when it offers none', async () => {
    const link = jest.fn(() => Promise.resolve());
    await linkLaunchSession(null, link);
    await linkLaunchSession({}, link);
    await linkLaunchSession({ launchSession: () => null }, link);
    expect(link).not.toHaveBeenCalled();
  });
});
