import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sample_ui/sample_ui.dart';

import '../state/use_smileid_sample_providers.dart';
import '../use_smileid_sample_routes.dart';
import 'use_smileid_sample_above_shell_page.dart';

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
    return UseSmileIDSampleAboveShellPage(
      onBack: widget.onBack,
      child: UseSmileIDSampleProfilesScreen(
        profiles: profiles.all,
        activeId: profiles.activeId,
        onBack: widget.onBack,
        onProfileTap: (UseSmileIDSampleProfile profile) =>
            context.go(UseSmileIDSampleRoutes.profileConfig(profile.id)),
        onCreate: _create,
        createdNotice: created?.title,
        onMakeCreatedActive: created == null
            ? null
            : () {
                ref
                    .read(useSmileIDSampleProfilesProvider.notifier)
                    .setActive(created.id);
                setState(() => _createdId = null);
              },
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
              .add(organisation: organisation, defaults: details);
          final bool offer =
              ref.read(useSmileIDSampleProfilesProvider).lastCreatedId ==
              added.id;
          // Consumed on sight, before the confirmation is shown: returning to this screen later
          // must not replay a confirmation for a profile created minutes ago.
          ref
              .read(useSmileIDSampleProfilesProvider.notifier)
              .clearLastCreated();
          setState(() => _createdId = offer ? added.id : null);
          Navigator.of(sheetContext).pop();
        },
      ),
    );
  }
}
