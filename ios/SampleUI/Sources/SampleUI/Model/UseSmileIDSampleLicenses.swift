import Foundation

/// The generated third-party notices, as the screen renders them.
public struct UseSmileIDSampleLicenses: Equatable {
  public let components: [UseSmileIDSampleNotice]

  public init(components: [UseSmileIDSampleNotice] = []) {
    self.components = components
  }

  public var isEmpty: Bool {
    components.isEmpty
  }
}

/// One component a partner ships, and what it is licensed under.
///
/// The text is the component's own, holder line included, so it belongs to the notice rather than
/// to a table keyed by licence: two MIT components carry two different copyright holders.
public struct UseSmileIDSampleNotice: Equatable, Decodable {
  public let component: String
  public let version: String
  public let licenseId: String
  public let licenseName: String
  /// Nil when the licence is known but its text ships inside the component instead of with us.
  public let text: String?
  /// Set only alongside a nil text: the page that carries the licence we cannot ship.
  public let url: String?

  public init(
    component: String,
    version: String,
    licenseId: String,
    licenseName: String,
    text: String?,
    url: String? = nil
  ) {
    self.component = component
    self.version = version
    self.licenseId = licenseId
    self.licenseName = licenseName
    self.text = text
    self.url = url
  }

  /// The version where there is one; a vendored notice inside another component carries none.
  public var subtitle: String {
    version.isEmpty ? licenseName : "\(version) · \(licenseName)"
  }
}

extension UseSmileIDSampleLicenses {
  /// Reads the generated notices out of the library bundle; an absent or unreadable asset is the
  /// empty state rather than a crash, because it means the build did not ship them.
  public static func bundled() -> UseSmileIDSampleLicenses {
    // `.module` is internal, so it cannot be this public method's default argument.
    bundled(in: .module)
  }

  static func bundled(in bundle: Bundle) -> UseSmileIDSampleLicenses {
    guard let url = bundle.url(forResource: "licenses", withExtension: "json"),
          let data = try? Data(contentsOf: url)
    else {
      return UseSmileIDSampleLicenses()
    }
    return decode(data)
  }

  static func decode(_ data: Data) -> UseSmileIDSampleLicenses {
    guard let asset = try? JSONDecoder().decode(Asset.self, from: data) else {
      return UseSmileIDSampleLicenses()
    }
    return UseSmileIDSampleLicenses(components: asset.components)
  }

  private struct Asset: Decodable {
    let components: [UseSmileIDSampleNotice]
  }
}
