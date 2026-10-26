import {
  UseSmileIDSampleStatus,
  smileIDSampleCatalogueFieldsToCollectOf,
  smileIDSampleCatalogueIdTypeFieldsOf,
  smileIDSampleDetailsWithoutHiddenNames,
  smileIDSampleLiveSession,
  smileIDSampleProductFrom,
  smileIDSampleIdTypeEntry,
  smileIDSampleRequirementFor,
  smileIDSampleSessionExpired,
  useSmileIDSampleActiveProfile,
  useSmileIDSampleFormsStore,
  useSmileIDSampleJobStore,
  smileIDSampleRunRecorder,
  useSmileIDSampleResultStore,
  useSmileIDSampleSessionStore,
  useSmileIDSampleSettingsStore,
  type UseSmileIDSampleRunContext,
  type UseSmileIDSampleRunIntent,
  USE_SMILE_ID_SAMPLE_FIRST_PROFILE_ID,
  smileIDSamplePartnerName,
  smileIDSampleSkipsApiSubmission,
} from '@smileid/sample-ui';
import {
  UseSmileIDBuilder,
  type JobSubmissionResponse,
  type UseSmileIDFlowBuilder,
  type UseSmileIDResult,
} from '@smileid/usesmileid';
import { useEffect, useLayoutEffect, useMemo, useRef, useState } from 'react';

import { smileIDSampleCatalogueStore } from '../catalogue/use-smile-id-sample-catalogue';
import { useSmileIDSampleShellExtension } from '../extension';
import {
  smileIDSampleApplying,
  smileIDSampleAnalyzersReady,
  smileIDSampleAnalyzersSettled,
} from '../flow/use-smile-id-sample-flow-builder-config';
import { smileIDSampleDeleteCapturedFiles, smileIDSampleRecordResult } from '../flow/use-smile-id-sample-captured-job';
import {
  smileIDSampleSnapshotSession,
  type UseSmileIDSampleFlowLaunchSnapshot,
} from '../flow/use-smile-id-sample-flow-launch-snapshot';
import { smileIDSamplePreflight } from '../flow/use-smile-id-sample-flow-preflight';
import {
  smileIDSampleLeaveRun,
  smileIDSampleLeaveToProducts,
  smileIDSampleRunProductId,
  useSmileIDSampleEngine,
  type UseSmileIDSampleStepScope,
} from '../navigation/use-smile-id-sample-navigation';
import { UseSmileIDSampleLeave } from '../navigation/use-smile-id-sample-leave';
import { useLaunchArgs } from '../use-smile-id-sample-launch';
import { useSmileIDSampleStrings } from '@smileid/sample-ui';

