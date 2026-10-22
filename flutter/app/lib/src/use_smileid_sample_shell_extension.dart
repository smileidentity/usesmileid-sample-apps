import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sample_ui/sample_ui.dart';
import 'package:usesmileid/usesmileid.dart';

/// Developer tooling an SDK repo's source build adds to this app; a registry build has none.
abstract class UseSmileIDSampleShellExtension {
  /// Extra rows for the Settings DEBUG section, which debug builds show.
  List<Widget> debugRows() => const <Widget>[];

  /// Runs after the shell has configured a flow, so it may replace any of that configuration.
  void customiseFlow(
    UseSmileIDFlowBuilder builder,
    UseSmileIDSampleProduct product,
  ) {}

  /// Runs last inside the shell's network block, so it may add to that configuration without replacing it.
  void customiseNetwork(
    UseSmileIDNetworkBuilder network,
    UseSmileIDSampleProduct product,
  ) {}

  /// Runs once before the first frame and before any other member, with the route the app was launched on.
  Future<void> onLaunch(String defaultRouteName) async {}

  /// A session the shell links once, after [onLaunch] and before autostart, as if its token had been scanned.
  UseSmileIDSampleTokenSession? launchSession() => null;
}

/// Runs the [extension]'s `onLaunch` with [route], then links its launch session through [link].
Future<void> useSmileIDSampleLaunchExtension(
  UseSmileIDSampleShellExtension? extension,
  String route,
  Future<void> Function(UseSmileIDSampleTokenSession session) link,
) async {
  await extension?.onLaunch(route);
  await useSmileIDSampleLinkLaunchSession(extension, link);
}

/// Links the [extension]'s launch session through [link], if it offers one; a failed link only skips it.
Future<void> useSmileIDSampleLinkLaunchSession(
  UseSmileIDSampleShellExtension? extension,
  Future<void> Function(UseSmileIDSampleTokenSession session) link,
) async {
  try {
    final UseSmileIDSampleTokenSession? session = extension?.launchSession();
    if (session != null) await link(session);
  } on Object {
    // Nothing to recover: the app starts without it, as it would without the extension.
  }
}

/// The extension the app was bootstrapped with; null in a registry build.
final Provider<UseSmileIDSampleShellExtension?>
useSmileIDSampleShellExtensionProvider =
    Provider<UseSmileIDSampleShellExtension?>((Ref ref) => null);
