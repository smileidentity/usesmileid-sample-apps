import 'package:flutter/material.dart';

import '../model/use_smileid_sample_result.dart';
import '../theme/use_smileid_sample_colors.dart';
import '../theme/use_smileid_sample_label_type.dart';
import '../theme/use_smileid_sample_theme.dart';
import '../theme/use_smileid_sample_typography.dart';
import '../tokens/smile_tokens.dart';
import '../use_smileid_sample_test_ids.dart';

/// Stable: flows assert on it to prove a value was absent.
const String _nullValue = '—';

/// Every `spec/result-card.schema.json` field under its own id, expanded by default since a collapsed field leaves the tree.
class UseSmileIDSampleResultCard extends StatefulWidget {
  /// Renders [result] as the card.
  const UseSmileIDSampleResultCard({required this.result, super.key});

  /// What the SDK did.
  final UseSmileIDSampleResult result;

  @override
  State<UseSmileIDSampleResultCard> createState() =>
      _UseSmileIDSampleResultCardState();
}

class _UseSmileIDSampleResultCardState
    extends State<UseSmileIDSampleResultCard> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final UseSmileIDSampleColors colors = UseSmileIDSampleTheme.colorsOf(
      context,
    );
    final UseSmileIDSampleResult result = widget.result;
    return Semantics(
      // A container, or the card's id replaces every field's and a flow can read none.
      container: true,
      identifier: UseSmileIDSampleTestIds.resultCard,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surfaceAlt,
          borderRadius: UseSmileIDSampleShapes.card,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: SmileDimens.spacingSm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Semantics(
                button: true,
                label: _expanded ? 'Collapse SDK result' : 'Expand SDK result',
                excludeSemantics: true,
                child: InkWell(
                  onTap: () => setState(() => _expanded = !_expanded),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      minHeight: SmileDimens.space40,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: SmileDimens.spacingMd,
                      ),
                      child: Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              'SDK RESULT',
                              style: useSmileIDSampleLabelStyle(
                                UseSmileIDSampleType.textStyleOverline,
                              ).copyWith(color: colors.textMuted),
                            ),
                          ),
                          const SizedBox(width: SmileDimens.spacingXs),
                          Text(
                            _expanded ? 'Hide' : 'Show',
                            style: UseSmileIDSampleType.textStyleCaption
                                .copyWith(color: colors.textLink),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              if (_expanded) ...<Widget>[
                _Field(
                  'Scenario',
                  result.activeScenario.id,
                  UseSmileIDSampleTestIds.resultActiveScenario,
                ),
                _Field(
                  'Theme',
                  result.activeTheme.id,
                  UseSmileIDSampleTestIds.resultActiveTheme,
                ),
                _Field(
                  'Route',
                  result.route.id,
                  UseSmileIDSampleTestIds.resultRoute,
                ),
                _Field(
                  'Environment',
                  result.environment.id,
                  UseSmileIDSampleTestIds.resultEnvironment,
                ),
                _Field(
                  'Job id',
                  result.jobId,
                  UseSmileIDSampleTestIds.resultJobId,
                ),
                _Field(
                  'User id',
                  result.userId,
                  UseSmileIDSampleTestIds.resultUserId,
                ),
                _Field(
                  'Job status',
                  result.jobStatus.id,
                  UseSmileIDSampleTestIds.resultJobStatus,
                ),
                _Field(
                  'Result callbacks',
                  '${result.resultCallbackCount}',
                  UseSmileIDSampleTestIds.resultResultCount,
                ),
                _Field(
                  'Refresh callbacks',
                  '${result.refreshCallbackCount}',
                  UseSmileIDSampleTestIds.resultRefreshCount,
                ),
                _Field(
                  'Last error',
                  result.lastError,
                  UseSmileIDSampleTestIds.resultLastError,
                ),
                _Field(
                  'SDK version',
                  result.sdkVersion,
                  UseSmileIDSampleTestIds.resultSdkVersion,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// The compact form on products while a run is in flight: three fields, under the same ids as the card.
class UseSmileIDSampleResultLine extends StatelessWidget {
  /// Renders [result] as one line.
  const UseSmileIDSampleResultLine({required this.result, super.key});

  /// The run in flight.
  final UseSmileIDSampleResult result;

  @override
  Widget build(BuildContext context) {
    final UseSmileIDSampleColors colors = UseSmileIDSampleTheme.colorsOf(
      context,
    );
    final Widget heading = Text(
      'SDK',
      style: useSmileIDSampleLabelStyle(
        UseSmileIDSampleType.textStyleOverline,
      ).copyWith(color: colors.textMuted),
    );
    final Widget status = _Value(
      result.jobStatus.id,
      UseSmileIDSampleTestIds.resultJobStatus,
    );
    final Widget scenario = _Value(
      result.activeScenario.id,
      UseSmileIDSampleTestIds.resultActiveScenario,
    );
    final Widget route = _Value(
      result.route.id,
      UseSmileIDSampleTestIds.resultRoute,
    );
    final bool stacked = MediaQuery.textScalerOf(context).scale(1) > 1;
    return Semantics(
      container: true,
      identifier: UseSmileIDSampleTestIds.resultCard,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surfaceAlt,
          borderRadius: UseSmileIDSampleShapes.card,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: SmileDimens.space40),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: SmileDimens.spacingMd,
              vertical: SmileDimens.spacingXs,
            ),
            child: stacked
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: SmileDimens.spacingXxs,
                    children: <Widget>[heading, status, scenario, route],
                  )
                : Row(
                    spacing: SmileDimens.spacingXs,
                    children: <Widget>[
                      heading,
                      Expanded(child: status),
                      scenario,
                      route,
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

/// One label and its value; a null value still renders, since a missing id and an empty one are different failures.
class _Field extends StatelessWidget {
  const _Field(this.label, this.value, this.testId);

  final String label;

  final String? value;

  final String testId;

  @override
  Widget build(BuildContext context) {
    final UseSmileIDSampleColors colors = UseSmileIDSampleTheme.colorsOf(
      context,
    );
    final Widget labelText = Text(
      label,
      style: UseSmileIDSampleType.textStyleCaption.copyWith(
        color: colors.textMuted,
      ),
    );
    final bool stacked = MediaQuery.textScalerOf(context).scale(1) > 1;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: SmileDimens.spacingMd,
        vertical: SmileDimens.spacingXxs,
      ),
      child: stacked
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: SmileDimens.spacingXxs,
              children: <Widget>[labelText, _Value(value, testId)],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              spacing: SmileDimens.spacingXs,
              children: <Widget>[
                labelText,
                Expanded(child: _Value(value, testId, align: TextAlign.end)),
              ],
            ),
    );
  }
}

class _Value extends StatelessWidget {
  const _Value(this.value, this.testId, {this.align = TextAlign.start});

  final String? value;

  final String testId;

  final TextAlign align;

  @override
  Widget build(BuildContext context) => Semantics(
    identifier: testId,
    child: Text(
      value ?? _nullValue,
      textAlign: align,
      style: UseSmileIDSampleType.textStyleCaption.copyWith(
        color: UseSmileIDSampleTheme.colorsOf(context).textBody,
      ),
    ),
  );
}
