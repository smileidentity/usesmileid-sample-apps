import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sample_ui/sample_ui.dart';

import '../state/use_smileid_sample_providers.dart';
import '../state/use_smileid_sample_session_providers.dart';
import 'use_smileid_sample_above_shell_page.dart';

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

  String? _editedCallbackUrl;

  String? _editedOrganisation;

  bool _leaving = false;

  @override
  Widget build(BuildContext context) {
    final UseSmileIDSampleProfiles profiles = ref.watch(
      useSmileIDSampleProfilesProvider,
    );
    final UseSmileIDSampleProfile? profile = profiles.find(widget.profileId);
    if (profile == null) {
      if (!_leaving) {
        _leaving = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            widget.onBack();
          }
        });
      }
      return const SizedBox.shrink();
    }
    final UseSmileIDSampleUserDetails details = _edited ?? profile.defaults;
    final String organisation = _editedOrganisation ?? profile.organisation;
    final String callbackUrl = _editedCallbackUrl ?? profile.callbackUrl;
    final UseSmileIDSampleTokenSession? live = ref
        .watch(useSmileIDSampleSessionProvider)
        .live;
    final UseSmileIDSampleProfilesNotifier edits = ref.read(
      useSmileIDSampleProfilesProvider.notifier,
    );
    return UseSmileIDSampleAboveShellPage(
      onBack: widget.onBack,
      child: UseSmileIDSampleProfileConfigScreen(
        title: profile.title,
        organisation: organisation,
        onOrganisationChanged: (String value) =>
            setState(() => _editedOrganisation = value),
        details: details,
        isActive: profile.id == profiles.activeId,
        changed:
            organisation.trim() != profile.organisation ||
            details != profile.defaults ||
            callbackUrl.trim() != profile.callbackUrl,
        onBack: widget.onBack,
        onFieldChanged: (UseSmileIDSampleUserField field, String value) =>
            setState(() => _edited = field.apply(details, value)),
        callbackUrl: callbackUrl,
        onCallbackUrlChanged: (String value) =>
            setState(() => _editedCallbackUrl = value),
        callbackOverride: live?.callbackOverrideCaption,
        onSave: () {
          edits
            ..update(
              profile.id,
              organisation: organisation,
              defaults: details,
              callbackUrl: callbackUrl,
            )
            ..setActive(profile.id);
          widget.onBack();
        },
        onDelete: () {
          _leaving = true;
          edits.delete(profile.id);
          widget.onBack();
        },
      ),
    );
  }
}
