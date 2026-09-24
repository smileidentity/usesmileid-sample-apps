import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../theme/use_smileid_sample_colors.dart';
import '../theme/use_smileid_sample_theme.dart';

/// Asks before an action that deletes something, in the platform's own alert; true only when confirmed.
Future<bool> showUseSmileIDSampleConfirmation(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  required String confirmTestId,
}) async {
  final UseSmileIDSampleColors colors = UseSmileIDSampleTheme.colorsOf(context);
  final bool? confirmed = await showAdaptiveDialog<bool>(
    context: context,
    builder: (BuildContext context) => AlertDialog.adaptive(
      title: Text(title),
      content: Text(message),
      actions: <Widget>[
        _action(
          context: context,
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        Semantics(
          identifier: confirmTestId,
          child: _action(
            context: context,
            onPressed: () => Navigator.of(context).pop(true),
            destructive: true,
            child: Text(
              confirmLabel,
              style: TextStyle(color: colors.badge.errorText),
            ),
          ),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}

/// A Cupertino action on iOS and a text button elsewhere, as `AlertDialog.adaptive` expects.
Widget _action({
  required BuildContext context,
  required VoidCallback onPressed,
  required Widget child,
  bool destructive = false,
}) => switch (Theme.of(context).platform) {
  TargetPlatform.iOS || TargetPlatform.macOS => CupertinoDialogAction(
    onPressed: onPressed,
    isDestructiveAction: destructive,
    child: child,
  ),
  _ => TextButton(onPressed: onPressed, child: child),
};
