import Foundation
import SampleUI

/// The two unauthenticated catalogue endpoints; `URLSession` stays in the shell and no token is ever sent.
struct UseSmileIDSampleCatalogueApi: UseSmileIDSampleCatalogueSource {
  private let session: URLSession

  init(session: URLSession = UseSmileIDSampleCatalogueApi.bounded) {
    self.session = session
  }

  /// Ten seconds, as status refresh is bounded; the store's own timeout is the same.
  private static let bounded: URLSession = {
    let configuration = URLSessionConfiguration.default
    configuration.timeoutIntervalForRequest = 10
    #if DEBUG
      Loupe.instrument(configuration)
    #endif
    return URLSession(configuration: configuration)
  }()

  func supportedIdTypes(environment: UseSmileIDSampleEnvironment) async throws -> Data {
    try await get(environment, "v3/services/supported_id_types", [])
  }

  func supportedDocuments(environment: UseSmileIDSampleEnvironment, locale: String) async throws -> Data {
    // The picker lists African countries only; the API's continent filter is how it asks for them.
    try await get(environment, "v3/services/supported_documents", [
      URLQueryItem(name: "continent", value: "AFRICA"),
      URLQueryItem(name: "locale", value: locale)
    ])
  }

  private func get(_ environment: UseSmileIDSampleEnvironment, _ path: String, _ query: [URLQueryItem]) async throws -> Data {
    guard var components = URLComponents(string: environment.baseUrl + path) else { throw URLError(.badURL) }
    components.queryItems = query.isEmpty ? nil : query
    guard let url = components.url else { throw URLError(.badURL) }
    let (data, response) = try await session.data(from: url)
    guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
      throw URLError(.badServerResponse)
    }
    return data
  }
}
