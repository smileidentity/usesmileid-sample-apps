import 'package:flutter/material.dart';

import '../components/use_smileid_sample_button.dart';
import '../components/use_smileid_sample_floating_token_button.dart';
import '../components/use_smileid_sample_icon.dart';
import '../components/use_smileid_sample_section_label.dart';
import '../components/use_smileid_sample_select_trigger.dart';
import '../components/use_smileid_sample_text_input.dart';
import '../components/use_smileid_sample_top_app_bar.dart';
import '../state/use_smileid_sample_catalogue.dart';
import '../state/use_smileid_sample_id_details.dart';
import '../state/use_smileid_sample_id_number_hint.dart';
import '../tokens/smile_icons.dart';
import '../tokens/smile_tokens.dart';
import '../use_smileid_sample_strings_scope.dart';
import '../use_smileid_sample_test_ids.dart';

/// The ID-details form: an ID type and number for KYC, a document and how to capture it otherwise.
class UseSmileIDSampleKycFormScreen extends StatelessWidget {
  /// [onScanToken] is offered because a pushed form covers the nav bar's own token affordance.
  const UseSmileIDSampleKycFormScreen({
    required this.title,
    required this.family,
    required this.details,
    required this.countryListLoading,
    required this.onBack,
    required this.onPickCountry,
    required this.onPickIdType,
    required this.onPickDocument,
    required this.onPickCaptureAs,
    required this.onIdNumberChanged,
    required this.onContinue,
    this.onScanToken,
    super.key,
  });

  /// The product's own label.
  final String title;

  /// Which list the second trigger reads.
  final UseSmileIDSampleCatalogueFamily family;

  /// What has been chosen so far.
  final UseSmileIDSampleIdDetails details;

  /// Whether the chosen country's list is still arriving, which the second trigger says.
  final bool countryListLoading;

  /// Leaves the form.
  final VoidCallback onBack;

  /// Opens the country picker.
  final VoidCallback onPickCountry;

  /// Opens the ID type picker.
  final VoidCallback onPickIdType;

  /// Opens the document picker.
  final VoidCallback onPickDocument;

  /// Opens the capture-as sheet.
  final VoidCallback onPickCaptureAs;

  /// Called on every keystroke of the number.
  final ValueChanged<String> onIdNumberChanged;

  /// Starts the flow.
  final VoidCallback onContinue;

