@testable import SampleUI
import SwiftUI
import XCTest

/// The card in every terminal state and the line in the one state it shows, matching the Compose goldens.
final class UseSmileIDSampleResultCardGoldenTest: UseSmileIDSampleGoldenTest {
  func testResultCardIdle() {
    goldens("result_card_idle") { card(UseSmileIDSampleResultFixtures.idle) }
  }

  func testResultCardSucceeded() {
    goldens("result_card_succeeded") { card(UseSmileIDSampleResultFixtures.succeeded) }
  }

  func testResultCardCancelled() {
    goldens("result_card_cancelled") { card(UseSmileIDSampleResultFixtures.cancelled) }
  }

  func testResultCardFailed() {
    goldens("result_card_failed") { card(UseSmileIDSampleResultFixtures.failed) }
  }

  func testResultCardSurvivesMaxDynamicType() {
    assertSurvivesMaxDynamicType { card(UseSmileIDSampleResultFixtures.failed) }
  }

  func testResultLineRunning() {
    goldens("result_line_running") { UseSmileIDSampleResultLine(result: UseSmileIDSampleResultFixtures.running) }
  }

  func testResultLineSurvivesMaxDynamicType() {
    assertSurvivesMaxDynamicType { UseSmileIDSampleResultLine(result: UseSmileIDSampleResultFixtures.running) }
  }

  private func card(_ result: UseSmileIDSampleResult) -> some View {
    UseSmileIDSampleResultCard(result: result, expanded: .constant(true))
  }
}
