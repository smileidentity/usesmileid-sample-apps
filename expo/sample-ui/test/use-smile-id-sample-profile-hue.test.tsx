import { act, render } from '@testing-library/react-native';
import { Text } from 'react-native';

import { avatarColorForProfile } from '../src/components/use-smile-id-sample-avatar';
import {
  UseSmileIDSampleStatus,
  smileIDSampleStatusFrom,
} from '../src/model/use-smile-id-sample-status';
import { smileProfileHues } from '../src/smile-product-hues';
import {
  useSmileIDSampleActiveProfile,
  useSmileIDSampleActiveProfileIndex,
  useSmileIDSampleProfileStore,
} from '../src/state/use-smile-id-sample-profile-store';
import {
  smileIDSampleFixtureProfiles,
} from '../src/state/use-smile-id-sample-profiles';

/// These four have no screen yet, so this is the call site that proves them before U2 and U3 arrive.
describe('the profile hue', () => {
  it('indexes the design list by position rather than hashing a name', () => {
    expect(avatarColorForProfile(0)).toBe(smileProfileHues[0]);
    expect(avatarColorForProfile(2)).toBe(smileProfileHues[2]);
  });

  it('cycles beyond the list rather than running off the end', () => {
    expect(avatarColorForProfile(smileProfileHues.length)).toBe(smileProfileHues[0]);
  });

  it('never returns undefined for a negative index, which a restored state can carry', () => {
    expect(avatarColorForProfile(-3)).toBe(smileProfileHues[0]);
  });
});

describe('a restored status', () => {
  it('resolves a value it recognises', () => {
    expect(smileIDSampleStatusFrom('Blocked')).toBe(UseSmileIDSampleStatus.Blocked);
  });

  it('falls back rather than throwing, so a rename cannot crash a restore', () => {
    expect(smileIDSampleStatusFrom('Renamed')).toBe(UseSmileIDSampleStatus.Processing);
    expect(smileIDSampleStatusFrom(null)).toBe(UseSmileIDSampleStatus.Processing);
    expect(smileIDSampleStatusFrom(undefined)).toBe(UseSmileIDSampleStatus.Processing);
  });
});

describe('the active profile', () => {
  afterEach(async () => {
    // Wrapped, because the store is subscribed by a mounted probe and React warns otherwise.
    await act(async () => {
      useSmileIDSampleProfileStore.getState().reset([]);
    });
  });

  const Probe = () => {
    const profile = useSmileIDSampleActiveProfile();
    const index = useSmileIDSampleActiveProfileIndex();
    return <Text testID="probe">{`${profile?.organisation ?? 'none'}|${index}`}</Text>;
  };

  it('is none on a plain launch, at position zero', async () => {
    const rendered = await render(<Probe />);
    expect(rendered.getByTestId('probe')).toHaveTextContent('none|0');
  });

  it('follows the active id, which is what picks the avatar hue', async () => {
    await act(async () => {
      useSmileIDSampleProfileStore.getState().reset(smileIDSampleFixtureProfiles());
      useSmileIDSampleProfileStore.getState().setActive('p-3');
    });
    const rendered = await render(<Probe />);
    expect(rendered.getByTestId('probe')).toHaveTextContent('PesaLink|2');
  });
});
