import 'package:flutter/material.dart';

import '../tokens/smile_tokens.dart';

/// The bundled family, addressed through the package that ships it so no host has to declare it.
const String useSmileIDSampleFontFamily = 'packages/sample_ui/DM Sans';

/// The generated ramp rebound onto the bundled family — the token source names Epilogue for the
/// display styles and it is not shipped, so they resolve to DM Sans exactly as the Compose twin does.
abstract final class UseSmileIDSampleType {
  /// The largest display style.
  static final TextStyle textStyleDisplayLg = _bundled(
    SmileType.textStyleDisplayLg,
  );

  /// The medium display style.
  static final TextStyle textStyleDisplayMd = _bundled(
    SmileType.textStyleDisplayMd,
  );

  /// A page heading.
  static final TextStyle textStyleHeadingPage = _bundled(
    SmileType.textStyleHeadingPage,
  );

  /// A card heading.
  static final TextStyle textStyleHeadingCard = _bundled(
    SmileType.textStyleHeadingCard,
  );

  /// A section heading.
  static final TextStyle textStyleHeadingSection = _bundled(
    SmileType.textStyleHeadingSection,
  );

  /// A title.
  static final TextStyle textStyleTitle = _bundled(SmileType.textStyleTitle);

  /// A subtitle.
  static final TextStyle textStyleSubtitle = _bundled(
    SmileType.textStyleSubtitle,
  );

  /// Body prose.
  static final TextStyle textStyleBody = _bundled(SmileType.textStyleBody);

  /// Body prose, emphasised.
  static final TextStyle textStyleBodyStrong = _bundled(
    SmileType.textStyleBodyStrong,
  );

  /// Small body prose.
  static final TextStyle textStyleBodySm = _bundled(SmileType.textStyleBodySm);

  /// A caption, and a field's error message.
  static final TextStyle textStyleCaption = _bundled(
    SmileType.textStyleCaption,
  );

  /// The all-caps overline the section label and the badges build on.
  static final TextStyle textStyleOverline = _bundled(
    SmileType.textStyleOverline,
  );

  /// A button label.
  static final TextStyle textStyleButton = _bundled(SmileType.textStyleButton);

  /// A small button label.
  static final TextStyle textStyleButtonSm = _bundled(
    SmileType.textStyleButtonSm,
  );

  /// The avatar's initials.
  static final TextStyle avatarFont = _bundled(SmileType.avatarFont);

  /// A status badge's label.
  static final TextStyle badgeFont = _bundled(SmileType.badgeFont);

  /// An inline banner's heading.
  static final TextStyle bannerTitleFont = _bundled(SmileType.bannerTitleFont);

  /// An inline banner's prose, which the toast's message builds on.
  static final TextStyle bannerTextFont = _bundled(SmileType.bannerTextFont);

  /// The primary button's label.
  static final TextStyle buttonFont = _bundled(SmileType.buttonFont);

  /// A card's heading.
  static final TextStyle cardTitleFont = _bundled(SmileType.cardTitleFont);

  /// A label/value row's label.
  static final TextStyle dataFieldLabelFont = _bundled(
    SmileType.dataFieldLabelFont,
  );

  /// A label/value row's value.
  static final TextStyle dataFieldValueFont = _bundled(
    SmileType.dataFieldValueFont,
  );

  /// A filter chip's label.
  static final TextStyle filterChipFont = _bundled(SmileType.filterChipFont);

  /// A text field's value and placeholder.
  static final TextStyle inputFont = _bundled(SmileType.inputFont);

  /// A link, which the toast's action builds on.
  static final TextStyle linkFont = _bundled(SmileType.linkFont);

  /// The search field's query and placeholder.
  static final TextStyle searchFont = _bundled(SmileType.searchFont);

  /// A table header cell.
  static final TextStyle tableHeaderFont = _bundled(SmileType.tableHeaderFont);

  /// A table body cell.
  static final TextStyle tableCellFont = _bundled(SmileType.tableCellFont);

  /// A tab label.
  static final TextStyle tabFont = _bundled(SmileType.tabFont);
}

TextStyle _bundled(TextStyle style) =>
    style.copyWith(fontFamily: useSmileIDSampleFontFamily);
