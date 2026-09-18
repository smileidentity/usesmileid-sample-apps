import 'package:flutter/material.dart';

import '../theme/use_smileid_sample_colors.dart';
import '../theme/use_smileid_sample_theme.dart';
import '../theme/use_smileid_sample_typography.dart';
import '../tokens/smile_tokens.dart';
import '../use_smileid_sample_test_ids.dart';
import 'use_smileid_sample_button.dart';
import 'use_smileid_sample_glyphs.dart';
import 'use_smileid_sample_text_input.dart';

/// What the sheet renders, so the screen owns the entry state and the sheet stays stateless.
@immutable
class UseSmileIDSampleScanSheetState {
  /// [rejection] is why the entered token is not a session; never the token itself.
  const UseSmileIDSampleScanSheetState({this.token = '', this.rejection});

  /// The manually entered token.
  final String token;

  /// Why the token was refused, shown under the field.
  final String? rejection;

  @override
  bool operator ==(Object other) =>
      other is UseSmileIDSampleScanSheetState &&
      other.token == token &&
      other.rejection == rejection;

  @override
  int get hashCode => Object.hash(token, rejection);
}

/// The sheet under the scanner: manual entry, and a simulated scan.
class UseSmileIDSampleScanSheet extends StatelessWidget {
  /// The Link action appears only once there is something to link, so the default sheet keeps the
  /// design's two rows.
  const UseSmileIDSampleScanSheet({
    required this.state,
    required this.onTokenChanged,
    required this.onPaste,
    required this.onLink,
    required this.onSimulate,
    super.key,
  });

  /// What to render.
  final UseSmileIDSampleScanSheetState state;

  /// Called on every edit of the manual field.
  final ValueChanged<String> onTokenChanged;

  /// Pastes the clipboard into the field.
  final VoidCallback onPaste;

  /// Links the entered token.
  final VoidCallback onLink;

  /// Mints a fixture token and links it, which is what makes the session states reachable.
  final VoidCallback onSimulate;

  @override
  Widget build(BuildContext context) {
    final UseSmileIDSampleColors colors = UseSmileIDSampleTheme.colorsOf(
      context,
    );
    return Material(
      color: colors.surface,
      shape: RoundedRectangleBorder(borderRadius: UseSmileIDSampleShapes.sheet),
      child: Padding(
        padding: EdgeInsets.only(
          left: SmileDimens.spacingMd,
          right: SmileDimens.spacingMd,
          top: SmileDimens.spacingMd,
          bottom:
              SmileDimens.spacingMd + MediaQuery.viewPaddingOf(context).bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            UseSmileIDSampleTextInput(
              value: state.token,
              onChanged: onTokenChanged,
              placeholder: 'Or enter token manually',
              isError: state.rejection != null,
              errorMessage: state.rejection,
              // A bearer credential 900 characters long: nobody proofreads it, and masked it stays
              // out of screenshots and out of a failed run's hierarchy dump.
              masked: true,
              testId: UseSmileIDSampleTestIds.tokenManualEntry,
              leading: UseSmileIDSampleGlyphs.scanMark,
              trailing: (Color tint) => _SheetAction(
                label: 'Paste',
                onTap: onPaste,
                testId: UseSmileIDSampleTestIds.tokenPaste,
                colors: colors,
              ),
            ),
            if (state.token.trim().isNotEmpty) ...<Widget>[
              const SizedBox(height: SmileDimens.spacingSm),
              UseSmileIDSampleButton(text: 'Link token', onPressed: onLink),
            ],
            const SizedBox(height: SmileDimens.spacingSm),
            UseSmileIDSampleButton(
              text: 'Simulate a successful scan',
              onPressed: onSimulate,
              testId: UseSmileIDSampleTestIds.tokenSimulate,
            ),
          ],
        ),
      ),
    );
  }
}

/// A text action inside the sheet, its tap target expanded to the platform minimum.
class _SheetAction extends StatelessWidget {
  const _SheetAction({
    required this.label,
    required this.onTap,
    required this.testId,
    required this.colors,
  });

  final String label;
  final VoidCallback onTap;
  final String testId;
  final UseSmileIDSampleColors colors;

  @override
  Widget build(BuildContext context) => Semantics(
    identifier: testId,
    button: true,
    child: GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: SmileDimens.sizeControlMd),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: SmileDimens.spacingXs,
          ),
          child: Text(
            label,
            softWrap: false,
            textAlign: TextAlign.center,
            style: UseSmileIDSampleType.linkFont.copyWith(
              fontSize: _sheetActionSize,
              fontWeight: FontWeight.w700,
              color: colors.primary,
            ),
          ),
        ),
      ),
    ),
  );
}

/// The sheet's action run.
const double _sheetActionSize = 13.5;
