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

/// The camera lives in the shell: the shared UI runs under eight identities, and only this one owns a scanner.
const Viewfinder = (props: UseSmileIDSampleViewfinderProps) => (
  <UseSmileIDSampleQrScanner {...props} torchOn={use(TorchContext)} />
);

/// Acknowledged in the hand as well as on screen, which is where a silent success feels like a freeze.
const feedback = (kind: UseSmileIDSampleScanFeedback) => {
  const played =
    kind === 'found'
      ? Haptics.selectionAsync()
      : Haptics.notificationAsync(
          kind === 'linked' ? Haptics.NotificationFeedbackType.Success : Haptics.NotificationFeedbackType.Error,
        );
  played.catch(() => undefined);
};

/// The token-scanning route, which a relink resumes the interrupted run from.
export default function ScanToken() {
  const router = useRouter();
  const back = useSmileIDSampleBack('/products');
  const link = useSmileIDSampleSessionStore((state) => state.link);
  const clearRun = useSmileIDSampleSessionStore((state) => state.clearRun);
  const current = useSmileIDSampleSessionStore((state) => state.live);
  const [torchOn, setTorchOn] = useState(false);
  // Claimed at mount and dropped from app state, so leaving by any route drops it and no later scan resurrects it.
  const [resuming] = useState(() => useSmileIDSampleSessionStore.getState().pendingRun);
  // The resume waits for a different session, separating the token that sent us here from the new one.
  const [arrivedWith] = useState(() => useSmileIDSampleSessionStore.getState().live?.id ?? null);
  const resumeHandled = useRef(false);

  useEffect(() => {
    clearRun();
  }, [clearRun]);

  // Waits for the link to reach app state: re-entering against the expired session would bounce straight back.
  useEffect(() => {
    if (resuming === null || resumeHandled.current || current === null || current.id === arrivedWith) return;
    resumeHandled.current = true;
    // An already-expired relink cannot start the run, and the pill offers no retry, so leave rather than freeze.
    if (smileIDSampleSessionHasExpired(current, Date.now())) back();
    else router.replace(`/flow/${resuming.productId}/run`);
  }, [resuming, current, arrivedWith, back, router]);

  const onLink = (session: UseSmileIDSampleTokenSession) => {
    // Held by the store, not this screen, so leaving cannot cancel the write half-done.
    link(session).catch(() => undefined);
    // A resumed run leaves on the effect above instead.
    if (resuming === null) back();
  };

  return (
    <TorchContext value={torchOn}>
      <ScanTokenScreen
        // Why this screen opened: the redirect's message belongs to the screen it arrives at.
        reason={resuming === null ? null : 'sessionEnded'}
        onBack={back}
        onLink={onLink}
        onPaste={() => Clipboard.getStringAsync()}
        onSimulate={(span, bindings, environment) => {
          const minted = smileIDSampleSimulatedToken({ span, bindings, environment, nowMillis: Date.now() });
          // The minter and the decoder have to agree; a fixture that no longer decodes is a defect, not a session.
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
