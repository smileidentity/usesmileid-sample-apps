import 'package:flutter/material.dart';

import '../components/use_smileid_sample_date_group_header.dart';
import '../components/use_smileid_sample_empty_state.dart';
import '../components/use_smileid_sample_filter_chip.dart';
import '../components/use_smileid_sample_job_row.dart';
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
  });

  /// Every stored job, or null while the store is still answering.
  final List<UseSmileIDSampleJob>? jobs;

  /// The clock the day headers are read against.
  ///
  /// Midnight is what actually matters, so a caller ticking every second must round this down or
  /// the grouping is rebuilt sixty times a minute for a header that changes once a day.
  final int nowMillis;

  /// The active chip.
  final UseSmileIDSampleJobFilter filter;

  /// The jobs the active chip keeps, newest first.
  List<UseSmileIDSampleJob> get visible =>
      jobs?.where(filter.matches).toList() ?? const <UseSmileIDSampleJob>[];

  /// How many jobs each chip matches, counted against the WHOLE list rather than the visible one.
  int countFor(UseSmileIDSampleJobFilter chip) =>
      jobs?.where(chip.matches).length ?? 0;
}

/// The verifications list: the title, the chips, and the rows grouped by day.
///
/// There is no app bar and no search field on this screen; the title is the list's first row and
/// scrolls with it, which is what the design draws.
class UseSmileIDSampleVerificationsScreen extends StatelessWidget {
  /// [bottomInset] is the room the floating nav bar needs; the screen is not inset by it.
  const UseSmileIDSampleVerificationsScreen({
    required this.state,
    required this.onFilterChanged,
    this.onJobTap,
    this.bottomInset = 0,
    super.key,
  });

  /// What to render.
  final UseSmileIDSampleVerificationsState state;

  /// Switches the active chip.
  final void Function(UseSmileIDSampleJobFilter filter) onFilterChanged;

  /// Opens one job's detail page.
  final void Function(UseSmileIDSampleJob job)? onJobTap;

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
    return Semantics(
      identifier: UseSmileIDSampleTestIds.verificationsScreen,
      child: ListView(
        padding: EdgeInsets.only(bottom: bottomInset),
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: SmileDimens.spacingMd,
              vertical: SmileDimens.spacingXs,
            ),
            child: Text(
              'Verifications',
              style: UseSmileIDSampleType.textStyleHeadingPage.copyWith(
                color: colors.textTitle,
              ),
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
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  SmileDimens.spacingMd,
                  0,
                  SmileDimens.spacingMd,
                  SmileDimens.spacingXs,
                ),
                child: UseSmileIDSampleJobRow(
                  product: job.product,
                  jobId: job.shortId,
                  time: useSmileIDSampleTimeLabel(job.createdAtMillis),
                  status: job.status,
                  onTap: onJobTap == null ? null : () => onJobTap!(job),
                  testId: UseSmileIDSampleTestIds.jobRow(index++),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
