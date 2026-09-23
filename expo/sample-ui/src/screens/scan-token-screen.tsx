import { useEffect, useEffectEvent, useState, type ComponentType } from 'react';
import { ScrollView, StyleSheet, Text, View, type StyleProp, type TextStyle, type ViewStyle } from 'react-native';

import { UseSmileIDSampleIcon } from '../components/use-smile-id-sample-icon';
import { UseSmileIDSampleScanGlyph } from '../components/use-smile-id-sample-scan-glyph';
import {
  UseSmileIDSampleScanSheet,
  smileIDSampleScanSheetDefaults,
  type UseSmileIDSampleScanSheetState,
} from '../components/use-smile-id-sample-scan-sheet';
import { UseSmileIDSampleScanStatus } from '../components/use-smile-id-sample-scan-status';
import {
  UseSmileIDSampleTopAppBar,
  UseSmileIDSampleTopAppBarButton,
} from '../components/use-smile-id-sample-top-app-bar';
import type { UseSmileIDSampleEnvironment } from '../model/use-smile-id-sample-result';
import { UseSmileIDSampleScanReason, type UseSmileIDSampleScanState } from '../model/use-smile-id-sample-scan-state';
import type {
  UseSmileIDSampleSimulatedBindings,
  UseSmileIDSampleSimulatedSpan,
} from '../model/use-smile-id-sample-simulated-scan';
import { smileIDSampleDecodeToken } from '../state/use-smile-id-sample-token-decoder';
import {
  smileIDSampleCountdown,
  smileIDSampleSessionRemaining,
  type UseSmileIDSampleTokenSession,
} from '../state/use-smile-id-sample-token-session';
import { atSize } from '../theme/smile-type';
import { useSmileIDSampleTheme } from '../theme/use-smile-id-sample-theme';
import { UseSmileIDSampleTestIds } from '../use-smile-id-sample-test-ids';

const SCAN_TITLE = 'Point at a Smile token QR';
const SCAN_CAPTION = 'Line up the code inside the frame to link this device to a verification session.';
const SCAN_BODY_SIZE = 12.5;
/// Long enough to read "Session linked" and its handle, short enough not to feel like a wait.
const LINKED_DWELL_MILLIS = 900;
/// The design's own reticle opacity, which keeps it from competing with the preview.
const RETICLE_IDLE_ALPHA = 0.45;
const RETICLE_WIDTH_FRACTION = 0.72;
const RETICLE_HEIGHT_FRACTION = 0.52;
const COPY_SHADOW_BLUR = 8;

/// What the host's camera preview is handed: whether to read frames, and where to send a code.
export type UseSmileIDSampleViewfinderProps = {
  readonly enabled: boolean;
  readonly onCandidate: (candidate: string) => void;
};

/// A moment the host may acknowledge in the hand, since a silent success at a scanner feels like a freeze.
export type UseSmileIDSampleScanFeedback = 'found' | 'linked' | 'rejected';

type Props = {
  onBack: () => void;
  onLink: (session: UseSmileIDSampleTokenSession) => void;
  onSimulate: (
    span: UseSmileIDSampleSimulatedSpan,
    bindings: UseSmileIDSampleSimulatedBindings,
    environment: UseSmileIDSampleEnvironment,
  ) => void;
  /// The host's clipboard, since reading it is platform-owned; absent drops the Paste action.
  onPaste?: () => Promise<string | null>;
  /// Why the screen opened when something sent the user here; absent when opened deliberately.
  reason?: UseSmileIDSampleScanReason | null;
  torchOn?: boolean;
  onTorchToggle?: () => void;
  /// The host's camera preview. Absent — in a golden, or a host without a camera — the screen keeps the glyph.
  Viewfinder?: ComponentType<UseSmileIDSampleViewfinderProps>;
  onFeedback?: (feedback: UseSmileIDSampleScanFeedback) => void;
  style?: StyleProp<ViewStyle>;
};

