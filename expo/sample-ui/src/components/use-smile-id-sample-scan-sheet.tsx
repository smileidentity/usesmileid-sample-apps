import { Pressable, StyleSheet, Text, View, type StyleProp, type ViewStyle } from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';

import { UseSmileIDSampleButton } from './use-smile-id-sample-button';
import { UseSmileIDSampleIcon } from './use-smile-id-sample-icon';
import { UseSmileIDSampleSectionLabel } from './use-smile-id-sample-section-label';
import { UseSmileIDSampleTextInput } from './use-smile-id-sample-text-input';
import { smileIDSampleEnvironmentLabels } from '../model/use-smile-id-sample-environment';
import { smileIDSampleEnvironments, type UseSmileIDSampleEnvironment } from '../model/use-smile-id-sample-result';
import {
  smileIDSampleSimulatedBindingsDefaults,
  smileIDSampleSimulatedSpans,
  type UseSmileIDSampleSimulatedBindings,
  type UseSmileIDSampleSimulatedSpan,
} from '../model/use-smile-id-sample-simulated-scan';
import { smileCardStrokeWidth } from '../smile-product-hues';
import { insetForBorder, touchTargetStyle } from '../theme/smile-compose-layout';
import { atSize, atWeight } from '../theme/smile-type';
import { useSmileIDSampleTheme } from '../theme/use-smile-id-sample-theme';
import { UseSmileIDSampleSuffixedTestIds, UseSmileIDSampleTestIds } from '../use-smile-id-sample-test-ids';

const SHEET_ACTION_SIZE = 13;

/// What the sheet renders; the screen owns the state.
export type UseSmileIDSampleScanSheetState = {
  readonly token: string;
  /// Why the entered token is not a session; never the token.
  readonly rejection: string | null;
  readonly span: UseSmileIDSampleSimulatedSpan;
  /// Which host the minted token's `api_url` will name.
  readonly environment: UseSmileIDSampleEnvironment;
  readonly bindings: UseSmileIDSampleSimulatedBindings;
  /// The mint controls, closed by default.
  readonly expanded: boolean;
};

export const smileIDSampleScanSheetDefaults: UseSmileIDSampleScanSheetState = {
  token: '',
  rejection: null,
  span: smileIDSampleSimulatedSpans[0]!,
  environment: 'sandbox',
  bindings: smileIDSampleSimulatedBindingsDefaults,
  expanded: false,
};

type Props = {
  state: UseSmileIDSampleScanSheetState;
  onTokenChange: (token: string) => void;
  /// Absent drops the Paste action.
  onPaste?: () => void;
  onLink: () => void;
  onExpandToggle: () => void;
  onSpanSelect: (span: UseSmileIDSampleSimulatedSpan) => void;
  onEnvironmentSelect: (environment: UseSmileIDSampleEnvironment) => void;
  onBindingsChange: (bindings: UseSmileIDSampleSimulatedBindings) => void;
  onSimulate: () => void;
  style?: StyleProp<ViewStyle>;
};

