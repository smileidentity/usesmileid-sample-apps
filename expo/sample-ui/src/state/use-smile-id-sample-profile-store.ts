import AsyncStorage from '@react-native-async-storage/async-storage';
import { create } from 'zustand';

import type { UseSmileIDSampleLaunchArgs } from './use-smile-id-sample-launch-args';
import {
  smileIDSampleDecodeProfiles,
  smileIDSampleEncodeProfiles,
  smileIDSampleFixtureProfiles,
  smileIDSampleProfilesRecord,
  smileIDSampleUserDetailsDefaults,
  smileIDSampleUserDetailsEqual,
  type UseSmileIDSampleProfile,
  type UseSmileIDSampleUserDetails,
} from './use-smile-id-sample-profiles';
import {
  smileIDSampleRequirementDefaults,
  smileIDSampleRequirementSupplies,
  type UseSmileIDSampleUserDetailsRequirement,
} from './use-smile-id-sample-user-details-requirement';
import {
  smileIDSampleUserFieldRead,
  smileIDSampleUserFields,
  smileIDSampleUserFieldWrite,
} from '../model/use-smile-id-sample-user-fields';

/// The key the record is stored under, the same on all four apps.
export const SMILE_ID_SAMPLE_PROFILES_KEY = 'sample_profiles';

type State = {
  readonly items: readonly UseSmileIDSampleProfile[];
  /// Null exactly when there are no profiles.
  readonly activeId: string | null;
  /// The last profile `add` created without activating, until the list that offers "Make active" consumes it.
  readonly lastCreatedId: string | null;
  /// False until the store has answered, so nothing reads "no profile" from a list still loading.
  readonly loaded: boolean;
  /// A seeded launch holds the fixtures in memory only.
  readonly seeded: boolean;
};

type Edit = {
  readonly organisation?: string;
  readonly defaults?: UseSmileIDSampleUserDetails;
  readonly callbackUrl?: string;
};

type Actions = {
  /// The stored profiles, or the fixtures when the launch seeds them; once per launch.
  load: (args: UseSmileIDSampleLaunchArgs) => Promise<void>;
  /// Holds these in memory without storing them, for tests and seeded launches.
  reset: (seed: readonly UseSmileIDSampleProfile[], activeId?: string | null) => void;
  setActive: (id: string) => void;
  clearLastCreated: () => void;
  add: (organisation: string, defaults?: UseSmileIDSampleUserDetails, activate?: boolean) => string;
  /// An absent part is left alone.
  update: (id: string, edit: Edit) => void;
  delete: (id: string) => void;
  /// Sign out: every profile goes.
  clear: () => void;
  /// Continue's write-back from the details form; a field the token supplies is never stored.
  keep: (
    details: UseSmileIDSampleUserDetails,
    organisation: string,
    requirement?: UseSmileIDSampleUserDetailsRequirement,
  ) => void;
};

/// First free id, not one derived from the count: duplicate keys crash the list and double a test id.
const nextId = (items: readonly UseSmileIDSampleProfile[]): string => {
  for (let candidate = items.length + 1; ; candidate += 1) {
    const id = `p-${candidate}`;
    if (!items.some((item) => item.id === id)) return id;
  }
};

/// Serialises the writes, so the last change is the one that lands.
let writes: Promise<void> = Promise.resolve();

