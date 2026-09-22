import 'package:flutter/material.dart';

import '../components/use_smileid_sample_date_group_header.dart';
import '../components/use_smileid_sample_empty_state.dart';
import '../components/use_smileid_sample_filter_chip.dart';
import '../components/use_smileid_sample_job_row.dart';
import '../components/use_smileid_sample_selection_checkbox.dart';
import '../components/use_smileid_sample_spaced.dart';
import '../components/use_smileid_sample_swipe_action.dart';
import '../components/use_smileid_sample_toast.dart';
import '../model/use_smileid_sample_job.dart';
import '../theme/use_smileid_sample_colors.dart';
import '../theme/use_smileid_sample_theme.dart';
import '../theme/use_smileid_sample_typography.dart';
import '../tokens/smile_tokens.dart';
import '../use_smileid_sample_test_ids.dart';

/// What the verifications list draws.
class UseSmileIDSampleVerificationsState {
  /// A null [jobs] means the store has not answered yet, which draws neither empty state.
  const UseSmileIDSampleVerificationsState({
    required this.jobs,
    required this.nowMillis,
    this.filter = UseSmileIDSampleJobFilter.all,
    this.selectMode = false,
    this.selected = const <String>{},
    this.removedCount,
  });

  /// Every stored job, or null while the store is still answering.
  final List<UseSmileIDSampleJob>? jobs;

  /// The clock the day headers are read against.
  final int nowMillis;

  /// The active chip.
  final UseSmileIDSampleJobFilter filter;

  /// Whether the rows are being picked rather than opened.
  final bool selectMode;

  /// The ids picked so far.
  final Set<String> selected;

  /// How many rows the last removal took, which the toast reports; null when there is no notice.
  final int? removedCount;

  /// The jobs the active chip keeps, newest first.
  List<UseSmileIDSampleJob> get visible =>
      jobs?.where(filter.matches).toList() ?? const <UseSmileIDSampleJob>[];

  /// How many jobs each chip matches, counted against the WHOLE list rather than the visible one.
  int countFor(UseSmileIDSampleJobFilter chip) =>
      jobs?.where(chip.matches).length ?? 0;
}

/// The verifications list: the title, the chips, and the rows grouped by day.
class UseSmileIDSampleVerificationsScreen extends StatelessWidget {
  /// [bottomInset] is the room the floating nav bar needs; the screen is not inset by it.
  const UseSmileIDSampleVerificationsScreen({
    required this.state,
    required this.onFilterChanged,
    this.onJobTap,
    this.onSelectModeChanged,
    this.onSelectionChanged,
    this.onRemove,
    this.onUndo,
    this.bottomInset = 0,
    super.key,
  });

  /// What to render.
  final UseSmileIDSampleVerificationsState state;

  /// Switches the active chip.
  final void Function(UseSmileIDSampleJobFilter filter) onFilterChanged;

  /// Opens one job's detail page.
  final void Function(UseSmileIDSampleJob job)? onJobTap;

  /// Enters or leaves select mode; a null callback hides the header action entirely.
  final void Function(bool on)? onSelectModeChanged;

  /// Picks or unpicks one row.
  final void Function(String jobId, bool selected)? onSelectionChanged;

  /// Hides rows from this app's list; the same callback serves the swipe and the selection bar.
  final void Function(Set<String> ids)? onRemove;

  /// Puts the last removal back; the offer is consumed on dismissal, so there is no second chance.
  final VoidCallback? onUndo;

  /// Trailing room so the last row can scroll clear of the floating bar.
  final double bottomInset;

