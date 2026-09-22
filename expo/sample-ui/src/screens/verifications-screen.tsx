import { useEffect, useMemo, useRef, useState } from 'react';
import { Pressable, ScrollView, StyleSheet, Text, View, type StyleProp, type ViewStyle } from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';

import { UseSmileIDSampleDateGroupHeader } from '../components/use-smile-id-sample-date-group-header';
import { UseSmileIDSampleEmptyState } from '../components/use-smile-id-sample-empty-state';
import { UseSmileIDSampleFilterChip } from '../components/use-smile-id-sample-filter-chip';
import { UseSmileIDSampleJobRow } from '../components/use-smile-id-sample-job-row';
import { UseSmileIDSampleSelectionBar } from '../components/use-smile-id-sample-selection-bar';
import { UseSmileIDSampleSelectionCheckbox } from '../components/use-smile-id-sample-selection-checkbox';
import { UseSmileIDSampleSwipeAction } from '../components/use-smile-id-sample-swipe-action';
import {
  smileIDSampleGroupByDay,
  smileIDSampleTimeLabels,
} from '../model/use-smile-id-sample-job-dates';
import {
  smileIDSampleJobFilters,
  smileIDSampleJobMatches,
  type UseSmileIDSampleJob,
  type UseSmileIDSampleJobFilter,
} from '../model/use-smile-id-sample-job';
import {
  UseSmileIDSampleSuffixedTestIds,
  UseSmileIDSampleTestIds,
} from '../use-smile-id-sample-test-ids';
import { useSmileIDSampleTheme } from '../theme/use-smile-id-sample-theme';

/// What the list renders. `jobs` is null until the store's first read: not loaded is not empty.
export type UseSmileIDSampleVerificationsState = {
  readonly jobs: readonly UseSmileIDSampleJob[] | null;
  readonly nowMillis: number;
};

type Props = {
  state: UseSmileIDSampleVerificationsState;
  onJobPress: (job: UseSmileIDSampleJob) => void;
  /// One handler for both removal paths, so a rule added to one cannot miss the other.
  onRemove: (ids: readonly string[]) => void;
  /// Select mode replaces the bottom chrome, so a host drawing its own must be told to stand down.
  onSelectingChange?: (selecting: boolean) => void;
  bottomInset?: number;
  style?: StyleProp<ViewStyle>;
};

/// The verifications list: filters with live counts, day headers, and two ways to hide a row.
export const VerificationsScreen = ({
  state,
  onJobPress,
  onRemove,
  onSelectingChange,
  bottomInset = 0,
  style,
}: Props) => {
  const theme = useSmileIDSampleTheme();
  const insets = useSafeAreaInsets();
  const [filterId, setFilterId] = useState(smileIDSampleJobFilters[0]!.id);
  const [selecting, setSelecting] = useState(false);
  const [selected, setSelected] = useState<readonly string[]>([]);

  // Held in a ref so an inline callback does not re-fire this, and so unmount can still report.
  const reportSelecting = useRef(onSelectingChange);

  // Declared first, so the report below always reads the callback this render was given.
  useEffect(() => {
    reportSelecting.current = onSelectingChange;
  }, [onSelectingChange]);

  useEffect(() => {
    reportSelecting.current?.(selecting);
  }, [selecting]);

  // Leaving while selecting would otherwise strand a host that had stood its own chrome down.
  useEffect(() => () => reportSelecting.current?.(false), []);

  const jobs = state.jobs;
  const filter =
    smileIDSampleJobFilters.find((entry) => entry.id === filterId) ?? smileIDSampleJobFilters[0]!;

  // Recomputed on the rows and the filter, never on a clock tick.
  const visible = useMemo(
    () => (jobs ?? []).filter((job) => smileIDSampleJobMatches(filter, job)),
    [jobs, filter],
  );
  const days = useMemo(
    () => smileIDSampleGroupByDay(visible, state.nowMillis),
    [visible, state.nowMillis],
  );
  const times = useMemo(() => smileIDSampleTimeLabels(visible), [visible]);
  const counts = useMemo(() => countsFor(jobs ?? []), [jobs]);

  /// Both removal paths run this: the swipe and the selection bar, so neither can miss a rule.
  const removeRows = (ids: readonly string[]) => {
    if (ids.length === 0) return;
    const remaining = (jobs ?? []).filter((job) => !ids.includes(job.id));
    // Removing the last row of the active filter falls back to All, or the screen is blank under a
    // chip reading 0 with nothing to explain why.
    if (!remaining.some((job) => smileIDSampleJobMatches(filter, job))) {
      setFilterId(smileIDSampleJobFilters[0]!.id);
    }
    setSelected([]);
    setSelecting(false);
    onRemove(ids);
  };

  const toggle = (id: string) =>
    setSelected((current) =>
      current.includes(id) ? current.filter((entry) => entry !== id) : [...current, id],
    );

  return (
    <View style={[styles.screen, { backgroundColor: theme.colors.background }, style]}>
      <ScrollView
        testID={UseSmileIDSampleTestIds.VERIFICATIONS_SCREEN}
        contentContainerStyle={{
          paddingTop: insets.top,
          // In select mode the selection bar replaces the nav bar, so the inset does not change.
          paddingBottom: bottomInset,
          rowGap: theme.dimens.spacing.xs,
        }}
      >
        <View
          style={[
            styles.header,
            { paddingHorizontal: theme.dimens.spacing.md, paddingVertical: theme.dimens.spacing.xs },
          ]}
        >
          <Text style={[theme.type.textStyleHeadingPage, styles.title, { color: theme.colors.textTitle }]}>
            Verifications
          </Text>
          {(jobs ?? []).length > 0 ? (
            <Pressable
              testID={UseSmileIDSampleTestIds.SELECT_TOGGLE}
              accessibilityRole="button"
              onPress={() => {
                setSelecting((current) => !current);
                setSelected([]);
              }}
              // The platform's own minimum target, which is what sets the header row's height.
              style={[
                styles.selectToggle,
                { minHeight: theme.dimens.touchTarget, minWidth: theme.dimens.touchTarget, paddingHorizontal: theme.dimens.spacing.xs },
              ]}
            >
              <Text style={[theme.type.textStyleButtonSm, { color: theme.colors.primary }]}>
                {selecting ? 'Cancel' : 'Select'}
              </Text>
            </Pressable>
          ) : null}
        </View>

        <ScrollView
          horizontal
          showsHorizontalScrollIndicator={false}
          contentContainerStyle={{
            paddingHorizontal: theme.dimens.spacing.md,
            columnGap: theme.dimens.spacing.xs,
          }}
        >
          {smileIDSampleJobFilters.map((entry) => (
            <UseSmileIDSampleFilterChip
              key={entry.id}
              label={entry.label}
              count={counts[entry.id] ?? 0}
              selected={entry.id === filter.id}
              onPress={() => setFilterId(entry.id)}
              testID={UseSmileIDSampleSuffixedTestIds.filterChip(entry.id)}
              countTestID={UseSmileIDSampleSuffixedTestIds.filterCount(entry.id)}
            />
          ))}
        </ScrollView>

        {jobs !== null && visible.length === 0 ? (
          <UseSmileIDSampleEmptyState
            // Two texts behind one id: nothing submitted yet, versus nothing matching this filter.
            text={
              jobs.length === 0
                ? 'Nothing submitted yet'
                : 'No verifications match this filter'
            }
            supportingText={
              jobs.length === 0 ? 'Start a verification from the Products tab' : undefined
            }
            testID={UseSmileIDSampleTestIds.VERIFICATIONS_EMPTY}
          />
        ) : null}

        {days.map((day) => (
          <View
            key={`${day.relative}-${day.absolute}`}
            style={{ paddingHorizontal: theme.dimens.spacing.md, rowGap: theme.dimens.spacing.xs }}
          >
            <UseSmileIDSampleDateGroupHeader relative={day.relative} absolute={day.absolute} />
            {day.jobs.map((job) => (
              <JobEntry
                key={job.id}
                job={job}
                index={(jobs ?? []).indexOf(job)}
                time={times[job.id] ?? ''}
                selecting={selecting}
                checked={selected.includes(job.id)}
                onToggle={() => toggle(job.id)}
                onPress={() => onJobPress(job)}
                onSwipeRemove={() => removeRows([job.id])}
              />
            ))}
          </View>
        ))}
      </ScrollView>

      {selecting ? (
        <UseSmileIDSampleSelectionBar
          selectedCount={selected.length}
          onRemove={() => removeRows(selected)}
        />
      ) : null}
    </View>
  );
};

