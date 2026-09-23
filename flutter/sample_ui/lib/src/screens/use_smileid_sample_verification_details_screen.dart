import 'package:flutter/material.dart';

import '../components/use_smileid_sample_data_field_row.dart';
import '../components/use_smileid_sample_empty_state.dart';
import '../components/use_smileid_sample_glyphs.dart';
import '../components/use_smileid_sample_section_label.dart';
import '../components/use_smileid_sample_status_badge.dart';
import '../components/use_smileid_sample_toast.dart';
import '../components/use_smileid_sample_top_app_bar.dart';
import '../model/use_smileid_sample_job.dart';
import '../theme/use_smileid_sample_colors.dart';
import '../theme/use_smileid_sample_theme.dart';
import '../theme/use_smileid_sample_typography.dart';
import '../tokens/smile_tokens.dart';
import '../use_smileid_sample_test_ids.dart';

/// One verification, or an honest account of why there is nothing to show.
class UseSmileIDSampleVerificationDetailsScreen extends StatelessWidget {
  /// A null [job] draws the empty state for [jobId], which is what a stale link lands on.
  const UseSmileIDSampleVerificationDetailsScreen({
    required this.jobId,
    required this.job,
    required this.onBack,
    this.onDelete,
    this.onRefresh,
    this.onCopy,
    this.refreshNotice,
    super.key,
  });

  /// The id the page was asked for, which the empty state names.
  final String jobId;

  /// The stored job, absent when this build never had it.
  final UseSmileIDSampleJobLookup job;

  /// Leaves the page; the platform back gesture calls the same thing.
  final VoidCallback onBack;

  /// Hides this verification from the app's list.
  final VoidCallback? onDelete;

  /// Re-reads the job's status; the affordance is always wired and reports why it cannot succeed.
  final Future<void> Function()? onRefresh;

  /// Puts a field's full value on the clipboard, with the label a paste target would show.
  final void Function(String label, String value)? onCopy;

  /// Why the last pull could not re-read the job, shown until it is withdrawn.
  final String? refreshNotice;

  @override
  Widget build(BuildContext context) {
    final UseSmileIDSampleColors colors = UseSmileIDSampleTheme.colorsOf(
      context,
    );
    final UseSmileIDSampleJob? found = job.value;
    final Widget page = Semantics(
      identifier: UseSmileIDSampleTestIds.verificationDetailsScreen,
      child: Column(
        children: <Widget>[
          UseSmileIDSampleTopAppBar(
            title: 'Verification details',
            onBack: onBack,
            // Offered only where there is something to hide: a delete on the empty state would
            // promise an action with no object.
            action: found == null || onDelete == null
                ? null
                : UseSmileIDSampleTopAppBarButton(
                    semanticLabel: 'Hide verification from the app list',
                    onTap: onDelete!,
                    emphasis: UseSmileIDSampleTopAppBarEmphasis.destructive,
                    glyph: UseSmileIDSampleGlyphs.trash,
                    testId: UseSmileIDSampleTestIds.detailsDelete,
                  ),
          ),
          Expanded(
            child: Semantics(
              identifier: UseSmileIDSampleTestIds.detailsRefresh,
              child: RefreshIndicator(
                onRefresh: onRefresh ?? _nothingToRefresh,
                child: ListView(
                  padding: const EdgeInsets.all(SmileDimens.spacingMd),
                  children: found == null
                      ? <Widget>[
                          UseSmileIDSampleEmptyState(
                            text: 'No verification here',
                            supportingText: 'Nothing stored for jobId = $jobId',
                            testId: UseSmileIDSampleTestIds.detailsEmpty,
                          ),
                        ]
                      : _fields(found, colors),
                ),
              ),
            ),
          ),
        ],
      ),
    );
    if (refreshNotice == null) {
      return page;
    }
    // The app's own toast rather than a Material snackbar: a refresh that cannot succeed still
    // reports in the app's voice, and a foreign control on one screen reads as a different app.
    return Stack(
      children: <Widget>[
        page,
        Positioned(
          left: SmileDimens.spacingMd,
          right: SmileDimens.spacingMd,
          // Past the system bar too: under edge to edge this page reaches the screen's bottom edge.
          bottom: MediaQuery.paddingOf(context).bottom + SmileDimens.spacingMd,
          child: UseSmileIDSampleToast(message: refreshNotice!),
        ),
      ],
    );
  }

  List<Widget> _fields(
    UseSmileIDSampleJob found,
    UseSmileIDSampleColors colors,
  ) => <Widget>[
    Row(
      children: <Widget>[
        Expanded(
          child: Text(
            found.product.label,
            style: UseSmileIDSampleType.textStyleTitle.copyWith(
              color: colors.textTitle,
            ),
          ),
        ),
        const SizedBox(width: SmileDimens.spacingSm),
        UseSmileIDSampleStatusBadge(
          status: found.status,
          testId: UseSmileIDSampleTestIds.statusBadge,
        ),
      ],
    ),
    const SizedBox(height: SmileDimens.spacingMd),
    const UseSmileIDSampleSectionLabel(text: 'DETAILS'),
    const SizedBox(height: SmileDimens.spacingXs),
    UseSmileIDSampleDataFieldRow(
      label: 'Created_at',
      value: found.createdAtLabel,
      testId: UseSmileIDSampleTestIds.detailField('createdAt'),
    ),
    UseSmileIDSampleDataFieldRow(
      label: 'Job_id',
      // Shows the elided id and copies the WHOLE one: the short form is for reading, and a
      // support ticket needs the id the API answers to.
      value: found.shortId,
      onCopy: onCopy == null ? null : () => onCopy!('Job ID', found.id),
      testId: UseSmileIDSampleTestIds.detailField('jobId'),
      copyTestId: UseSmileIDSampleTestIds.detailCopy('jobId'),
    ),
    UseSmileIDSampleDataFieldRow(
      label: 'Message',
      value: found.message,
      testId: UseSmileIDSampleTestIds.detailField('message'),
    ),
    UseSmileIDSampleDataFieldRow(
      label: 'Status',
      value: found.httpStatusLabel,
      // Coloured by the TRANSPORT, not the verdict: a cleared job that failed to submit is still
      // a red row here, and a 202 on a blocked job is still green.
      valueColor: switch (found.httpSucceeded) {
        null => null,
        true => colors.badge.successText,
        false => colors.badge.errorText,
      },
      testId: UseSmileIDSampleTestIds.detailField('status'),
    ),
    UseSmileIDSampleDataFieldRow(
      label: 'User_id',
      value: found.shortUserId,
      onCopy: onCopy == null ? null : () => onCopy!('User ID', found.userId),
      testId: UseSmileIDSampleTestIds.detailField('userId'),
      copyTestId: UseSmileIDSampleTestIds.detailCopy('userId'),
    ),
  ];

  /// The pull gesture stays wired with no job to re-read, so it settles rather than hanging.
  static Future<void> _nothingToRefresh() async {}
}

/// One store lookup: a job that may be absent, so a caller cannot pass "not loaded" and "not stored" as one value.
class UseSmileIDSampleJobLookup {
  /// The store has answered and found one.
  const UseSmileIDSampleJobLookup.found(UseSmileIDSampleJob job) : value = job;

  /// The store has answered and there is none.
  const UseSmileIDSampleJobLookup.none() : value = null;

  /// The job, or null when the store had none.
  final UseSmileIDSampleJob? value;
}
