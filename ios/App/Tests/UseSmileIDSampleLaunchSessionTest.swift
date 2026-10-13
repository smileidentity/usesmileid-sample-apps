import SampleUI
@testable import UseSmileIDSample
import XCTest

@MainActor
final class UseSmileIDSampleLaunchSessionTest: XCTestCase {
  private enum Offering: UseSmileIDSampleShellExtending {
    static let session = UseSmileIDSampleTokenDecoder.session(
      UseSmileIDSampleFlowTokens.session(span: .fifteenMinutes, bindings: .init(), environment: .sandbox, now: Date())
    )

    static func launchSession() -> UseSmileIDSampleTokenSession? {
      session
    }
  }

  private enum Silent: UseSmileIDSampleShellExtending {}

  func testLinksTheSessionTheExtensionOffersAtLaunch() throws {
    var linked: [UseSmileIDSampleTokenSession] = []
    linkLaunchSession(Offering.self) { linked.append($0) }
    XCTAssertEqual(linked.map(\.id), try [XCTUnwrap(Offering.session).id])
  }

  func testLinksNothingWithoutAnExtensionOrWhenItOffersNone() {
    var linked: [UseSmileIDSampleTokenSession] = []
    linkLaunchSession(nil) { linked.append($0) }
    linkLaunchSession(Silent.self) { linked.append($0) }
    XCTAssertTrue(linked.isEmpty)
  }
}
