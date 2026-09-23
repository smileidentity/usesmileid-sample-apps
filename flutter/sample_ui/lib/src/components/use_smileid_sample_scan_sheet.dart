import 'package:flutter/material.dart';

import '../model/use_smileid_sample_environment.dart';
import '../model/use_smileid_sample_simulated_scan.dart';
import '../theme/use_smileid_sample_colors.dart';
import '../theme/use_smileid_sample_theme.dart';
import '../theme/use_smileid_sample_typography.dart';
import '../tokens/smile_product_hues.dart';
import '../tokens/smile_tokens.dart';
import '../use_smileid_sample_test_ids.dart';
import 'use_smileid_sample_button.dart';
import 'use_smileid_sample_glyphs.dart';
import 'use_smileid_sample_section_label.dart';
import 'use_smileid_sample_text_input.dart';

/// What the sheet renders, so the screen owns the entry state and the sheet stays stateless.
@immutable
class UseSmileIDSampleScanSheetState {
  /// [rejection] is why the entered token is not a session; never the token itself.
  const UseSmileIDSampleScanSheetState({
    this.token = '',
    this.rejection,
    this.span = UseSmileIDSampleSimulatedSpan.fifteenMinutes,
    this.environment = UseSmileIDSampleEnvironment.sandbox,
    this.bindings = const UseSmileIDSampleSimulatedBindings(),
    this.expanded = false,
  });

  /// The manually entered token.
  final String token;

  /// Why the token was refused, shown under the field.
  final String? rejection;

  /// How long a simulated scan's token lasts.
  final UseSmileIDSampleSimulatedSpan span;

  /// Which host the minted token's `api_url` names.
  final UseSmileIDSampleEnvironment environment;

  /// What the minted token binds.
  final UseSmileIDSampleSimulatedBindings bindings;

  /// The mint controls start closed so the viewfinder keeps its height.
  final bool expanded;

  @override
  bool operator ==(Object other) =>
      other is UseSmileIDSampleScanSheetState &&
      other.token == token &&
      other.rejection == rejection &&
      other.span == span &&
      other.environment == environment &&
      other.bindings == bindings &&
      other.expanded == expanded;

  @override
  int get hashCode =>
      Object.hash(token, rejection, span, environment, bindings, expanded);
}

