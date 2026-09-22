import {
  UseSmileIDSampleStatus,
  smileIDSampleProductFrom,
  useSmileIDSampleActiveProfile,
  useSmileIDSampleFormsStore,
  useSmileIDSampleJobStore,
  useSmileIDSampleSettingsStore,
} from '@smileid/sample-ui';
import {
  UseSmileIDBuilder,
  type JobSubmissionResponse,
  type UseSmileIDFlowBuilder,
  type UseSmileIDResult,
} from '@smileid/usesmileid';
import { Redirect, useLocalSearchParams, useRouter } from 'expo-router';
import { useEffect, useId, useMemo, useRef } from 'react';

import { smileIDSampleApplying } from '../../../src/flow/use-smile-id-sample-flow-builder-config';
import type { UseSmileIDSampleFlowLaunchSnapshot } from '../../../src/flow/use-smile-id-sample-flow-launch-snapshot';
import { smileIDSamplePreflight } from '../../../src/flow/use-smile-id-sample-flow-preflight';
import { useLaunchArgs } from '../../../src/use-smile-id-sample-launch';

/// The single route hosting the SDK flow. The SDK owns everything inside it: no host chrome, no host back.
export default function SdkFlowRun() {
  const router = useRouter();
  const { productId } = useLocalSearchParams<{ productId: string }>();
  const args = useLaunchArgs();
  const profile = useSmileIDSampleActiveProfile();
  const userDetails = useSmileIDSampleFormsStore((state) => state.userDetails);
  const idDetails = useSmileIDSampleFormsStore((state) => state.idDetails);
  const settings = useSmileIDSampleSettingsStore((state) => state.settings);
  const addJob = useSmileIDSampleJobStore((state) => state.add);
  // React's own per-mount id: reading a clock during render is the impurity that makes it drift.
  const runUserId = `user_${useId().replace(/[^a-zA-Z0-9]/g, '')}`;
  /// A cancel delivered after teardown would otherwise act on whatever replaced this route.
  const left = useRef(false);

  // Set on unmount too, or a teardown-delivered cancel navigates whatever replaced this route.
  useEffect(
    () => () => {
      left.current = true;
    },
    [],
  );

  // Once at entry: the SDK builds on mount, and remounting it tears the run down.
  const snapshot = useMemo<UseSmileIDSampleFlowLaunchSnapshot | null>(() => {
    const product = smileIDSampleProductFrom(productId);
    if (product === null) return null;
    return {
      product,
      route: args.route,
      userDetails,
      idDetails,
      scenario: args.scenario,
      theme: args.theme,
      // Sandbox until a scanned session says otherwise, because the environment is the token's.
      sandbox: true,
      allowAgentMode: settings.agentMode,
      enableEnhancedLiveness: settings.enhancedSmartSelfie,
      consentStep: settings.consentStep,
      instructionsStep: settings.instructionsStep,
      previewStep: settings.previewStep,
      userId: runUserId,
      partnerId: profile.id,
      partnerName: profile.organisation,
      // A profile here carries no webhook URL yet, and empty means the partner's portal default.
      callbackUrl: '',
    };
    // Entry-only: re-reading any dependency rebuilds the flow.
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  const preflight = useMemo(
    () => (snapshot === null ? null : smileIDSamplePreflight(snapshot)),
    [snapshot],
  );

  const leave = () => {
    if (left.current) return;
    left.current = true;
    router.replace('/products');
  };

  // Declared, not replaced from an effect: on a cold link that took the whole app off screen.
  if (snapshot === null) return <Redirect href="/products" />;
  if (preflight?.kind === 'needsDetails') {
    return <Redirect href={`/flow/${productId}/details`} />;
  }
  // No form fixes a misconfigured builder, and it must still never reach the SDK.
  if (preflight?.kind !== 'ready') return <Redirect href="/products" />;

  return (
    <UseSmileIDBuilder
      builder={(builder: UseSmileIDFlowBuilder) => {
        smileIDSampleApplying(builder, snapshot);
        if (snapshot.scenario === 'noCallback') return;
        builder.onResult = (result: UseSmileIDResult<JobSubmissionResponse>) => {
          if (snapshot.scenario === 'throwingCallback') {
            throw new Error('throwingCallback scenario: the host result callback throws');
          }
          if (result.status !== 'success') {
            leave();
            return;
          }
          // Held by the store, not this screen: the write must outlive a same-frame teardown.
          void addJob({
            id: result.value.jobId,
            userId: result.value.userId,
            product: snapshot.product,
            status: UseSmileIDSampleStatus.Processing,
            createdAtMillis: Date.now(),
            message: result.value.message,
            // Accepted, not judged, which is what a finished run writes.
            httpStatus: acceptedCode,
            // From the snapshot, not re-read: by the time a result lands the toggles may have moved on.
            sandbox: snapshot.sandbox,
            sessionId: null,
            partnerId: null,
          });
          if (left.current) return;
          left.current = true;
          // `replace`, not a push: the wizard beneath must not be reachable back INTO from the result.
          router.replace(`/verifications/${result.value.jobId}`);
        };
      }}
    />
  );
}

const acceptedCode = 202;
