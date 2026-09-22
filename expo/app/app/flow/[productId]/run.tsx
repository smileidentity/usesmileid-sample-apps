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
import { useLocalSearchParams, useRouter } from 'expo-router';
import { useEffect, useId, useMemo, useRef } from 'react';
import { View } from 'react-native';

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
  // React's own per-mount id rather than a clock: stable across re-renders, and reading a clock
  // during render is the impurity that makes a value change when nothing asked it to.
  const runUserId = `user_${useId().replace(/[^a-zA-Z0-9]/g, '')}`;
  /// A teardown-delivered cancel arrives after the route is gone, where leaving again would act on
  /// whatever replaced it.
  const left = useRef(false);

  // Read once at entry and never while the run is in flight: the SDK builds its configuration when
  // the component mounts, and remounting it tears the run down.
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
    // Deliberately entry-only: every dependency is read once, and re-reading one rebuilds the flow.
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

  useEffect(() => {
    if (preflight === null) {
      leave();
      return;
    }
    if (preflight.kind === 'needsDetails') {
      left.current = true;
      router.replace(`/flow/${productId}/details`);
      return;
    }
    // No form fixes a misconfigured builder, and it must still never reach the SDK.
    if (preflight.kind === 'misconfigured') leave();
    // Runs once for the entry the gate decided on.
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [preflight]);

  if (snapshot === null || preflight?.kind !== 'ready') {
    // An empty frame: the effect above is already leaving this route.
    return <View style={{ flex: 1 }} />;
  }

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
          // Not awaited and held by the store rather than this screen: a result the SDK delivers
          // exactly once must be written even if the route is torn down in the same frame.
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
