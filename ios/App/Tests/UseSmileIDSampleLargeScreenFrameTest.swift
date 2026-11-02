@testable import UseSmileIDSample
import XCTest

/// On a large screen the app draws its own screens in the largest iPhone's frame; a phone fills the window.
final class UseSmileIDSampleLargeScreenFrameTest: XCTestCase {
  private let frame = UseSmileIDSampleLargeScreen.frame

  func testTheFrameIsTheSpecsIosFrame() throws {
    let spec = try UseSmileIDSampleSpec.object("large-screen-frame.json")
    let ios = try XCTUnwrap((spec["frames"] as? [String: Any])?["ios"] as? [String: Any])

    XCTAssertEqual(try XCTUnwrap(spec["largeScreenMinSide"] as? Double), UseSmileIDSampleLargeScreen.minSide)
    XCTAssertEqual(try CGSize(width: XCTUnwrap(ios["width"] as? Double), height: XCTUnwrap(ios["height"] as? Double)), frame)
  }

  func testALargeScreenDrawsTheAppInTheLargestPhonesFrame() {
    XCTAssertEqual(frameIn(800, 1280), frame)
    XCTAssertEqual(frameIn(600, 960), frame)
    XCTAssertEqual(frameIn(1280, 800), CGSize(width: frame.width, height: 800))
  }

  func testAPhoneDrawsTheAppAcrossItsWholeWindow() {
    XCTAssertNil(frameIn(frame.width, frame.height))
    XCTAssertNil(frameIn(frame.height, frame.width))
    XCTAssertNil(frameIn(599, 1280))
  }

  func testASideShorterThanItsFrameKeepsTheSafeAreasLength() {
    XCTAssertEqual(
      UseSmileIDSampleLargeScreen.frameSize(window: CGSize(width: 1280, height: 800), safeArea: CGSize(width: 1280, height: 728)),
      CGSize(width: frame.width, height: 728)
    )
  }

  private func frameIn(_ width: CGFloat, _ height: CGFloat) -> CGSize? {
    let window = CGSize(width: width, height: height)
    return UseSmileIDSampleLargeScreen.frameSize(window: window, safeArea: window)
  }
}