  /// Opens the token scanner; absent until the scanner exists.
  final VoidCallback? onScanToken;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      identifier: UseSmileIDSampleTestIds.kycFormScreen,
      child: Column(
        children: <Widget>[
          UseSmileIDSampleTopAppBar(title: title, onBack: onBack),
          Expanded(
            child: Stack(
              children: <Widget>[
                ListView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: SmileDimens.spacingMd,
                  ),
                  children: <Widget>[
                    UseSmileIDSampleSectionLabel(
                      text: context.strings.kycCountry,
                    ),
                    const SizedBox(height: SmileDimens.spacingSm),
                    UseSmileIDSampleSelectTrigger(
                      value: details.country?.name,
                      placeholder: context.strings.kycSelectCountry,
                      onTap: onPickCountry,
                      leading: (Color tint) => UseSmileIDSampleTriggerEmoji(
                        emoji: details.country?.flag ?? '🌍',
                      ),
                      testId: UseSmileIDSampleTestIds.countryTrigger,
                    ),
                    const SizedBox(height: SmileDimens.spacingSm),
                    ...switch (family) {
                      UseSmileIDSampleCatalogueFamily.kyc => _kycFields(
                        context,
                      ),
                      UseSmileIDSampleCatalogueFamily.document =>
                        _documentFields(context),
                      UseSmileIDSampleCatalogueFamily.passport => <Widget>[],
                    },
                    const SizedBox(height: SmileDimens.spacingXl),
                  ],
                ),
                if (onScanToken != null)
                  Positioned(
                    right: SmileDimens.spacingMd,
                    bottom: SmileDimens.spacingMd,
                    child: UseSmileIDSampleFloatingTokenButton(
                      onTap: onScanToken!,
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(SmileDimens.spacingMd),
            child: UseSmileIDSampleButton(
              text: context.strings.commonContinue,
              onPressed: onContinue,
              enabled: details.isComplete(family),
              testId: UseSmileIDSampleTestIds.kycContinue,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _kycFields(BuildContext context) {
    final String? error = UseSmileIDSampleIdNumberHint.error(
      details.idType,
      details.idNumber,
      context.strings,
    );
    return <Widget>[
      UseSmileIDSampleSectionLabel(text: context.strings.kycIdType),
      const SizedBox(height: SmileDimens.spacingSm),
      UseSmileIDSampleSelectTrigger(
        value: details.idType?.label,
        placeholder: _secondPlaceholder(
          context,
          context.strings.kycLoadingIdTypes,
          context.strings.kycSelectIdType,
        ),
        onTap: onPickIdType,
        enabled: details.country != null,
        // A glyph, not the design's 🪪: that emoji is tofu on older Androids.
        leading: (Color tint) =>
            UseSmileIDSampleIcon(asset: SmileIcons.biometricKyc, tint: tint),
        testId: UseSmileIDSampleTestIds.idTypeTrigger,
      ),
      const SizedBox(height: SmileDimens.spacingSm),
      UseSmileIDSampleSectionLabel(text: context.strings.kycIdNumber),
      const SizedBox(height: SmileDimens.spacingSm),
      UseSmileIDSampleTextInput(
        value: details.idNumber,
        onChanged: onIdNumberChanged,
        placeholder: UseSmileIDSampleIdNumberHint.placeholder(
          details.idType,
          context.strings,
        ),
        enabled: details.idType != null,
        isError: error != null,
        errorMessage: error,
        textCapitalization: TextCapitalization.characters,
        testId: UseSmileIDSampleTestIds.idNumberInput,
        errorTestId: UseSmileIDSampleTestIds.idNumberError,
      ),
    ];
  }

  List<Widget> _documentFields(BuildContext context) => <Widget>[
    UseSmileIDSampleSectionLabel(text: context.strings.kycDocument),
    const SizedBox(height: SmileDimens.spacingSm),
    UseSmileIDSampleSelectTrigger(
      value: details.document?.name,
      placeholder: _secondPlaceholder(
        context,
        context.strings.kycLoadingDocuments,
        context.strings.kycSelectDocument,
      ),
      onTap: onPickDocument,
      enabled: details.country != null,
      leading: (Color tint) => UseSmileIDSampleIcon(
        asset: SmileIcons.documentVerification,
        tint: tint,
      ),
      testId: UseSmileIDSampleTestIds.documentTrigger,
    ),
    const SizedBox(height: SmileDimens.spacingSm),
    UseSmileIDSampleSectionLabel(text: context.strings.kycCaptureAs),
    const SizedBox(height: SmileDimens.spacingSm),
    UseSmileIDSampleSelectTrigger(
      value: details.document == null
          ? null
          : details.resolvedCaptureAs.triggerText(context.strings),
      placeholder: context.strings.captureAsMatchDocument,
      onTap: onPickCaptureAs,
      enabled: details.document != null,
      leading: (Color tint) =>
          UseSmileIDSampleIcon(asset: SmileIcons.preview, tint: tint),
      testId: UseSmileIDSampleTestIds.captureAsTrigger,
    ),
  ];

  /// Enabled while loading, with "Loading…" in place of the prompt, so the form never looks stuck.
  String _secondPlaceholder(
    BuildContext context,
    String loading,
    String ready,
  ) {
    if (details.country == null) {
      return context.strings.kycChooseCountryFirst;
    }
    return countryListLoading ? loading : ready;
  }
}
