import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sample_ui/sample_ui.dart';

import 'state/use_smileid_sample_providers.dart';
import 'use_smileid_sample_remove_jobs.dart';
import 'use_smileid_sample_routes.dart';

/// The three-tab host: the branch's content, with the nav bar floating over it.
class UseSmileIDSampleShell extends ConsumerWidget {
  /// [location] is the current destination, which alone decides whether the bar is drawn.
  const UseSmileIDSampleShell({
    required this.shell,
    required this.location,
    super.key,
  });

  /// The indexed stack go_router owns, one navigator per tab.
  final StatefulNavigationShell shell;

  /// The current path.
  final String location;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final UseSmileIDSampleColors colors = UseSmileIDSampleTheme.colorsOf(
      context,
    );
    final UseSmileIDSampleSelection selection = ref.watch(
      useSmileIDSampleSelectionProvider,
    );
    final bool showsSelectionBar = _showsSelectionBar(selection);
    final bool showsNavBar =
        useSmileIDSampleShowsNavBar(location) && !showsSelectionBar;
    // Back from a tab that is not the first returns to products rather than leaving the app.
    return PopScope(
      canPop: shell.currentIndex == _productsBranch,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (!didPop) {
          shell.goBranch(_productsBranch);
        }
      },
      child: Scaffold(
        backgroundColor: colors.background,
        // What publishes the bar's measured height to the body as its bottom padding.
        extendBody: showsNavBar,
        bottomNavigationBar: _bottomBar(
          ref,
          shell,
          selection,
          showsSelectionBar: showsSelectionBar,
          showsNavBar: showsNavBar,
        ),
        // Top only: the bar insets the bottom itself, and doing it here too lifts it twice.
        body: SafeArea(
          bottom: false,
          child: UseSmileIDSampleTextMetrics(child: shell),
        ),
      ),
    );
  }

  /// Whichever bar owns the bottom slot, which is what the body's padding is then measured from.
  Widget? _bottomBar(
    WidgetRef ref,
    StatefulNavigationShell shell,
    UseSmileIDSampleSelection selection, {
    required bool showsSelectionBar,
    required bool showsNavBar,
  }) {
    // The exception that proves R13's rule: this one is opaque, so content does stop above it.
    if (showsSelectionBar) {
      return UseSmileIDSampleSelectionBar(
        selectedCount: selection.ids.length,
        onRemove: () => useSmileIDSampleRemoveJobs(ref, selection.ids),
      );
    }
    if (!showsNavBar) {
      return null;
    }
    return UseSmileIDSampleNavBar(
      selected: UseSmileIDSampleNavItem.values[shell.currentIndex],
      onSelect: (UseSmileIDSampleNavItem item) => _select(item.index),
      onTokenTap: () {},
    );
  }

  /// Whether select mode's bar stands in for the nav bar, which only the verifications tab has.
  bool _showsSelectionBar(UseSmileIDSampleSelection selection) =>
      selection.active && location == UseSmileIDSampleRoutes.verifications;

  /// Switches tab, and pops the tab to its root when the active one is tapped again.
  void _select(int index) =>
      shell.goBranch(index, initialLocation: index == shell.currentIndex);
}

/// Products' branch, which is the start destination and so where back lands.
const int _productsBranch = 0;
