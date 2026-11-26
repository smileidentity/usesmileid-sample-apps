import 'package:flutter/material.dart';

import '../components/use_smileid_sample_banner.dart';
import '../components/use_smileid_sample_data_field_row.dart';
import '../components/use_smileid_sample_empty_state.dart';
import '../components/use_smileid_sample_glyphs.dart';
import '../components/use_smileid_sample_result_card.dart';
import '../components/use_smileid_sample_rise_in.dart';
import '../components/use_smileid_sample_section_label.dart';
import '../components/use_smileid_sample_status_badge.dart';
import '../components/use_smileid_sample_toast.dart';
import '../components/use_smileid_sample_top_app_bar.dart';
import '../model/use_smileid_sample_error_resolution.dart';
import '../model/use_smileid_sample_job.dart';
import '../model/use_smileid_sample_product.dart';
import '../model/use_smileid_sample_result.dart';
import '../state/use_smileid_sample_details_failure.dart';
import '../theme/use_smileid_sample_colors.dart';
import '../theme/use_smileid_sample_theme.dart';
import '../theme/use_smileid_sample_typography.dart';
import '../tokens/smile_product_hues.dart';
import '../tokens/smile_tokens.dart';
import '../use_smileid_sample_strings_scope.dart';
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
    this.notice,
    this.result,
    this.landedFailure,
    this.landedProduct,
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

  /// What the last pull or copy reported, shown until the host withdraws it.
  final String? notice;

  /// The last run's result card; null hides it, which is the host's probes decision.
  final UseSmileIDSampleResult? result;

  /// The row the run that landed here with no job failed with; null for any other visit.
  final UseSmileIDSampleErrorResolution? landedFailure;

  /// That run's product, named over its banner.
  final UseSmileIDSampleProduct? landedProduct;

  @override
  Widget build(BuildContext context) {
    final UseSmileIDSampleColors colors = UseSmileIDSampleTheme.colorsOf(
      context,
    );
    final UseSmileIDSampleJob? found = job.value;
    final UseSmileIDSampleErrorResolution? failure =
        useSmileIDSampleDetailsFailure(job: found, landedRun: landedFailure);
    final Widget page = Semantics(
      identifier: UseSmileIDSampleTestIds.verificationDetailsScreen,
      child: Column(
        children: <Widget>[
          UseSmileIDSampleTopAppBar(
            title: context.strings.detailsTitle,
            onBack: onBack,
            // Offered only where there is something to hide: a delete on the empty state would
            // promise an action with no object.
            action: found == null || onDelete == null
                ? null
                : UseSmileIDSampleTopAppBarButton(
                    semanticLabel: context.strings.detailsHide,
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
                  children: <Widget>[
                    if (found == null && failure != null) ...<Widget>[
                      if (landedProduct != null) ...<Widget>[
                        Text(
                          landedProduct!.title(context.strings),
                          style: UseSmileIDSampleType.textStyleTitle.copyWith(
                            color: colors.textTitle,
                          ),
                        ),
                        const SizedBox(height: SmileDimens.spacingMd),
                      ],
                      _banner(context, failure),
                    ] else if (job.pending)
                      const SizedBox.shrink()
                    else if (found == null)
                      UseSmileIDSampleEmptyState(
                        text: context.strings.detailsMissingTitle,
                        supportingText: context.strings.detailsMissingBody(
                          jobId: jobId,
                        ),
                        testId: UseSmileIDSampleTestIds.detailsEmpty,
                      )
                    else
                      ..._fields(context, found, colors, failure),
                    // Rendered even with no job: a flow that failed before submission has nothing else to show.
                    if (result != null) ...<Widget>[
                      const SizedBox(height: SmileDimens.spacingSm),
                      UseSmileIDSampleResultCard(result: result!),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
    if (notice == null) {
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
          // Past the system bar: under edge to edge this page reaches the bottom edge.
          bottom: MediaQuery.paddingOf(context).bottom + SmileDimens.spacingMd,
          child: UseSmileIDSampleRiseIn(
            child: UseSmileIDSampleToast(message: notice!),
          ),
        ),
      ],
    );
  }

  Widget _banner(
    BuildContext context,
    UseSmileIDSampleErrorResolution failure,
  ) => UseSmileIDSampleBanner(
    caption: failure.bannerTone == UseSmileIDSampleBannerTone.warning
        ? context.strings.errorTitleNotCompleted
        : context.strings.errorTitleFailed,
    message: failure.message.text(context.strings),
    testId: UseSmileIDSampleTestIds.errorBanner,
  );

  List<Widget> _fields(
    BuildContext context,
    UseSmileIDSampleJob found,
    UseSmileIDSampleColors colors,
    UseSmileIDSampleErrorResolution? failure,
  ) => <Widget>[
    Row(
      children: <Widget>[
        Expanded(
          child: Text(
            found.product.title(context.strings),
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
    if (failure != null) ...<Widget>[
      const SizedBox(height: SmileDimens.spacingMd),
      _banner(context, failure),
    ],
    const SizedBox(height: SmileDimens.spacingMd),
    UseSmileIDSampleSectionLabel(text: context.strings.detailsSection),
    const SizedBox(height: SmileDimens.spacingXs),
    DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: UseSmileIDSampleShapes.card,
        border: Border.all(
          color: colors.cardStroke,
          width: smileCardStrokeWidth,
        ),
      ),
      child: ClipRRect(
        borderRadius: UseSmileIDSampleShapes.card,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: _rows(context, found, colors),
        ),
      ),
    ),
  ];

  List<Widget> _rows(
    BuildContext context,
    UseSmileIDSampleJob found,
    UseSmileIDSampleColors colors,
  ) => <Widget>[
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
      onCopy: onCopy == null
          ? null
          : () => onCopy!(context.strings.detailsJobId, found.id),
      testId: UseSmileIDSampleTestIds.detailField('jobId'),
      copyTestId: UseSmileIDSampleTestIds.detailCopy('jobId'),
    ),
    UseSmileIDSampleDataFieldRow(
      label: context.strings.detailsMessage,
      value: found.message,
      testId: UseSmileIDSampleTestIds.detailField('message'),
    ),
    UseSmileIDSampleDataFieldRow(
      label: context.strings.detailsStatus,
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
      onCopy: onCopy == null
          ? null
          : () => onCopy!(context.strings.detailsUserId, found.userId),
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
  const UseSmileIDSampleJobLookup.found(UseSmileIDSampleJob job)
    : value = job,
      pending = false;

  /// The store has answered and there is none.
  const UseSmileIDSampleJobLookup.none() : value = null, pending = false;

  /// The store has not answered yet, which a cold link reaches before its first read.
  const UseSmileIDSampleJobLookup.pending() : value = null, pending = true;

  /// The job, or null when the store had none or has not answered.
  final UseSmileIDSampleJob? value;

  /// Whether the store has yet to answer; the page then claims neither a job nor its absence.
  final bool pending;
}
