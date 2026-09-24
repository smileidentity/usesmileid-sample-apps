import { create } from 'zustand';

import {
  smileIDSampleResultBlocked,
  smileIDSampleResultDefaults,
  smileIDSampleResultRecorded,
  smileIDSampleResultStarted,
  type UseSmileIDSampleFlowStatus,
  type UseSmileIDSampleResult,
  type UseSmileIDSampleRunContext,
} from '../model/use-smile-id-sample-result';

type State = { readonly result: UseSmileIDSampleResult };

type Actions = {
  start: (run: UseSmileIDSampleRunContext) => void;
  record: (
    status: UseSmileIDSampleFlowStatus,
    outcome?: { readonly jobId?: string; readonly userId?: string; readonly error?: string },
  ) => void;
  block: (reason: string, run: UseSmileIDSampleRunContext) => void;
  refreshed: () => void;
  reset: () => void;
};

/// What the SDK did on the last run. Held outside any route, so a count survives the flow's own teardown.
export const useSmileIDSampleResultStore = create<State & Actions>((set, get) => ({
  result: smileIDSampleResultDefaults,
  start: (run) => set({ result: smileIDSampleResultStarted(get().result, run) }),
  record: (status, outcome) => set({ result: smileIDSampleResultRecorded(get().result, status, outcome) }),
  block: (reason, run) => set({ result: smileIDSampleResultBlocked(get().result, reason, run) }),
  refreshed: () =>
    set({ result: { ...get().result, refreshCallbackCount: get().result.refreshCallbackCount + 1 } }),
  reset: () => set({ result: smileIDSampleResultDefaults }),
}));

/// One run's link to the card: started exactly once, before its first delivery, whichever comes first.
export const smileIDSampleRunRecorder = (run: UseSmileIDSampleRunContext) => {
  let started = false;
  /// Starts the run unless a delivery already did: a child's effects run before its host's.
  const ensureStarted = () => {
    if (started) return;
    started = true;
    useSmileIDSampleResultStore.getState().start(run);
  };
  return {
    ensureStarted,
    deliver: (...args: Parameters<Actions['record']>) => {
      ensureStarted();
      useSmileIDSampleResultStore.getState().record(...args);
    },
  };
};
