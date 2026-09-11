import Foundation
import ObjectiveC

/// Makes every session built from a stock configuration visible to the loupe.
///
/// `URLProtocol.registerClass` reaches `URLSession.shared` and `NSURLConnection` and nothing else:
/// a session created from a configuration consults that configuration's `protocolClasses`, never
/// the global registry. The SDK builds its own session, so without this the one traffic worth
/// watching is the traffic the loupe cannot see.
///
/// Swizzling the two factory getters is how netfox reached it, and there is no API that does the
/// same job — the configuration is created inside the SDK, where nothing can hand it over.
/// Debug builds only, installed once.
@MainActor
enum LoupeSessionInstrumentation {
  private static var isInstalled = false

  /// Swaps the two stock configuration getters for ones that add the protocol before returning.
  static func install() {
    guard !isInstalled else {
      return
    }
    isInstalled = true
    exchange(NSSelectorFromString("defaultSessionConfiguration"), #selector(URLSessionConfiguration.loupeDefault))
    exchange(NSSelectorFromString("ephemeralSessionConfiguration"), #selector(URLSessionConfiguration.loupeEphemeral))
  }

  private static func exchange(_ original: Selector, _ replacement: Selector) {
    guard let lhs = class_getClassMethod(URLSessionConfiguration.self, original),
          let rhs = class_getClassMethod(URLSessionConfiguration.self, replacement) else {
      return
    }
    method_exchangeImplementations(lhs, rhs)
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
