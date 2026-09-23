import {
  ScanTokenScreen,
  smileIDSampleSessionHasExpired,
  smileIDSampleTokenSession,
  useSmileIDSampleSessionStore,
  type UseSmileIDSampleScanFeedback,
  type UseSmileIDSampleTokenSession,
  type UseSmileIDSampleViewfinderProps,
} from '@smileid/sample-ui';
import * as Clipboard from 'expo-clipboard';
import * as Haptics from 'expo-haptics';
import { useRouter } from 'expo-router';
import { createContext, use, useEffect, useRef, useState } from 'react';

import { smileIDSampleSimulatedToken } from '../../src/flow/use-smile-id-sample-flow-tokens';
import { UseSmileIDSampleQrScanner } from '../../src/scan/use-smile-id-sample-qr-scanner';
import { useSmileIDSampleBack } from '../../src/use-smile-id-sample-back';

/// Read by the viewfinder, so toggling the flash does not remount the camera.
const TorchContext = createContext(false);

/// The shell's camera: the shared UI runs under hosts that carry none.
const Viewfinder = (props: UseSmileIDSampleViewfinderProps) => (
  <UseSmileIDSampleQrScanner {...props} torchOn={use(TorchContext)} />
);

/// Acknowledges a scan in the hand.
const feedback = (kind: UseSmileIDSampleScanFeedback) => {
  Haptics.notificationAsync(
    kind === 'linked' ? Haptics.NotificationFeedbackType.Success : Haptics.NotificationFeedbackType.Error,
  ).catch(() => undefined);
};

/// The token-scanning route; a relink resumes the interrupted run.
export default function ScanToken() {
  const router = useRouter();
  const back = useSmileIDSampleBack('/products');
  const link = useSmileIDSampleSessionStore((state) => state.link);
  const clearRun = useSmileIDSampleSessionStore((state) => state.clearRun);
  const current = useSmileIDSampleSessionStore((state) => state.live);
  const [torchOn, setTorchOn] = useState(false);
  // Claimed at mount, so leaving by any route drops it.
  const [resuming] = useState(() => useSmileIDSampleSessionStore.getState().pendingRun);
  // Resumes only on a different session than the one that sent us here.
  const [arrivedWith] = useState(() => useSmileIDSampleSessionStore.getState().live?.id ?? null);
  const resumeHandled = useRef(false);

  useEffect(() => {
    clearRun();
  }, [clearRun]);

  useEffect(() => {
    if (resuming === null || resumeHandled.current || current === null || current.id === arrivedWith) return;
    resumeHandled.current = true;
    // An expired relink cannot start the run, so leave rather than freeze.
    if (smileIDSampleSessionHasExpired(current, Date.now())) back();
    else router.replace(`/flow/${resuming.productId}/run`);
  }, [resuming, current, arrivedWith, back, router]);

  const onLink = (session: UseSmileIDSampleTokenSession) => {
    link(session).catch(() => undefined);
    if (resuming === null) back();
  };

  return (
    <TorchContext value={torchOn}>
      <ScanTokenScreen
        reason={resuming === null ? null : 'sessionEnded'}
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
      />
    </TorchContext>
  );
}