  @override
  Widget build(BuildContext context) {
    final UseSmileIDSampleColors colors = UseSmileIDSampleTheme.colorsOf(
      context,
    );
    final List<UseSmileIDSampleJob> visible = state.visible;
    final List<UseSmileIDSampleJobDay> days = useSmileIDSampleGroupByDay(
      visible,
    );
    // The row index a test id carries is its position in the WHOLE visible list, not within its
    // day, so a flow can address row 4 without knowing where the day boundaries fell.
    int index = 0;
    final Widget list = Semantics(
      identifier: UseSmileIDSampleTestIds.verificationsScreen,
      child: ListView(
        padding: EdgeInsets.only(bottom: bottomInset),
        children: useSmileIDSampleSpaced(<Widget>[
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: SmileDimens.spacingMd,
              vertical: SmileDimens.spacingXs,
            ),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    'Verifications',
                    style: UseSmileIDSampleType.textStyleHeadingPage.copyWith(
                      color: colors.textTitle,
                    ),
                  ),
                ),
                if (onSelectModeChanged != null)
                  Semantics(
                    identifier: UseSmileIDSampleTestIds.selectToggle,
                    button: true,
                    child: InkWell(
                      onTap: () => onSelectModeChanged!(!state.selectMode),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          minWidth: kMinInteractiveDimension,
                          minHeight: kMinInteractiveDimension,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: SmileDimens.spacingXs,
                          ),
                          child: Center(
                            widthFactor: 1,
                            child: Text(
                              state.selectMode ? 'Cancel' : 'Select',
                              softWrap: false,
                              style: UseSmileIDSampleType.linkFont.copyWith(
                                fontWeight: FontWeight.w700,
                                color: colors.primary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: SmileDimens.spacingMd,
            ),
            child: Wrap(
              spacing: SmileDimens.spacingXs,
              runSpacing: SmileDimens.spacingXs,
              children: <Widget>[
                for (final UseSmileIDSampleJobFilter chip
                    in UseSmileIDSampleJobFilter.values)
                  UseSmileIDSampleFilterChip(
                    label: chip.label,
                    count: state.countFor(chip),
                    selected: chip == state.filter,
                    onTap: () => onFilterChanged(chip),
                    testId: UseSmileIDSampleTestIds.filterChip(chip.id),
                    countTestId: UseSmileIDSampleTestIds.filterCount(chip.id),
                  ),
              ],
            ),
          ),
          // Below the chips, never instead of them: a filter that matched nothing has to stay
          // switchable, and a port that replaces the whole body strands the reader on it.
          if (state.jobs != null && visible.isEmpty)
            UseSmileIDSampleEmptyState(
              text: state.jobs!.isEmpty
                  ? 'No verifications yet'
                  : 'Nothing ${state.filter.label.toLowerCase()}',
              supportingText: state.jobs!.isEmpty
                  ? 'Start a product above and the job lands here.'
                  : 'Other filters still have verifications.',
              testId: UseSmileIDSampleTestIds.verificationsEmpty,
            ),
          for (final UseSmileIDSampleJobDay day in days) ...<Widget>[
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: SmileDimens.spacingMd,
              ),
              child: UseSmileIDSampleDateGroupHeader(
                relative: useSmileIDSampleRelativeDay(
                  day.startMillis,
                  state.nowMillis,
                ),
                absolute: useSmileIDSampleAbsoluteDay(day.startMillis),
              ),
            ),
            for (final UseSmileIDSampleJob job in day.jobs)
              _Row(
                job: job,
                index: index++,
                state: state,
                onJobTap: onJobTap,
                onSelectionChanged: onSelectionChanged,
                onRemove: onRemove,
              ),
          ],
        ]),
      ),
    );
    if (state.removedCount == null) {
      return list;
    }
    // Over the content, not in it: a confirmation that pushed the rows down would move the very
    // row a reader was reaching for, and it has to sit clear of whatever chrome is at the bottom.
    return Stack(
      children: <Widget>[
        list,
        Positioned(
          left: SmileDimens.spacingMd,
          right: SmileDimens.spacingMd,
          bottom: bottomInset + SmileDimens.spacingXxs,
          child: UseSmileIDSampleToast(
            message: state.removedCount == 1
                ? '1 verification hidden from App list'
                : '${state.removedCount} verifications hidden from App list',
            actionLabel: 'Undo',
            onAction: onUndo,
          ),
        ),
      ],
    );
  }
}

/// One row, with the treatment select mode and the swipe each ask for.
class _Row extends StatelessWidget {
  const _Row({
    required this.job,
    required this.index,
    required this.state,
    required this.onJobTap,
    required this.onSelectionChanged,
    required this.onRemove,
  });

  final UseSmileIDSampleJob job;
  final int index;
  final UseSmileIDSampleVerificationsState state;
  final void Function(UseSmileIDSampleJob job)? onJobTap;
  final void Function(String jobId, bool selected)? onSelectionChanged;
  final void Function(Set<String> ids)? onRemove;

  @override
  Widget build(BuildContext context) {
    // In select mode a row neither opens nor swipes: a tap belongs to the checkbox, and the
    // gesture would fight it.
    final Widget row = UseSmileIDSampleJobRow(
      product: job.product,
      jobId: job.shortId,
      time: useSmileIDSampleTimeLabel(job.createdAtMillis),
      status: job.status,
      onTap: state.selectMode || onJobTap == null ? null : () => onJobTap!(job),
      testId: UseSmileIDSampleTestIds.jobRow(index),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: SmileDimens.spacingMd),
      child: state.selectMode
          ? Row(
              children: <Widget>[
                UseSmileIDSampleSelectionCheckbox(
                  checked: state.selected.contains(job.id),
                  onChanged: (bool picked) =>
                      onSelectionChanged?.call(job.id, picked),
                  testId: UseSmileIDSampleTestIds.selectionCheckbox(index),
                ),
                const SizedBox(width: SmileDimens.spacingXs),
                Expanded(child: row),
              ],
            )
          : onRemove == null
          ? row
          : UseSmileIDSampleSwipeAction(
              dismissKey: ValueKey<String>(job.id),
              onRemove: () => onRemove!(<String>{job.id}),
              child: row,
            ),
    );
  }
}
