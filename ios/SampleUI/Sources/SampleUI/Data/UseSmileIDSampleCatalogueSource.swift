import Foundation

/// The ID form's two lists as raw response bodies, so the network stays in the shell and one decoder reads live and fixture alike.
public protocol UseSmileIDSampleCatalogueSource: Sendable {
  /// `GET /v3/services/supported_id_types`, every country.
  func supportedIdTypes(environment: UseSmileIDSampleEnvironment) async throws -> Data

  /// `GET /v3/services/supported_documents?continent=AFRICA&locale=…`.
  func supportedDocuments(environment: UseSmileIDSampleEnvironment, locale: String) async throws -> Data
}

/// `catalogue=fixture`: the two bodies from `spec/catalogue-fixture.json`, with no network.
public struct UseSmileIDSampleFixtureCatalogueSource: UseSmileIDSampleCatalogueSource {
  private let idTypes: Data
  private let documents: Data

  public init(fixture: Data) throws {
    guard let root = try JSONSerialization.jsonObject(with: fixture) as? [String: Any],
          let idTypes = root["supported_id_types"], let documents = root["supported_documents"] else {
      throw UseSmileIDSampleCatalogueError.unreadable
    }
    self.idTypes = try JSONSerialization.data(withJSONObject: idTypes)
    self.documents = try JSONSerialization.data(withJSONObject: documents)
  }

  public func supportedIdTypes(environment _: UseSmileIDSampleEnvironment) async throws -> Data {
    idTypes
  }

  public func supportedDocuments(environment _: UseSmileIDSampleEnvironment, locale _: String) async throws -> Data {
    documents
  }
}

/// `catalogue=unreachable`: every call fails at once, which is how a flow reaches the error state.
public struct UseSmileIDSampleUnreachableCatalogueSource: UseSmileIDSampleCatalogueSource {
  public init() {}

  public func supportedIdTypes(environment _: UseSmileIDSampleEnvironment) async throws -> Data {
    throw URLError(.notConnectedToInternet)
  }

  public func supportedDocuments(environment _: UseSmileIDSampleEnvironment, locale _: String) async throws -> Data {
    throw URLError(.notConnectedToInternet)
  }
}

public enum UseSmileIDSampleCatalogueError: Error, Equatable {
  case unreadable
  case timedOut
}
