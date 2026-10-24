import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sample_ui/sample_ui.dart';

import '../navigation/use_smileid_sample_navigation.dart';
import '../navigation/use_smileid_sample_njia.dart';
import '../state/use_smileid_sample_providers.dart';
import 'use_smileid_sample_above_shell_page.dart';

/// The profiles list, whose new-profile sheet is a step over it.
class UseSmileIDSampleProfilesTab extends ConsumerStatefulWidget {
  /// The list for [scope]'s entry.
  const UseSmileIDSampleProfilesTab({required this.scope, super.key});

  /// The list's entry, which a row and the create button go from.
  final UseSmileIDSampleStepScope scope;

  @override
  ConsumerState<UseSmileIDSampleProfilesTab> createState() =>
      _UseSmileIDSampleProfilesTabState();
}

class _UseSmileIDSampleProfilesTabState
    extends ConsumerState<UseSmileIDSampleProfilesTab> {
  String? _createdId;

  @override
  Widget build(BuildContext context) {
    // Consumed on sight: returning to this screen later must not replay a confirmation for a profile created minutes ago.
    ref.listen<String?>(
      useSmileIDSampleProfilesProvider.select(
        (UseSmileIDSampleProfiles profiles) => profiles.lastCreatedId,
      ),
      (String? _, String? created) {
        if (created == null) {
          return;
        }
        setState(() => _createdId = created);
        scheduleMicrotask(
          ref.read(useSmileIDSampleProfilesProvider.notifier).clearLastCreated,
        );
      },
    );
    final UseSmileIDSampleProfiles profiles = ref.watch(
      useSmileIDSampleProfilesProvider,
    );
    final UseSmileIDSampleProfile? created = _createdId == null
        ? null
        : profiles.find(_createdId!);
    return UseSmileIDSampleAboveShellPage(
      child: UseSmileIDSampleProfilesScreen(
        profiles: profiles.all,
        activeId: profiles.activeId,
        onBack: () => unawaited(widget.scope.navigator.back()),
        onProfileTap: (UseSmileIDSampleProfile profile) => unawaited(
          widget.scope.navigator.goStep(
            UseSmileIDSampleStep.profileConfig,
            arg: profile.id,
          ),
        ),
        onCreate: () => unawaited(
          widget.scope.navigator.goStep(UseSmileIDSampleStep.newProfile),
        ),
        createdNotice: created?.title(context.strings),
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
}
