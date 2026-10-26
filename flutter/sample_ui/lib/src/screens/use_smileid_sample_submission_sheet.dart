import 'package:flutter/material.dart';

import '../components/use_smileid_sample_option_row.dart';
import '../state/use_smileid_sample_settings.dart';
import '../use_smileid_sample_strings_scope.dart';
import '../use_smileid_sample_test_ids.dart';

/// config.skipApiSubmission's two values: submit the job, or hand the captured job back.
class UseSmileIDSampleSubmissionSheet extends StatelessWidget {
  /// [onSelect] both chooses and dismisses.
  const UseSmileIDSampleSubmissionSheet({
    required this.selected,
    required this.onSelect,
    super.key,
  });

  /// The choice already made.
  final UseSmileIDSampleSubmission selected;

  /// Chooses one.
  final ValueChanged<UseSmileIDSampleSubmission> onSelect;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      for (final UseSmileIDSampleSubmission submission
          in UseSmileIDSampleSubmission.values)
        UseSmileIDSampleOptionRow(
          label: submission.label(context.strings),
          selected: submission == selected,
          onTap: () => onSelect(submission),
          testId: UseSmileIDSampleTestIds.submissionOption(submission.id),
        ),
    ],
  );
}
