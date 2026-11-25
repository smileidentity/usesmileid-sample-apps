import * as Haptics from 'expo-haptics';

import { smileIDSampleHapticsFor } from '../src/use-smile-id-sample-haptics';

jest.mock('expo-haptics', () => ({
  selectionAsync: jest.fn(async () => undefined),
  impactAsync: jest.fn(async () => undefined),
  performAndroidHapticsAsync: jest.fn(async () => undefined),
  ImpactFeedbackStyle: { Light: 'light' },
  AndroidHaptics: { Segment_Tick: 'segment-tick', Toggle_On: 'toggle-on', Toggle_Off: 'toggle-off' },
}));

beforeEach(() => jest.clearAllMocks());

describe('on Android', () => {
  const haptics = smileIDSampleHapticsFor('android');

  it('plays a segment tick for a selection, as the Compose app does', () => {
    haptics.selection();
    expect(Haptics.performAndroidHapticsAsync).toHaveBeenCalledWith('segment-tick');
  });

  it('plays toggle on and toggle off for a switch, as the Compose app does', () => {
    haptics.toggle(true);
    haptics.toggle(false);
    expect(jest.mocked(Haptics.performAndroidHapticsAsync).mock.calls).toEqual([['toggle-on'], ['toggle-off']]);
  });
});

describe('on iOS', () => {
  const haptics = smileIDSampleHapticsFor('ios');

  it("plays UIKit's selection feedback for a selection", () => {
    haptics.selection();
    expect(Haptics.selectionAsync).toHaveBeenCalledTimes(1);
    expect(Haptics.performAndroidHapticsAsync).not.toHaveBeenCalled();
  });

  it('plays nothing for a toggle, which UISwitch already ticks', () => {
    haptics.toggle(true);
    expect(Haptics.impactAsync).not.toHaveBeenCalled();
    expect(Haptics.selectionAsync).not.toHaveBeenCalled();
  });
});
