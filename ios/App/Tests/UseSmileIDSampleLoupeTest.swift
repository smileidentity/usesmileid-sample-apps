@testable import UseSmileIDSample
import XCTest

final class UseSmileIDSampleLoupeTest: XCTestCase {
  func testAStructuredJsonSuffixIsStillJson() {
    XCTAssertEqual(LoupeBodyKind(contentType: "application/json"), .json)
    XCTAssertEqual(LoupeBodyKind(contentType: "application/vnd.smileid.v1+json"), .json)
    XCTAssertEqual(LoupeBodyKind(contentType: "application/json; charset=utf-8"), .json)
  }

  func testTheKindIsReadCaseInsensitivelyAndFallsBackToOther() {
    XCTAssertEqual(LoupeBodyKind(contentType: "TEXT/HTML"), .html)
    XCTAssertEqual(LoupeBodyKind(contentType: "image/png"), .image)
    XCTAssertEqual(LoupeBodyKind(contentType: "application/octet-stream"), .other)
    XCTAssertEqual(LoupeBodyKind(contentType: ""), .other)
  }

  func testCurlQuotesAValueContainingAQuoteSoItStillRuns() {
    let record = Self.record(
      headers: ["Authorization": "Bearer it's-a-token"],
      body: Data(#"{"note":"don't"}"#.utf8)
    )
    let curl = record.curl
    XCTAssertTrue(curl.contains(#"'Authorization: Bearer it'\''s-a-token'"#), curl)
    XCTAssertTrue(curl.contains(#"'{"note":"don'\''t"}'"#), curl)
  }

  func testCurlNamesTheMethodAndUrl() {
    let curl = Self.record().curl
    XCTAssertTrue(curl.hasPrefix("curl -X POST 'https://api.example.com/v1/jobs?page=2'"), curl)
  }

  func testAJsonBodyIsRenderedIndentedAndAMalformedOneFallsBackToItsText() {
    let indented = LoupeRecord.displayBody(Data(#"{"a":1}"#.utf8), kind: .json)
    XCTAssertEqual(indented?.contains("\n"), true, "expected re-indented JSON, got \(indented ?? "nil")")

    let malformed = LoupeRecord.displayBody(Data("{not json".utf8), kind: .json)
    XCTAssertEqual(malformed, "{not json")
  }

  func testAnEmptyBodyRendersAsNothingRatherThanAnEmptyString() {
    XCTAssertNil(LoupeRecord.displayBody(nil, kind: .json))
    XCTAssertNil(LoupeRecord.displayBody(Data(), kind: .json))
  }

  func testThePathCarriesTheQueryBecauseThatIsWhatNamesACall() {
    XCTAssertEqual(Self.record().path, "/v1/jobs?page=2")
  }

  func testAnExchangeStillOpenReportsNoDuration() {
    XCTAssertNil(Self.record(responseDate: nil).duration)
    XCTAssertNotNil(Self.record().duration)
  }

  func testNothingIsRecordedUntilRecordingStarts() {
    var configuration = LoupeConfiguration()
    XCTAssertFalse(configuration.shouldRecord(URLRequest(url: Self.url)))

    configuration.isRecording = true
    XCTAssertTrue(configuration.shouldRecord(URLRequest(url: Self.url)))
  }

  func testANonHttpSchemeIsLeftAloneSoTheProtocolCannotBreakIt() throws {
    var configuration = LoupeConfiguration()
    configuration.isRecording = true
    XCTAssertFalse(try configuration.shouldRecord(URLRequest(url: XCTUnwrap(URL(string: "ws://example.com")))))
    XCTAssertFalse(try configuration.shouldRecord(URLRequest(url: XCTUnwrap(URL(string: "file:///tmp/a")))))
  }

  func testAnIgnoredPrefixIsNotRecordedAndAnEmptyPrefixIgnoresNothing() throws {
    var configuration = LoupeConfiguration()
    configuration.isRecording = true
    configuration.ignoredURLPrefixes = ["https://api.example.com/v1/health"]
    XCTAssertTrue(configuration.shouldRecord(URLRequest(url: Self.url)))
    let health = try XCTUnwrap(URL(string: "https://api.example.com/v1/health"))
    XCTAssertFalse(configuration.shouldRecord(URLRequest(url: health)))

    configuration.ignoredURLPrefixes = [""]
    XCTAssertTrue(configuration.shouldRecord(URLRequest(url: Self.url)))
  }

  @MainActor
  func testTheNewestRecordIsFirstAndTheOldestFallsOffTheCap() {
    let store = LoupeStore(limit: 2)
    store.upsert(Self.record(path: "/first"))
    store.upsert(Self.record(path: "/second"))
    store.upsert(Self.record(path: "/third"))

    XCTAssertEqual(store.records.count, 2)
    XCTAssertEqual(store.records.map(\.path), ["/third", "/second"])
  }

  @MainActor
  func testSearchMatchesTheUrlAndTheKindFilterNarrowsIt() {
    let store = LoupeStore()
    store.upsert(Self.record(path: "/jobs", kind: .json))
    store.upsert(Self.record(path: "/avatar.png", kind: .image))

    store.searchText = "avatar"
    XCTAssertEqual(store.visibleRecords.map(\.path), ["/avatar.png"])

    store.searchText = ""
    store.toggle(.image)
    XCTAssertEqual(store.visibleRecords.map(\.path), ["/jobs"])
  }

  @MainActor
  func testTheLastKindCannotBeTurnedOffBecauseAnEmptyListReadsAsBroken() {
    let store = LoupeStore()
    for kind in LoupeBodyKind.allCases {
      store.toggle(kind)
    }

    XCTAssertEqual(store.visibleKinds.count, 1)
  }

  @MainActor
  func testClearingLeavesTheFilterAlone() {
    let store = LoupeStore()
    store.upsert(Self.record())
    store.toggle(.image)

    store.clear()

    XCTAssertTrue(store.records.isEmpty)
    XCTAssertFalse(store.visibleKinds.contains(.image))
  }

  @MainActor
  func testACompletionReplacesTheRequestItFinishesRatherThanAddingASecondRow() {
    let store = LoupeStore()
    let id = UUID()
    store.upsert(Self.record(id: id, responseDate: nil, status: nil))
    XCTAssertEqual(store.inFlightCount, 1)

    store.upsert(Self.record(id: id, status: 200))

    XCTAssertEqual(store.records.count, 1)
    XCTAssertEqual(store.inFlightCount, 0)
  }

  @MainActor
  func testAHungRequestIsCountedInFlightAndNotAsAFailure() {
    let store = LoupeStore()
    store.upsert(Self.record(responseDate: nil, status: nil))

    XCTAssertEqual(store.inFlightCount, 1)
    XCTAssertEqual(store.failureCount, 0)
  }

  @MainActor
  func testAFailureIsAnyNon2xxOrATransportError() {
    let store = LoupeStore()
    store.upsert(Self.record(path: "/a", status: 500))
    store.upsert(Self.record(path: "/b", status: nil, error: "lost connection"))
    store.upsert(Self.record(path: "/c", status: 201))

    XCTAssertEqual(store.failureCount, 2)
  }

  @MainActor
  func testClearingRestartsTheWindowSoAnExportCoversOnlyTheRepro() {
    let store = LoupeStore()
    store.upsert(Self.record())
    let opened = store.recordingSince

    store.clear()

    XCTAssertTrue(store.recordingSince > opened)
  }

  func testTheReportLeadsWithContextThenTheTraffic() {
    let text = LoupeReport.text(records: [Self.record(status: 200)], since: Date())

    XCTAssertTrue(text.hasPrefix("# Network report"), text)
    XCTAssertTrue(text.contains("Requests: 1 — 1 ok, 0 failed"), text)
    XCTAssertTrue(text.contains("curl -X POST"), text)
  }

  /// The record is taken before the request is forwarded, so reading the stream here would empty
  /// the body out of the very request being observed.
  func testAStreamedRequestBodyIsLeftUnreadSoTheRequestStillCarriesIt() {
    let payload = Data(#"{"selfie":"..."}"#.utf8)
    var request = URLRequest(url: Self.url)
    request.httpMethod = "POST"
    request.httpBodyStream = InputStream(data: payload)

    let captured = LoupeURLProtocol.bodyForTesting(request)

    XCTAssertNil(captured.data, "a streamed body must not be read")
    XCTAssertTrue(captured.streamed)
    // The stream is still unopened, so the loading system can still send it
    XCTAssertEqual(request.httpBodyStream?.streamStatus, .notOpen)
  }

  func testAPlainRequestBodyIsCapturedBecauseReadingItCostsNothing() {
    var request = URLRequest(url: Self.url)
    request.httpBody = Data("hello".utf8)

    let captured = LoupeURLProtocol.bodyForTesting(request)

    XCTAssertEqual(captured.data, Data("hello".utf8))
    XCTAssertFalse(captured.streamed)
  }

  /// Registration reaches only `URLSession.shared`; a session built from a configuration reads
  /// that configuration, which is how the SDK's traffic went unseen.
  @MainActor
  func testAStockConfigurationCarriesTheProtocolOnceInstrumentationIsInstalled() {
    LoupeSessionInstrumentation.install()

    let classes = URLSessionConfiguration.default.protocolClasses ?? []

    XCTAssertEqual(classes.first == LoupeURLProtocol.self, true, "the protocol must be offered first")
  }

  @MainActor
  func testInstrumentingTwiceDoesNotStackTheProtocol() {
    let configuration = URLSessionConfiguration.default
    Loupe.instrument(configuration)
    Loupe.instrument(configuration)

    let matches = (configuration.protocolClasses ?? []).filter { $0 == LoupeURLProtocol.self }
    XCTAssertEqual(matches.count, 1)
  }

  func testACredentialHeaderKeepsFiveCharactersAndNoMore() {
    XCTAssertEqual(LoupeRedaction.mask("abcdefghijklmnop"), "abcde*****")
    XCTAssertEqual(LoupeRedaction.mask("abcdefghijklmnop").count, 10)
  }

  /// Revealing a short secret whole would defeat the masking entirely.
  func testAShortValueIsMaskedWholeRatherThanRevealed() {
    XCTAssertEqual(LoupeRedaction.mask("abc"), "*****")
    XCTAssertEqual(LoupeRedaction.mask("abcde"), "*****")
  }

  func testTheTokenAndItsSiblingsAreMaskedWhateverTheHeaderCase() {
    let masked = LoupeRedaction.headers([
      "smileid-token": "eyJhbGciOiJIUzI1NiJ9.payload",
      "SmileID-Api-Key": "0123456789abcdef",
      "smileid-request-mac": "deadbeefcafe",
      "Authorization": "Bearer sk_live_abcdefgh"
    ])

    XCTAssertEqual(masked["smileid-token"], "eyJhb*****")
    XCTAssertEqual(masked["SmileID-Api-Key"], "01234*****")
    XCTAssertEqual(masked["smileid-request-mac"], "deadb*****")
    XCTAssertEqual(masked["Authorization"], "Beare*****")
  }

  /// Masking what merely identifies the caller would cost the debugging these headers exist for.
  func testHeadersThatIdentifyRatherThanAuthenticateAreLeftAlone() {
    let masked = LoupeRedaction.headers([
      "smileid-partner-id": "0001",
      "smileid-source-sdk": "ios",
      "Content-Type": "application/json"
    ])

    XCTAssertEqual(masked["smileid-partner-id"], "0001")
    XCTAssertEqual(masked["smileid-source-sdk"], "ios")
    XCTAssertEqual(masked["Content-Type"], "application/json")
  }

  /// The auth response carries the token in its body, so headers alone would leave it in clear on
  /// the one call that mints it.
  func testATokenInAJsonBodyIsMaskedAtAnyDepth() throws {
    let body = Data(#"{"data":{"token":"eyJhbGciOiJIUzI1NiJ9","expires":"2026"},"ok":true}"#.utf8)

    let masked = try XCTUnwrap(LoupeRedaction.body(body))
    let text = try XCTUnwrap(String(data: masked, encoding: .utf8))

    XCTAssertTrue(text.contains("eyJhb*****"), text)
    XCTAssertFalse(text.contains("eyJhbGciOiJIUzI1NiJ9"), text)
    XCTAssertTrue(text.contains("2026"), "everything else must survive")
  }

  func testABodyThatIsNotJsonIsLeftExactlyAsItCame() {
    let body = Data("not json at all".utf8)

    XCTAssertEqual(LoupeRedaction.body(body), body)
  }

  func testStatisticsCountA2xxAsSuccessAndEverythingElseAsFailure() {
    let statistics = LoupeStatistics(records: [
      Self.record(status: 200),
      Self.record(status: 204),
      Self.record(status: 404),
      Self.record(status: nil, error: "lost connection")
    ])

    XCTAssertEqual(statistics.total, 4)
    XCTAssertEqual(statistics.successes, 2)
    XCTAssertEqual(statistics.failures, 2)
  }

  func testStatisticsSumAndAverageTheBodySizes() {
    let statistics = LoupeStatistics(records: [
      Self.record(body: Data(count: 100), responseBody: Data(count: 400)),
      Self.record(body: Data(count: 300), responseBody: Data(count: 600))
    ])

    XCTAssertEqual(statistics.requestBytes, 400)
    XCTAssertEqual(statistics.averageRequestBytes, 200)
    XCTAssertEqual(statistics.responseBytes, 1000)
    XCTAssertEqual(statistics.averageResponseBytes, 500)
  }

  func testStatisticsReportTheFastestAndSlowestExchange() {
    let statistics = LoupeStatistics(records: [
      Self.record(seconds: 3),
      Self.record(seconds: 1),
      Self.record(seconds: 2)
    ])

    XCTAssertEqual(statistics.fastest, .seconds(1))
    XCTAssertEqual(statistics.slowest, .seconds(3))
    XCTAssertEqual(statistics.averageDuration, .seconds(2))
  }

  func testStatisticsOverNothingReportNoTimingRatherThanZero() {
    let statistics = LoupeStatistics(records: [])

    XCTAssertEqual(statistics.total, 0)
    XCTAssertNil(statistics.averageDuration)
    XCTAssertNil(statistics.fastest)
    XCTAssertEqual(statistics.averageRequestBytes, 0)
  }

  func testAnExchangeStillOpenIsCountedButNotTimed() {
    let statistics = LoupeStatistics(records: [Self.record(responseDate: nil, status: nil)])

    XCTAssertEqual(statistics.total, 1)
    XCTAssertNil(statistics.fastest)
  }

  func testAnExportLeadsWithTheCurlAndCarriesTheResponse() {
    let text = LoupeExport.text(for: Self.record(status: 201))

    XCTAssertTrue(text.hasPrefix("curl -X POST"), text)
    XCTAssertTrue(text.contains("Status: 201"), text)
  }

  func testASessionExportReadsOldestFirstBecauseTheStoreIsNewestFirst() throws {
    let text = LoupeExport.text(for: [Self.record(path: "/second"), Self.record(path: "/first")])

    let first = try? XCTUnwrap(text.range(of: "/first"))
    let second = try? XCTUnwrap(text.range(of: "/second"))
    XCTAssertNotNil(first)
    XCTAssertNotNil(second)
    XCTAssertTrue(try XCTUnwrap(first?.lowerBound) < second!.lowerBound, "expected /first before /second")
  }

  func testTheProtocolTellsTheClientNotToCacheWhatItForwards() {
    XCTAssertEqual(LoupeConfiguration().cacheStoragePolicy, .notAllowed)
  }

  private static let url = URL(string: "https://api.example.com/v1/jobs?page=2")!

  private static func record(
    id: UUID = UUID(),
    path: String? = nil,
    headers: [String: String] = [:],
    body: Data? = nil,
    responseBody: Data? = nil,
    responseDate: Date? = Date(timeIntervalSince1970: 1),
    seconds: Int = 1,
    status: Int? = 200,
    error: String? = nil,
    kind: LoupeBodyKind = .json
  ) -> LoupeRecord {
    LoupeRecord(
      id: id,
      method: "POST",
      url: path.map { URL(string: "https://api.example.com\($0)")! } ?? url,
      requestDate: Date(timeIntervalSince1970: 0),
      requestHeaders: headers,
      requestBody: body,
      responseDate: responseDate.map { _ in Date(timeIntervalSince1970: TimeInterval(seconds)) },
      statusCode: status,
      responseBody: responseBody,
      bodyKind: kind,
      errorDescription: error
    )
  }
}
