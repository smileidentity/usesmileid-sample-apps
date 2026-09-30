import Foundation
import SampleUI

/// The two unauthenticated catalogue endpoints and the partner's own configuration under its token; `URLSession` stays in the shell.
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
    try await get(
      environment, "v3/services/supported_documents", [URLQueryItem(name: "locale", value: locale)]
    )
  }

  func servicesConfig(environment: UseSmileIDSampleEnvironment, token: String, locale: String) async throws -> Data {
    try await get(
      environment,
      "v3/services/config",
      [
        URLQueryItem(name: "product", value: UseSmileIDSampleCatalogueJson.enhancedDocumentVerification),
        URLQueryItem(name: "locale", value: locale)
      ],
      token: token
    )
  }

  private func get(
    _ environment: UseSmileIDSampleEnvironment,
    _ path: String,
    _ query: [URLQueryItem],
    token: String? = nil
  ) async throws -> Data {
    guard var components = URLComponents(string: environment.baseUrl + path) else { throw URLError(.badURL) }
    components.queryItems = query.isEmpty ? nil : query
    guard let url = components.url else { throw URLError(.badURL) }
    var request = URLRequest(url: url)
    if let token {
      request.setValue(token, forHTTPHeaderField: "SmileID-Token")
    }
    let (data, response) = try await session.data(for: request)
    guard let http = response as? HTTPURLResponse else { throw URLError(.badServerResponse) }
    guard (200..<300).contains(http.statusCode) else { throw UseSmileIDSampleCatalogueError.http(http.statusCode) }
    return data
  }
}
