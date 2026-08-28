@testable import SampleUI
import SnapshotTesting
import SwiftUI
import XCTest

/// The golden harness. Baselines live in `__Snapshots__/` beside this file and are recorded on the
/// pinned simulator (iPhone 17 Pro) — a diff means the UI changed, not the environment.
///
/// Re-record an intentional change by deleting the affected baseline, or with
/// `SNAPSHOT_TESTING_RECORD=all`, then commit what the run wrote.
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
    // Measured once for both schemes: colour is the only thing that differs between them, so a
    // component whose HEIGHT changed with the scheme would size one baseline wrong. None does.
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

  /// The largest accessibility size, as a baseline plus a width assertion.
  ///
  /// Weaker than the Compose twin, and deliberately so rather than by omission: Compose exposes
  /// `didExceedMaxLines` through the semantics tree, and SwiftUI publishes no truncation flag a
  /// unit test can read. So overflow past the viewport fails here, and clipping *within* the
  /// viewport is caught by reviewing the baseline this writes.
  func assertSurvivesMaxDynamicType(
    file: StaticString = #filePath,
    testName: String = #function,
    line: UInt = #line,
    @ViewBuilder content: () -> some View
  ) {
    // The size category goes in through SwiftUI's environment, not a UITraitCollection: a trait is
    // applied after `.sizeThatFits` has measured, so the content renders larger than the frame it
    // was sized for and the baseline records a clipped view instead of a tall one.
    let scaled = content().environment(\.sizeCategory, .accessibilityExtraExtraExtraLarge)

    // Measured WITHOUT the host's fixed-width frame, which would force the answer to the viewport
    // width and make the assertion vacuous. Text that wraps comes back within the proposed width;
    // a child that cannot shrink — a fixed frame, a row of fixed-width controls — comes back wider.
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

  /// The height the view actually needs at the golden width, pinned as a fixed layout.
  ///
  /// Not `.sizeThatFits`, which measures with `layoutFittingCompressedSize` — that returns a
  /// SINGLE line's height for wrapping text, so the baseline records the component truncated into
  /// a box too short for it. Measured here: 88.7pt compressed against 198.7pt actual for three
  /// lines of the heading style at the largest content size.
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
