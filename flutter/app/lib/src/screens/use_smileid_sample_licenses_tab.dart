import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sample_ui/sample_ui.dart';

import '../state/use_smileid_sample_providers.dart';

/// The third-party notices, pushed inside the settings tab.
///
/// Reads Flutter's own licence registry rather than a committed asset.
class UseSmileIDSampleLicensesTab extends ConsumerWidget {
  /// [onBack] leaves the screen, which the route supplies.
  const UseSmileIDSampleLicensesTab({required this.onBack, super.key});

  /// Leaves the screen.
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<UseSmileIDSampleLicenses> licenses = ref.watch(
      useSmileIDSampleLicensesProvider,
    );
    return Scaffold(
      body: SafeArea(
        // While the registry is still streaming the screen shows its own empty state, which reads as "not bundled".
        child: licenses.hasError
            ? UseSmileIDSampleLicensesScreen(
                licenses: const UseSmileIDSampleLicenses(),
                onBack: onBack,
              )
            : licenses.value == null
            ? const Center(child: CircularProgressIndicator())
            : UseSmileIDSampleLicensesScreen(
                licenses: licenses.value!,
                onBack: onBack,
              ),
      ),
    );
  }
}
