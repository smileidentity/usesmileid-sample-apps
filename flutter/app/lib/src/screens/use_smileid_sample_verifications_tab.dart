import 'package:flutter/material.dart';
import 'package:sample_ui/sample_ui.dart';

/// The verifications tab, which a first launch shows empty because nothing is seeded.
///
/// The list, its filters and its row actions arrive with the job store; the empty state is the
/// whole of this screen until then, and is what the tab genuinely shows on a clean install.
class UseSmileIDSampleVerificationsTab extends StatelessWidget {
  /// Takes nothing; there is nothing to show until a flow has run.
  const UseSmileIDSampleVerificationsTab({super.key});

  @override
  Widget build(BuildContext context) => Semantics(
    identifier: UseSmileIDSampleTestIds.verificationsScreen,
    child: const Center(
      child: UseSmileIDSampleEmptyState(
        text: 'No verifications yet',
        supportingText: 'Run a product to see it here',
        testId: UseSmileIDSampleTestIds.verificationsEmpty,
      ),
    ),
  );
}
