@testable import SampleUI
import SwiftUI
import XCTest

/// Every mark in one baseline: a wrong transform or a dropped subpath still compiles and still draws something.
final class UseSmileIDSampleIconGoldenTest: UseSmileIDSampleGoldenTest {
  func testEveryIcon() {
    goldens("icons") { IconGrid() }
  }
}

private struct IconGrid: View {
  @Environment(\.useSmileIDSampleColors) private var colors

  var body: some View {
    VStack(alignment: .leading, spacing: SmileSpacing.spacingSm) {
      ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
        HStack(spacing: SmileSpacing.spacingSm) {
          ForEach(row, id: \.0) { _, icon in
            UseSmileIDSampleIcon(icon, tint: colors.textTitle, size: SmileSpacing.sizeIconLg)
          }
        }
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }

  private var rows: [[(String, SmileIcon)]] {
    stride(from: 0, to: Self.all.count, by: 8).map {
      Array(Self.all[$0..<min($0 + 8, Self.all.count)])
    }
  }

  /// Listed by hand: a mark the generator stopped emitting should break the build, not shrink the baseline.
  private static let all: [(String, SmileIcon)] = [
    ("agent", SmileIcons.agent), ("arrowBack", SmileIcons.arrowBack),
    ("arrowForward", SmileIcons.arrowForward), ("biometricKyc", SmileIcons.biometricKyc),
    ("check", SmileIcons.check), ("chevron", SmileIcons.chevron),
    ("chevronDown", SmileIcons.chevronDown), ("consent", SmileIcons.consent),
    ("copy", SmileIcons.copy), ("darkMode", SmileIcons.darkMode),
    ("docs", SmileIcons.docs), ("documentVerification", SmileIcons.documentVerification),
    ("enhancedKyc", SmileIcons.enhancedKyc), ("fieldEmail", SmileIcons.fieldEmail),
    ("fieldPerson", SmileIcons.fieldPerson), ("fieldPhone", SmileIcons.fieldPhone),
    ("instructions", SmileIcons.instructions), ("licenses", SmileIcons.licenses),
    ("plus", SmileIcons.plus), ("preview", SmileIcons.preview),
    ("privacy", SmileIcons.privacy), ("productMark", SmileIcons.productMark),
    ("products", SmileIcons.products), ("scanGlyph", SmileIcons.scanGlyph),
    ("settingScenarios", SmileIcons.settingScenarios), ("settings", SmileIcons.settings),
    ("smartSelfieAuth", SmileIcons.smartSelfieAuth),
    ("smartSelfieEnrollment", SmileIcons.smartSelfieEnrollment),
    ("smile", SmileIcons.smile), ("support", SmileIcons.support),
    ("terms", SmileIcons.terms), ("tokenScan", SmileIcons.tokenScan),
    ("torch", SmileIcons.torch), ("trash", SmileIcons.trash),
    ("verifications", SmileIcons.verifications)
  ]
}
