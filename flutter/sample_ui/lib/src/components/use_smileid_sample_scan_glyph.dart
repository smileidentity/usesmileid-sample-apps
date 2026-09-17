import 'package:flutter/material.dart';

import '../theme/use_smileid_sample_theme.dart';
import '../tokens/smile_icons.dart';
import 'use_smileid_sample_icon.dart';

/// The scan target: one exported asset rather than a drawn reticle, so its proportions are the
/// design's own. The tint is a parameter because the reticle carries scanner state over a camera.
class UseSmileIDSampleScanGlyph extends StatelessWidget {
  /// [size] is the design's 279, not a scale token — no token reaches it.
  const UseSmileIDSampleScanGlyph({
    this.size = _scanGlyphSize,
    this.tint,
    super.key,
  });

  /// The square the glyph is drawn into.
  final double size;

  /// The bracket colour; the title colour where there is no camera behind it.
  final Color? tint;

  @override
  Widget build(BuildContext context) => UseSmileIDSampleIcon(
    asset: SmileIcons.scanGlyph,
    tint: tint ?? UseSmileIDSampleTheme.colorsOf(context).textTitle,
    size: size,
  );
}

/// The design's own 279; no scale token reaches it.
const double _scanGlyphSize = 279;