const JobEntry = ({
  job,
  index,
  time,
  selecting,
  checked,
  onToggle,
  onPress,
  onSwipeRemove,
}: {
  job: UseSmileIDSampleJob;
  index: number;
  time: string;
  selecting: boolean;
  checked: boolean;
  onToggle: () => void;
  onPress: () => void;
  onSwipeRemove: () => void;
}) => {
  const theme = useSmileIDSampleTheme();
  const row = (
    <UseSmileIDSampleJobRow
      product={job.product}
      jobId={job.id.length > 8 ? `${job.id.slice(0, 8)}…` : job.id}
      time={time}
      status={job.status}
      onPress={selecting ? onToggle : onPress}
      testID={UseSmileIDSampleSuffixedTestIds.jobRow(index)}
      statusTestID={UseSmileIDSampleTestIds.JOB_ROW_STATUS}
    />
  );

  if (!selecting) {
    return <UseSmileIDSampleSwipeAction onAction={onSwipeRemove}>{row}</UseSmileIDSampleSwipeAction>;
  }

  // The checkbox sits beside the card, as the design draws it: inside it cost the title its width.
  return (
    <View style={[styles.selectRow, { columnGap: theme.dimens.spacing.xs }]}>
      <UseSmileIDSampleSelectionCheckbox
        checked={checked}
        onCheckedChange={onToggle}
        testID={UseSmileIDSampleSuffixedTestIds.selectionCheckbox(index)}
      />
      <View style={styles.selectRowCard}>{row}</View>
    </View>
  );
};

/// One pass over the rows for all four chips, so a count cannot disagree with the list beside it.
const countsFor = (jobs: readonly UseSmileIDSampleJob[]): Readonly<Record<string, number>> => {
  const counts: Record<string, number> = {};
  for (const filter of smileIDSampleJobFilters) {
    counts[filter.id] = jobs.filter((job) => smileIDSampleJobMatches(filter, job)).length;
  }
  return counts;
};

/// Exported for the screen's own tests, which assert the counts the delete flow keys off.
export const smileIDSampleFilterCounts = countsFor;

export type { UseSmileIDSampleJobFilter };

const styles = StyleSheet.create({
  screen: { flex: 1 },
  header: { alignItems: 'center', flexDirection: 'row', width: '100%' },
  selectToggle: { alignItems: 'center', justifyContent: 'center' },
  title: { flex: 1 },
  selectRow: { alignItems: 'center', flexDirection: 'row', width: '100%' },
  selectRowCard: { flex: 1 },
});
