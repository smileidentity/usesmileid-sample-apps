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

  it('a failed link only skips the launch session', async () => {
    const link = jest.fn(() => Promise.reject(new Error('secure storage refused the write')));
    await expect(linkLaunchSession({ launchSession: () => session }, link)).resolves.toBeUndefined();
  });

  it('an extension that fails to offer a session only skips it', async () => {
    const link = jest.fn(() => Promise.resolve());
    const failing = {
      launchSession: () => {
        throw new Error('no session to offer');
      },
    };
    await expect(linkLaunchSession(failing, link)).resolves.toBeUndefined();
    expect(link).not.toHaveBeenCalled();
  });

  it('awaits a session the extension offers asynchronously', async () => {
    const link = jest.fn(() => Promise.resolve());
    await linkLaunchSession({ launchSession: () => Promise.resolve(session) }, link);
    expect(link).toHaveBeenCalledWith(session);
  });

  it('an offer that rejects only skips the launch session', async () => {
    const link = jest.fn(() => Promise.resolve());
    const rejecting = { launchSession: () => Promise.reject(new Error('the test server did not start')) };
    await expect(linkLaunchSession(rejecting, link)).resolves.toBeUndefined();
    expect(link).not.toHaveBeenCalled();
  });
});
