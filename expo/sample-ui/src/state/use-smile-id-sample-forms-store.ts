import { create } from 'zustand';

import {
  smileIDSampleIdDetailsDefaults,
  type UseSmileIDSampleCountry,
  type UseSmileIDSampleIdDetails,
  type UseSmileIDSampleIdType,
} from './use-smile-id-sample-id-details';
import {
  smileIDSampleUserDetailsDefaults,
  type UseSmileIDSampleProfile,
  type UseSmileIDSampleUserDetails,
} from './use-smile-id-sample-profiles';
import { smileIDSampleUserFieldWrite, type UseSmileIDSampleUserField } from '../model/use-smile-id-sample-user-fields';

type State = {
  readonly userDetails: UseSmileIDSampleUserDetails;
  readonly idDetails: UseSmileIDSampleIdDetails;
  /// Whether Continue keeps what was typed: into the active profile, or as a new one when there is none.
  readonly saveToProfile: boolean;
  /// The new profile's name, asked only while there is no profile.
  readonly organisation: string;
};

type Actions = {
  setUserField: (field: UseSmileIDSampleUserField, value: string) => void;
  setSaveToProfile: (enabled: boolean) => void;
  setOrganisation: (value: string) => void;
  /// A run starts from the profile it runs as; whatever was typed for another is dropped.
  fillFrom: (profile: UseSmileIDSampleProfile) => void;
  /// A product tap: fills from the active profile, and never carries the last run's ID details into this one.
  startRun: (profile: UseSmileIDSampleProfile | null) => void;
  setCountry: (country: UseSmileIDSampleCountry) => void;
  setIdType: (idType: UseSmileIDSampleIdType) => void;
  setIdNumber: (value: string) => void;
  clear: () => void;
};

/// What the two pre-flow forms hold, for the life of the app rather than of a screen.
export const useSmileIDSampleFormsStore = create<State & Actions>((set) => ({
  userDetails: smileIDSampleUserDetailsDefaults,
  idDetails: smileIDSampleIdDetailsDefaults,
  saveToProfile: true,
  organisation: '',

  setUserField: (field, value) =>
    set((state) => ({ userDetails: smileIDSampleUserFieldWrite(field, state.userDetails, value) })),

  setSaveToProfile: (enabled) => set({ saveToProfile: enabled }),

  setOrganisation: (value) => set({ organisation: value }),

  fillFrom: (profile) => set({ userDetails: profile.defaults, saveToProfile: true, organisation: '' }),

  startRun: (profile) =>
    set({
      ...(profile === null ? {} : { userDetails: profile.defaults, saveToProfile: true, organisation: '' }),
      idDetails: smileIDSampleIdDetailsDefaults,
    }),

  /// Choosing a country clears the ID type, because the types it offered may not apply to the new one.
  setCountry: (country) =>
    set((state) => ({ idDetails: { ...state.idDetails, country, idType: null } })),

  setIdType: (idType) => set((state) => ({ idDetails: { ...state.idDetails, idType } })),

  setIdNumber: (value) => set((state) => ({ idDetails: { ...state.idDetails, idNumber: value } })),

  /// Sign out: what a partner would expect gone.
  clear: () =>
    set({
      userDetails: smileIDSampleUserDetailsDefaults,
      idDetails: smileIDSampleIdDetailsDefaults,
      saveToProfile: true,
      organisation: '',
    }),
}));
