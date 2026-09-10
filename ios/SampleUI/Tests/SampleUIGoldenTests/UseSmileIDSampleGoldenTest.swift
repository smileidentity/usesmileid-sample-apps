@testable import SampleUI
import SnapshotTesting
import SwiftUI
import XCTest

/// The golden harness: baselines in `__Snapshots__/`, recorded on the pinned iPhone 17 Pro; delete one to re-record.
@MainActor
class UseSmileIDSampleGoldenTest: XCTestCase {
  /// Captures one component in light and dark, the pair every UI change has to update together.
  func goldens(
    _ name: String,
    file: StaticString = #filePath,
    testName: String = #function,
    line: UInt = #line,
    @ViewBuilder content: () -> some View
  ) {
    let view = host(content())
    // Measured once for both schemes: only colour differs, so a scheme-dependent height would size one wrong.
    let layout = measured(view)
    for (suffix, style) in [("light", UIUserInterfaceStyle.light), ("dark", .dark)] {
      assertSnapshot(
        of: view,
        as: .image(layout: layout, traits: .init(userInterfaceStyle: style)),
        named: "\(name)_\(suffix)",
        file: file,
        testName: testName,
        line: line
      )
    }
  }

  /// The largest accessibility size: overflow past the viewport fails here, clipping within it is caught by reading the baseline.
  func assertSurvivesMaxDynamicType(
    growsWithContentSize: Bool = true,
    file: StaticString = #filePath,
    testName: String = #function,
    line: UInt = #line,
    @ViewBuilder content: () -> some View
  ) {
    // Through the environment, not a UITraitCollection: a trait applies after `.sizeThatFits`, so the baseline clips.
    let scaled = content().environment(\.sizeCategory, .accessibilityExtraExtraExtraLarge)

    // Without the host's fixed-width frame, which would force the answer to the viewport width and make this vacuous.
    let available = Self.width - SmileSpacing.spacingMd * 2
    let ideal = UIHostingController(rootView: scaled.useSmileIDSampleTheme())
      .sizeThatFits(in: CGSize(width: available, height: .greatestFiniteMagnitude))

    XCTAssertLessThanOrEqual(
      ideal.width,
      available + Self.tolerance,
      "laid out wider than the viewport at the largest content size",
      file: file,
      line: line
    )

    // Growth is the only truncation signal SwiftUI leaves, so the fixed ones are declared and a stale declaration fails.
    // Pinned rather than inherited: at the host's own category a runner set to large text makes this equal `ideal`.
    let natural = UIHostingController(
      rootView: content().environment(\.sizeCategory, .large).useSmileIDSampleTheme()
    )
    .sizeThatFits(in: CGSize(width: available, height: .greatestFiniteMagnitude))
    if growsWithContentSize {
      XCTAssertGreaterThan(
        ideal.height,
        natural.height + Self.tolerance,
        "did not get taller at the largest content size: its text is capped, or it fills its frame "
          + "and should declare growsWithContentSize: false",
        file: file,
        line: line
      )
    } else {
      XCTAssertLessThanOrEqual(
        ideal.height,
        natural.height + Self.tolerance,
        "grew at the largest content size, so it is no longer fixed by design — drop the flag",
        file: file,
        line: line
      )
    }

    let view = host(scaled)
    assertSnapshot(
      of: view,
      as: .image(layout: measured(view), traits: .init(userInterfaceStyle: .light)),
      named: "max_dynamic_type",
      file: file,
      testName: testName,
      line: line
    )
  }

  /// The viewport every golden is measured in: the width of the phone the goldens are verified on.
  private func host(_ content: some View) -> some View {
    content
      .frame(width: Self.width - SmileSpacing.spacingMd * 2)
      .padding(SmileSpacing.spacingMd)
      .background(BackgroundFill())
      .useSmileIDSampleTheme()
  }

  /// The height the view needs at the golden width — not `.sizeThatFits`, which returns one line's height for wrapping text.
  private func measured(_ view: some View) -> SwiftUISnapshotLayout {
    let height = UIHostingController(rootView: view)
      .sizeThatFits(in: CGSize(width: Self.width, height: .greatestFiniteMagnitude))
      .height
    return .fixed(width: Self.width, height: height)
  }

  private static let width: CGFloat = 393
  /// Sub-pixel rounding in layout, not a real overflow.
  private static let tolerance: CGFloat = 0.5
}

/// Reads the themed background, which the host cannot do before the theme is in the environment.
private struct BackgroundFill: View {
  @Environment(\.useSmileIDSampleColors) private var colors

  var body: some View {
    colors.background
  }
}