/// The step hosting the SDK flow, in the shell or over it as its step says. The SDK owns everything inside it: no host chrome, no host back.
export const UseSmileIDSampleSdkFlowStep = ({ scope }: { scope: UseSmileIDSampleStepScope }) => {
  const strings = useSmileIDSampleStrings();
  const engine = useSmileIDSampleEngine();
  const productId = smileIDSampleRunProductId(engine, scope.entry);
  const args = useLaunchArgs();
  const profile = useSmileIDSampleActiveProfile();
  const userDetails = useSmileIDSampleFormsStore((state) => state.userDetails);
  const idDetails = useSmileIDSampleFormsStore((state) => state.idDetails);
  const settings = useSmileIDSampleSettingsStore((state) => state.settings);
  const addJob = useSmileIDSampleJobStore((state) => state.add);
  const authUserId = useSmileIDSampleFormsStore((state) => state.authUserId);
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
    // Read, not subscribed: a tick re-render would tear the SDK run down.
    const sessions = useSmileIDSampleSessionStore.getState();
    // The clock, not the last tick: a session can lapse between ticks.
    // eslint-disable-next-line react-hooks/purity -- read once, inside the entry-only memo
    const entryMillis = Date.now();
    const session = smileIDSampleLiveSession(sessions, entryMillis);
    const catalogue = smileIDSampleCatalogueStore(args.catalogue).getState();
    const fieldsToCollect = smileIDSampleCatalogueFieldsToCollectOf(catalogue, session?.id ?? null);
    const idTypeFields = smileIDSampleCatalogueIdTypeFieldsOf(catalogue, session?.id ?? null);
    return {
      product,
      route: scope.step.kind === 'sdkFlowFullScreen' ? 'fullscreen' : 'shell',
      userDetails: smileIDSampleDetailsWithoutHiddenNames(
        userDetails,
        smileIDSampleRequirementFor(session?.bindings, product, fieldsToCollect, idTypeFields),
        smileIDSampleIdTypeEntry(
          idTypeFields,
          product,
          idDetails.country?.code ?? '',
          idDetails.idType?.type ?? '',
        ),
      ),
      idDetails,
      scenario: args.scenario,
      theme: args.theme,
      sandbox: session?.environment !== 'production',
      allowAgentMode: settings.agentMode,
      enableEnhancedLiveness: settings.enhancedSmartSelfie,
      consentStep: settings.consentStep,
      instructionsStep: settings.instructionsStep,
      previewStep: settings.previewStep,
      captureMode: settings.captureMode,
      galleryUpload: settings.galleryUpload,
      allowSkipBack: settings.allowSkipBack,
      selfieFirst: settings.selfieFirst,
      skipApiSubmission: smileIDSampleSkipsApiSubmission(settings.submission),
      userId: authUserId.trim(),
      partnerId: profile?.id ?? USE_SMILE_ID_SAMPLE_FIRST_PROFILE_ID,
      partnerName: smileIDSamplePartnerName(profile),
      callbackUrl: profile?.callbackUrl ?? '',
      session,
      sessionExpired: smileIDSampleSessionExpired(sessions, entryMillis),
    };
    // Entry-only: re-reading any dependency rebuilds the flow.
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  // The analyzers follow the phone's mobile services, answered a few milliseconds after launch; settled long
  // before a run mounts, except an autostart racing it, which waits here.
  const [analyzersReady, setAnalyzersReady] = useState(smileIDSampleAnalyzersSettled());
  useEffect(() => {
    if (analyzersReady) return;
    let mounted = true;
    void smileIDSampleAnalyzersReady.then(() => {
      if (mounted) setAnalyzersReady(true);
    });
    return () => {
      mounted = false;
    };
  }, [analyzersReady]);
  const preflight = useMemo(
    () => (snapshot === null ? null : smileIDSamplePreflight(snapshot)),
    [snapshot],
  );

  const recorder = useMemo(() => (snapshot === null ? null : smileIDSampleRunRecorder(runOf(snapshot))), [snapshot]);

  useEffect(() => {
    if (preflight?.kind === 'ready') recorder?.ensureStarted();
    // Entry-only, like the snapshot it records.
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  const toProducts = () => smileIDSampleLeaveToProducts(engine);
  const leave = () => {
    if (left.current) return;
    left.current = true;
    toProducts();
  };
  // Where the SDK's own failure lands, so the reason is on screen rather than a dead tap.
  const toUnsubmittedDetails = () => {
    if (left.current) return;
    left.current = true;
    smileIDSampleLeaveRun(engine, scope.entry, 'verificationDetails', unsubmittedJobId);
  };

  if (snapshot === null) return <UseSmileIDSampleLeave onLeave={toProducts} />;
  if (preflight?.kind === 'needsSession') {
    return (
      <SendToScanner
        intent={{ productId: snapshot.product.id, route: snapshot.route, resumeAt: 'flow' }}
        onSent={() => smileIDSampleLeaveRun(engine, scope.entry, 'scanToken')}
      />
    );
  }
  if (preflight?.kind === 'needsUserId') {
    return <UseSmileIDSampleLeave onLeave={() => smileIDSampleLeaveRun(engine, scope.entry, 'authUserId', productId)} />;
  }
  if (preflight?.kind === 'needsDetails') {
    return (
      <UseSmileIDSampleLeave onLeave={() => smileIDSampleLeaveRun(engine, scope.entry, 'consentDetailsForm', productId)} />
    );
  }
  // No form fixes a misconfigured builder, and validate() gives build()'s verdict, so it never reaches the SDK.
  if (preflight?.kind === 'misconfigured') {
    const reason = preflight.issues.map((issue) => issue.message).join('; ') || strings.flowInvalid;
    return <RecordBlocked reason={reason} run={runOf(snapshot)} onBlocked={toUnsubmittedDetails} />;
  }
  if (preflight?.kind !== 'ready') return <UseSmileIDSampleLeave onLeave={toProducts} />;
  if (!analyzersReady) return null;

  return (
    <UseSmileIDBuilder
      builder={(builder: UseSmileIDFlowBuilder) => {
        smileIDSampleApplying(
          builder,
          snapshot,
          useSmileIDSampleResultStore.getState().refreshed,
          useSmileIDSampleShellExtension,
        );
        useSmileIDSampleShellExtension?.customiseFlow?.(builder, snapshot.product);
        if (snapshot.scenario === 'noCallback') return;
        builder.onResult = (result: UseSmileIDResult<JobSubmissionResponse>) => {
          // Before the throw: the throwing scenario still delivered, and the count must say so.
          if (recorder !== null) smileIDSampleRecordResult(recorder, result);
          if (snapshot.scenario === 'throwingCallback') {
            throw new Error('throwingCallback scenario: the host result callback throws');
          }
          if (result.status === 'cancelled') {
            leave();
            return;
          }
          if (result.status === 'captured') smileIDSampleDeleteCapturedFiles(result.job);
          if (result.status !== 'success') {
            toUnsubmittedDetails();
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
            sessionId: smileIDSampleSnapshotSession(snapshot)?.id ?? null,
            partnerId: smileIDSampleSnapshotSession(snapshot)?.partnerId ?? null,
          });
          if (left.current) return;
          left.current = true;
          // In the run's place: the wizard beneath must not be reachable back INTO from the result.
          smileIDSampleLeaveRun(engine, scope.entry, 'verificationDetails', result.value.jobId);
        };
      }}
    />
  );
};

const acceptedCode = 202;

/// The details entry for a run that never produced a job: the screen shows the run's result instead.
const unsubmittedJobId = 'unsubmitted';

const runOf = (snapshot: UseSmileIDSampleFlowLaunchSnapshot): UseSmileIDSampleRunContext => ({
  scenario: snapshot.scenario,
  theme: snapshot.theme,
  route: snapshot.route,
  environment: snapshot.sandbox ? 'sandbox' : 'production',
});

/// Records the refusal, then leaves.
const RecordBlocked = ({
  reason,
  run,
  onBlocked,
}: {
  reason: string;
  run: UseSmileIDSampleRunContext;
  onBlocked: () => void;
}) => {
  useLayoutEffect(() => {
    useSmileIDSampleResultStore.getState().block(reason, run);
    onBlocked();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);
  return null;
};

/// Hands the run to the scanner, then leaves for it.
const SendToScanner = ({ intent, onSent }: { intent: UseSmileIDSampleRunIntent; onSent: () => void }) => {
  const sendRun = useSmileIDSampleSessionStore((state) => state.sendRun);
  useLayoutEffect(() => {
    sendRun(intent);
    onSent();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);
  return null;
};
