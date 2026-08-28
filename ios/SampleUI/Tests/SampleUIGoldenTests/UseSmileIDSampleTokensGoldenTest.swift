@testable import SampleUI
import SwiftUI
import XCTest

/// Proves the harness before any component exists, against the layer everything else resolves
/// through. A scheme that stops re-resolving, a face that stops registering, or a soft badge fill
/// that reverts to the saturated pair all show up here rather than in the first screen that ships.
final class UseSmileIDSampleTokensGoldenTest: UseSmileIDSampleGoldenTest {
  func testTypeRamp() {
    goldens("type_ramp") { TypeRamp() }
  }

  func testSemanticColours() {
    goldens("semantic_colours") { SemanticColours() }
  }

  func testSoftBadgeFills() {
    goldens("soft_badge_fills") { SoftBadgeFills() }
  }

  func testTypeRampSurvivesMaxDynamicType() {
    assertSurvivesMaxDynamicType { TypeRamp() }
  }
}

private struct TypeRamp: View {
  @Environment(\.useSmileIDSampleColors) private var colors

  private var styles: [(String, SmileTextStyle)] {
    let type = UseSmileIDSampleTheme.type
    return [
      ("Heading page", type.textStyleHeadingPage),
      ("Heading section", type.textStyleHeadingSection),
      ("Title", type.textStyleTitle),
      ("Subtitle", type.textStyleSubtitle),
      ("Body", type.textStyleBody),
      ("Body strong", type.textStyleBodyStrong),
      ("Caption", type.textStyleCaption),
      ("OVERLINE", type.textStyleOverline)
    ]
  }

  var body: some View {
    VStack(alignment: .leading, spacing: SmileSpacing.spacingXs) {
      ForEach(styles, id: \.0) { name, style in
        UseSmileIDSampleText(name, style: style)
          .foregroundColor(colors.textTitle)
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }
}

private struct SemanticColours: View {
  @Environment(\.useSmileIDSampleColors) private var colors

  private var swatches: [(String, Color)] {
    [
      ("background", colors.background),
      ("surface", colors.surface),
      ("surfaceTile", colors.surfaceTile),
      ("cardStroke", colors.cardStroke),
      ("border", colors.border),
      ("foreground", colors.foreground),
      ("navBar", colors.navBar),
      ("primary", colors.primary),
      ("accent", colors.accent),
      ("textMuted", colors.textMuted)
    ]
  }

  var body: some View {
    VStack(alignment: .leading, spacing: SmileSpacing.spacingXxs) {
      ForEach(swatches, id: \.0) { name, colour in
        HStack(spacing: SmileSpacing.spacingXs) {
          RoundedRectangle(cornerRadius: SmileSpacing.radiusSm)
            .fill(colour)
            .frame(width: SmileSpacing.space40, height: SmileSpacing.space24)
            .overlay(
              RoundedRectangle(cornerRadius: SmileSpacing.radiusSm)
                .strokeBorder(colors.cardStroke, lineWidth: smileCardStrokeWidth)
            )
          UseSmileIDSampleText(name, style: UseSmileIDSampleTheme.type.textStyleBodySm)
            .foregroundColor(colors.textBody)
        }
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }
}

private struct SoftBadgeFills: View {
  @Environment(\.useSmileIDSampleColors) private var colors

  /// The four job statuses, in the vocabulary the design uses, mapped onto their feedback roles.
  private var pills: [(String, Color, Color)] {
    [
      ("Clear", colors.badge.successBackground, colors.badge.successText),
      ("Attention", colors.badge.warningBackground, colors.badge.warningText),
      ("Blocked", colors.badge.errorBackground, colors.badge.errorText),
      ("Processing", colors.badge.infoBackground, colors.badge.infoText)
    ]
  }

  var body: some View {
    HStack(spacing: SmileSpacing.spacingXs) {
      ForEach(pills, id: \.0) { label, background, text in
        UseSmileIDSampleText(label, style: UseSmileIDSampleTheme.type.badgeFont)
          .foregroundColor(text)
          .padding(.horizontal, SmileSpacing.spacingSm)
          .padding(.vertical, SmileSpacing.spacingXxs)
          .background(
            RoundedRectangle(cornerRadius: UseSmileIDSampleShapes.pill).fill(background)
          )
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }
}
