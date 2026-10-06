import 'package:flutter/widgets.dart';

import 'state/use_smileid_sample_settings.dart';
import 'use_smileid_sample_strings.dart';

/// The language the app shows, for every widget below; English outside one.
class UseSmileIDSampleStringsScope extends InheritedWidget {
  /// Shows [language] below [child].
  UseSmileIDSampleStringsScope({
    required this.language,
    required this.deviceLanguages,
    required super.child,
    super.key,
  }) : strings = UseSmileIDSampleStrings.forLanguage(language.id);

  /// The language resolved for display, never System.
  final UseSmileIDSampleLanguage language;

  /// The device's languages, which the System label resolves.
  final List<String> deviceLanguages;

  /// The copy in [language].
  final UseSmileIDSampleStrings strings;

  /// The nearest scope's copy, or English with none.
  static UseSmileIDSampleStrings of(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<UseSmileIDSampleStringsScope>()
          ?.strings ??
      UseSmileIDSampleStrings.forLanguage(UseSmileIDSampleLanguage.en.id);

  /// The nearest scope's language, or English with none.
  static UseSmileIDSampleLanguage languageOf(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<UseSmileIDSampleStringsScope>()
          ?.language ??
      UseSmileIDSampleLanguage.en;

  /// The nearest scope's device languages, or none.
  static List<String> deviceLanguagesOf(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<UseSmileIDSampleStringsScope>()
          ?.deviceLanguages ??
      const <String>[];

  @override
  bool updateShouldNotify(UseSmileIDSampleStringsScope oldWidget) =>
      oldWidget.language != language ||
      oldWidget.deviceLanguages != deviceLanguages;
}

/// `context.strings`, so a build method reads the copy without naming the scope.
extension UseSmileIDSampleStringsContext on BuildContext {
  /// The copy in the language the app shows.
  UseSmileIDSampleStrings get strings => UseSmileIDSampleStringsScope.of(this);
}
