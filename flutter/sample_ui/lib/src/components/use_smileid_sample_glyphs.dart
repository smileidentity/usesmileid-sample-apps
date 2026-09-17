import 'package:flutter/material.dart';

import '../tokens/smile_icons.dart';
import '../tokens/smile_tokens.dart';
import 'use_smileid_sample_icon.dart';

/// The design's own stroke-based marks, and the Material Symbols the design supplies nowhere.
///
/// The two families are deliberately not interchangeable — `spec/components.json` → conventions.
/// All decorative: the enclosing control supplies the label.
abstract final class UseSmileIDSampleGlyphs {
  /// The list chevron, which points RIGHT.
  static Widget chevronRight(
    Color tint, {
    double size = SmileDimens.sizeIconMd,
  }) => UseSmileIDSampleIcon(asset: SmileIcons.chevron, tint: tint, size: size);

  /// The select trigger's chevron, which points DOWN.
  static Widget chevronDown(
    Color tint, {
    double size = SmileDimens.sizeIconSm,
  }) => UseSmileIDSampleIcon(
    asset: SmileIcons.chevronDown,
    tint: tint,
    size: size,
  );

  /// The design's own arrows, which are shorter than a hand-drawn glyph.
  static Widget arrowBack(Color tint, {double size = SmileDimens.sizeIconMd}) =>
      UseSmileIDSampleIcon(asset: SmileIcons.arrowBack, tint: tint, size: size);

  /// The forward arrow.
  static Widget arrowForward(
    Color tint, {
    double size = SmileDimens.sizeIconSm,
  }) => UseSmileIDSampleIcon(
    asset: SmileIcons.arrowForward,
    tint: tint,
    size: size,
  );

  /// The token scan mark.
  static Widget scanMark(Color tint, {double size = SmileDimens.sizeIconMd}) =>
      UseSmileIDSampleIcon(asset: SmileIcons.tokenScan, tint: tint, size: size);

  /// The design's own trash mark, not the Material stand-in that once stood in for it.
  static Widget trash(Color tint, {double size = SmileDimens.sizeIconMd}) =>
      UseSmileIDSampleIcon(asset: SmileIcons.trash, tint: tint, size: size);

  /// The design's own flash mark, for Scan token's torch.
  static Widget flash(Color tint, {double size = SmileDimens.sizeIconMd}) =>
      UseSmileIDSampleIcon(asset: SmileIcons.flash, tint: tint, size: size);

  /// Material Symbols: the check the design supplies nowhere.
  static Widget check(Color tint, {double size = SmileDimens.sizeIconMd}) =>
      UseSmileIDSampleIcon(
        asset: SmileIcons.materialCheck,
        tint: tint,
        size: size,
      );

  /// Material Symbols: the copy control on the job and user id rows.
  static Widget copy(Color tint, {double size = SmileDimens.sizeIconSm}) =>
      UseSmileIDSampleIcon(
        asset: SmileIcons.materialCopy,
        tint: tint,
        size: size,
      );

  /// Material Symbols: the add-a-profile control.
  static Widget plus(Color tint, {double size = SmileDimens.sizeIconMd}) =>
      UseSmileIDSampleIcon(
        asset: SmileIcons.materialPlus,
        tint: tint,
        size: size,
      );

  /// Material Symbols stand-in: Enhanced KYC has no mark of its own yet.
  static Widget productMark(
    Color tint, {
    double size = SmileDimens.sizeIconMd,
  }) => UseSmileIDSampleIcon(
    asset: SmileIcons.materialProductMark,
    tint: tint,
    size: size,
  );
}
