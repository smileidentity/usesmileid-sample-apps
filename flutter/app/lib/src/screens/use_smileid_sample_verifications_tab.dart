import 'package:flutter/material.dart';
import 'package:sample_ui/sample_ui.dart';

/// The verifications tab, which a first launch shows empty because nothing is seeded.
///
/// The list, its filters and its row actions arrive with the job store. The empty state sits where
/// the first row would, which is where the twin puts it, rather than centred in the page.
class UseSmileIDSampleVerificationsTab extends StatelessWidget {
  /// Takes nothing; there is nothing to show until a flow has run.
  const UseSmileIDSampleVerificationsTab({super.key});

  @override
  Widget build(BuildContext context) => Semantics(
    identifier: UseSmileIDSampleTestIds.verificationsScreen,
    child: ListView(
      padding: EdgeInsets.only(
        bottom: useSmileIDSampleNavBarClearance(context),
      ),
      children: const <Widget>[
        UseSmileIDSampleEmptyState(
          text: 'No verifications yet',
          supportingText: 'Start a product above and the job lands here.',
          testId: UseSmileIDSampleTestIds.verificationsEmpty,
        ),
      ],
    ),
  );
}
