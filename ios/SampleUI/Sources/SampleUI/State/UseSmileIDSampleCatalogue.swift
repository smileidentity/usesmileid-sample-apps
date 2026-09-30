import Foundation

/// Which list a product's form reads: the KYC products name an ID type, the document products a document, residency a passport's country.
public enum UseSmileIDSampleCatalogueFamily: Sendable {
  case kyc, document, passport
}

public extension UseSmileIDSampleProduct {
  /// Nil for the products that ask for no ID details.
  var catalogueFamily: UseSmileIDSampleCatalogueFamily? {
    switch self {
    case .biometricKyc, .enhancedKyc: .kyc
    case .documentVerification, .enhancedDocumentVerification: .document
    case .residencyDocumentVerification: .passport
    default: nil
    }
  }
}

/// One picker's list: still arriving, arrived, arrived with nothing the form can use, or failed.
public enum UseSmileIDSampleCatalogue<Item: Sendable>: Sendable {
  case loading
  case ready([Item])
  case empty
  /// `advice` is the error state's supporting line, per `spec/catalogue-rules.json` failures.
  case failed(String, advice: String = UseSmileIDSampleCatalogueRules.defaultAdvice)

  public var isLoading: Bool {
    if case .loading = self {
      return true
    }
    return false
  }

  /// The rows once the list has settled, an empty list for `.empty`; nil while it loads or after it fails.
  public var settledItems: [Item]? {
    switch self {
    case .ready(let items): items
    case .empty: []
    case .loading, .failed: nil
    }
  }

  public var isReady: Bool {
    if case .ready = self {
      return true
    }
    return false
  }

  public var isFailed: Bool {
    if case .failed = self {
      return true
    }
    return false
  }
}

/// An ID type as `supported_id_types` returns it.
public struct UseSmileIDSampleApiIdType: Equatable, Sendable {
  public let country: String
  public let type: String
  public let label: String
  public let regex: String
  public let requiredFields: [String]

  public init(country: String, type: String, label: String, regex: String, requiredFields: [String]) {
    self.country = country
    self.type = type
    self.label = label
    self.regex = regex
    self.requiredFields = requiredFields
  }
}

/// One country's entry in `supported_documents`, with its documents as the API lists them.
public struct UseSmileIDSampleApiCountryDocuments: Equatable, Sendable {
  public let country: UseSmileIDSampleCountry
  public let documents: [UseSmileIDSampleApiDocument]
}

public struct UseSmileIDSampleApiDocument: Equatable, Sendable {
  public let code: String
  public let name: String
  public let hasBack: Bool
  public let format: Int
  public let subTypes: [UseSmileIDSampleApiSubType]
}

public struct UseSmileIDSampleApiSubType: Equatable, Sendable {
  public let id: String
  public let name: String
  public let hasBack: Bool
  public let format: Int
  public let displayStandalone: Bool
}

/// A country of `products.enhanced_document_verification` in `GET /v3/services/config`, with the ID types the partner enabled.
public struct UseSmileIDSampleApiEnabledCountry: Equatable, Sendable {
  public let code: String
  public let documents: [UseSmileIDSampleApiEnabledDocument]
}

public struct UseSmileIDSampleApiEnabledDocument: Equatable, Sendable {
  public let code: String
  public let label: String
}

/// Both responses a run of the form reads; fetched together because the KYC countries need names from the second.
public struct UseSmileIDSampleCatalogueData: Equatable, Sendable {
  public let idTypes: [UseSmileIDSampleApiIdType]
  public let documents: [UseSmileIDSampleApiCountryDocuments]

  public init(idTypes: [UseSmileIDSampleApiIdType], documents: [UseSmileIDSampleApiCountryDocuments]) {
    self.idTypes = idTypes
    self.documents = documents
  }
}

/// The pure rules from `spec/catalogue-rules.json`, run on whatever the server returns.
public enum UseSmileIDSampleCatalogueRules {
  /// The one document code Residency Document Verification accepts, which the SDK enforces too.
  public static let passport = "PASSPORT"

