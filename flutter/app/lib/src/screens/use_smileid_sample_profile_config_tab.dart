import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sample_ui/sample_ui.dart';

import '../state/use_smileid_sample_providers.dart';

/// One profile's own page, which saves and activates in a single act.
class UseSmileIDSampleProfileConfigTab extends ConsumerStatefulWidget {
  /// [profileId] comes from the route and may name a profile this launch does not hold.
  const UseSmileIDSampleProfileConfigTab({
    required this.profileId,
    required this.onBack,
    super.key,
  });

  /// The id the route carried.
  final String profileId;

  /// Leaves the page, discarding anything unsaved.
  final VoidCallback onBack;

  @override
  ConsumerState<UseSmileIDSampleProfileConfigTab> createState() =>
      _UseSmileIDSampleProfileConfigTabState();
}

class _UseSmileIDSampleProfileConfigTabState
    extends ConsumerState<UseSmileIDSampleProfileConfigTab> {
  UseSmileIDSampleUserDetails? _edited;

  @override
  Widget build(BuildContext context) {
    final UseSmileIDSampleProfiles profiles = ref.watch(
      useSmileIDSampleProfilesProvider,
    );
    final UseSmileIDSampleProfile? profile = profiles.find(widget.profileId);
    final UseSmileIDSampleUserDetails details =
        _edited ?? profile?.defaults ?? const UseSmileIDSampleUserDetails();
    // Its own chrome: this route sits ABOVE the shell, so it inherits no Scaffold and the material
    // an editable row needs would be missing.
    return Scaffold(
      backgroundColor: UseSmileIDSampleTheme.colorsOf(context).background,
      body: SafeArea(
        child: UseSmileIDSampleProfileConfigScreen(
          // The raw id when the profile is unknown, so a stale link says which one it looked for
          // rather than showing an empty title.
          organisation: profile?.organisation ?? widget.profileId,
          details: details,
          isActive: profile != null && profile.id == profiles.activeId,
          onBack: widget.onBack,
          onFieldChanged: (UseSmileIDSampleUserField field, String value) =>
              setState(() => _edited = field.apply(details, value)),
          onSave: () {
            ref
                .read(useSmileIDSampleProfilesProvider.notifier)
                .setDefaults(widget.profileId, details);
            ref
                .read(useSmileIDSampleProfilesProvider.notifier)
                .setActive(widget.profileId);
            widget.onBack();
          },
        ),
      ),
    );
  }
}