/// The sheet under the scanner: manual entry and a simulated scan.
export const UseSmileIDSampleScanSheet = ({
  state,
  onTokenChange,
  onPaste,
  onLink,
  onExpandToggle,
  onSpanSelect,
  onEnvironmentSelect,
  onBindingsChange,
  onSimulate,
  style,
}: Props) => {
  const theme = useSmileIDSampleTheme();
  const insets = useSafeAreaInsets();
  const actionFont = atSize(atWeight(theme.type.linkFont, 700), SHEET_ACTION_SIZE);

  return (
    <View
      style={[
        styles.sheet,
        {
          backgroundColor: theme.colors.surface,
          borderTopLeftRadius: theme.shapes.sheet,
          borderTopRightRadius: theme.shapes.sheet,
          padding: theme.dimens.spacing.md,
          paddingBottom: theme.dimens.spacing.md + insets.bottom,
          rowGap: theme.dimens.spacing.sm,
        },
        style,
      ]}
    >
      <UseSmileIDSampleTextInput
        value={state.token}
        onValueChange={onTokenChange}
        placeholder="Or enter token manually"
        isError={state.rejection !== null}
        errorMessage={state.rejection}
        // Masked: a bearer credential, kept out of screenshots and hierarchy dumps.
        masked
        testID={UseSmileIDSampleTestIds.TOKEN_MANUAL_ENTRY}
        testIDOnField
        leading={(tint) => <UseSmileIDSampleIcon name="tokenScan" tint={tint} size={theme.dimens.size['icon-md']} />}
        trailing={
          onPaste === undefined
            ? undefined
            : () => (
                <Pressable
                  testID={UseSmileIDSampleTestIds.TOKEN_PASTE}
                  accessibilityRole="button"
                  onPress={onPaste}
                  style={[styles.action, touchTargetStyle(theme), { paddingHorizontal: theme.dimens.spacing.xs }]}
                >
                  <Text numberOfLines={1} style={[actionFont, { color: theme.colors.primary }]}>
                    Paste
                  </Text>
                </Pressable>
              )
        }
      />
      {state.token.trim().length > 0 ? <UseSmileIDSampleButton text="Link token" onPress={onLink} /> : null}
      <Pressable
        accessibilityRole="button"
        accessibilityState={{ expanded: state.expanded }}
        onPress={onExpandToggle}
        style={[styles.row, { columnGap: theme.dimens.spacing.xs, paddingVertical: theme.dimens.spacing.xxs }]}
      >
        <UseSmileIDSampleSectionLabel text="SIMULATED SCAN" style={styles.grow} />
        <UseSmileIDSampleIcon
          name={state.expanded ? 'chevronDown' : 'chevron'}
          tint={theme.colors.textMuted}
          size={theme.dimens.size['icon-md']}
        />
      </Pressable>
      {state.expanded ? (
        <>
          <View style={[styles.flow, { gap: theme.dimens.spacing.xs }]}>
            {smileIDSampleSimulatedSpans.map((span) => (
              <ScanSheetChip
                key={span.id}
                label={span.label}
                selected={state.span.id === span.id}
                role="radio"
                onPress={() => onSpanSelect(span)}
              />
            ))}
          </View>
          <View style={[styles.flow, { gap: theme.dimens.spacing.xs }]}>
            {smileIDSampleEnvironments.map((environment) => (
              <ScanSheetChip
                key={environment}
                label={smileIDSampleEnvironmentLabels[environment]}
                selected={state.environment === environment}
                role="radio"
                onPress={() => onEnvironmentSelect(environment)}
                testID={UseSmileIDSampleSuffixedTestIds.tokenEnvironment(environment)}
              />
            ))}
          </View>
          <View style={[styles.flow, { gap: theme.dimens.spacing.xs }]}>
            <ScanSheetChip
              label="Binds consent"
              selected={state.bindings.consent}
              role="checkbox"
              onPress={() => onBindingsChange({ ...state.bindings, consent: !state.bindings.consent })}
            />
            <ScanSheetChip
              label="Binds details"
              selected={state.bindings.userDetails}
              role="checkbox"
              onPress={() => onBindingsChange({ ...state.bindings, userDetails: !state.bindings.userDetails })}
            />
          </View>
        </>
      ) : null}
      <UseSmileIDSampleButton
        text="Simulate a successful scan"
        onPress={onSimulate}
        testID={UseSmileIDSampleTestIds.TOKEN_SIMULATE}
      />
    </View>
  );
};

type ChipProps = {
  label: string;
  selected: boolean;
  role: 'radio' | 'checkbox';
  onPress: () => void;
  testID?: string;
};

/// The filter chip's shape without its count.
const ScanSheetChip = ({ label, selected, role, onPress, testID }: ChipProps) => {
  const theme = useSmileIDSampleTheme();
  const stroke = selected ? 0 : smileCardStrokeWidth;
  return (
    <Pressable
      testID={testID}
      accessibilityRole={role}
      accessibilityState={{ checked: selected }}
      onPress={onPress}
      style={[styles.target, touchTargetStyle(theme)]}
    >
      <View
        style={[
          styles.chip,
          {
            borderRadius: theme.shapes.chip,
            backgroundColor: selected ? theme.colors.primary : theme.colors.filterChip.background,
            borderWidth: stroke,
            borderColor: selected ? 'transparent' : theme.colors.filterChip.border,
            minHeight: theme.dimens.space[32],
            paddingHorizontal: insetForBorder(theme.dimens.spacing.sm, stroke),
            paddingVertical: insetForBorder(theme.dimens.spacing.xs, stroke),
          },
        ]}
      >
        <Text
          style={[
            atSize(atWeight(theme.type.filterChipFont, 700), SHEET_ACTION_SIZE),
            { color: selected ? theme.colors.onPrimary : theme.colors.filterChip.label },
          ]}
        >
          {label}
        </Text>
      </View>
    </Pressable>
  );
};

const styles = StyleSheet.create({
  sheet: { width: '100%' },
  row: { alignItems: 'center', flexDirection: 'row', width: '100%' },
  grow: { flex: 1 },
  flow: { flexDirection: 'row', flexWrap: 'wrap', width: '100%' },
  action: { alignItems: 'center', justifyContent: 'center' },
  target: { alignItems: 'center', justifyContent: 'center' },
  chip: { alignItems: 'center', justifyContent: 'center' },
});
