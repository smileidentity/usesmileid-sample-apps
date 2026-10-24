import {
  ScanTokenScreen,
  SMILE_ID_PORTAL_URL,
  smileIDSampleProducts,
  smileIDSampleResumesInFlow,
  smileIDSampleSessionExpired,
  smileIDSampleSessionHasExpired,
  smileIDSampleTokenSession,
  useSmileIDSampleSessionStore,
  type UseSmileIDSampleScanFeedback,
  type UseSmileIDSampleTokenSession,
  type UseSmileIDSampleViewfinderProps,
} from '@smileid/sample-ui';
import * as Clipboard from 'expo-clipboard';
import * as Haptics from 'expo-haptics';
import { NjiaDefaults } from '@smileid/njia';
import { Linking } from 'react-native';
import { createContext, use, useCallback, useEffect, useRef, useState } from 'react';

import { smileIDSampleRunEntryFor, smileIDSampleRunOnly } from '../flow/use-smile-id-sample-flow-journey';
import { smileIDSampleSimulatedToken } from '../flow/use-smile-id-sample-flow-tokens';
import { smileIDSampleLiveBindingsNow } from '../flow/use-smile-id-sample-token-binding-rules';
import {
  smileIDSampleStartRun,
  useSmileIDSampleEngine,
  type UseSmileIDSampleStepScope,
} from '../navigation/use-smile-id-sample-navigation';
import { UseSmileIDSampleQrScanner } from '../scan/use-smile-id-sample-qr-scanner';
import { useLaunchArgs } from '../use-smile-id-sample-launch';

/// Read by the viewfinder, so toggling the flash does not remount the camera.
const TorchContext = createContext(false);

/// Whether the scanner's step is on screen, read by the viewfinder for the same reason.
const FocusedContext = createContext(true);

/// The shell's camera: the shared UI runs under hosts that carry none.
const Viewfinder = (props: UseSmileIDSampleViewfinderProps) => (
  <UseSmileIDSampleQrScanner {...props} torchOn={use(TorchContext)} focused={use(FocusedContext)} />
);

/// Acknowledges a scan in the hand.
const feedback = (kind: UseSmileIDSampleScanFeedback) => {
  Haptics.notificationAsync(
    kind === 'linked' ? Haptics.NotificationFeedbackType.Success : Haptics.NotificationFeedbackType.Error,
  ).catch(() => undefined);
};

/// The token scanner; a relink resumes the interrupted run in the scanner's place.
export const UseSmileIDSampleScanTokenStep = ({ scope }: { scope: UseSmileIDSampleStepScope }) => {
  const engine = useSmileIDSampleEngine();
  const { navigator } = scope;
  const back = useCallback(() => navigator.back(), [navigator]);
  const link = useSmileIDSampleSessionStore((state) => state.link);
  const clearRun = useSmileIDSampleSessionStore((state) => state.clearRun);
  const current = useSmileIDSampleSessionStore((state) => state.live);
  const [torchOn, setTorchOn] = useState(false);
  // Claimed at mount, so leaving by any route drops it.
  const [resuming] = useState(() => useSmileIDSampleSessionStore.getState().pendingRun);
  // Resumes only on a different session than the one that sent us here.
  const [arrivedWith] = useState(() => useSmileIDSampleSessionStore.getState().live?.id ?? null);
  const [arrivedEnded] = useState(() => {
    const state = useSmileIDSampleSessionStore.getState();
    return smileIDSampleSessionExpired(state, Date.now());
  });
  const resumeHandled = useRef(false);
  const { scenario } = useLaunchArgs();
  /// False until the step has moved in, so a second tap on the nav bar's Token button cannot land on Simulate.
  const [settled, setSettled] = useState(false);

  useEffect(() => {
    const moved = setTimeout(() => setSettled(true), NjiaDefaults.motionDurationMs);
    return () => clearTimeout(moved);
  }, []);

  useEffect(() => {
    clearRun();
  }, [clearRun]);

  useEffect(() => {
    if (resuming === null || resumeHandled.current || current === null || current.id === arrivedWith) return;
    resumeHandled.current = true;
    // An expired relink cannot start the run, so leave rather than freeze.
    if (smileIDSampleSessionHasExpired(current, Date.now())) {
      back();
      return;
    }
    const product = smileIDSampleProducts.find((candidate) => candidate.id === resuming.productId);
    const store = useSmileIDSampleSessionStore.getState();
    const intoFlow = smileIDSampleResumesInFlow(resuming, store.runPartnerId, current.partnerId);
    store.recordRunPartner(current.partnerId);
    if (product === undefined) {
      back();
      return;
    }
    const bindings = smileIDSampleLiveBindingsNow(scenario);
    smileIDSampleStartRun(
      engine,
      scope.entry,
      product,
      intoFlow
        ? smileIDSampleRunOnly(product, resuming.route, bindings)
        : smileIDSampleRunEntryFor(engine.graph, product, resuming.route, bindings),
      scope.entry.id,
    );
  }, [resuming, current, arrivedWith, back, engine, scope.entry, scenario]);

  const onLink = (session: UseSmileIDSampleTokenSession) => {
    link(session).catch(() => undefined);
    if (resuming === null) {
      useSmileIDSampleSessionStore.getState().recordRunPartner(session.partnerId);
      back();
    }
  };

  return (
    <FocusedContext value={scope.isTop}>
    <TorchContext value={torchOn}>
      <ScanTokenScreen
        reason={resuming === null ? null : arrivedEnded ? 'sessionEnded' : 'sessionNeeded'}
        onBack={back}
        onLink={onLink}
        onPaste={() => Clipboard.getStringAsync()}
        onSimulate={(span, bindings, environment) => {
          const minted = smileIDSampleSimulatedToken({ span, bindings, environment, nowMillis: Date.now() });
          // A fixture that no longer decodes is a defect, not a session.
          const session = smileIDSampleTokenSession(minted);
          if (session !== null) onLink(session);
        }}
        torchOn={torchOn}
        onTorchToggle={() => setTorchOn((on) => !on)}
        Viewfinder={Viewfinder}
        onFeedback={feedback}
        acceptsTaps={settled}
        onOpenPortal={() => {
          Linking.openURL(SMILE_ID_PORTAL_URL).catch(() => undefined);
        }}
      />
    </TorchContext>
    </FocusedContext>
  );
};
