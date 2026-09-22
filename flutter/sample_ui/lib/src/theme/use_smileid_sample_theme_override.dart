import 'package:flutter/material.dart';
import 'package:usesmileid/usesmileid.dart';

import '../model/use_smileid_sample_scenario.dart';

/// A theme scenario stated in the SDK's own types, so the host is a straight assignment.
@immutable
class UseSmileIDSampleThemeOverride {
  /// Every field the SDK's public override takes; [fontFamily] is null where the scenario keeps the SDK's.
  const UseSmileIDSampleThemeOverride({
    required this.primaryColor,
    required this.primaryForeground,
    required this.secondaryColor,
    required this.accentColor,
    required this.buttonShape,
    this.fontFamily,
  });

  /// The SDK's primary.
  final AdaptiveColor primaryColor;

  /// What sits on the primary.
  final AdaptiveColor primaryForeground;

  /// The SDK's secondary.
  final AdaptiveColor secondaryColor;

  /// The SDK's accent.
  final AdaptiveColor accentColor;

  /// The button corner radius.
  final double buttonShape;

  /// The family every SDK screen draws in, or null to keep the SDK's own.
  final String? fontFamily;
}

/// What each theme scenario overrides, or null for the ship state.
extension UseSmileIDSampleThemeScenarioOverride
    on UseSmileIDSampleThemeScenario {
  /// The palette this scenario hands the SDK.
  UseSmileIDSampleThemeOverride? get override => switch (this) {
    UseSmileIDSampleThemeScenario.brandDefault => null,
    // Baseline Material 3: a plausible partner palette that is nobody's brand, and no raw hex.
    UseSmileIDSampleThemeScenario.partnerOverride => _partnerOverride(),
    // Named colours outside every palette; purple where the twins use the magenta Flutter lacks.
    UseSmileIDSampleThemeScenario.clashingHost => UseSmileIDSampleThemeOverride(
      primaryColor: const AdaptiveColor(
        light: Colors.purple,
        dark: Colors.purple,
      ),
      primaryForeground: const AdaptiveColor(
        light: Colors.yellow,
        dark: Colors.yellow,
      ),
      secondaryColor: const AdaptiveColor(
        light: Colors.green,
        dark: Colors.green,
      ),
      accentColor: const AdaptiveColor(light: Colors.red, dark: Colors.red),
      buttonShape: _clashingButtonRadius,
      // A guaranteed system family, so the font override always resolves.
      fontFamily: 'monospace',
    ),
  };
}

UseSmileIDSampleThemeOverride _partnerOverride() {
  final ColorScheme light = ColorScheme.fromSeed(seedColor: _partnerSeed);
  final ColorScheme dark = ColorScheme.fromSeed(
    seedColor: _partnerSeed,
    brightness: Brightness.dark,
  );
  return UseSmileIDSampleThemeOverride(
    primaryColor: AdaptiveColor(light: light.primary, dark: dark.primary),
    primaryForeground: AdaptiveColor(
      light: light.onPrimary,
      dark: dark.onPrimary,
    ),
    secondaryColor: AdaptiveColor(light: light.secondary, dark: dark.secondary),
    accentColor: AdaptiveColor(light: light.tertiary, dark: dark.tertiary),
    buttonShape: _partnerButtonRadius,
  );
}

/// Material 3's own baseline seed family, which is what makes this palette nobody's brand.
const Color _partnerSeed = Colors.deepPurple;
const double _partnerButtonRadius = 4;
const double _clashingButtonRadius = 24;
