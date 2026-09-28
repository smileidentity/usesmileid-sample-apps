import AsyncStorage from '@react-native-async-storage/async-storage';
import { create } from 'zustand';

import { smileIDSampleSettings, type UseSmileIDSampleSetting } from '../model/use-smile-id-sample-setting';
import { smileIDSampleCaptureModes, type UseSmileIDSampleCaptureMode } from '../model/use-smile-id-sample-capture-mode';
import {
  smileIDSampleSettingsDefaults,
  smileIDSampleSettingsNormalised,
  smileIDSampleSettingsWith,
  type UseSmileIDSampleSettings,
} from './use-smile-id-sample-settings';

const KEY_PREFIX = 'sample.setting.';

type State = {
  readonly settings: UseSmileIDSampleSettings;
  /// Null until the first read finishes: "not loaded yet" is not "the defaults".
  readonly loaded: boolean;
};

type Actions = {
  load: () => Promise<void>;
  setSetting: (setting: UseSmileIDSampleSetting, enabled: boolean) => Promise<void>;
  setCaptureMode: (mode: UseSmileIDSampleCaptureMode) => Promise<void>;
  reset: () => void;
};

const key = (setting: UseSmileIDSampleSetting) => `${KEY_PREFIX}${setting}`;

const CAPTURE_MODE_KEY = `${KEY_PREFIX}captureMode`;

/// Whether the capture mode moved while `load` was reading.
let captureModeMovedDuringLoad = false;

/// Settings the user moved while `load` was reading, which the read must not undo.
const movedDuringLoad = new Set<UseSmileIDSampleSetting>();

/// A preference, never a credential: the token session has its own home (docs/architecture.md §5).
export const useSmileIDSampleSettingsStore = create<State & Actions>((set, get) => ({
  settings: smileIDSampleSettingsDefaults,
  loaded: false,

  load: async () => {
    const stored = { ...smileIDSampleSettingsDefaults } as Record<string, unknown>;
    try {
      const pairs = await AsyncStorage.multiGet([...smileIDSampleSettings.map(key), CAPTURE_MODE_KEY]);
      for (const [storedKey, value] of pairs) {
        if (value === null) continue;
        if (storedKey === CAPTURE_MODE_KEY) {
          // An id this build does not know keeps the default rather than reaching the SDK.
          if (smileIDSampleCaptureModes.some((mode) => mode.id === value)) stored.captureMode = value;
          continue;
        }
        stored[storedKey.slice(KEY_PREFIX.length)] = value === 'true';
      }
    } catch {
      // Unreadable storage leaves the defaults, rather than a store that never reports loaded.
    }
    const live = get().settings;
    for (const setting of movedDuringLoad) stored[setting] = live[setting];
    if (captureModeMovedDuringLoad) stored.captureMode = live.captureMode;
    movedDuringLoad.clear();
    captureModeMovedDuringLoad = false;
    // Normalised on read, because a device may already hold the pair the SDK refuses.
    set({ settings: smileIDSampleSettingsNormalised(stored as UseSmileIDSampleSettings), loaded: true });
  },

  setCaptureMode: async (mode) => {
    set({ settings: { ...get().settings, captureMode: mode } });
    if (!get().loaded) captureModeMovedDuringLoad = true;
    await AsyncStorage.setItem(CAPTURE_MODE_KEY, mode);
  },

  setSetting: async (setting, enabled) => {
    const current = get().settings;
    const updated = smileIDSampleSettingsWith(current, setting, enabled);
    set({ settings: updated });
    // Only what moved: writing every switch would freeze today's defaults onto the device.
    const moved = smileIDSampleSettings.filter((name) => updated[name] !== current[name]);
    if (!get().loaded) for (const name of moved) movedDuringLoad.add(name);
    if (moved.length > 0) {
      await AsyncStorage.multiSet(moved.map((name) => [key(name), String(updated[name])]));
    }
  },

  reset: () => {
    movedDuringLoad.clear();
    captureModeMovedDuringLoad = false;
    set({ settings: smileIDSampleSettingsDefaults, loaded: false });
  },
}));
