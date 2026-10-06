import Foundation

/// The ID-details form, holding whole rows because a flow rebuilt from it has no catalogue to resolve a code.
public struct UseSmileIDSampleIdDetails: Equatable, Sendable {
  public var country: UseSmileIDSampleCountry?
  public var idType: UseSmileIDSampleKycIdType?
  public var document: UseSmileIDSampleDocument?
  /// Nil is Match document: the row decides, per `useSmileIDSampleResolvedCaptureAs`.
  public var captureAsOverride: UseSmileIDSampleCaptureAs?
  public var genericDocument: UseSmileIDSampleGenericDocument
  public var idNumber: String

  public init(
    country: UseSmileIDSampleCountry? = nil,
    idType: UseSmileIDSampleKycIdType? = nil,
    document: UseSmileIDSampleDocument? = nil,
    captureAsOverride: UseSmileIDSampleCaptureAs? = nil,
    genericDocument: UseSmileIDSampleGenericDocument = UseSmileIDSampleGenericDocument(),
    idNumber: String = ""
  ) {
    self.country = country
    self.idType = idType
    self.document = document
    self.captureAsOverride = captureAsOverride
    self.genericDocument = genericDocument
    self.idNumber = idNumber
  }

  /// What the SDK will be handed for this form.
  public var resolvedCaptureAs: UseSmileIDSampleResolvedCaptureAs {
    useSmileIDSampleResolvedCaptureAs(document: document, override: captureAsOverride, genericDocument: genericDocument)
  }

  /// A different country clears the ID type, document and override, which may not apply to it; the typed number stays.
  public mutating func choose(country: UseSmileIDSampleCountry) {
    guard country != self.country else { return }
    self.country = country
    idType = nil
    document = nil
    captureAsOverride = nil
  }

  /// A different document drops the override, which described one pairing.
  public mutating func choose(document: UseSmileIDSampleDocument) {
    if document.id != self.document?.id {
      captureAsOverride = nil
    }
    self.document = document
  }

  /// A relinked partner may not enable what was picked for the last one, so a pick its lists lack is dropped; a list still loading keeps it.
  public mutating func keepOnlyEnabled(countries: [UseSmileIDSampleCountry]?, documents: [UseSmileIDSampleDocument]?) {
    guard let country else { return }
    if let countries, !countries.contains(where: { $0.code == country.code }) {
      self.country = nil
      idType = nil
      document = nil
      captureAsOverride = nil
      return
    }
    if let document, let documents, !documents.contains(where: { $0.id == document.id }) {
      self.document = nil
      captureAsOverride = nil
    }
  }

  /// A link can open `product`'s form holding a row it does not list; the row and its override go.
  public mutating func keepDocumentListed(on product: UseSmileIDSampleProduct) {
    if document?.isListed(on: product) == false {
      document = nil
      captureAsOverride = nil
    }
  }

  /// Whether Continue can enable for `family`: every field it shows is set, and the number fits its type.
  public func isComplete(_ family: UseSmileIDSampleCatalogueFamily) -> Bool {
    switch family {
    case .document:
      return country != nil && document != nil
    case .passport:
      return country != nil
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

  /// Whether `product` lists this row: the SDK refuses the Green Book on Enhanced Document Verification.
  public func isListed(on product: UseSmileIDSampleProduct) -> Bool {
    !(product == .enhancedDocumentVerification && subType == useSmileIDSampleGreenBookSubType)
  }
}

/// How the SDK photographs the chosen document, each the SDK's own type; never what the server receives.
public enum UseSmileIDSampleCaptureAs: String, CaseIterable, Sendable {
  case genericDocument, greenBook, passport

  /// The sheet's first row, which clears the override so the document decides.
  public static let matchDocumentId = "matchDocument"
  public static var matchDocumentLabel: String {
    UseSmileIDSampleStrings.captureAsMatchDocument
  }

  public var label: String {
    switch self {
    case .greenBook: UseSmileIDSampleStrings.captureAsGreenBook
    case .passport: UseSmileIDSampleStrings.captureAsPassport
    case .genericDocument: UseSmileIDSampleStrings.captureAsGenericDocument
    }
  }
}

public enum UseSmileIDSampleDocumentOrientation: String, CaseIterable, Sendable {
  case landscape, portrait

  public var label: String {
    self == .landscape ? UseSmileIDSampleStrings.genericDocumentLandscape : UseSmileIDSampleStrings.genericDocumentPortrait
  }
}

/// The frame ratios the sheet offers, as width over height.
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
    case .off: UseSmileIDSampleStrings.genericDocumentRatioOff
    case .card: UseSmileIDSampleStrings.genericDocumentRatioCard
    case .passport: UseSmileIDSampleStrings.genericDocumentRatioPassport
    case .booklet: UseSmileIDSampleStrings.genericDocumentRatioBooklet
    }
  }
}

