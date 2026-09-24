import { useState } from 'react';
import { PixelRatio, Pressable, StyleSheet, Text, View, type StyleProp, type ViewStyle } from 'react-native';

import {
  smileIDSampleResultFields,
  type UseSmileIDSampleResult,
} from '../model/use-smile-id-sample-result';
import { smileLabelSize, smileLabelTracking } from '../smile-product-hues';
import { atSize } from '../theme/smile-type';
import { useSmileIDSampleTheme } from '../theme/use-smile-id-sample-theme';
import { UseSmileIDSampleTestIds } from '../use-smile-id-sample-test-ids';

/// Stable: flows assert on it to prove a value was absent.
const NULL_VALUE = '—';

const LABELS: Record<(typeof smileIDSampleResultFields)[number]['field'], string> = {
  activeScenario: 'Scenario',
  activeTheme: 'Theme',
  route: 'Route',
  environment: 'Environment',
  jobId: 'Job id',
  userId: 'User id',
  jobStatus: 'Job status',
  resultCallbackCount: 'Result callbacks',
  refreshCallbackCount: 'Refresh callbacks',
  lastError: 'Last error',
  sdkVersion: 'SDK version',
};

type Props = {
  result: UseSmileIDSampleResult;
  style?: StyleProp<ViewStyle>;
};

/// Every `spec/result-card.schema.json` field under its own id, expanded by default since a collapsed field leaves the tree.
export const UseSmileIDSampleResultCard = ({ result, style }: Props) => {
  const theme = useSmileIDSampleTheme();
  const [expanded, setExpanded] = useState(true);
  return (
    <View
      testID={UseSmileIDSampleTestIds.RESULT_CARD}
      style={[
        styles.card,
        {
          backgroundColor: theme.colors.surfaceAlt,
          borderRadius: theme.shapes.card,
          paddingVertical: theme.dimens.spacing.sm,
        },
        style,
      ]}
    >
      <Pressable
        accessibilityRole="button"
        accessibilityLabel={expanded ? 'Collapse SDK result' : 'Expand SDK result'}
        onPress={() => setExpanded((open) => !open)}
        style={[
          styles.header,
          {
            columnGap: theme.dimens.spacing.xs,
            minHeight: theme.dimens.space[40],
            paddingHorizontal: theme.dimens.spacing.md,
          },
        ]}
      >
        <Text style={[styles.grow, overline(theme)]}>SDK RESULT</Text>
        <Text style={[theme.type.textStyleCaption, { color: theme.colors.textLink }]}>
          {expanded ? 'Hide' : 'Show'}
        </Text>
      </Pressable>
      {expanded
        ? smileIDSampleResultFields.map(({ field, testId }) => (
            <ResultField key={field} label={LABELS[field]} value={displayed(result[field])} testID={testId} />
          ))
        : null}
    </View>
  );
};

/// The compact form on products while a run is in flight: three fields, under the same ids as the card.
export const UseSmileIDSampleResultLine = ({ result, style }: Props) => {
  const theme = useSmileIDSampleTheme();
  const stacks = PixelRatio.getFontScale() > 1;
  return (
    <View
      testID={UseSmileIDSampleTestIds.RESULT_CARD}
      style={[
        stacks ? styles.stacked : styles.line,
        {
          backgroundColor: theme.colors.surfaceAlt,
          borderRadius: theme.shapes.card,
          columnGap: theme.dimens.spacing.xs,
          rowGap: theme.dimens.space[4],
          minHeight: theme.dimens.space[40],
          paddingHorizontal: theme.dimens.spacing.md,
          paddingVertical: theme.dimens.spacing.xs,
        },
        style,
      ]}
    >
      <Text style={overline(theme)}>SDK</Text>
      <ResultValue value={result.jobStatus} testID={UseSmileIDSampleTestIds.RESULT_JOB_STATUS} grow={!stacks} />
      <ResultValue value={result.activeScenario} testID={UseSmileIDSampleTestIds.RESULT_ACTIVE_SCENARIO} />
      <ResultValue value={result.route} testID={UseSmileIDSampleTestIds.RESULT_ROUTE} />
    </View>
  );
};

/// One label and its value; a null value still renders, since a missing id and an empty one are different failures.
const ResultField = ({ label, value, testID }: { label: string; value: string; testID: string }) => {
  const theme = useSmileIDSampleTheme();
  const stacks = PixelRatio.getFontScale() > 1;
  return (
    <View
      style={[
        stacks ? styles.fieldStacked : styles.field,
        {
          columnGap: theme.dimens.spacing.xs,
          rowGap: theme.dimens.space[4],
          paddingHorizontal: theme.dimens.spacing.md,
          paddingVertical: theme.dimens.space[4],
        },
      ]}
    >
      <Text style={[theme.type.textStyleCaption, { color: theme.colors.textMuted }]}>{label}</Text>
      <ResultValue value={value} testID={testID} grow={!stacks} alignEnd={!stacks} />
    </View>
  );
};

const ResultValue = ({
  value,
  testID,
  grow = false,
  alignEnd = false,
}: {
  value: string;
  testID: string;
  grow?: boolean;
  alignEnd?: boolean;
}) => {
  const theme = useSmileIDSampleTheme();
  return (
    <Text
      testID={testID}
      style={[
        theme.type.textStyleCaption,
        { color: theme.colors.textBody },
        grow ? styles.grow : null,
        alignEnd ? styles.end : null,
      ]}
    >
      {value}
    </Text>
  );
};

const displayed = (value: string | number | null): string => (value === null ? NULL_VALUE : String(value));

const overline = (theme: ReturnType<typeof useSmileIDSampleTheme>) => [
  atSize(theme.type.textStyleOverline, smileLabelSize),
  { letterSpacing: smileLabelTracking, color: theme.colors.textMuted },
];

const styles = StyleSheet.create({
  card: { width: '100%' },
  header: { alignItems: 'center', flexDirection: 'row' },
  line: { alignItems: 'center', flexDirection: 'row' },
  stacked: { alignItems: 'flex-start', flexDirection: 'column' },
  field: { alignItems: 'baseline', flexDirection: 'row' },
  fieldStacked: { flexDirection: 'column' },
  grow: { flex: 1 },
  end: { textAlign: 'right' },
});
