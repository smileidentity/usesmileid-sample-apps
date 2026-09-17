import 'package:flutter/material.dart';

import '../components/use_smileid_sample_button.dart';
import '../components/use_smileid_sample_floating_token_button.dart';
import '../components/use_smileid_sample_icon.dart';
import '../components/use_smileid_sample_section_label.dart';
import '../components/use_smileid_sample_select_trigger.dart';
import '../components/use_smileid_sample_text_input.dart';
import '../components/use_smileid_sample_top_app_bar.dart';
import '../state/use_smileid_sample_id_details.dart';
import '../tokens/smile_icons.dart';
import '../tokens/smile_tokens.dart';
import '../use_smileid_sample_test_ids.dart';

/// Country, ID type and number, for the products that need a document.
class UseSmileIDSampleKycFormScreen extends StatelessWidget {
  /// [onScanToken] is offered because a pushed form covers the nav bar's own token affordance.
  const UseSmileIDSampleKycFormScreen({
    required this.title,
    required this.details,
    required this.onBack,
    required this.onPickCountry,
    required this.onPickIdType,
    required this.onIdNumberChanged,
    required this.onContinue,
    this.onScanToken,
    super.key,
  });

  /// The product's own label.
  final String title;

  /// What has been chosen so far.
  final UseSmileIDSampleIdDetails details;

  /// Leaves the form.
  final VoidCallback onBack;

  /// Opens the country picker.
  final VoidCallback onPickCountry;

  /// Opens the ID type picker.
  final VoidCallback onPickIdType;

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
                    const UseSmileIDSampleSectionLabel(text: 'COUNTRY'),
                    const SizedBox(height: SmileDimens.spacingXs),
                    UseSmileIDSampleSelectTrigger(
                      value: details.country?.label,
                      placeholder: 'Select country',
                      onTap: onPickCountry,
                      leading: (Color tint) => UseSmileIDSampleTriggerEmoji(
                        emoji: details.country?.flag ?? '🌍',
                      ),
                      testId: UseSmileIDSampleTestIds.countryTrigger,
                    ),
                    const SizedBox(height: SmileDimens.spacingMd),
                    const UseSmileIDSampleSectionLabel(text: 'ID TYPE'),
                    const SizedBox(height: SmileDimens.spacingXs),
                    UseSmileIDSampleSelectTrigger(
                      value: details.idType?.label,
                      // Names the missing step rather than the missing value: a reader who has
                      // chosen no country needs to know why this is closed.
                      placeholder: details.country == null
                          ? 'Choose a country first'
                          : 'Select ID type',
                      onTap: onPickIdType,
                      enabled: details.country != null,
                      // A glyph, not the design's 🪪: that emoji is tofu on older Androids.
                      leading: (Color tint) => UseSmileIDSampleIcon(
                        asset: SmileIcons.biometricKyc,
                        tint: tint,
                      ),
                      testId: UseSmileIDSampleTestIds.idTypeTrigger,
                    ),
                    const SizedBox(height: SmileDimens.spacingMd),
                    const UseSmileIDSampleSectionLabel(text: 'ID NUMBER'),
                    const SizedBox(height: SmileDimens.spacingXs),
                    UseSmileIDSampleTextInput(
                      value: details.idNumber,
                      onChanged: onIdNumberChanged,
                      placeholder: 'Enter ID number',
                      // The only rule on this field: a capitalisation HINT to the keyboard. A
                      // pasted lowercase value stays lowercase, exactly as the twin leaves it.
                      textCapitalization: TextCapitalization.characters,
                      testId: UseSmileIDSampleTestIds.idNumberInput,
                    ),
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
              text: 'Continue',
              onPressed: onContinue,
              enabled: details.isComplete,
              testId: UseSmileIDSampleTestIds.kycContinue,
            ),
          ),
        ],
      ),
    );
  }
}
