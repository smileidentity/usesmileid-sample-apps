import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sample_ui/sample_ui.dart';
import 'package:usesmileid/usesmileid.dart';

/// Developer tooling an SDK repo's source build adds to this app; a registry build has none.
abstract class UseSmileIDSampleShellExtension {
  /// Extra rows for the Settings DEBUG section, which debug builds show.
  List<Widget> debugRows(UseSmileIDSampleShellHost host) => const <Widget>[];

  /// Runs after the shell has configured a flow, so it may replace any of that configuration.
  void customiseFlow(
    UseSmileIDFlowBuilder builder,
    UseSmileIDSampleProduct product,
  ) {}

  /// Runs once before the first frame, with the route the app was launched on.
  Future<void> onLaunch(String defaultRouteName) async {}

  /// A session the shell links once at launch, before autostart, as if its token had been scanned.
  UseSmileIDSampleTokenSession? launchSession() => null;
}

/// Links the [extension]'s launch session through [link], if it offers one.
Future<void> useSmileIDSampleLinkLaunchSession(
  UseSmileIDSampleShellExtension? extension,
  Future<void> Function(UseSmileIDSampleTokenSession session) link,
) async {
  final UseSmileIDSampleTokenSession? session = extension?.launchSession();
  if (session != null) await link(session);
}

/// What the shell lets an extension do.
class UseSmileIDSampleShellHost {
  /// The two operations the shell grants.
  const UseSmileIDSampleShellHost({
    required this.linkTokenSession,
    required this.openScenarioDrawer,
  });

  /// Links a session as a scanned token would.
  final Future<void> Function(UseSmileIDSampleTokenSession) linkTokenSession;

  /// Opens the scenario drawer.
  final VoidCallback openScenarioDrawer;
}

/// The extension the app was bootstrapped with; null in a registry build.
final Provider<UseSmileIDSampleShellExtension?>
useSmileIDSampleShellExtensionProvider =
    Provider<UseSmileIDSampleShellExtension?>((Ref ref) => null);
