import { create } from 'zustand';

import {
  smileIDSampleIdDetailsDefaults,
  type UseSmileIDSampleCountry,
  type UseSmileIDSampleIdDetails,
  type UseSmileIDSampleIdType,
} from './use-smile-id-sample-id-details';
import { smileIDSampleUserDetailsDefaults, type UseSmileIDSampleUserDetails } from './use-smile-id-sample-profiles';
import { smileIDSampleUserFieldWrite, type UseSmileIDSampleUserField } from '../model/use-smile-id-sample-user-fields';

type State = {
  readonly userDetails: UseSmileIDSampleUserDetails;
  readonly idDetails: UseSmileIDSampleIdDetails;
  readonly rememberDetails: boolean;
};

type Actions = {
  setUserField: (field: UseSmileIDSampleUserField, value: string) => void;
  setRememberDetails: (enabled: boolean) => void;
  seedUserDetails: (details: UseSmileIDSampleUserDetails) => void;
  setCountry: (country: UseSmileIDSampleCountry) => void;
  setIdType: (idType: UseSmileIDSampleIdType) => void;
  setIdNumber: (value: string) => void;
  clear: () => void;
};

/// What the two pre-flow forms hold, for the life of the app rather than of a screen.
export const useSmileIDSampleFormsStore = create<State & Actions>((set) => ({
  userDetails: smileIDSampleUserDetailsDefaults,
  idDetails: smileIDSampleIdDetailsDefaults,
  rememberDetails: false,

  setUserField: (field, value) =>
    set((state) => ({ userDetails: smileIDSampleUserFieldWrite(field, state.userDetails, value) })),

  setRememberDetails: (enabled) => set({ rememberDetails: enabled }),

  // Only into rows the partner has not typed into, so seeding cannot overwrite an edit.
  seedUserDetails: (details) =>
    set((state) => ({
      userDetails: {
        firstName: state.userDetails.firstName || details.firstName,
        lastName: state.userDetails.lastName || details.lastName,
        email: state.userDetails.email || details.email,
        phone: state.userDetails.phone || details.phone,
      },
    })),

  /// Choosing a country clears the ID type, because the types it offered may not apply to the new one.
  setCountry: (country) =>
    set((state) => ({ idDetails: { ...state.idDetails, country, idType: null } })),

  setIdType: (idType) => set((state) => ({ idDetails: { ...state.idDetails, idType } })),

  setIdNumber: (value) => set((state) => ({ idDetails: { ...state.idDetails, idNumber: value } })),

  /// Sign out: what a partner would expect gone, including the choice to keep it.
  clear: () =>
    set({
      userDetails: smileIDSampleUserDetailsDefaults,
      idDetails: smileIDSampleIdDetailsDefaults,
      rememberDetails: false,
    }),
}));
