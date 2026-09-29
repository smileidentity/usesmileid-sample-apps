import { create } from 'zustand';

import {
  smileIDSampleDocumentId,
  smileIDSampleIdDetailsDefaults,
  type UseSmileIDSampleCountry,
  type UseSmileIDSampleGenericDocument,
  type UseSmileIDSampleDocument,
  type UseSmileIDSampleIdDetails,
  type UseSmileIDSampleKycIdType,
} from './use-smile-id-sample-id-details';
import { UseSmileIDSampleCaptureAs } from '../model/use-smile-id-sample-capture-as';
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
  setIdType: (idType: UseSmileIDSampleKycIdType) => void;
  setDocument: (document: UseSmileIDSampleDocument) => void;
  /// Null is Match document.
  setCaptureAs: (captureAs: UseSmileIDSampleCaptureAs | null) => void;
  /// Keeps what the generic-document sheet built, which also selects Generic document.
  setGenericDocument: (genericDocument: UseSmileIDSampleGenericDocument) => void;
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

  /// Choosing a country clears the ID type, document and "Capture as" override, which may not apply to it, and keeps the typed number.
  setCountry: (country) =>
    set((state) => ({ idDetails: { ...state.idDetails, country, idType: null, document: null, captureAsOverride: null } })),

  setIdType: (idType) => set((state) => ({ idDetails: { ...state.idDetails, idType } })),

  /// A different document drops the override, which described one pairing.
  setDocument: (document) =>
    set((state) => {
      const same = state.idDetails.document !== null && smileIDSampleDocumentId(state.idDetails.document) === smileIDSampleDocumentId(document);
      return { idDetails: { ...state.idDetails, document, captureAsOverride: same ? state.idDetails.captureAsOverride : null } };
    }),

  setCaptureAs: (captureAs) => set((state) => ({ idDetails: { ...state.idDetails, captureAsOverride: captureAs } })),

  setGenericDocument: (genericDocument) =>
    set((state) => ({
      idDetails: { ...state.idDetails, genericDocument, captureAsOverride: UseSmileIDSampleCaptureAs.GenericDocument },
    })),

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