/// Scan token. A token arrives from the host's camera, by hand, or from a simulated scan, and links only once it decodes.
export const ScanTokenScreen = ({
  onBack,
  onLink,
  onSimulate,
  onPaste,
  reason,
  torchOn = false,
  onTorchToggle,
  Viewfinder,
  onFeedback,
  style,
}: Props) => {
  const theme = useSmileIDSampleTheme();
  const [sheet, setSheet] = useState<UseSmileIDSampleScanSheetState>(smileIDSampleScanSheetDefaults);
  const [scan, setScan] = useState<UseSmileIDSampleScanState>({ kind: 'searching' });
  const [area, setArea] = useState({ width: 0, height: 0 });
  // Held apart from the display state: the credential has no business in something a pill renders.
  const [linked, setLinked] = useState<UseSmileIDSampleTokenSession | null>(null);
  const announce = useEffectEvent((feedback: UseSmileIDSampleScanFeedback) => onFeedback?.(feedback));
  const leave = useEffectEvent(() => {
    if (linked !== null) onLink(linked);
  });

  // Scanned, pasted or typed, a candidate is judged here and nowhere else — proving it parses, never that it is valid.
  const judge = (candidate: string, fromField: boolean) => {
    if (!fromField) setScan({ kind: 'found' });
    const decoded = smileIDSampleDecodeToken(candidate);
    if (decoded.kind === 'decoded') {
      setLinked(decoded.session);
      setSheet((current) => ({ ...current, rejection: null }));
      setScan({
        kind: 'linked',
        handle: decoded.session.id,
        remaining: smileIDSampleCountdown(smileIDSampleSessionRemaining(decoded.session, Date.now())),
      });
      return;
    }
    // The field's error sits under the field; a scanned code has no field, so it answers in the pill. Never both.
    if (fromField) setSheet((current) => ({ ...current, rejection: decoded.reason }));
    else setScan({ kind: 'rejected', reason: decoded.reason });
  };

  useEffect(() => {
    if (scan.kind === 'searching') return undefined;
    announce(scan.kind);
    if (scan.kind !== 'linked') return undefined;
    // Held long enough to be read, then the screen leaves: navigating on the decode frame looked like nothing happened.
    const timer = setTimeout(leave, LINKED_DWELL_MILLIS);
    return () => clearTimeout(timer);
  }, [scan]);

  const caption = reason == null ? SCAN_CAPTION : UseSmileIDSampleScanReason[reason];
  const titleStyle = theme.type.textStyleTitle;
  const captionStyle = atSize(theme.type.textStyleCaption, SCAN_BODY_SIZE);
  const searching = scan.kind === 'searching';
  const reticleSize = Math.min(area.width * RETICLE_WIDTH_FRACTION, area.height * RETICLE_HEIGHT_FRACTION);
  const overCamera: TextStyle = {
    color: theme.colors.textInverse,
    textShadowColor: theme.colors.textTitle,
    textShadowRadius: COPY_SHADOW_BLUR,
  };
  const reticleTint = {
    searching: theme.colors.textInverse,
    found: theme.colors.infoFill,
    linked: theme.colors.successFill,
    rejected: theme.colors.errorFill,
  }[scan.kind];

  return (
    <View
      testID={UseSmileIDSampleTestIds.SCAN_TOKEN_SCREEN}
      style={[styles.screen, { backgroundColor: theme.colors.background }, style]}
    >
      <UseSmileIDSampleTopAppBar
        title="Scan token"
        onBack={onBack}
        action={
          <UseSmileIDSampleTopAppBarButton
            accessibilityLabel={torchOn ? 'Turn flash off' : 'Turn flash on'}
            onPress={() => onTorchToggle?.()}
            emphasis="Filled"
            glyph={(tint) => <UseSmileIDSampleIcon name="flash" tint={tint} />}
          />
        }
      />
      <View
        style={styles.area}
        onLayout={(event) => setArea({ width: event.nativeEvent.layout.width, height: event.nativeEvent.layout.height })}
      >
        {Viewfinder === undefined ? (
          // Centring and scrolling are one requirement: at 2x the copy no longer fits above the sheet.
          <ScrollView
            contentContainerStyle={[
              styles.placeholder,
              { padding: theme.dimens.spacing.md, rowGap: theme.dimens.spacing.sm },
            ]}
          >
            <UseSmileIDSampleScanGlyph />
            <Text style={[titleStyle, styles.copy, { color: theme.colors.textTitle }]}>{SCAN_TITLE}</Text>
            <Text style={[captionStyle, styles.copy, { color: theme.colors.textMuted }]}>{caption}</Text>
          </ScrollView>
        ) : (
          <>
            <View style={StyleSheet.absoluteFill}>
              <Viewfinder enabled={searching} onCandidate={(candidate) => judge(candidate, false)} />
            </View>
            <View
              pointerEvents="box-none"
              style={[styles.overlay, { padding: theme.dimens.spacing.md, rowGap: theme.dimens.spacing.md }]}
            >
              {reticleSize > 0 ? (
                <UseSmileIDSampleScanGlyph
                  size={reticleSize}
                  tint={reticleTint}
                  style={{ opacity: searching ? RETICLE_IDLE_ALPHA : 1 }}
                />
              ) : null}
              {/* Straight on the camera: a container here was a white slab over the preview. */}
              {searching ? (
                <>
                  <Text style={[titleStyle, styles.copy, overCamera]}>{SCAN_TITLE}</Text>
                  <Text style={[captionStyle, styles.copy, overCamera]}>{caption}</Text>
                </>
              ) : (
                <UseSmileIDSampleScanStatus
                  state={scan}
                  // Re-enables the scanner, whose last-seen code clears with it so the same QR reads.
                  onRetry={() => {
                    setSheet((current) => ({ ...current, rejection: null }));
                    setScan({ kind: 'searching' });
                  }}
                />
              )}
            </View>
          </>
        )}
      </View>
      <UseSmileIDSampleScanSheet
        state={sheet}
        onTokenChange={(token) => setSheet((current) => ({ ...current, token, rejection: null }))}
        onPaste={
          onPaste === undefined
            ? undefined
            : () => {
                void onPaste()
                  .catch(() => null)
                  .then((pasted) =>
                    setSheet((current) =>
                      pasted == null || pasted.trim().length === 0
                        ? { ...current, rejection: 'The clipboard holds no text to paste.' }
                        : { ...current, token: pasted, rejection: null },
                    ),
                  );
              }
        }
        onLink={() => judge(sheet.token, true)}
        onExpandToggle={() => setSheet((current) => ({ ...current, expanded: !current.expanded }))}
        onSpanSelect={(span) => setSheet((current) => ({ ...current, span }))}
        onEnvironmentSelect={(environment) => setSheet((current) => ({ ...current, environment }))}
        onBindingsChange={(bindings) => setSheet((current) => ({ ...current, bindings }))}
        onSimulate={() => onSimulate(sheet.span, sheet.bindings, sheet.environment)}
      />
    </View>
  );
};

const styles = StyleSheet.create({
  screen: { flex: 1 },
  area: { flex: 1, width: '100%' },
  placeholder: { alignItems: 'center', flexGrow: 1, justifyContent: 'center' },
  overlay: { alignItems: 'center', flex: 1, justifyContent: 'center' },
  // Width-bound, because centred copy that is not wraps past both edges instead.
  copy: { textAlign: 'center', width: '100%' },
});
