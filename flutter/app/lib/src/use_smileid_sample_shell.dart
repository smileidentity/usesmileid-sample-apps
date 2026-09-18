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
        // The exception that proves R13's rule: the selection bar is opaque with a top edge, so it
        // REPLACES the bottom chrome and the content does stop above it.
        bottomNavigationBar: _showsSelectionBar(selection)
            ? UseSmileIDSampleSelectionBar(
                selectedCount: selection.ids.length,
                onRemove: () => useSmileIDSampleRemoveJobs(ref, selection.ids),
              )
            : null,
        body: Stack(
          children: <Widget>[
            // Top only: the bar draws over the bottom inset itself, and insetting here as well
            // would lift it by the system bar twice.
            SafeArea(bottom: false, child: shell),
            if (useSmileIDSampleShowsNavBar(location) &&
                !_showsSelectionBar(selection))
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: UseSmileIDSampleNavBar(
                  selected: UseSmileIDSampleNavItem.values[shell.currentIndex],
                  onSelect: (UseSmileIDSampleNavItem item) =>
                      _select(item.index),
                  onTokenTap: () {},
                ),
              ),
          ],
        ),
      ),
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
