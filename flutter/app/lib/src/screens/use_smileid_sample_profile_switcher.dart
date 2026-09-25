import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sample_ui/sample_ui.dart';

import '../state/use_smileid_sample_forms.dart';
import '../state/use_smileid_sample_providers.dart';

/// The switch sheet over Products or the form; a pick refills the form, and "New profile" is active at once.
Future<void> showUseSmileIDSampleProfileSwitch(
  BuildContext context,
  WidgetRef ref, {
  bool overForm = false,
}) async {
  bool creating = false;
  await showUseSmileIDSampleSheet<void>(
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
          ref.read(useSmileIDSampleFormsProvider.notifier).fillFrom(profile);
          Navigator.of(sheetContext).pop();
        },
        onCreate: () {
          creating = true;
          Navigator.of(sheetContext).pop();
        },
      );
    },
  );
  if (!creating || !context.mounted) {
    return;
  }
  // What the form had typed, so a profile created from it is not typed twice.
  final UseSmileIDSampleForms forms = ref.read(useSmileIDSampleFormsProvider);
  await showUseSmileIDSampleSheet<void>(
    context: context,
    testId: UseSmileIDSampleTestIds.newProfileSheet,
    builder: (BuildContext sheetContext) => UseSmileIDSampleNewProfileSheet(
      initialName: overForm ? forms.organisation : '',
      initialDetails: overForm
          ? forms.userDetails
          : const UseSmileIDSampleUserDetails(),
      onCreate: (String organisation, UseSmileIDSampleUserDetails details) {
        final UseSmileIDSampleProfile created = ref
            .read(useSmileIDSampleProfilesProvider.notifier)
            .add(organisation: organisation, defaults: details, activate: true);
        ref.read(useSmileIDSampleFormsProvider.notifier).fillFrom(created);
        Navigator.of(sheetContext).pop();
      },
    ),
  );
}
