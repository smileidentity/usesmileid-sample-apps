@testable import SampleUI
import SwiftUI
import XCTest

/// The scan screen's composites and the ring they feed, in every state a device can show.
final class UseSmileIDSampleScanChromeGoldenTest: UseSmileIDSampleGoldenTest {
  /// Collapsed is the design's two rows; expanded shows what a simulated scan mints; a typed token
  /// adds the link action, and a rejection sits under the field.
  func testScanSheet() {
    goldens("scan_sheet") { ScanSheets() }
  }

  func testScanSheetSurvivesMaxDynamicType() {
    assertSurvivesMaxDynamicType {
      UseSmileIDSampleScanSheet(state: .constant(Self.expanded), onPaste: {}, onLink: {}, onSimulate: {})
    }
  }

  func testScanStatus() {
    goldens("scan_status") { ScanStatuses() }
  }

  func testScanStatusSurvivesMaxDynamicType() {
    assertSurvivesMaxDynamicType { ScanStatuses() }
  }

  /// At rest, and the hidden reticle part at its 45% over a dark ground with the inverse tint.
  func testScanGlyph() {
    goldens("scan_glyph") { ScanGlyphs() }
  }

  /// Idle, counting, expiring and expired: the ring reads remaining time, so these are progress values.
  func testTokenRing() {
    goldens("token_ring") { TokenRings() }
  }

  static let expanded = UseSmileIDSampleScanSheetState(
    span: .oneHour,
    environment: .production,
    bindings: UseSmileIDSampleSimulatedBindings(consent: true),
    expanded: true
  )
}

private struct ScanSheets: View {
  var body: some View {
    VStack(spacing: SmileSpacing.spacingSm) {
      UseSmileIDSampleScanSheet(state: .constant(UseSmileIDSampleScanSheetState()), onPaste: {}, onLink: {}, onSimulate: {})
      UseSmileIDSampleScanSheet(
        state: .constant(UseSmileIDSampleScanChromeGoldenTest.expanded),
        onPaste: {},
        onLink: {},
        onSimulate: {}
      )
      UseSmileIDSampleScanSheet(
        state: .constant(UseSmileIDSampleScanSheetState(
          token: "header.payload.signature",
          rejection: "The token carries no numeric exp claim."
        )),
        onPaste: {},
        onLink: {},
        onSimulate: {}
      )
    }
  }
}

private struct ScanStatuses: View {
  var body: some View {
    VStack(spacing: SmileSpacing.spacingSm) {
      UseSmileIDSampleScanStatus(state: .searching, onRetry: {})
      UseSmileIDSampleScanStatus(state: .found, onRetry: {})
      UseSmileIDSampleScanStatus(state: .linked(handle: "sess_7f2", remaining: "14:59"), onRetry: {})
      UseSmileIDSampleScanStatus(
        state: .rejected(reason: "The token's api_url names api.example.test, which is not a Smile ID environment."),
        onRetry: {}
      )
    }
  }
}

private struct ScanGlyphs: View {
  @Environment(\.useSmileIDSampleColors) private var colors

  var body: some View {
    HStack(spacing: SmileSpacing.spacingSm) {
      UseSmileIDSampleScanGlyph(size: 160)
        .frame(maxWidth: .infinity)
      UseSmileIDSampleScanGlyph(size: 160, tint: colors.textInverse, reticle: true)
        .frame(maxWidth: .infinity)
        .background(colors.textTitle)
    }
  }
}

private struct TokenRings: View {
  var body: some View {
    HStack(spacing: SmileSpacing.spacingMd) {
      ForEach([1.0, 0.62, 0.1, 0.0], id: \.self) { progress in
        UseSmileIDSampleTokenRing(progress: progress)
          .frame(width: SmileSpacing.space64, height: SmileSpacing.space64)
          .frame(maxWidth: .infinity)
      }
    }
  }
}
