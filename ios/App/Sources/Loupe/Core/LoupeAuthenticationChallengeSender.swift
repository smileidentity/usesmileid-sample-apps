import Foundation

/// Carries a challenge decision back to the session that raised it.
///
/// `URLProtocolClient` hands the app a challenge and expects a sender to answer; the session that
/// raised it expects a completion handler. This is the adapter between the two, without which an
/// authenticating host cannot complete a handshake through the protocol.
final class LoupeAuthenticationChallengeSender: NSObject, URLAuthenticationChallengeSender {
  private let handler: (URLSession.AuthChallengeDisposition, URLCredential?) -> Void

  init(handler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
    self.handler = handler
  }

  func use(_ credential: URLCredential, for _: URLAuthenticationChallenge) {
    handler(.useCredential, credential)
  }

  func continueWithoutCredential(for _: URLAuthenticationChallenge) {
    handler(.useCredential, nil)
  }

  func cancel(_: URLAuthenticationChallenge) {
    handler(.cancelAuthenticationChallenge, nil)
  }

  func performDefaultHandling(for _: URLAuthenticationChallenge) {
    handler(.performDefaultHandling, nil)
  }

  func rejectProtectionSpaceAndContinue(with _: URLAuthenticationChallenge) {
    handler(.rejectProtectionSpace, nil)
  }
}
