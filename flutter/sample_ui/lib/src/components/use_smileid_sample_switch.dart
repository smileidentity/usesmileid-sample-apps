import 'package:flutter/material.dart';

import '../theme/use_smileid_sample_colors.dart';
import '../theme/use_smileid_sample_theme.dart';
import '../tokens/smile_tokens.dart';

/// The platform switch styled from semantic tokens — deliberately not hand-drawn, since the design
/// system has no switch contract (spec/components.json → Switch).
class UseSmileIDSampleSwitch extends StatelessWidget {
  /// A null [onChanged] is the disabled state, which is the platform control's own convention.
  const UseSmileIDSampleSwitch({
    required this.value,
    required this.onChanged,
    this.enabled = true,
    this.testId,
    super.key,
  });

  /// Whether the switch is on.
  final bool value;

  /// Called with the new value; null leaves the control disabled.
  final ValueChanged<bool>? onChanged;

  /// Whether the switch accepts input.
  final bool enabled;

  /// The `sample_*` id the screen supplies.
  final String? testId;

  @override
  Widget build(BuildContext context) {
    final UseSmileIDSampleColors colors = UseSmileIDSampleTheme.colorsOf(
      context,
    );
    // `adaptive` is what makes this native on both hosts: Material on Android, Cupertino on iOS,
    // which is also why only the on-track colour survives on iOS — the same divergence that app has.
    return Semantics(
      identifier: testId,
      child: Switch.adaptive(
        value: value,
        onChanged: enabled ? onChanged : null,
        thumbColor:
            WidgetStateProperty<Color>.fromMap(<WidgetStatesConstraint, Color>{
              WidgetState.disabled & WidgetState.selected: colors.surface,
              WidgetState.disabled: colors.surfaceMuted,
              WidgetState.any: colors.surface,
            }),
        trackColor:
            WidgetStateProperty<Color>.fromMap(<WidgetStatesConstraint, Color>{
              WidgetState.disabled & WidgetState.selected: colors.textMuted,
              WidgetState.disabled: colors.border,
              WidgetState.selected: colors.primary,
              WidgetState.any: colors.border,
            }),
        trackOutlineColor:
            WidgetStateProperty<Color>.fromMap(<WidgetStatesConstraint, Color>{
              WidgetState.disabled & WidgetState.selected: colors.textMuted,
              WidgetState.disabled: colors.border,
              WidgetState.selected: colors.primary,
              WidgetState.any: colors.border,
            }),
        trackOutlineWidth: const WidgetStatePropertyAll<double>(
          SmileDimens.borderWidthThin,
        ),
      ),
    );
  }
}
