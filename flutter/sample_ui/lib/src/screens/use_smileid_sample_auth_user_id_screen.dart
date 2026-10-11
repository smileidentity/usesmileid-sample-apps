import 'package:flutter/material.dart';

import '../components/use_smileid_sample_button.dart';
import '../components/use_smileid_sample_job_row.dart';
import '../components/use_smileid_sample_section_label.dart';
import '../components/use_smileid_sample_setting_row.dart';
import '../components/use_smileid_sample_status_badge.dart';
import '../components/use_smileid_sample_text_input.dart';
import '../components/use_smileid_sample_top_app_bar.dart';
import '../model/use_smileid_sample_job.dart';
import '../model/use_smileid_sample_product.dart';
import '../theme/use_smileid_sample_colors.dart';
import '../theme/use_smileid_sample_label_type.dart';
import '../theme/use_smileid_sample_theme.dart';
import '../theme/use_smileid_sample_typography.dart';
import '../tokens/smile_product_hues.dart';
import '../tokens/smile_tokens.dart';
import '../use_smileid_sample_strings_scope.dart';
import '../use_smileid_sample_test_ids.dart';

/// SmartSelfie Authentication's user ID: typed, or picked from earlier runs that enrolled one. Never made up, because the SDK authenticates only an enrolled user.
class UseSmileIDSampleAuthUserIdScreen extends StatelessWidget {
  /// [previousUsers] is the newest run per enrolled user, newest first.
  const UseSmileIDSampleAuthUserIdScreen({
    required this.userId,
    required this.previousUsers,
    required this.onUserIdChanged,
    required this.onRegister,
    required this.onBack,
    required this.onContinue,
    super.key,
  });

  /// What the field holds, typed or picked.
  final String userId;

  /// The runs that enrolled a user, one per user.
  final List<UseSmileIDSampleJob> previousUsers;

  /// Called on every keystroke, and with the ID a card picks.
  final ValueChanged<String> onUserIdChanged;

  /// Starts SmartSelfie Enrollment, which is how a user ID is made.
  final VoidCallback onRegister;

  /// Leaves the screen.
  final VoidCallback onBack;

  /// Starts the flow with the chosen ID.
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final UseSmileIDSampleColors colors = UseSmileIDSampleTheme.colorsOf(
      context,
    );
    final String chosen = userId.trim();
    return Semantics(
      identifier: UseSmileIDSampleTestIds.authUserIdScreen,
      child: Column(
        children: <Widget>[
          UseSmileIDSampleTopAppBar(
            title: UseSmileIDSampleProduct.smartSelfieAuth.title(
              context.strings,
            ),
            onBack: onBack,
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                SmileDimens.spacingMd,
                0,
                SmileDimens.spacingMd,
                SmileDimens.spacingSm,
              ),
              children: <Widget>[
                UseSmileIDSampleSectionLabel(
                  text: context.strings.authUserIdSection,
                ),
                const SizedBox(height: SmileDimens.spacingSm),
                UseSmileIDSampleTextInput(
                  value: userId,
                  onChanged: onUserIdChanged,
                  placeholder: context.strings.authUserIdPlaceholder,
                  keyboardType: TextInputType.visiblePassword,
                  testId: UseSmileIDSampleTestIds.authUserIdInput,
                ),
                const SizedBox(height: SmileDimens.spacingSm),
                _Caption(context.strings.authUserIdHint, colors),
                const SizedBox(height: SmileDimens.spacingSm),
                _OrDivider(colors),
                const SizedBox(height: SmileDimens.spacingSm),
                if (previousUsers.isEmpty) ...<Widget>[
                  _ListSection(
                    label: context.strings.authUserIdRun,
                    hint: context.strings.authUserIdRunBody,
                    colors: colors,
                  ),
                  const SizedBox(height: SmileDimens.spacingSm),
                  _EnrollmentCard(onTap: onRegister, colors: colors),
                ] else ...<Widget>[
                  _ListSection(
                    label: context.strings.authUserIdPrevious,
                    hint: context.strings.authUserIdPreviousHint,
                    colors: colors,
                  ),
                  const SizedBox(height: SmileDimens.spacingSm),
                  for (int i = 0; i < previousUsers.length; i++) ...<Widget>[
                    if (i > 0) const SizedBox(height: SmileDimens.spacingXs),
                    _PreviousUserCard(
                      job: previousUsers[i],
                      latest: i == 0,
                      selected: previousUsers[i].userId == chosen,
                      onTap: () => onUserIdChanged(previousUsers[i].userId),
                      testId: UseSmileIDSampleTestIds.authUserIdOption(i),
                      colors: colors,
                    ),
                  ],
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(SmileDimens.spacingMd),
            child: UseSmileIDSampleButton(
              text: context.strings.commonContinue,
              onPressed: onContinue,
              enabled: chosen.isNotEmpty,
              testId: UseSmileIDSampleTestIds.authUserIdContinue,
            ),
          ),
        ],
      ),
    );
  }
}

/// An earlier user, laid out like a verifications row.
class _PreviousUserCard extends StatelessWidget {
  const _PreviousUserCard({
    required this.job,
    required this.latest,
    required this.selected,
    required this.onTap,
    required this.testId,
    required this.colors,
  });

  final UseSmileIDSampleJob job;
  final bool latest;
  final bool selected;
  final VoidCallback onTap;
  final String testId;
  final UseSmileIDSampleColors colors;

