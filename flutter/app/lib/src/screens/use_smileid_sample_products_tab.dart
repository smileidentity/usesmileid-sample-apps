import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sample_ui/sample_ui.dart';

import '../state/use_smileid_sample_providers.dart';
import '../use_smileid_sample_journey.dart';
import '../use_smileid_sample_routes.dart';

/// The products tab: the grid every flow starts from.
class UseSmileIDSampleProductsTab extends ConsumerStatefulWidget {
  /// [openSwitch] is set by the deep link, which opens this page with the switch sheet up.
  const UseSmileIDSampleProductsTab({this.openSwitch = false, super.key});

  /// Whether a link asked for the profile-switch sheet.
  final bool openSwitch;

  @override
  ConsumerState<UseSmileIDSampleProductsTab> createState() =>
      _UseSmileIDSampleProductsTabState();
}

class _UseSmileIDSampleProductsTabState
    extends ConsumerState<UseSmileIDSampleProductsTab> {
  @override
  void initState() {
    super.initState();
    // After the first frame, because a sheet cannot be presented while this is still building.
    if (widget.openSwitch) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _openSwitchFromLink();
        }
      });
    }
  }

  /// Hands the route back on dismiss, or a second delivery of the link reopens nothing.
  Future<void> _openSwitchFromLink() async {
    // Read before the await: an inherited lookup across the gap is what `mounted` does not cover.
    final GoRouter router = GoRouter.of(context);
    await _switchProfile();
    if (router.routerDelegate.currentConfiguration.uri.path ==
        UseSmileIDSampleRoutes.profileSwitch) {
      router.go(UseSmileIDSampleRoutes.products);
    }
  }

  /// Opens the switch sheet, which PRODUCTS owns rather than the profiles list.
  Future<void> _switchProfile() => showUseSmileIDSampleSheet<void>(
    context: context,
    testId: UseSmileIDSampleTestIds.profileSwitchSheet,
    builder: (BuildContext sheetContext) {
      final UseSmileIDSampleProfiles profiles = ref.read(
        useSmileIDSampleProfilesProvider,
      );
      return UseSmileIDSampleProfileSwitchSheet(
        profiles: profiles.all,
        activeId: profiles.activeId,
        onSelect: (UseSmileIDSampleProfile profile) {
          ref
              .read(useSmileIDSampleProfilesProvider.notifier)
              .setActive(profile.id);
          Navigator.of(sheetContext).pop();
        },
      );
    },
  );

  @override
  Widget build(BuildContext context) {
    final UseSmileIDSampleProfiles profiles = ref.watch(
      useSmileIDSampleProfilesProvider,
    );
    return UseSmileIDSampleProductsScreen(
      state: UseSmileIDSampleProductsState(
        initials: profiles.active.initials,
        // By POSITION, not by id: the hue is the profile's place in the list, and every screen
        // showing the same profile has to agree on it.
        avatarColor: avatarColorForProfile(profiles.activeIndex),
      ),
      onProductTap: (UseSmileIDSampleProduct product) =>
          context.push(UseSmileIDSampleJourney.firstStepFor(product)),
      onProfileTap: _switchProfile,
      onScanTap: () {},
      bottomInset: useSmileIDSampleNavBarClearance(context),
    );
  }
}
