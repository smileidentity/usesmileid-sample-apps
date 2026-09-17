import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sample_ui/sample_ui.dart';

import 'use_smileid_sample_routes.dart';

/// The three-tab host: the branch's content, with the nav bar floating over it.
///
/// It floats rather than sitting in `bottomNavigationBar`, which is R13: a bottom-bar slot insets
/// the content and draws a seam across the page, where the design has the list continuing under
/// the pill. The consequence is that each screen reserves its own room, which is the clearance the
/// bar publishes.
class UseSmileIDSampleShell extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final UseSmileIDSampleColors colors = UseSmileIDSampleTheme.colorsOf(
      context,
    );
    return Scaffold(
      backgroundColor: colors.background,
      body: Stack(
        children: <Widget>[
          // Top only: the bar draws over the bottom inset itself, and insetting here as well
          // would lift it by the system bar twice.
          SafeArea(bottom: false, child: shell),
          if (useSmileIDSampleShowsNavBar(location))
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: UseSmileIDSampleNavBar(
                selected: UseSmileIDSampleNavItem.values[shell.currentIndex],
                onSelect: (UseSmileIDSampleNavItem item) => _select(item.index),
                onTokenTap: () {},
              ),
            ),
        ],
      ),
    );
  }

  /// Switches tab, and pops the tab to its root when the active one is tapped again.
  void _select(int index) =>
      shell.goBranch(index, initialLocation: index == shell.currentIndex);
}
