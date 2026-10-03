import { create } from 'zustand';

type State = {
  /// The device's own theme, which the System label names.
  readonly deviceDark: boolean;
  readonly setDeviceDark: (deviceDark: boolean) => void;
};

/// Written only by the root layout, which alone can read the device before the app's pin masks it.
export const useSmileIDSampleDeviceScheme = create<State>((set) => ({
  deviceDark: false,
  setDeviceDark: (deviceDark) => set({ deviceDark }),
}));
