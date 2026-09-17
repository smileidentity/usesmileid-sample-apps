import 'package:flutter/material.dart';

import '../components/use_smileid_sample_empty_state.dart';
import '../components/use_smileid_sample_section_label.dart';
import '../components/use_smileid_sample_setting_row.dart';
import '../components/use_smileid_sample_top_app_bar.dart';
import '../model/use_smileid_sample_licenses.dart';
import '../theme/use_smileid_sample_colors.dart';
import '../theme/use_smileid_sample_theme.dart';
import '../theme/use_smileid_sample_typography.dart';
import '../tokens/smile_tokens.dart';
import '../use_smileid_sample_test_ids.dart';

/// The third-party notices, opened from the LEGAL section of settings.
///
/// A flat list rather than the rounded section cards the rest of the app uses: two hundred rows
/// inside one card compose all of them at once.
class UseSmileIDSampleLicensesScreen extends StatefulWidget {
  /// An empty [licenses] means the notices did not reach this build, which the screen says rather
  /// than showing a blank page.
  const UseSmileIDSampleLicensesScreen({
    required this.licenses,
    required this.onBack,
    super.key,
  });

  /// The notices, already grouped and sorted by the model.
  final UseSmileIDSampleLicenses licenses;

  /// Leaves the screen.
  final VoidCallback onBack;

  @override
  State<UseSmileIDSampleLicensesScreen> createState() =>
      _UseSmileIDSampleLicensesScreenState();
}

class _UseSmileIDSampleLicensesScreenState
    extends State<UseSmileIDSampleLicensesScreen> {
  /// One at a time: two copies of the Apache text at once is a screen nobody can read.
  String? _expanded;

  @override
  Widget build(BuildContext context) {
    final UseSmileIDSampleColors colors = UseSmileIDSampleTheme.colorsOf(
      context,
    );
    final List<UseSmileIDSampleNotice> notices = widget.licenses.components;
    return Semantics(
      identifier: UseSmileIDSampleTestIds.licensesScreen,
      child: ColoredBox(
        color: colors.background,
        child: Column(
          children: <Widget>[
            UseSmileIDSampleTopAppBar(
              title: 'Open-source licenses',
              onBack: widget.onBack,
            ),
            Expanded(
              child: widget.licenses.isEmpty
                  ? UseSmileIDSampleEmptyState(
                      text: 'No notices bundled',
                      // Flutter's build step writes them, so an empty list means the asset did
                      // not reach this build rather than that nothing is licensed.
                      supportingText:
                          'The generated notices are missing from this build',
                      testId: UseSmileIDSampleTestIds.licensesEmpty,
                    )
                  : ListView.builder(
                      // One header above the rows, so the count is part of the scrolled content.
                      itemCount: notices.length + 1,
                      itemBuilder: (BuildContext context, int index) =>
                          index == 0
                          ? Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: SmileDimens.spacingMd,
                                vertical: SmileDimens.spacingXs,
                              ),
                              child: UseSmileIDSampleSectionLabel(
                                text:
                                    'OPEN-SOURCE COMPONENTS — ${notices.length}',
                              ),
                            )
                          : _row(notices[index - 1], colors),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(UseSmileIDSampleNotice notice, UseSmileIDSampleColors colors) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          UseSmileIDSampleSettingRow(
            title: notice.component,
            supportingText: notice.licenseName,
            onTap: () => setState(
              () => _expanded = _expanded == notice.component
                  ? null
                  : notice.component,
            ),
            testId: UseSmileIDSampleTestIds.licenseRow(notice.component),
          ),
          if (_expanded == notice.component)
            Semantics(
              identifier: UseSmileIDSampleTestIds.licenseText(notice.component),
              child: Padding(
                padding: const EdgeInsets.only(
                  left: SmileDimens.spacingMd,
                  right: SmileDimens.spacingMd,
                  bottom: SmileDimens.spacingSm,
                ),
                child: Text(
                  notice.text,
                  style: UseSmileIDSampleType.textStyleCaption.copyWith(
                    color: colors.textMuted,
                  ),
                ),
              ),
            ),
        ],
      );
}
