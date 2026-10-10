import 'package:flutter/material.dart';

import '../components/use_smileid_sample_button.dart';
import '../components/use_smileid_sample_job_row.dart';
import '../components/use_smileid_sample_option_row.dart';
import '../components/use_smileid_sample_text_input.dart';
import '../components/use_smileid_sample_top_app_bar.dart';
import '../model/use_smileid_sample_product.dart';
import '../theme/use_smileid_sample_colors.dart';
import '../theme/use_smileid_sample_theme.dart';
import '../theme/use_smileid_sample_typography.dart';
import '../tokens/smile_product_hues.dart';
import '../tokens/smile_tokens.dart';
import '../use_smileid_sample_strings_scope.dart';
import '../use_smileid_sample_test_ids.dart';

/// SmartSelfie Authentication's user ID: typed, or picked from earlier runs that enrolled one. Never made up, because the SDK authenticates only an enrolled user.
class UseSmileIDSampleAuthUserIdScreen extends StatelessWidget {
  /// [previousUserIds] is newest first; empty shows the way to enrol one instead.
  const UseSmileIDSampleAuthUserIdScreen({
    required this.userId,
    required this.previousUserIds,
    required this.onUserIdChanged,
    required this.onRegister,
    required this.onBack,
    required this.onContinue,
    super.key,
  });

  /// What the field holds, typed or picked.
  final String userId;

  /// The user IDs earlier runs enrolled.
  final List<String> previousUserIds;

  /// Called on every keystroke, and with the ID a row picks.
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
    final Widget field = _UserIdField(
      userId: userId,
      onChanged: onUserIdChanged,
      colors: colors,
    );
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
              padding: const EdgeInsets.symmetric(
                horizontal: SmileDimens.spacingMd,
                vertical: SmileDimens.spacingLg,
              ),
              children: <Widget>[
                const Center(
                  child: UseSmileIDSampleProductTile(
                    product: UseSmileIDSampleProduct.smartSelfieAuth,
                    side: SmileDimens.space64,
                  ),
                ),
                const SizedBox(height: SmileDimens.spacingSm),
                if (previousUserIds.isEmpty) ...<Widget>[
                  _Heading(context.strings.authUserIdEmptyTitle, colors),
                  _Note(context.strings.authUserIdPreviousBody, colors),
                  const SizedBox(height: SmileDimens.spacingSm),
                  _Heading(context.strings.authUserIdRun, colors),
                  const SizedBox(height: SmileDimens.spacingSm),
                  _RegisterCard(onTap: onRegister, colors: colors),
                  _Or(colors),
                  field,
                ] else ...<Widget>[
                  field,
                  _Or(colors),
                  _Heading(context.strings.authUserIdPrevious, colors),
                  _Note(context.strings.authUserIdPreviousBody, colors),
                  const SizedBox(height: SmileDimens.spacingSm),
                  for (int i = 0; i < previousUserIds.length; i++)
                    UseSmileIDSampleOptionRow(
                      label: previousUserIds[i],
                      selected: previousUserIds[i] == chosen,
                      onTap: () => onUserIdChanged(previousUserIds[i]),
                      testId: UseSmileIDSampleTestIds.authUserIdOption(i),
                    ),
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

class _UserIdField extends StatelessWidget {
  const _UserIdField({
    required this.userId,
    required this.onChanged,
    required this.colors,
  });

  final String userId;
  final ValueChanged<String> onChanged;
  final UseSmileIDSampleColors colors;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[
      _Heading(context.strings.authUserIdEnter, colors),
      const SizedBox(height: SmileDimens.spacingXs),
      UseSmileIDSampleTextInput(
        value: userId,
        onChanged: onChanged,
        placeholder: context.strings.authUserIdPlaceholder,
        keyboardType: TextInputType.visiblePassword,
        testId: UseSmileIDSampleTestIds.authUserIdInput,
      ),
    ],
  );
}

class _RegisterCard extends StatelessWidget {
  const _RegisterCard({required this.onTap, required this.colors});

  final VoidCallback onTap;
  final UseSmileIDSampleColors colors;

  @override
  Widget build(BuildContext context) => Semantics(
    identifier: UseSmileIDSampleTestIds.authUserIdRegister,
    button: true,
    child: Material(
      color: colors.card.background,
      shape: RoundedRectangleBorder(
        borderRadius: UseSmileIDSampleShapes.card,
        side: BorderSide(color: colors.cardStroke, width: smileCardStrokeWidth),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: UseSmileIDSampleShapes.card,
        child: Padding(
          padding: const EdgeInsets.all(SmileDimens.spacingSm),
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
            ],
          ),
        ),
      ),
    ),
  );
}

class _Heading extends StatelessWidget {
  const _Heading(this.text, this.colors);

  final String text;
  final UseSmileIDSampleColors colors;

  @override
  Widget build(BuildContext context) => Semantics(
    header: true,
    child: Text(
      text,
      style: UseSmileIDSampleType.textStyleTitle.copyWith(
        color: colors.textTitle,
      ),
    ),
  );
}

class _Note extends StatelessWidget {
  const _Note(this.text, this.colors);

  final String text;
  final UseSmileIDSampleColors colors;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: SmileDimens.spacingXxs),
    child: Text(
      text,
      style: UseSmileIDSampleType.textStyleCaption.copyWith(
        color: colors.textMuted,
      ),
    ),
  );
}

class _Or extends StatelessWidget {
  const _Or(this.colors);

  final UseSmileIDSampleColors colors;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: SmileDimens.spacingSm),
    child: Text(
      context.strings.authUserIdOr,
      textAlign: TextAlign.center,
      style: UseSmileIDSampleType.textStyleCaption.copyWith(
        color: colors.textMuted,
      ),
    ),
  );
}
