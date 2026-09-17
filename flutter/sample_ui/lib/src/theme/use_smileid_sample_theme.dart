import 'package:flutter/material.dart';

import '../tokens/smile_tokens.dart';
import 'use_smileid_sample_colors.dart';
import 'use_smileid_sample_typography.dart';

/// One shape per named surface; the radius comes from the tokens and this fixes where it is applied.
abstract final class UseSmileIDSampleShapes {
  /// A card, and the form's section surfaces.
  static final BorderRadius card = BorderRadius.circular(SmileDimens.radiusSurface);

  /// A square tile.
  static final BorderRadius tile = BorderRadius.circular(SmileDimens.radiusLg);

  /// The verifications row's tile: node 5206-2410 draws 10, the one radius no token carries.
  static const BorderRadius rowTile = BorderRadius.all(Radius.circular(10));

  /// A text field or a search field.
  static final BorderRadius field = BorderRadius.circular(SmileDimens.radiusField);

  /// A pill: the primary button, the status badges and the nav bar.
  static final BorderRadius pill = BorderRadius.circular(SmileDimens.radiusControl);

  /// A chip.
  static final BorderRadius chip = BorderRadius.circular(SmileDimens.radiusChip);

  /// A bottom sheet, rounded at the top only.
  static final BorderRadius sheet = BorderRadius.vertical(
    top: Radius.circular(SmileDimens.radiusSurface),
  );

  /// The avatar's rounded square — a square at radius 12, not a circle (node 5206:2904).
  static const BorderRadius avatar = BorderRadius.all(Radius.circular(12));
}

/// The app's theme, built entirely from the vendored design-system tokens.
abstract final class UseSmileIDSampleTheme {
  /// The light theme.
  static ThemeData light() => _themeFor(Brightness.light, UseSmileIDSampleColorSchemes.light);

  /// The dark theme.
  static ThemeData dark() => _themeFor(Brightness.dark, UseSmileIDSampleColorSchemes.dark);

  /// The component tokens for the active mode; every widget reads colours through this.
  static UseSmileIDSampleColors colorsOf(BuildContext context) =>
      Theme.of(context).extension<UseSmileIDSampleColors>() ??
      UseSmileIDSampleColorSchemes.light;
}

/// The SDK maps the same tokens onto the same roles, keeping host chrome and flow continuous.
ThemeData _themeFor(Brightness brightness, UseSmileIDSampleColors colors) {
  final ColorScheme scheme = ColorScheme(
    brightness: brightness,
    primary: colors.primary,
    onPrimary: colors.onPrimary,
    secondary: colors.secondary,
    onSecondary: colors.textInverse,
    tertiary: colors.accent,
    onTertiary: colors.textInverse,
    surface: colors.surface,
    onSurface: colors.textTitle,
    surfaceContainerHighest: colors.surfaceAlt,
    onSurfaceVariant: colors.textBody,
    outline: colors.border,
    error: colors.errorFill,
    onError: colors.onError,
    scrim: colors.overlayScrim,
  );
  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: colors.background,
    fontFamily: useSmileIDSampleFontFamily,
    textTheme: _textTheme(colors),
    extensions: <ThemeExtension<dynamic>>[colors],
  );
}

/// The ramp on Material's own slots, reusing the nearest style where Material has none.
TextTheme _textTheme(UseSmileIDSampleColors colors) => TextTheme(
  displayLarge: UseSmileIDSampleType.textStyleDisplayLg,
  displayMedium: UseSmileIDSampleType.textStyleDisplayMd,
  displaySmall: UseSmileIDSampleType.textStyleHeadingPage,
  headlineLarge: UseSmileIDSampleType.textStyleHeadingPage,
  headlineMedium: UseSmileIDSampleType.textStyleHeadingCard,
  headlineSmall: UseSmileIDSampleType.textStyleHeadingSection,
  titleLarge: UseSmileIDSampleType.textStyleTitle,
  titleMedium: UseSmileIDSampleType.textStyleSubtitle,
  titleSmall: UseSmileIDSampleType.textStyleSubtitle,
  bodyLarge: UseSmileIDSampleType.textStyleBody,
  bodyMedium: UseSmileIDSampleType.textStyleBodySm,
  bodySmall: UseSmileIDSampleType.textStyleCaption,
  labelLarge: UseSmileIDSampleType.textStyleButton,
  labelMedium: UseSmileIDSampleType.textStyleButtonSm,
  labelSmall: UseSmileIDSampleType.textStyleOverline,
).apply(bodyColor: colors.textBody, displayColor: colors.textTitle);
