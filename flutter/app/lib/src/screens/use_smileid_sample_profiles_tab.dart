import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sample_ui/sample_ui.dart';

import '../state/use_smileid_sample_providers.dart';
import '../use_smileid_sample_routes.dart';

/// The profiles list, and the sheet that creates another.
class UseSmileIDSampleProfilesTab extends ConsumerStatefulWidget {
  /// [onBack] leaves the list.
  const UseSmileIDSampleProfilesTab({required this.onBack, super.key});

  /// Leaves the list.
  final VoidCallback onBack;

  @override
  ConsumerState<UseSmileIDSampleProfilesTab> createState() =>
      _UseSmileIDSampleProfilesTabState();
}

class _UseSmileIDSampleProfilesTabState
    extends ConsumerState<UseSmileIDSampleProfilesTab> {
  String? _createdId;

  @override
  Widget build(BuildContext context) {
    final UseSmileIDSampleProfiles profiles = ref.watch(
      useSmileIDSampleProfilesProvider,
    );
    final UseSmileIDSampleProfile? created = _createdId == null
        ? null
        : profiles.find(_createdId!);
    // Its own chrome: this route sits ABOVE the shell, so it inherits no Scaffold and the material
    // the create row's ink needs would be missing.
    return Scaffold(
      backgroundColor: UseSmileIDSampleTheme.colorsOf(context).background,
      body: SafeArea(
        child: UseSmileIDSampleProfilesScreen(
          profiles: profiles.all,
          activeId: profiles.activeId,
          onBack: widget.onBack,
          onProfileTap: (UseSmileIDSampleProfile profile) =>
              context.go(UseSmileIDSampleRoutes.profileConfig(profile.id)),
          onCreate: _create,
          createdNotice: created?.organisation,
          onMakeCreatedActive: created == null
              ? null
              : () {
                  ref
                      .read(useSmileIDSampleProfilesProvider.notifier)
                      .setActive(created.id);
                  setState(() => _createdId = null);
                },
        ),
      ),
    );
  }

  Future<void> _create() async {
    await showUseSmileIDSampleSheet<void>(
      context: context,
      testId: UseSmileIDSampleTestIds.newProfileSheet,
      builder: (BuildContext sheetContext) => UseSmileIDSampleNewProfileSheet(
        onCreate: (String organisation, UseSmileIDSampleUserDetails details) {
          final UseSmileIDSampleProfile added = ref
              .read(useSmileIDSampleProfilesProvider.notifier)
              .add(
                organisation: organisation,
                person: '${details.firstName} ${details.lastName}'.trim(),
                defaults: details,
              );
          // Consumed on sight, before the confirmation is shown: returning to this screen later
          // must not replay a confirmation for a profile created minutes ago.
          ref
              .read(useSmileIDSampleProfilesProvider.notifier)
              .clearLastCreated();
          setState(() => _createdId = added.id);
          Navigator.of(sheetContext).pop();
        },
      ),
    );
  }
}