  @override
  Widget build(BuildContext context) {
    final bool stacks = MediaQuery.textScalerOf(context).scale(1) > 1;
    final int? lines = stacks ? null : 1;
    final TextOverflow? overflow = stacks ? null : TextOverflow.ellipsis;
    final Widget pill = UseSmileIDSamplePill(
      label: context.strings.authUserIdLatest,
      background: colors.badge.infoBackground,
      foreground: colors.badge.infoText,
    );
    return Semantics(
      identifier: testId,
      selected: selected,
      inMutuallyExclusiveGroup: true,
      child: _Card(
        onTap: onTap,
        colors: colors,
        border: selected
            ? BorderSide(
                color: colors.primary,
                width: SmileDimens.borderWidthThin,
              )
            : null,
        child: Row(
          children: <Widget>[
            UseSmileIDSampleProductTile(product: job.product),
            const SizedBox(width: SmileDimens.spacingSm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    job.product.title(context.strings),
                    maxLines: lines,
                    overflow: overflow,
                    style: UseSmileIDSampleType.textStyleBodyStrong.copyWith(
                      color: colors.card.title,
                    ),
                  ),
                  const SizedBox(height: SmileDimens.spacingXxs),
                  Text(
                    '${job.middleUserId} · ${useSmileIDSampleTimeLabel(job.createdAtMillis)}',
                    maxLines: lines,
                    overflow: overflow,
                    style: UseSmileIDSampleType.textStyleCaption.copyWith(
                      color: colors.textMuted,
                    ),
                  ),
                  if (latest && stacks) ...<Widget>[
                    const SizedBox(height: SmileDimens.spacingXs),
                    pill,
                  ],
                ],
              ),
            ),
            if (latest && !stacks) ...<Widget>[
              const SizedBox(width: SmileDimens.spacingSm),
              pill,
            ],
          ],
        ),
      ),
    );
  }
}

/// Starts SmartSelfie Enrollment.
class _EnrollmentCard extends StatelessWidget {
  const _EnrollmentCard({required this.onTap, required this.colors});

  final VoidCallback onTap;
  final UseSmileIDSampleColors colors;

  @override
  Widget build(BuildContext context) => Semantics(
    identifier: UseSmileIDSampleTestIds.authUserIdRegister,
    button: true,
    child: _Card(
      onTap: onTap,
      colors: colors,
      child: Row(
        children: <Widget>[
          const UseSmileIDSampleProductTile(
            product: UseSmileIDSampleProduct.smartSelfieEnrollment,
          ),
          const SizedBox(width: SmileDimens.spacingSm),
          Expanded(
            child: Text(
              UseSmileIDSampleProduct.smartSelfieEnrollment.title(
                context.strings,
              ),
              style: UseSmileIDSampleType.textStyleBodyStrong.copyWith(
                color: colors.card.title,
              ),
            ),
          ),
          const UseSmileIDSampleSettingRowChevron(),
        ],
      ),
    ),
  );
}

/// The verifications row's card.
class _Card extends StatelessWidget {
  const _Card({
    required this.onTap,
    required this.colors,
    required this.child,
    this.border,
  });

  final VoidCallback onTap;
  final UseSmileIDSampleColors colors;
  final Widget child;
  final BorderSide? border;

  @override
  Widget build(BuildContext context) => Material(
    color: colors.card.background,
    shape: RoundedRectangleBorder(
      borderRadius: UseSmileIDSampleShapes.card,
      side:
          border ??
          BorderSide(color: colors.cardStroke, width: smileCardStrokeWidth),
    ),
    child: InkWell(
      onTap: onTap,
      borderRadius: UseSmileIDSampleShapes.card,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: SmileDimens.space64),
        child: Padding(
          padding: const EdgeInsets.all(SmileDimens.spacingSm),
          child: child,
        ),
      ),
    ),
  );
}

/// A section label with its hint.
class _ListSection extends StatelessWidget {
  const _ListSection({
    required this.label,
    required this.hint,
    required this.colors,
  });

  final String label;
  final String hint;
  final UseSmileIDSampleColors colors;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      UseSmileIDSampleSectionLabel(text: label),
      const SizedBox(height: SmileDimens.spacingXxs),
      _Caption(hint, colors),
    ],
  );
}

/// OR between two hairlines.
class _OrDivider extends StatelessWidget {
  const _OrDivider(this.colors);

  final UseSmileIDSampleColors colors;

  @override
  Widget build(BuildContext context) {
    final Widget hairline = Expanded(
      child: Container(height: smileCardStrokeWidth, color: colors.cardStroke),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: SmileDimens.spacingXs),
      child: Row(
        children: <Widget>[
          hairline,
          const SizedBox(width: SmileDimens.spacingSm),
          Text(
            context.strings.authUserIdOr,
            style: useSmileIDSampleLabelStyle(
              UseSmileIDSampleType.textStyleOverline,
            ).copyWith(color: colors.textMuted),
          ),
          const SizedBox(width: SmileDimens.spacingSm),
          hairline,
        ],
      ),
    );
  }
}

/// Muted supporting copy.
class _Caption extends StatelessWidget {
  const _Caption(this.text, this.colors);

  final String text;
  final UseSmileIDSampleColors colors;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: UseSmileIDSampleType.textStyleCaption.copyWith(
      color: colors.textMuted,
    ),
  );
}