/// The sheet under the scanner: manual entry, and a simulated scan that mints its own fixture token.
class UseSmileIDSampleScanSheet extends StatelessWidget {
  /// The Link action appears only once there is something to link, so the default sheet keeps the
  /// design's rows.
  const UseSmileIDSampleScanSheet({
    required this.state,
    required this.onTokenChanged,
    required this.onPaste,
    required this.onLink,
    required this.onExpandToggle,
    required this.onSpanSelect,
    required this.onEnvironmentSelect,
    required this.onBindingsChanged,
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

  /// Opens or closes the mint controls.
  final VoidCallback onExpandToggle;

  /// Chooses the minted span.
  final ValueChanged<UseSmileIDSampleSimulatedSpan> onSpanSelect;

  /// Chooses the minted environment.
  final ValueChanged<UseSmileIDSampleEnvironment> onEnvironmentSelect;

  /// Chooses what the minted token binds.
  final ValueChanged<UseSmileIDSampleSimulatedBindings> onBindingsChanged;

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
            // Collapsed by default: this is a scanner, and the mint controls are a probe affordance.
            Semantics(
              button: true,
              expanded: state.expanded,
              child: GestureDetector(
                onTap: onExpandToggle,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: SmileDimens.spacingXxs,
                  ),
                  child: Row(
                    children: <Widget>[
                      const Expanded(
                        child: UseSmileIDSampleSectionLabel(
                          text: 'SIMULATED SCAN',
                        ),
                      ),
                      const SizedBox(width: SmileDimens.spacingXs),
                      if (state.expanded)
                        UseSmileIDSampleGlyphs.chevronDown(colors.textMuted)
                      else
                        UseSmileIDSampleGlyphs.chevronRight(colors.textMuted),
                    ],
                  ),
                ),
              ),
            ),
            if (state.expanded) ...<Widget>[
              const SizedBox(height: SmileDimens.spacingSm),
              _ChipRow(
                children: <Widget>[
                  for (final UseSmileIDSampleSimulatedSpan span
                      in UseSmileIDSampleSimulatedSpan.values)
                    _SheetChip(
                      label: span.label,
                      selected: state.span == span,
                      onTap: () => onSpanSelect(span),
                    ),
                ],
              ),
              const SizedBox(height: SmileDimens.spacingSm),
              // Minting is where a run picks an environment, because no app-side control is left.
              _ChipRow(
                children: <Widget>[
                  for (final UseSmileIDSampleEnvironment environment
                      in UseSmileIDSampleEnvironment.values)
                    _SheetChip(
                      label: environment.label,
                      selected: state.environment == environment,
                      onTap: () => onEnvironmentSelect(environment),
                      testId: UseSmileIDSampleTestIds.tokenEnvironment(
                        environment.id,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: SmileDimens.spacingSm),
              _ChipRow(
                children: <Widget>[
                  _SheetChip(
                    label: 'Binds consent',
                    selected: state.bindings.consent,
                    checkbox: true,
                    onTap: () => onBindingsChanged(
                      state.bindings.copyWith(consent: !state.bindings.consent),
                    ),
                  ),
                  _SheetChip(
                    label: 'Binds details',
                    selected: state.bindings.userDetails,
                    checkbox: true,
                    onTap: () => onBindingsChanged(
                      state.bindings.copyWith(
                        userDetails: !state.bindings.userDetails,
                      ),
                    ),
                  ),
                ],
              ),
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

/// A wrapping run of chips at the sheet's own gap.
class _ChipRow extends StatelessWidget {
  const _ChipRow({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: SmileDimens.spacingXs,
    runSpacing: SmileDimens.spacingXs,
    children: children,
  );
}

/// The filter chip's shape without its count, because what a simulated scan mints has no count.
class _SheetChip extends StatelessWidget {
  const _SheetChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.checkbox = false,
    this.testId,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool checkbox;
  final String? testId;

  @override
  Widget build(BuildContext context) {
    final UseSmileIDSampleColors colors = UseSmileIDSampleTheme.colorsOf(
      context,
    );
    return Semantics(
      identifier: testId,
      selected: checkbox ? null : selected,
      checked: checkbox ? selected : null,
      inMutuallyExclusiveGroup: !checkbox,
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: useSmileIDSampleTapTarget(context),
          ),
          child: Align(
            widthFactor: 1,
            heightFactor: 1,
            child: DecoratedBox(
              decoration: ShapeDecoration(
                color: selected ? colors.primary : colors.filterChip.background,
                shape: StadiumBorder(
                  side: selected
                      ? BorderSide.none
                      : BorderSide(
                          color: colors.filterChip.border,
                          width: smileCardStrokeWidth,
                        ),
                ),
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: SmileDimens.space32),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: SmileDimens.spacingSm,
                    vertical: SmileDimens.spacingXs,
                  ),
                  child: Text(
                    label,
                    style: UseSmileIDSampleType.filterChipFont.copyWith(
                      fontSize: _sheetActionSize,
                      fontWeight: FontWeight.w700,
                      color: selected
                          ? colors.onPrimary
                          : colors.filterChip.label,
                    ),
                  ),
                ),
              ),
            ),
          ),
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
      // Laid out at the tap target, as Compose's minimumInteractiveComponentSize is: it sets the field's height.
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: SmileDimens.sizeControlMd,
          minHeight: useSmileIDSampleTapTarget(context),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: SmileDimens.spacingXs,
          ),
          child: Center(
            widthFactor: 1,
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
    ),
  );
}

/// The sheet's action run.
const double _sheetActionSize = 13.5;
