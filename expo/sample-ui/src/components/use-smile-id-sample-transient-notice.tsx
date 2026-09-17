import { createContext, useCallback, useContext, useEffect, useState } from 'react';
import { StyleSheet, View, type StyleProp, type ViewStyle } from 'react-native';

import { UseSmileIDSampleToast } from './use-smile-id-sample-toast';

/// One transient confirmation: what it says and the single action it may offer.
export type UseSmileIDSampleTransientNotice = {
  readonly message: string;
  readonly actionLabel?: string;
  readonly onAction?: () => void;
};

/// Long enough to undo, short enough not to outlive its cause.
export const SMILE_ID_SAMPLE_NOTICE_WINDOW_MS = 5_000;

/// The shell overrides this from `noticeWindow`; the default is the product's own behaviour.
const NoticeWindowContext = createContext(SMILE_ID_SAMPLE_NOTICE_WINDOW_MS);

export const UseSmileIDSampleNoticeWindowProvider = NoticeWindowContext.Provider;

export type UseSmileIDSampleTransientNoticeState = {
  readonly current: UseSmileIDSampleTransientNotice | null;
  /// A token, not a boolean, so showing the same message twice still restarts the window.
  readonly showToken: number;
  readonly show: (notice: UseSmileIDSampleTransientNotice) => void;
  readonly dismiss: () => void;
};

/// Not persisted, deliberately: a confirmation must not survive a relaunch.
export const useSmileIDSampleTransientNotice = (): UseSmileIDSampleTransientNoticeState => {
  const [state, setState] = useState<{
    current: UseSmileIDSampleTransientNotice | null;
    showToken: number;
  }>({ current: null, showToken: 0 });

  const show = useCallback((notice: UseSmileIDSampleTransientNotice) => {
    setState((previous) => ({ current: notice, showToken: previous.showToken + 1 }));
  }, []);

  const dismiss = useCallback(() => {
    setState((previous) => ({ current: null, showToken: previous.showToken }));
  }, []);

  // Not memoised: the two values it carries change on every show, so an identity guard buys nothing.
  return { current: state.current, showToken: state.showToken, show, dismiss };
};

type Props = {
  state: UseSmileIDSampleTransientNoticeState;
  style?: StyleProp<ViewStyle>;
};

/// Renders the notice and owns its auto-dismiss window. Padding stays caller-supplied: every screen clears different chrome.
export const UseSmileIDSampleTransientNoticeHost = ({ state, style }: Props) => {
  const windowMs = useContext(NoticeWindowContext);
  const { current, showToken, dismiss } = state;

  useEffect(() => {
    if (current === null) return undefined;
    // Keyed on the token as well, so a second notice restarts the window rather than inheriting it.
    const timer = setTimeout(dismiss, windowMs);
    return () => clearTimeout(timer);
  }, [current, showToken, dismiss, windowMs]);

  if (current === null) return null;

  const action = current.onAction;
  return (
    <View pointerEvents="box-none" style={[styles.host, style]}>
      <UseSmileIDSampleToast
        message={current.message}
        actionLabel={current.actionLabel}
        // Acting dismisses it, so the offer cannot be taken twice.
        onAction={
          action === undefined
            ? undefined
            : () => {
                action();
                dismiss();
              }
        }
      />
    </View>
  );
};

const styles = StyleSheet.create({ host: { width: '100%' } });
