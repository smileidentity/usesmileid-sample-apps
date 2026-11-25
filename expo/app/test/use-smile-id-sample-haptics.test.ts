import * as Haptics from 'expo-haptics';

import { smileIDSampleHapticsFor } from '../src/use-smile-id-sample-haptics';

jest.mock('expo-haptics', () => ({
  selectionAsync: jest.fn(async () => undefined),
  impactAsync: jest.fn(async () => undefined),
  performAndroidHapticsAsync: jest.fn(async () => undefined),
  ImpactFeedbackStyle: { Light: 'light' },
  AndroidHaptics: {
    Segment_Tick: 'segment-tick',
    Toggle_On: 'toggle-on',
    Toggle_Off: 'toggle-off',
    Clock_Tick: 'clock-tick',
    Virtual_Key: 'virtual-key',
    Virtual_Key_Release: 'virtual-key-release',
  },
}));

beforeEach(() => jest.clearAllMocks());

describe('on Android 14 and later', () => {
  const haptics = smileIDSampleHapticsFor('android', 34);

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

describe('before Android 14, which lacks the segment and toggle constants', () => {
  const haptics = smileIDSampleHapticsFor('android', 33);

  it('plays a clock tick for a selection, as Compose falls back to', () => {
    haptics.selection();
    expect(Haptics.performAndroidHapticsAsync).toHaveBeenCalledWith('clock-tick');
  });

  it('plays a virtual key press and release for a switch, as Compose falls back to', () => {
    haptics.toggle(true);
    haptics.toggle(false);
    expect(jest.mocked(Haptics.performAndroidHapticsAsync).mock.calls).toEqual([['virtual-key'], ['virtual-key-release']]);
  });
});

describe('on iOS', () => {
  const haptics = smileIDSampleHapticsFor('ios', 0);

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
