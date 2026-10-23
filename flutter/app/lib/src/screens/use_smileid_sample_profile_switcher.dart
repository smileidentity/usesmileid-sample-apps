import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sample_ui/sample_ui.dart';

import '../navigation/use_smileid_sample_navigation.dart';
import '../state/use_smileid_sample_forms.dart';
import '../state/use_smileid_sample_providers.dart';

/// The switch sheet over Products or the form; a pick refills the form, and "New profile" is active at once.
class UseSmileIDSampleProfileSwitchStep extends ConsumerStatefulWidget {
  /// The sheet for [scope]'s entry.
  const UseSmileIDSampleProfileSwitchStep({required this.scope, super.key});

  /// The sheet's entry, which a pick goes back from.
  final UseSmileIDSampleStepScope scope;

  @override
  ConsumerState<UseSmileIDSampleProfileSwitchStep> createState() =>
      _UseSmileIDSampleProfileSwitchStepState();
}

class _UseSmileIDSampleProfileSwitchStepState
    extends ConsumerState<UseSmileIDSampleProfileSwitchStep> {
  /// Whether "New profile" swapped the list for the new-profile form, in this sheet's place.
  bool _creating = false;

  @override
  Widget build(BuildContext context) {
    if (_creating) {
      return UseSmileIDSampleNewProfileStep(
        activate: true,
        onDone: widget.scope.navigator.back,
      );
    }
    final UseSmileIDSampleProfiles profiles = ref.watch(
      useSmileIDSampleProfilesProvider,
    );
    return UseSmileIDSamplePartialSheetBody(
      testId: UseSmileIDSampleTestIds.profileSwitchSheet,
      child: UseSmileIDSampleProfileSwitchSheet(
        profiles: profiles.all,
        activeId: profiles.activeId,
        onSelect: (UseSmileIDSampleProfile profile) {
          ref
              .read(useSmileIDSampleProfilesProvider.notifier)
              .setActive(profile.id);
          ref.read(useSmileIDSampleFormsProvider.notifier).fillFrom(profile);
          unawaited(widget.scope.navigator.back());
        },
        onCreate: () => setState(() => _creating = true),
      ),
    );
  }
}

/// The new-profile sheet, over the profiles list or in the switch sheet's place.
class UseSmileIDSampleNewProfileStep extends ConsumerWidget {
  /// A form that closes with [onDone] once it has created a profile, making it active when [activate].
  const UseSmileIDSampleNewProfileStep({
    required this.onDone,
    this.activate = false,
    super.key,
  });

  /// Closes the sheet.
  final Future<void> Function() onDone;

  /// Whether the profile created is made active and fills the form, as one created from the switch is.
  final bool activate;

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      UseSmileIDSamplePartialSheetBody(
        testId: UseSmileIDSampleTestIds.newProfileSheet,
        child: UseSmileIDSampleNewProfileSheet(
          onCreate: (String organisation, UseSmileIDSampleUserDetails details) {
            final UseSmileIDSampleProfile created = ref
                .read(useSmileIDSampleProfilesProvider.notifier)
                .add(
                  organisation: organisation,
                  defaults: details,
                  activate: activate,
                );
            if (activate) {
              ref
                  .read(useSmileIDSampleFormsProvider.notifier)
                  .fillFrom(created);
            }
            unawaited(onDone());
          },
        ),
      );
}
