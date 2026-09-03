@testable import SampleUI
import XCTest

/// The decode rules, held against the SDK's own and against the same fixtures the Android twin pins.
/// The SDK's payload parsing is internal, so these cases are what stop this duplicate drifting from
/// the rules the SDK actually applies at `build()`.
final class UseSmileIDSampleTokenDecoderTest: XCTestCase {
  func testATokenIsThreeBase64UrlSegmentsOrItIsNotAToken() {
    for candidate in [
      "not-a-jwt", "two.segments", "four.of.these.segments", "header..signature",
      "header.pay load.signature", "header.payload+slash.signature"
    ] {
      XCTAssertNotNil(decode(candidate).rejection, "\(candidate) should be rejected")
    }
  }

  func testSurroundingWhitespaceIsTrimmedRatherThanRejected() {
    XCTAssertNotNil(session("  \(token())\n"), "a pasted token with whitespace should decode")
  }

  func testAPayloadSegmentThatIsNotBase64UrlJsonIsRejected() {
    XCTAssertNotNil(decode("aGVhZGVy.@@@@.c2ln").rejection)
    XCTAssertNotNil(decode(jwt("[1,2,3]")).rejection)
    XCTAssertNotNil(decode(jwt("{\"exp\":")).rejection)
  }

  func testBothTimeClaimsAreRequiredAndExpMustBeAfterIat() {
    XCTAssertNotNil(decode(jwt(#"{"iat":\#(Self.iat)}"#)).rejection)
    XCTAssertNotNil(decode(jwt(#"{"exp":\#(Self.exp)}"#)).rejection)
    XCTAssertNotNil(decode(jwt(#"{"iat":\#(Self.exp),"exp":\#(Self.iat)}"#)).rejection)
    XCTAssertNotNil(decode(jwt(#"{"iat":\#(Self.iat),"exp":"\#(Self.exp)"}"#)).rejection)
  }

  func testARejectionNamesTheStructureThatFailedAndNeverTheToken() throws {
    let candidate = jwt(#"{"iat":\#(Self.iat)}"#)
    let reason = try XCTUnwrap(decode(candidate).rejection)
    XCTAssertTrue(reason.contains("exp"), "reason should name the claim: \(reason)")
    XCTAssertFalse(reason.contains(candidate.split(separator: ".")[1]), "reason must not carry the token")
  }

  func testEpochSecondsBecomeTheAbsoluteDeadline() throws {
    let session = try XCTUnwrap(session(token()))
    XCTAssertEqual(session.issuedAt, Date(timeIntervalSince1970: Self.iat))
    XCTAssertEqual(session.expiresAt, Date(timeIntervalSince1970: Self.exp))
  }

  func testTheHandleIsTheJtiWhenTheTokenCarriesOne() throws {
    let session = try XCTUnwrap(session(jwt(#"{"iat":\#(Self.iat),"exp":\#(Self.exp),\#(Self.sandboxUrl),"jti":"sess_7f2"}"#)))
    XCTAssertEqual(session.id, "sess_7f2")
  }

  func testWithoutAJtiTheHandleIsAShortDigestNeverAPrefixOfTheCredential() throws {
    let token = token()
    let session = try XCTUnwrap(session(token))
    XCTAssertNotNil(session.id.range(of: "^[0-9a-f]{8}$", options: .regularExpression), "handle should be short hex, was \(session.id)")
    XCTAssertFalse(token.hasPrefix(session.id))
    XCTAssertFalse(token.contains(session.id))
    XCTAssertEqual(session.id, self.session(token)?.id, "the same token must give the same handle")
  }

  func testDescriptionRedactsTheTokenBecauseThatIsHowACredentialReachesALog() throws {
    let session = try XCTUnwrap(session(token()))
    XCTAssertFalse("\(session)".contains(session.token))
    XCTAssertFalse(String(describing: session).contains(session.token))
  }

  func testEachKnownHostMapsToItsEnvironmentWhateverTheSchemePortPathOrCase() throws {
    let cases: [(String, UseSmileIDSampleEnvironment)] = [
      ("https://testapi.smileidentity.com/v3", .sandbox),
      ("https://testapi.smileidentity.com/", .sandbox),
      ("https://testapi.smileidentity.com", .sandbox),
      ("HTTPS://TestApi.SmileIdentity.COM/v3", .sandbox),
      // The SDK's constant carries the trailing slash a real claim does not; both must land.
      ("https://api.smileidentity.com/", .production),
      ("https://api.smileidentity.com/v3", .production),
      ("http://api.smileidentity.com/v3", .production),
      ("https://api.smileidentity.com:443/v3", .production)
    ]
    for (url, expected) in cases {
      let session = try XCTUnwrap(session(tokenWithApiUrl(#""api_url":"\#(url)""#)), "\(url) did not decode")
      XCTAssertEqual(session.environment, expected, url)
    }
  }

  func testAnUnrecognisedHostIsRefusedRatherThanFallingBackAndTheRejectionNamesIt() throws {
    let reason = try rejection(tokenWithApiUrl(#""api_url":"https://api.smileidentity.com.evil.test/v3""#))
    XCTAssertTrue(reason.contains("api.smileidentity.com.evil.test"), "the rejection should name the host it saw: \(reason)")
  }

  func testAHostThatOnlyLooksLikeOneOfOursIsNotOneOfOurs() {
    for url in [
      "https://smileidentity.com/v3", "https://api.smileidentity.com.br/v3", "https://testapi.smileidentity.co/v3",
      // No authority, so there is no host to match.
      "testapi.smileidentity.com/v3"
    ] {
      XCTAssertNotNil(decode(tokenWithApiUrl(#""api_url":"\#(url)""#)).rejection, "\(url) should be refused")
    }
  }

  func testAMalformedApiUrlIsRefusedAndSaysSoWithoutPretendingToNameAHost() throws {
    let reason = try rejection(tokenWithApiUrl(#""api_url":"not a url at all""#))
    XCTAssertTrue(reason.contains("not a URL"), "reason should say it is not a URL: \(reason)")
  }

  func testAnAbsentBlankOrNonStringApiUrlRefusesTheToken() throws {
    for claim in [#""jti":"sess_7f2""#, #""api_url":"""#, #""api_url":"  ""#, #""api_url":42"#] {
      let reason = try rejection(tokenWithApiUrl(claim))
      XCTAssertTrue(reason.contains("api_url"), "\(claim) should be refused for the claim: \(reason)")
    }
  }

  func testTheRedactedDescriptionReportsTheEnvironmentAsAValueBecauseAHostIsPublic() throws {
    let session = try XCTUnwrap(session(token()))
    XCTAssertTrue("\(session)".contains("Sandbox"))
  }

  func testAFieldBindsOnlyWhenTheClaimCarriesItAsANonEmptyString() throws {
    let bindings = try bindings(#""given_names":"vault_given_names","last_name":"","email":42,"phone_number":null"#)
    XCTAssertTrue(bindings.givenNames)
    XCTAssertFalse(bindings.lastName, "an empty string is not a binding")
    XCTAssertFalse(bindings.email, "a number is not a binding")
    XCTAssertFalse(bindings.phoneNumber, "null is not a binding")
  }

  func testAnObjectOrArrayInAUserDetailFieldIsNotABinding() throws {
    let bindings = try bindings(#""given_names":{"vault":"x"},"last_name":["x"]"#)
    XCTAssertFalse(bindings.givenNames)
    XCTAssertFalse(bindings.lastName)
  }

  func testTheTwoPlaintextClaimsAndTheIdNumbersVaultReferenceAreAllRead() throws {
    let bindings = try bindings(#""country":"KE","id_type":"NATIONAL_ID","id_number":"pii_fixture01""#)
    XCTAssertEqual(bindings.country, "KE")
    XCTAssertEqual(bindings.idType, "NATIONAL_ID")
    XCTAssertEqual(bindings.idNumberReference, "pii_fixture01")
  }

  func testABlankValueClaimReadsAsAbsentUnlikeThePresenceFlags() throws {
    let bindings = try bindings(#""country":" ","id_type":"","id_number":"  ""#)
    XCTAssertNil(bindings.country)
    XCTAssertNil(bindings.idType)
    XCTAssertNil(bindings.idNumberReference)
  }

  func testTheKycProductsNeedCountryIdTypeAndTheIdNumberReferenceBeforeTheirFormIsSkipped() {
    let bound = UseSmileIDSampleTokenBindings(country: "KE", idType: "NATIONAL_ID", idNumberReference: "pii_1")
    for product in [UseSmileIDSampleProduct.enhancedKyc, .biometricKyc] {
      XCTAssertTrue(bound.bindsIdDetails(product))
      XCTAssertFalse(bound.removing(\.idNumberReference).bindsIdDetails(product))
      XCTAssertFalse(bound.removing(\.idType).bindsIdDetails(product))
      XCTAssertFalse(bound.removing(\.country).bindsIdDetails(product))
    }
  }

  func testBothDocumentProductsNeedCountryAndIdTypeAndNeitherNeedsAnIdNumber() {
    let bound = UseSmileIDSampleTokenBindings(country: "KE", idType: "NATIONAL_ID")
    for product in [UseSmileIDSampleProduct.documentVerification, .enhancedDocumentVerification] {
      XCTAssertTrue(bound.bindsIdDetails(product))
      // Document Verification's own validator accepts a nil ID type, but the form is where the
      // document type is chosen — so a partial binding must still go through it.
      XCTAssertFalse(bound.removing(\.idType).bindsIdDetails(product))
      XCTAssertFalse(bound.removing(\.country).bindsIdDetails(product))
    }
  }

  func testAProductThatSubmitsNoIdParametersIsNeverSentToTheForm() {
    for product in [UseSmileIDSampleProduct.smartSelfieEnrollment, .smartSelfieAuth] {
      XCTAssertTrue(UseSmileIDSampleTokenBindings().bindsIdDetails(product))
    }
  }

  func testTheBindingsDescriptionReportsPresenceBecauseAVaultReferenceIsStillAClaimValue() throws {
    let text = try "\(bindings(#""country":"KE","id_type":"NATIONAL_ID","id_number":"pii_fixture01""#))"
    for value in ["KE", "NATIONAL_ID", "pii_fixture01"] {
      XCTAssertFalse(text.contains(value), "description must not carry \(value)")
    }
  }

  func testAnAbsentOrEmptyConsentObjectIsNoConsentBinding() throws {
    XCTAssertNil(try bindings(#""email":"vault_email""#).consent)
    XCTAssertNil(try bindings(#""consent":{}"#).consent)
    XCTAssertNil(try bindings(#""consent":[]"#).consent)
    XCTAssertNil(try bindings(#""consent":"granted""#).consent)
  }

  func testGrantedFalseOrNonBooleanNeverCountsTowardAConsentBinding() throws {
    for granted in ["false", #""true""#, "1", "null"] {
      let consent = try XCTUnwrap(bindings(#""consent":{"granted":\#(granted),"granted_at":"\#(Self.grantedAt)"}"#).consent)
      XCTAssertNil(consent.granted, "granted:\(granted) should read as absent")
      XCTAssertFalse(consent.isComplete)
    }
  }

  func testConsentIsCompleteOnlyWithGrantedTrueAndAllThreeSubfieldsNonBlank() throws {
    XCTAssertTrue(try XCTUnwrap(bindings(Self.consent).consent).isComplete)
    XCTAssertFalse(try XCTUnwrap(bindings(consent(grantedAt: "")).consent).isComplete)
    XCTAssertFalse(try XCTUnwrap(bindings(consent(language: " ")).consent).isComplete)
    XCTAssertFalse(try XCTUnwrap(bindings(consent(policyUrl: nil)).consent).isComplete)
    XCTAssertFalse(try XCTUnwrap(bindings(consent(granted: "false")).consent).isComplete)
  }

  func testANonStringConsentSubfieldReadsAsAbsent() throws {
    let consent = try XCTUnwrap(bindings(#""consent":{"granted":true,"granted_at":1755500000}"#).consent)
    XCTAssertNil(consent.grantedAt)
    XCTAssertFalse(consent.isComplete)
  }

  func testRequiredUserDetailsAreBothNamesPlusOneContactField() {
    let names = UseSmileIDSampleTokenBindings(givenNames: true, lastName: true)
    XCTAssertFalse(names.bindsRequiredUserDetails, "names alone relax nothing")
    XCTAssertTrue(names.with(email: true).bindsRequiredUserDetails)
    XCTAssertTrue(names.with(phoneNumber: true).bindsRequiredUserDetails)
    XCTAssertFalse(names.with(givenNames: false).with(email: true).bindsRequiredUserDetails)
    XCTAssertFalse(UseSmileIDSampleTokenBindings(email: true, phoneNumber: true).bindsRequiredUserDetails)
  }

  /// The requirement the consent form reads, field for field: a bound name lifts its row and one bound contact lifts the pair.
  func testTheRequirementLiftsExactlyWhatTheTokenBinds() {
    XCTAssertEqual(UseSmileIDSampleUserDetailsRequirement(bindings: nil), .init(firstName: true, lastName: true, contact: true))
    XCTAssertEqual(
      UseSmileIDSampleUserDetailsRequirement(bindings: .init(givenNames: true, phoneNumber: true)),
      .init(firstName: false, lastName: true, contact: false)
    )
  }

  func testAPayloadClaimOfTheWrongShapeLeavesTheTokenUsableAndUnbound() throws {
    // The SDK degrades a malformed `payload` claim to strict validation rather than failing.
    let session = try XCTUnwrap(session(jwt(#"{"iat":\#(Self.iat),"exp":\#(Self.exp),\#(Self.sandboxUrl),"payload":"nonsense"}"#)))
    XCTAssertEqual(session.bindings, UseSmileIDSampleTokenBindings())
  }

  func testNestingPastTheReadersDepthCapIsRejectedRatherThanCrashing() {
    let deep = String(repeating: "[", count: 200) + String(repeating: "]", count: 200)
    XCTAssertNotNil(decode(jwt(#"{"iat":\#(Self.iat),"exp":\#(Self.exp),\#(Self.sandboxUrl),"payload":\#(deep)}"#)).rejection)
  }

  private func decode(_ token: String) -> UseSmileIDSampleTokenDecode {
    UseSmileIDSampleTokenDecoder.decode(token)
  }

  private func session(_ token: String) -> UseSmileIDSampleTokenSession? {
    UseSmileIDSampleTokenDecoder.session(token)
  }

  private func bindings(_ payloadFields: String) throws -> UseSmileIDSampleTokenBindings {
    try XCTUnwrap(session(jwt(#"{"iat":\#(Self.iat),"exp":\#(Self.exp),\#(Self.sandboxUrl),"payload":{\#(payloadFields)}}"#))).bindings
  }

  private func consent(
    granted: String = "true",
    grantedAt: String? = grantedAt,
    language: String? = "en",
    policyUrl: String? = "https://smile.id/privacy-policy"
  ) -> String {
    #""consent":{"granted":\#(granted),"granted_at":\#(quoted(grantedAt)),"#
      + #""notice_language":\#(quoted(language)),"notice_privacy_policy_url":\#(quoted(policyUrl))}"#
  }

  private func quoted(_ value: String?) -> String {
    value.map { "\"\($0)\"" } ?? "null"
  }

  private func token() -> String {
    jwt(#"{"iat":\#(Self.iat),"exp":\#(Self.exp),\#(Self.sandboxUrl)}"#)
  }

  private func tokenWithApiUrl(_ claim: String) -> String {
    jwt(#"{"iat":\#(Self.iat),"exp":\#(Self.exp),\#(claim)}"#)
  }

  private func rejection(_ token: String) throws -> String {
    try XCTUnwrap(decode(token).rejection)
  }

  private func jwt(_ claims: String) -> String {
    [Self.header, claims, "sample-signature"].map(Self.base64Url).joined(separator: ".")
  }

  private static func base64Url(_ value: String) -> String {
    Data(value.utf8).base64EncodedString()
      .replacingOccurrences(of: "+", with: "-")
      .replacingOccurrences(of: "/", with: "_")
      .replacingOccurrences(of: "=", with: "")
  }

  private static let iat: Double = 1755500000
  private static let exp: Double = 1755500900
  private static let grantedAt = "2026-08-18T09:00:00Z"
  private static let header = #"{"alg":"none","typ":"JWT"}"#
  private static let sandboxUrl = #""api_url":"https://testapi.smileidentity.com/v3""#
  private static let consent = #""consent":{"granted":true,"granted_at":"\#(grantedAt)","#
    + #""notice_language":"en","notice_privacy_policy_url":"https://smile.id/privacy-policy"}"#
}

/// Kotlin's `copy(field = …)`, for the cases that vary one field of a fixture.
private extension UseSmileIDSampleTokenBindings {
  func with(givenNames: Bool? = nil, email: Bool? = nil, phoneNumber: Bool? = nil) -> Self {
    var copy = self
    copy.givenNames = givenNames ?? self.givenNames
    copy.email = email ?? self.email
    copy.phoneNumber = phoneNumber ?? self.phoneNumber
    return copy
  }

  func removing(_ field: WritableKeyPath<Self, String?>) -> Self {
    var copy = self
    copy[keyPath: field] = nil
    return copy
  }
}