/// The profiles the app can act as, and which is active. A plain first launch has none.
export const useSmileIDSampleProfileStore = create<State & Actions>((set, get) => {
  const change = (next: Pick<State, 'items' | 'activeId'> & Partial<State>) => {
    set(next);
    const { items, activeId, seeded } = get();
    if (seeded) return;
    const encoded = smileIDSampleEncodeProfiles({ profiles: items, activeId });
    // Caught, not voided: a refused write must never surface as an unhandled rejection.
    writes = writes.then(() => AsyncStorage.setItem(SMILE_ID_SAMPLE_PROFILES_KEY, encoded)).catch(() => undefined);
  };

  return {
    items: [],
    activeId: null,
    lastCreatedId: null,
    loaded: false,
    seeded: false,

    load: async (args) => {
      // Once per launch: a remount must not replace profiles already in use with an older read.
      if (get().loaded) return;
      if (args.seedProfiles) {
        get().reset(smileIDSampleFixtureProfiles());
        return;
      }
      let raw: string | null = null;
      try {
        // After any queued write, so the read is never older than the last change.
        await writes;
        raw = await AsyncStorage.getItem(SMILE_ID_SAMPLE_PROFILES_KEY);
      } catch {
        // Unreadable storage is no profiles, rather than a store that never reports loaded.
      }
      const record = smileIDSampleDecodeProfiles(raw);
      set({ items: record.profiles, activeId: record.activeId, lastCreatedId: null, loaded: true, seeded: false });
    },

    reset: (seed, activeId = null) => {
      const record = smileIDSampleProfilesRecord(seed, activeId);
      set({ items: record.profiles, activeId: record.activeId, lastCreatedId: null, loaded: true, seeded: true });
    },

    setActive: (id) => {
      const { items, activeId } = get();
      if (id !== activeId && items.some((item) => item.id === id)) change({ items, activeId: id });
    },

    clearLastCreated: () => set({ lastCreatedId: null }),

    add: (organisation, defaults = smileIDSampleUserDetailsDefaults, activate = false) => {
      const { items, activeId } = get();
      const id = nextId(items);
      const activates = activate || activeId === null;
      change({
        items: [...items, { id, organisation: organisation.trim(), defaults }],
        activeId: activates ? id : activeId,
        lastCreatedId: activates ? null : id,
      });
      return id;
    },

    update: (id, edit) => {
      const { items, activeId } = get();
      const current = items.find((item) => item.id === id);
      if (current === undefined) return;
      const updated = {
        ...current,
        organisation: edit.organisation?.trim() ?? current.organisation,
        defaults: edit.defaults ?? current.defaults,
        callbackUrl: edit.callbackUrl?.trim() ?? current.callbackUrl,
      };
      // Nothing moved, so nothing is written, as on Android and iOS.
      if (
        updated.organisation === current.organisation &&
        smileIDSampleUserDetailsEqual(updated.defaults, current.defaults) &&
        updated.callbackUrl === current.callbackUrl
      ) {
        return;
      }
      change({ activeId, items: items.map((item) => (item.id === id ? updated : item)) });
    },

    delete: (id) => {
      const { items, activeId, lastCreatedId } = get();
      const left = items.filter((item) => item.id !== id);
      if (left.length === items.length) return;
      change({
        items: left,
        activeId: activeId === id ? (left[0]?.id ?? null) : activeId,
        lastCreatedId: lastCreatedId === id ? null : lastCreatedId,
      });
    },

    clear: () => change({ items: [], activeId: null, lastCreatedId: null }),

    keep: (details, organisation, requirement = smileIDSampleRequirementDefaults) => {
      const { items, activeId } = get();
      const current = items.find((item) => item.id === activeId);
      const kept = smileIDSampleUserFields.reduce(
        (stored, field) =>
          smileIDSampleRequirementSupplies(requirement, field.id)
            ? stored
            : smileIDSampleUserFieldWrite(field.id, stored, smileIDSampleUserFieldRead(field.id, details)),
        current?.defaults ?? smileIDSampleUserDetailsDefaults,
      );
      if (current !== undefined) get().update(current.id, { defaults: kept });
      else get().add(organisation, kept, true);
    },
  };
});

/// The active profile, or null while there is none.
export const useSmileIDSampleActiveProfile = (): UseSmileIDSampleProfile | null =>
  // Selector, not the whole store: a bare call subscribes every caller to lastCreatedId too.
  useSmileIDSampleProfileStore((state) => state.items.find((item) => item.id === state.activeId) ?? null);

/// Position in the list, which is what picks a profile's avatar hue.
export const useSmileIDSampleActiveProfileIndex = (): number =>
  useSmileIDSampleProfileStore((state) =>
    Math.max(
      0,
      state.items.findIndex((item) => item.id === state.activeId),
    ),
  );
