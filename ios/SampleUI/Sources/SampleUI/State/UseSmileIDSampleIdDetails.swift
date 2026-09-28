import Foundation

/// The ID-details form, holding whole rows because a flow rebuilt from it has no catalogue to resolve a code.
public struct UseSmileIDSampleIdDetails: Equatable, Sendable {
  public var country: UseSmileIDSampleCountry?
  public var idType: UseSmileIDSampleKycIdType?
  public var document: UseSmileIDSampleDocument?
  public var captureAs: UseSmileIDSampleCaptureAs
  public var custom: UseSmileIDSampleCustomDocument
  public var idNumber: String

  public init(
    country: UseSmileIDSampleCountry? = nil,
    idType: UseSmileIDSampleKycIdType? = nil,
    document: UseSmileIDSampleDocument? = nil,
    captureAs: UseSmileIDSampleCaptureAs = .automatic,
    custom: UseSmileIDSampleCustomDocument = UseSmileIDSampleCustomDocument(),
    idNumber: String = ""
  ) {
    self.country = country
    self.idType = idType
    self.document = document
    self.captureAs = captureAs
    self.custom = custom
    self.idNumber = idNumber
  }

  /// Whether Continue can enable for `family`: every field it shows is set, and the number fits its type.
  public func isComplete(_ family: UseSmileIDSampleCatalogueFamily) -> Bool {
    switch family {
    case .document:
      return country != nil && document != nil
    case .kyc:
      guard country != nil, let idType else { return false }
      return UseSmileIDSampleIdNumberHint.accepts(idType.regex, idNumber)
    }
  }
}

/// A country from the Smile ID API; the flag is derived from the ISO code, so no table is needed.
public struct UseSmileIDSampleCountry: Hashable, Sendable {
  public let code: String
  public let name: String

  public init(code: String, name: String) {
    self.code = code
    self.name = name
  }

  /// Two regional-indicator letters, which every platform renders as the country's flag.
  public var flag: String {
    let letters = code.uppercased().unicodeScalars
    guard letters.count == 2, letters.allSatisfy({ ("A"..."Z").contains($0) }) else { return "\u{1F30D}" }
    return String(String.UnicodeScalarView(letters.compactMap { Unicode.Scalar(0x1f1e6 + $0.value - 65) }))
  }
}

/// A KYC ID type from `supported_id_types`; `id` is `type` with `_2`, `_3` on a repeat (spec/catalogue-rules.json).
public struct UseSmileIDSampleKycIdType: Hashable, Sendable {
  public let id: String
  public let type: String
  public let label: String
  public let regex: String

  public init(id: String, type: String, label: String, regex: String) {
    self.id = id
    self.type = type
    self.label = label
    self.regex = regex
  }
}

/// A document from `supported_documents`; a standalone sub-type row carries `subType` and submits the parent `code`.
public struct UseSmileIDSampleDocument: Hashable, Sendable {
  public let code: String
  public let subType: String?
  public let name: String
  public let hasBack: Bool
  public let format: Int

  public init(code: String, subType: String? = nil, name: String, hasBack: Bool, format: Int) {
    self.code = code
    self.subType = subType
    self.name = name
    self.hasBack = hasBack
    self.format = format
  }

  public var id: String {
    subType.map { "\(code)_\($0)" } ?? code
  }
}

/// How the SDK photographs the chosen document; never what the server receives.
public enum UseSmileIDSampleCaptureAs: String, CaseIterable, Sendable {
  case automatic, greenBook, passport, custom

  public var label: String {
    switch self {
    case .automatic: "Automatic"
    case .greenBook: "Green Book preset"
    case .passport: "Passport preset"
    case .custom: "Custom"
    }
  }
}

public enum UseSmileIDSampleDocumentOrientation: String, CaseIterable, Sendable {
  case landscape, portrait

  public var label: String {
    self == .landscape ? "Landscape" : "Portrait"
  }
}

/// The custom frame ratios the sheet offers, as width over height.
public enum UseSmileIDSampleAspectRatio: String, CaseIterable, Sendable {
  case off, card, passport, booklet

  public var ratio: Float? {
    switch self {
    case .off: nil
    case .card: 1.586
    case .passport: 1.309
    case .booklet: 0.748
    }
  }

  public var label: String {
    switch self {
    case .off: "Off"
    case .card: "Card 1.586"
    case .passport: "Passport 1.309"
    case .booklet: "Booklet 0.748"
    }
  }
}

/// What the custom-document sheet builds into a generic document.
public struct UseSmileIDSampleCustomDocument: Equatable, Sendable {
  public var displayName: String
  public var hasBackSide: Bool
  public var orientation: UseSmileIDSampleDocumentOrientation
  public var aspectRatio: UseSmileIDSampleAspectRatio

  public init(
    displayName: String = "Document",
    hasBackSide: Bool = true,
    orientation: UseSmileIDSampleDocumentOrientation = .landscape,
    aspectRatio: UseSmileIDSampleAspectRatio = .off
  ) {
    self.displayName = displayName
    self.hasBackSide = hasBackSide
    self.orientation = orientation
    self.aspectRatio = aspectRatio
  }
}

extension String {
  /// An empty query matches everything: `localizedCaseInsensitiveContains("")` is false where Kotlin's is true.
  func matches(_ query: String) -> Bool {
    query.isBlank || localizedCaseInsensitiveContains(query.trimmingCharacters(in: .whitespaces))
  }
}
