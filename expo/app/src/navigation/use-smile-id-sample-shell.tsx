import { stepOf, top, type NjiaNativeModule } from '@smileid/njia';
import { NjiaHost } from '@smileid/njia/host';
import { useSmileIDSampleTheme, type UseSmileIDSampleLaunchArgs } from '@smileid/sample-ui';
import * as Linking from 'expo-linking';
import { useEffect, useSyncExternalStore } from 'react';
import { BackHandler, Platform, View } from 'react-native';

import {
  smileIDSampleLinkFacts,
  smileIDSampleProductOf,
  smileIDSampleRunOnly,
} from '../flow/use-smile-id-sample-flow-journey';
import { smileIDSampleLiveBindingsNow } from '../flow/use-smile-id-sample-token-binding-rules';
import { smileIDSampleLinkOf } from './use-smile-id-sample-deep-links';
import {
  smileIDSampleRunProductId,
  smileIDSampleStartRun,
  UseSmileIDSampleNavigationContext,
  UseSmileIDSampleNavigationModel,
} from './use-smile-id-sample-navigation';
import { smileIDSampleNjiaGraph } from './use-smile-id-sample-njia';
import { smileIDSampleSteps } from './use-smile-id-sample-steps';

/// How long after launch iOS may deliver the cold link a second time, which would otherwise replace the flow it opened.
const SMILE_ID_SAMPLE_COLD_LINK_WINDOW_MILLIS = 2_000;

let shared: UseSmileIDSampleNavigationModel | null = null;

/// The app's one navigation model, on njia's native core unless a test hands in `module` before first use.
export const smileIDSampleNavigation = (module?: NjiaNativeModule): UseSmileIDSampleNavigationModel =>
  (shared ??= new UseSmileIDSampleNavigationModel(smileIDSampleNjiaGraph(), module));

/// Forgets the model and its engine, for tests.
export const smileIDSampleResetNavigation = (): void => {
  shared?.dispose();
  shared = null;
  pending.length = 0;
  echo = null;
  clearTimeout(echoExpiry);
};

/// Links that arrived before the flow started, opened once it has.
const pending: string[] = [];

/// The cold link while iOS may still repeat it.
let echo: string | null = null;
let echoExpiry: ReturnType<typeof setTimeout> | undefined;

/// Starts the flow at the launch link, or runs `autostart` straight away, once the launch's session is linked.
export const smileIDSampleStartShell = (url: string | null, args: UseSmileIDSampleLaunchArgs): void => {
  const model = smileIDSampleNavigation();
  const autostart = smileIDSampleProductOf(args.autostart ?? undefined);
  const link = autostart === undefined ? smileIDSampleLinkOf(url) : null;
  const bindings = smileIDSampleLiveBindingsNow(args.scenario);
  model.start(link?.path, link === null ? new Set() : smileIDSampleLinkFacts(link, args.route, bindings));
  echo = url;
  echoExpiry = setTimeout(() => (echo = null), SMILE_ID_SAMPLE_COLD_LINK_WINDOW_MILLIS);
  const engine = model.engine!;
  if (autostart !== undefined) {
    smileIDSampleStartRun(engine, top(engine.state)!, autostart, smileIDSampleRunOnly(autostart, args.route, bindings));
  }
  for (const waiting of pending.splice(0)) smileIDSampleOpenLink(waiting, args);
};

/// Opens a link delivered while the app runs as a new flow, under the facts its product runs with.
export const smileIDSampleOpenLink = (url: string, args: UseSmileIDSampleLaunchArgs): void => {
  if (url === echo) {
    echo = null;
    return;
  }
  const model = smileIDSampleNavigation();
  if (model.engine === null) {
    pending.push(url);
    return;
  }
  const link = smileIDSampleLinkOf(url);
  if (link !== null) model.open(link.path, smileIDSampleLinkFacts(link, args.route, smileIDSampleLiveBindingsNow(args.scenario)));
};

/// The graph link of the screen showing, the step beneath any sheet, with its argument filled in; null before the flow starts.
export const smileIDSampleCurrentLink = (): string | null => {
  const engine = shared?.engine;
  if (engine == null) return null;
  const entries = engine.state.entries;
  for (let at = entries.length - 1; at >= 0; at -= 1) {
    const entry = entries[at]!;
    const step = stepOf(engine.graph, entry);
    if (step.presentation === 'sheet' || step.link === undefined) continue;
    const productId = smileIDSampleRunProductId(engine, entry) ?? '';
    return step.link.replace(':productId', productId).replace(/:(jobId|profileId)/, entry.arg ?? '');
  }
  return null;
};

/// The window's root: njia draws the three tabs' stacks from `spec/njia-graph.json`, and links open new flows.
export const UseSmileIDSampleShell = ({ args }: { args: UseSmileIDSampleLaunchArgs }) => {
  const theme = useSmileIDSampleTheme();
  const model = smileIDSampleNavigation();
  const engine = useSyncExternalStore(model.subscribe, () => model.engine);

  useEffect(() => {
    const subscription = Linking.addEventListener('url', ({ url }) => smileIDSampleOpenLink(url, args));
    return () => subscription.remove();
  }, [args]);

  // Back from the products tab's root finishes the flow: the app goes to the background and comes back on a fresh one.
  useEffect(
    () =>
      model.subscribe(() => {
        if (!model.done) return;
        if (Platform.OS === 'android') BackHandler.exitApp();
        model.restart();
      }),
    [model],
  );

  if (engine === null) return <View style={{ backgroundColor: theme.colors.background, flex: 1 }} />;

  return (
    <UseSmileIDSampleNavigationContext value={model}>
      <NjiaHost
        key={model.generation}
        engine={engine}
        steps={smileIDSampleSteps}
        // Each screen names itself `sample_*`, and a second test id on its view would replace the first.
        stepIds={false}
        // The design's own scrim and corners, which njia's default sheet style would replace.
        sheetStyle={{
          scrim: theme.colors.overlayScrim,
          shape: { borderTopLeftRadius: theme.shapes.sheet, borderTopRightRadius: theme.shapes.sheet },
        }}
      />
    </UseSmileIDSampleNavigationContext>
  );
};
