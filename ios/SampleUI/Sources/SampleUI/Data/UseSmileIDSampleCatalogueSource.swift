import Foundation

/// The ID form's lists as raw bodies, so the network stays in the shell and one decoder reads live and fixture.
public protocol UseSmileIDSampleCatalogueSource: Sendable {
  /// `GET /v3/services/supported_id_types`, every country.
  func supportedIdTypes(environment: UseSmileIDSampleEnvironment) async throws -> Data

  /// `GET /v3/services/supported_documents?locale=…`.
  func supportedDocuments(environment: UseSmileIDSampleEnvironment, locale: String) async throws -> Data

  /// `GET /v3/services/config?product=enhanced_document_verification&locale=…`, under the session's `token`.
  func servicesConfig(environment: UseSmileIDSampleEnvironment, token: String, locale: String) async throws -> Data
}

/// A live source that answers a simulated session's configuration from the fixture: the server refuses an unsigned token.
public struct UseSmileIDSampleSessionAwareCatalogueSource: UseSmileIDSampleCatalogueSource {
  private let live: UseSmileIDSampleCatalogueSource
  private let fixture: UseSmileIDSampleCatalogueSource

  public init(live: UseSmileIDSampleCatalogueSource, fixture: UseSmileIDSampleCatalogueSource) {
    self.live = live
    self.fixture = fixture
  }

  public func supportedIdTypes(environment: UseSmileIDSampleEnvironment) async throws -> Data {
    try await live.supportedIdTypes(environment: environment)
  }

  public func supportedDocuments(environment: UseSmileIDSampleEnvironment, locale: String) async throws -> Data {
    try await live.supportedDocuments(environment: environment, locale: locale)
  }

  public func servicesConfig(environment: UseSmileIDSampleEnvironment, token: String, locale: String) async throws -> Data {
    if token.isEmpty {
      throw UseSmileIDSampleCatalogueError.http(401)
    }
    let source = UseSmileIDSampleTokenDecoder.isUnsigned(token) ? fixture : live
    return try await source.servicesConfig(environment: environment, token: token, locale: locale)
  }
}

/// `catalogue=fixture`: the bodies from `spec/catalogue-fixture.json`, with no network.
public struct UseSmileIDSampleFixtureCatalogueSource: UseSmileIDSampleCatalogueSource {
  private let idTypes: Data
  private let documents: Data
  private let config: Data

  public init(fixture: Data) throws {
    guard let root = try JSONSerialization.jsonObject(with: fixture) as? [String: Any],
          let idTypes = root["supported_id_types"], let documents = root["supported_documents"],
          let config = root["services_config"] else {
      throw UseSmileIDSampleCatalogueError.unreadable
    }
    self.idTypes = try JSONSerialization.data(withJSONObject: idTypes)
    self.documents = try JSONSerialization.data(withJSONObject: documents)
    self.config = try JSONSerialization.data(withJSONObject: config)
  }

  public func supportedIdTypes(environment _: UseSmileIDSampleEnvironment) async throws -> Data {
    idTypes
  }

  public func supportedDocuments(environment _: UseSmileIDSampleEnvironment, locale _: String) async throws -> Data {
    documents
  }

  public func servicesConfig(environment _: UseSmileIDSampleEnvironment, token _: String, locale _: String) async throws -> Data {
    config
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

  public func servicesConfig(environment _: UseSmileIDSampleEnvironment, token _: String, locale _: String) async throws -> Data {
    throw URLError(.notConnectedToInternet)
  }
}

public enum UseSmileIDSampleCatalogueError: Error, Equatable {
  case unreadable
  case timedOut
  /// A response that is not a 2xx, so the store can name a 401 or 403 in the error state.
  case http(Int)
}
