import 'package:flutter/material.dart';

import '../model/use_smileid_sample_simulated_scan.dart';
import '../theme/use_smileid_sample_colors.dart';
import '../theme/use_smileid_sample_theme.dart';
import '../theme/use_smileid_sample_typography.dart';
import '../tokens/smile_tokens.dart';
import 'use_smileid_sample_glyphs.dart';

/// The scanner's state over the viewfinder, in one pill; only a rejection offers an action.
class UseSmileIDSampleScanStatus extends StatelessWidget {
  /// [onRetry] re-enables the scanner after a rejection.
  const UseSmileIDSampleScanStatus({
    required this.state,
    required this.onRetry,
    super.key,
  });

  /// What to say.
  final UseSmileIDSampleScanState state;

  /// Called by the rejection's Try again.
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final UseSmileIDSampleColors colors = UseSmileIDSampleTheme.colorsOf(
      context,
    );
    final (Color background, Color foreground) = switch (state) {
      UseSmileIDSampleScanSearching() => (colors.surface, colors.textTitle),
      UseSmileIDSampleScanFound() => (colors.infoFill, colors.onInfo),
      UseSmileIDSampleScanLinked() => (colors.successFill, colors.onSuccess),
      UseSmileIDSampleScanRejected() => (colors.errorFill, colors.onError),
    };
    final String? detail = switch (state) {
      UseSmileIDSampleScanSearching() => null,
      UseSmileIDSampleScanFound() => 'Reading it now',
      // The handle and the time left: never the token, which no surface here may show.
      UseSmileIDSampleScanLinked(
        :final String handle,
        :final String remaining,
      ) =>
        '$handle · $remaining left',
      UseSmileIDSampleScanRejected(:final String reason) => reason,
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(SmileDimens.radiusSurface),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: SmileDimens.spacingMd,
          vertical: SmileDimens.spacingSm,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                if (state is UseSmileIDSampleScanLinked) ...<Widget>[
                  UseSmileIDSampleGlyphs.check(foreground),
                  const SizedBox(width: SmileDimens.spacingXs),
                ],
                Flexible(
                  child: Text(
                    _headline,
                    textAlign: TextAlign.center,
                    style: UseSmileIDSampleType.textStyleBodyStrong.copyWith(
                      color: foreground,
                    ),
                  ),
                ),
              ],
            ),
            if (detail != null) ...<Widget>[
              const SizedBox(height: SmileDimens.spacingXxs),
              Text(
                detail,
                textAlign: TextAlign.center,
                style: UseSmileIDSampleType.textStyleCaption.copyWith(
                  fontSize: _detailSize,
                  color: foreground,
                ),
              ),
            ],
            if (state is UseSmileIDSampleScanRejected)
              Semantics(
                button: true,
                child: GestureDetector(
                  onTap: onRetry,
                  behavior: HitTestBehavior.opaque,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      minHeight: SmileDimens.sizeControlMd,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: SmileDimens.spacingXs,
                      ),
                      child: Center(
                        widthFactor: 1,
                        child: Text(
                          'Try again',
                          style: UseSmileIDSampleType.linkFont.copyWith(
                            fontWeight: FontWeight.w700,
                            color: foreground,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String get _headline => switch (state) {
    UseSmileIDSampleScanSearching() => 'Point at a Smile token QR',
    UseSmileIDSampleScanFound() => 'Token found',
    UseSmileIDSampleScanLinked() => 'Session linked',
    UseSmileIDSampleScanRejected() => 'That is not a token',
  };
}

/// The detail line's run.
const double _detailSize = 12.5;
