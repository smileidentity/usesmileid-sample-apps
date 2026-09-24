import { create } from 'zustand';

import {
  smileIDSampleStarterProfiles,
  smileIDSampleUserDetailsDefaults,
  type UseSmileIDSampleProfile,
  type UseSmileIDSampleUserDetails,
} from './use-smile-id-sample-profiles';

type State = {
  readonly items: readonly UseSmileIDSampleProfile[];
  readonly activeId: string;
  /// The last profile `add` created, until whoever confirmed it calls `clearLastCreated`.
  readonly lastCreatedId: string | null;
};

type Actions = {
  reset: (seed: readonly UseSmileIDSampleProfile[]) => void;
  setActive: (id: string) => void;
  clearLastCreated: () => void;
  add: (organisation: string, person: string, defaults?: UseSmileIDSampleUserDetails) => string;
  /// An undefined `callbackUrl` leaves the stored one alone; only a caller that edited it passes a value.
  setDefaults: (id: string, defaults: UseSmileIDSampleUserDetails, callbackUrl?: string) => void;
};

const starter = smileIDSampleStarterProfiles();

/// First free id, not one derived from the count: duplicate keys crash the list and double a test id.
const nextId = (items: readonly UseSmileIDSampleProfile[]): string => {
  for (let candidate = items.length + 1; ; candidate += 1) {
    const id = `p-${candidate}`;
    if (!items.some((item) => item.id === id)) return id;
  }
};

/// The profiles the app can act as, and which one is active. In memory until profiles are a real account concern.
export const useSmileIDSampleProfileStore = create<State & Actions>((set, get) => ({
  items: starter,
  activeId: starter[0]?.id ?? 'p-1',
  lastCreatedId: null,

  reset: (seed) => {
    if (seed.length === 0) {
      throw new Error('useSmileIDSampleProfileStore needs at least one profile');
    }
    set({ items: seed, activeId: seed[0]?.id ?? 'p-1', lastCreatedId: null });
  },

  setActive: (id) => {
    if (get().items.some((item) => item.id === id)) set({ activeId: id });
  },

  clearLastCreated: () => set({ lastCreatedId: null }),

  add: (organisation, person, defaults = smileIDSampleUserDetailsDefaults) => {
    const items = get().items;
    const id = nextId(items);
    set({ items: [...items, { id, organisation, person, defaults }], lastCreatedId: id });
    return id;
  },

  setDefaults: (id, defaults, callbackUrl) => {
    set({
      items: get().items.map((item) =>
        item.id === id
          ? {
              ...item,
              defaults,
              callbackUrl: callbackUrl ?? item.callbackUrl,
              // The starter names nobody until its details are saved; a created profile keeps its sheet's name.
              person: item.person.trim() || `${defaults.firstName} ${defaults.lastName}`.trim(),
            }
          : item,
      ),
    });
  },
}));

/// The active profile, which never returns undefined because the store always holds at least one.
export const useSmileIDSampleActiveProfile = (): UseSmileIDSampleProfile =>
  // Selector, not the whole store: a bare call subscribes every caller to lastCreatedId too.
  useSmileIDSampleProfileStore(
    (state) =>
      state.items.find((item) => item.id === state.activeId) ??
      (state.items[0] as UseSmileIDSampleProfile),
  );

/// Position in the list, which is what picks a profile's avatar hue.
export const useSmileIDSampleActiveProfileIndex = (): number =>
  useSmileIDSampleProfileStore((state) =>
    Math.max(
      0,
      state.items.findIndex((item) => item.id === state.activeId),
    ),
  );
