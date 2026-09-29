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
  case failed(String)

  public var isLoading: Bool {
    if case .loading = self {
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

  public static func documents(_ all: [UseSmileIDSampleApiCountryDocuments], country: String) -> [UseSmileIDSampleDocument] {
    (all.first { $0.country.code == country }?.documents ?? [])
      .filter { !$0.code.isEmpty }
      .flatMap { document in
        [UseSmileIDSampleDocument(code: document.code, name: document.name, hasBack: document.hasBack, format: document.format)]
          + document.subTypes.filter(\.displayStandalone).map {
            UseSmileIDSampleDocument(code: document.code, subType: $0.id, name: $0.name, hasBack: $0.hasBack, format: $0.format)
          }
      }
  }

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
