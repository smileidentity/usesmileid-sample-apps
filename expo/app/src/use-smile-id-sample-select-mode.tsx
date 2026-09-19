import { createContext, use, useMemo, useState, type ReactNode } from 'react';

/// Whether a tab is in select mode, which is the one thing the shell's bar needs from a screen.
const SelectModeContext = createContext(false);

const SetSelectModeContext = createContext<(selecting: boolean) => void>(() => undefined);

/// Sits above the navigator so the bar and the screen that drives it are both inside it.
export const UseSmileIDSampleSelectModeProvider = ({ children }: { children: ReactNode }) => {
  const [selecting, setSelecting] = useState(false);
  const set = useMemo(() => setSelecting, []);
  return (
    <SetSelectModeContext.Provider value={set}>
      <SelectModeContext.Provider value={selecting}>{children}</SelectModeContext.Provider>
    </SetSelectModeContext.Provider>
  );
};

export const useSmileIDSampleSelectMode = (): boolean => use(SelectModeContext);

export const useSmileIDSampleSetSelectMode = (): ((selecting: boolean) => void) =>
  use(SetSelectModeContext);