/// What the generic-document sheet builds, as the SDK's GenericDocument takes it.
public struct UseSmileIDSampleGenericDocument: Equatable, Sendable {
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

/// The type "Capture as" resolves to: a preset, or a GenericDocument built from `genericDocument`.
public struct UseSmileIDSampleResolvedCaptureAs: Equatable, Sendable {
  public let captureAs: UseSmileIDSampleCaptureAs
  public let genericDocument: UseSmileIDSampleGenericDocument
  /// Whether the document decided it, rather than an override.
  public let matched: Bool

  public var hasBackSide: Bool {
    switch captureAs {
    case .genericDocument: genericDocument.hasBackSide
    case .greenBook: false
    case .passport: true
    }
  }

  /// The SDK's captureBothSides default, which the app leaves unset: false for a passport.
  public var captureBothSides: Bool {
    captureAs != .passport
  }

  /// The trigger text from `spec/catalogue-rules.json` captureAs.
  public func triggerText() -> String {
    let sides = captureBothSides && hasBackSide ? UseSmileIDSampleStrings.captureAsFrontAndBack : UseSmileIDSampleStrings.captureAsFrontOnly
    let orientation = genericDocument.orientation.label.lowercased()
    if captureAs != .genericDocument {
      return matched ? UseSmileIDSampleStrings.captureAsMatches(captureAs: captureAs.label) : UseSmileIDSampleStrings.captureAsChosen(captureAs: captureAs.label)
    }
    return matched
      ? UseSmileIDSampleStrings.captureAsGenericSummary(captureAs: UseSmileIDSampleCaptureAs.genericDocument.label, orientation: orientation, sides: sides)
      : UseSmileIDSampleStrings.captureAsGenericNamedSummary(name: genericDocument.displayName, orientation: orientation, sides: sides)
  }

  /// The sheet's Match row, naming what the document resolves to.
  public var matchRowLabel: String {
    UseSmileIDSampleStrings.captureAsMatchNamed(captureAs: captureAs.label)
  }
}

/// The one place the match table lives: keyed on sub-type and code, never format, with the row's has_back for the rest.
public func useSmileIDSampleResolvedCaptureAs(
  document: UseSmileIDSampleDocument?,
  override: UseSmileIDSampleCaptureAs?,
  genericDocument: UseSmileIDSampleGenericDocument
) -> UseSmileIDSampleResolvedCaptureAs {
  if let override {
    return UseSmileIDSampleResolvedCaptureAs(captureAs: override, genericDocument: genericDocument, matched: false)
  }
  if document?.subType == useSmileIDSampleGreenBookSubType {
    return UseSmileIDSampleResolvedCaptureAs(captureAs: .greenBook, genericDocument: UseSmileIDSampleGenericDocument(), matched: true)
  }
  if document?.code == "PASSPORT" {
    return UseSmileIDSampleResolvedCaptureAs(captureAs: .passport, genericDocument: UseSmileIDSampleGenericDocument(), matched: true)
  }
  return UseSmileIDSampleResolvedCaptureAs(
    captureAs: .genericDocument,
    genericDocument: UseSmileIDSampleGenericDocument(hasBackSide: document?.hasBack ?? true),
    matched: true
  )
}

/// The only sub-type the API lists, and the one document the SDK refuses on Enhanced Document Verification.
public let useSmileIDSampleGreenBookSubType = "green_book"

extension String {
  /// An empty query matches everything: `localizedCaseInsensitiveContains("")` is false where Kotlin's is true.
  func matches(_ query: String) -> Bool {
    query.isBlank || localizedCaseInsensitiveContains(query.trimmingCharacters(in: .whitespaces))
  }
}