  /// What the SDK fills in plus the two names the user-details form collects; anything else drops a type.
  public static let allowedRequiredFields: Set<String> = [
    "country", "first_name", "id_number", "id_type", "last_name", "partner_id", "partner_params", "timestamp"
  ]

  public static func idTypes(_ all: [UseSmileIDSampleApiIdType], country: String) -> [UseSmileIDSampleKycIdType] {
    var seen: [String: Int] = [:]
    return all
      .filter { $0.country == country && allowedRequiredFields.isSuperset(of: $0.requiredFields) }
      .map { type in
        let count = (seen[type.type] ?? 0) + 1
        seen[type.type] = count
        return UseSmileIDSampleKycIdType(
          id: count == 1 ? type.type : "\(type.type)_\(count)",
          type: type.type,
          label: type.label,
          regex: type.regex
        )
      }
  }

  /// `product` leaves out a row the SDK refuses on it: the Green Book on Enhanced Document Verification.
  public static func documents(
    _ all: [UseSmileIDSampleApiCountryDocuments],
    country: String,
    product: UseSmileIDSampleProduct = .documentVerification
  ) -> [UseSmileIDSampleDocument] {
    (all.first { $0.country.code == country }?.documents ?? [])
      .filter { !$0.code.isEmpty }
      .flatMap { document in
        [UseSmileIDSampleDocument(code: document.code, name: document.name, hasBack: document.hasBack, format: document.format)]
          + document.subTypes.filter(\.displayStandalone).map {
            UseSmileIDSampleDocument(code: document.code, subType: $0.id, name: $0.name, hasBack: $0.hasBack, format: $0.format)
          }
      }
      .filter { $0.isListed(on: product) }
  }

  /// Enhanced Document Verification's rows: the partner's enabled codes, each drawn from `supported_documents` when it lists it.
  public static func enabledDocuments(
    _ all: [UseSmileIDSampleApiCountryDocuments],
    enabled: [UseSmileIDSampleApiEnabledCountry],
    country: String
  ) -> [UseSmileIDSampleDocument] {
    let rows = documents(all, country: country, product: .enhancedDocumentVerification)
    let listed = Set((all.first { $0.country.code == country }?.documents ?? []).map(\.code))
    return (enabled.first { $0.code == country }?.documents ?? []).flatMap { entry in
      listed.contains(entry.code)
        ? rows.filter { $0.code == entry.code }
        : [UseSmileIDSampleDocument(code: entry.code, name: entry.label, hasBack: true, format: 1)]
    }
  }

  /// Enhanced Document Verification's countries, named from `supported_documents`, the rest by code.
  public static func enabledCountries(
    _ all: [UseSmileIDSampleApiCountryDocuments],
    enabled: [UseSmileIDSampleApiEnabledCountry]
  ) -> [UseSmileIDSampleCountry] {
    let offered = Set(enabled.map(\.code).filter { !enabledDocuments(all, enabled: enabled, country: $0).isEmpty })
    let named = all.map(\.country).filter { offered.contains($0.code) }
    return named + offered.filter { code in !named.contains { $0.code == code } }.sorted()
      .map { UseSmileIDSampleCountry(code: $0, name: $0) }
  }

  /// The error state's supporting line for an HTTP `status`, or nil when there was no answer.
  public static func advice(status: Int?) -> String {
    switch status {
    case 401: "The server refused this session's token. Link a new session, then try again"
    case 403: "Access denied: production may not be enabled for this partner, or this network is not allowed"
    default: defaultAdvice
    }
  }

  public static let defaultAdvice = "Check your connection, then try again"

