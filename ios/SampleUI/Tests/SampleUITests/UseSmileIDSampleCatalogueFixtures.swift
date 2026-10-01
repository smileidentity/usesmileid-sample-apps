import Foundation
@testable import SampleUI

/// The rows spec/catalogue-fixture.json yields, read through the same source, decoder and rules the app runs.
enum UseSmileIDSampleCatalogueFixtures {
  static var json: Data {
    // swiftlint:disable:next force_try
    try! Data(contentsOf: UseSmileIDSampleSpecFiles.directory.appendingPathComponent("catalogue-fixture.json"))
  }

  static func enabled() async throws -> [UseSmileIDSampleApiEnabledCountry] {
    let source = try UseSmileIDSampleFixtureCatalogueSource(fixture: json)
    return try await UseSmileIDSampleCatalogueJson.enabledCountries(
      source.servicesConfig(environment: .sandbox, token: "", locale: "en-GB")
    ) ?? []
  }

  static func data() async throws -> UseSmileIDSampleCatalogueData {
    let source = try UseSmileIDSampleFixtureCatalogueSource(fixture: json)
    return try await UseSmileIDSampleCatalogueData(
      idTypes: UseSmileIDSampleCatalogueJson.idTypes(source.supportedIdTypes(environment: .sandbox)) ?? [],
      documents: UseSmileIDSampleCatalogueJson.documents(source.supportedDocuments(environment: .sandbox, locale: "en-GB")) ?? []
    )
  }
}
