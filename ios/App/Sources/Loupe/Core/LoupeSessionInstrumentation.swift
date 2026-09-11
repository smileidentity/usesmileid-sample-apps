import Foundation
import ObjectiveC

/// Makes every session built from a stock configuration visible to the loupe.
///
/// `URLProtocol.registerClass` reaches `URLSession.shared` and `NSURLConnection` and nothing else:
/// a session created from a configuration consults that configuration's `protocolClasses`, never
/// the global registry. The SDK builds its own session, so without this the one traffic worth
/// watching is the traffic the loupe cannot see.
///
/// Swizzling is how netfox reached it, and there is no API that does the same job — the session is
/// created inside the SDK, where nothing can hand it over. Debug builds only, installed once.
@MainActor
enum LoupeSessionInstrumentation {
  private static var isInstalled = false

  /// Swaps the two stock configuration getters for ones that add the protocol before returning.
  static func install() {
    guard !isInstalled else {
      return
    }
    isInstalled = true
    exchange(URLSessionConfiguration.self, NSSelectorFromString("defaultSessionConfiguration"), #selector(URLSessionConfiguration.loupeDefault))
    exchange(URLSessionConfiguration.self, NSSelectorFromString("ephemeralSessionConfiguration"), #selector(URLSessionConfiguration.loupeEphemeral))
    // The one that actually guarantees coverage: a configuration can be obtained in ways the two
    // factories above never see — `URLSessionConfiguration()` among them — but every session is
    // built from one of these, and the configuration is copied at that moment
    exchange(URLSession.self, NSSelectorFromString("sessionWithConfiguration:"), #selector(URLSession.loupeSession(configuration:)))
    exchange(
      URLSession.self,
      NSSelectorFromString("sessionWithConfiguration:delegate:delegateQueue:"),
      #selector(URLSession.loupeSession(configuration:delegate:delegateQueue:))
    )
  }

  private static func exchange(_ owner: AnyClass, _ original: Selector, _ replacement: Selector) {
    guard let lhs = class_getClassMethod(owner, original),
          let rhs = class_getClassMethod(owner, replacement) else {
      return
    }
    method_exchangeImplementations(lhs, rhs)
  }
}

extension URLSession {
  /// The stock session factory, with the loupe's protocol added to the configuration first.
  @objc class func loupeSession(configuration: URLSessionConfiguration) -> URLSession {
    Loupe.instrument(configuration)
    return loupeSession(configuration: configuration)
  }

  @objc class func loupeSession(
    configuration: URLSessionConfiguration,
    delegate: URLSessionDelegate?,
    delegateQueue: OperationQueue?
  ) -> URLSession {
    // Not for the loupe's own replay session, which would then hand its own traffic back to itself
    if !(delegate is LoupeURLProtocol) {
      Loupe.instrument(configuration)
    }
    return loupeSession(configuration: configuration, delegate: delegate, delegateQueue: delegateQueue)
  }
}

extension URLSessionConfiguration {
  /// The stock `default`, with the loupe's protocol first. Recursive in appearance only: after the
  /// exchange this selector holds the original implementation.
  @objc class func loupeDefault() -> URLSessionConfiguration {
    let configuration = loupeDefault()
    Loupe.instrument(configuration)
    return configuration
  }

  @objc class func loupeEphemeral() -> URLSessionConfiguration {
    let configuration = loupeEphemeral()
    Loupe.instrument(configuration)
    return configuration
  }
}