  public static func countries(
    _ data: UseSmileIDSampleCatalogueData,
    family: UseSmileIDSampleCatalogueFamily
  ) -> [UseSmileIDSampleCountry] {
    let named = data.documents.map(\.country)
    switch family {
    case .document:
      return named.filter { !documents(data.documents, country: $0.code).isEmpty }
    case .passport:
      return named.filter { country in documents(data.documents, country: country.code).contains { $0.code == passport } }
    case .kyc:
      var listed: [String] = []
      for type in data.idTypes where !listed.contains(type.country) && !idTypes(data.idTypes, country: type.country).isEmpty {
        listed.append(type.country)
      }
      return named.filter { listed.contains($0.code) }
        + listed.filter { code in !named.contains { $0.code == code } }.map { UseSmileIDSampleCountry(code: $0, name: $0) }
    }
  }
}

/// Reads the two response bodies; readers ignore unknown keys, as status refresh does. Nil when malformed.
public enum UseSmileIDSampleCatalogueJson {
  public static func idTypes(_ body: Data) -> [UseSmileIDSampleApiIdType]? {
    guard let root = try? JSONSerialization.jsonObject(with: body) as? [String: Any],
          let items = root["id_types"] as? [[String: Any]] else { return nil }
    return items.compactMap { item in
      guard let country = item["country"] as? String, let type = item["type"] as? String,
            let label = item["label"] as? String else { return nil }
      return UseSmileIDSampleApiIdType(
        country: country,
        type: type,
        label: label,
        regex: item["regex"] as? String ?? "",
        requiredFields: item["required_fields"] as? [String] ?? []
      )
    }
  }

  public static func documents(_ body: Data) -> [UseSmileIDSampleApiCountryDocuments]? {
    guard let root = try? JSONSerialization.jsonObject(with: body) as? [String: Any],
          let items = root["valid_documents"] as? [[String: Any]] else { return nil }
    return items.compactMap { item in
      guard let country = item["country"] as? [String: Any], let code = country["code"] as? String,
            let name = country["name"] as? String else { return nil }
      return UseSmileIDSampleApiCountryDocuments(
        country: UseSmileIDSampleCountry(code: code, name: name),
        documents: (item["id_types"] as? [[String: Any]] ?? []).compactMap(document)
      )
    }
  }

  /// `products.enhanced_document_verification` of `GET /v3/services/config`: country code to enabled ID types.
  public static func enabledCountries(_ body: Data) -> [UseSmileIDSampleApiEnabledCountry]? {
    guard let root = try? JSONSerialization.jsonObject(with: body) as? [String: Any],
          let products = root["products"] as? [String: Any] else { return nil }
    let byCountry = products[enhancedDocumentVerification] as? [String: Any] ?? [:]
    return byCountry.map { code, entries in
      UseSmileIDSampleApiEnabledCountry(
        code: code,
        documents: (entries as? [[String: Any]] ?? []).compactMap { entry in
          guard let key = entry["key_name"] as? String, let label = entry["label"] as? String else { return nil }
          return UseSmileIDSampleApiEnabledDocument(code: key, label: label)
        }
      )
    }
  }

  /// The product key the configuration call asks for and reads back.
  public static let enhancedDocumentVerification = "enhanced_document_verification"

  private static func document(_ item: [String: Any]) -> UseSmileIDSampleApiDocument? {
    guard let code = item["code"] as? String, let name = item["name"] as? String else { return nil }
    return UseSmileIDSampleApiDocument(
      code: code,
      name: name,
      hasBack: bool(item["has_back"]) ?? true,
      format: item["format"] as? Int ?? 1,
      subTypes: (item["sub_types"] as? [[String: Any]] ?? []).compactMap { sub in
        guard let id = sub["id"] as? String, let name = sub["name"] as? String else { return nil }
        return UseSmileIDSampleApiSubType(
          id: id,
          name: name,
          hasBack: bool(sub["has_back"]) ?? true,
          format: sub["format"] as? Int ?? 1,
          displayStandalone: bool(sub["display_standalone"]) ?? false
        )
      }
    )
  }

  /// JSONSerialization hands a JSON boolean back as an NSNumber, which also casts from 0 and 1; only a real boolean counts.
  private static func bool(_ value: Any?) -> Bool? {
    guard let number = value as? NSNumber, CFGetTypeID(number) == CFBooleanGetTypeID() else { return nil }
    return number.boolValue
  }
}
