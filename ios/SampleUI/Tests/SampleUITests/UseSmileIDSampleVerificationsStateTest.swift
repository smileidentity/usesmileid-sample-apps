@testable import SampleUI
import XCTest

final class UseSmileIDSampleVerificationsStateTest: XCTestCase {
  private let jobs = UseSmileIDSampleJobStore.fixtures(now: Date(timeIntervalSince1970: 1784202612))

  func testAnEmptyListOffersNothingToSelect() {
    XCTAssertFalse(UseSmileIDSampleVerificationsState(jobs: []).offersSelect)
  }

  func testAListStillLoadingOffersNothingToSelect() {
    XCTAssertFalse(UseSmileIDSampleVerificationsState(jobs: nil).offersSelect)
  }

  func testAListWithRowsOffersSelect() {
    XCTAssertTrue(UseSmileIDSampleVerificationsState(jobs: jobs).offersSelect)
  }

  func testSelectModeKeepsCancelEvenOnceTheListEmpties() {
    XCTAssertTrue(UseSmileIDSampleVerificationsState(jobs: [], selectMode: true).offersSelect)
  }
}
