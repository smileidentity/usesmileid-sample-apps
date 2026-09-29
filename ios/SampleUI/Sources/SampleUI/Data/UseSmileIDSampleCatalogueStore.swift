import Foundation

/// The ID form's lists for one run: fetched ahead, held in memory only, cancelled on leaving.
@MainActor
public final class UseSmileIDSampleCatalogueStore: ObservableObject {
  private struct Run: Equatable {
    let environment: UseSmileIDSampleEnvironment
    let locale: String
  }

  private let source: UseSmileIDSampleCatalogueSource
  /// Nanoseconds rather than `Duration`, which needs iOS 16.
  private let timeout: UInt64
  private var run: Run?
  private var idTypesTask: Task<Void, Never>?
  private var documentsTask: Task<Void, Never>?

  @Published public private(set) var idTypes: UseSmileIDSampleCatalogue<UseSmileIDSampleApiIdType> = .loading
  @Published public private(set) var documents: UseSmileIDSampleCatalogue<UseSmileIDSampleApiCountryDocuments> = .loading

  public init(source: UseSmileIDSampleCatalogueSource, timeoutNanoseconds: UInt64 = 10000000000) {
    self.source = source
    timeout = timeoutNanoseconds
  }

  /// A product tap: a new run always asks the server again, so a list changed on the server shows up.
  public func begin(environment: UseSmileIDSampleEnvironment, locale: String) {
    stop()
    run = Run(environment: environment, locale: locale)
    fetchIdTypes()
    fetchDocuments()
  }

  /// The form itself: a deep link can land here without the product tap, so start only if nothing has.
  public func ensure(environment: UseSmileIDSampleEnvironment, locale: String) {
    if run != Run(environment: environment, locale: locale) {
      begin(environment: environment, locale: locale)
    }
  }

  /// Asks again for whichever list failed, under the same timing as the first attempt.
  public func retry() {
    guard run != nil else { return }
    if idTypes.isFailed {
      fetchIdTypes()
    }
    if documents.isFailed {
      fetchDocuments()
    }
  }

  /// Leaving the form: anything in flight is cancelled and the next run starts clean.
  public func stop() {
    idTypesTask?.cancel()
    documentsTask?.cancel()
    run = nil
    idTypes = .loading
    documents = .loading
  }

  public func countries(_ family: UseSmileIDSampleCatalogueFamily) -> UseSmileIDSampleCatalogue<UseSmileIDSampleCountry> {
    let types: UseSmileIDSampleCatalogue<UseSmileIDSampleApiIdType> = family == .kyc ? idTypes : .ready([])
    switch (documents, types) {
    case (.failed(let reason), _), (_, .failed(let reason)):
      return .failed(reason)
    case (.ready(let docs), .ready(let ids)):
      return Self.ready(UseSmileIDSampleCatalogueRules.countries(.init(idTypes: ids, documents: docs), family: family))
    default:
      return .loading
    }
  }

  public func idTypes(_ country: String) -> UseSmileIDSampleCatalogue<UseSmileIDSampleKycIdType> {
    switch idTypes {
    case .ready(let items): Self.ready(UseSmileIDSampleCatalogueRules.idTypes(items, country: country))
    case .failed(let reason): .failed(reason)
    case .empty: .empty
    case .loading: .loading
    }
  }

  public func documents(
    _ country: String,
    product: UseSmileIDSampleProduct = .documentVerification
  ) -> UseSmileIDSampleCatalogue<UseSmileIDSampleDocument> {
    switch documents {
    case .ready(let items): Self.ready(UseSmileIDSampleCatalogueRules.documents(items, country: country, product: product))
    case .failed(let reason): .failed(reason)
    case .empty: .empty
    case .loading: .loading
    }
  }

  private func fetchIdTypes() {
    guard let run else { return }
    idTypesTask?.cancel()
    idTypes = .loading
    let source = source
    idTypesTask = Task {
      let result = await load {
        try await UseSmileIDSampleCatalogueJson.idTypes(source.supportedIdTypes(environment: run.environment))
      }
      if !Task.isCancelled {
        idTypes = result
      }
    }
  }

  private func fetchDocuments() {
    guard let run else { return }
    documentsTask?.cancel()
    documents = .loading
    let source = source
    documentsTask = Task {
      let result = await load {
        try await UseSmileIDSampleCatalogueJson.documents(source.supportedDocuments(environment: run.environment, locale: run.locale))
      }
      if !Task.isCancelled {
        documents = result
      }
    }
  }

  /// Races the fetch against the timeout; decoded off the main actor, since the whole catalogue is about 200 KB.
  private func load<Item: Sendable>(
    _ fetch: @escaping @Sendable () async throws -> [Item]?
  ) async -> UseSmileIDSampleCatalogue<Item> {
    let timeout = timeout
    do {
      let items = try await withThrowingTaskGroup(of: [Item]?.self) { group in
        group.addTask { try await fetch() }
        group.addTask {
          try await Task.sleep(nanoseconds: timeout)
          throw UseSmileIDSampleCatalogueError.timedOut
        }
        defer { group.cancelAll() }
        return try await group.next() ?? nil
      }
      return items.map(UseSmileIDSampleCatalogue.ready) ?? .failed("Unreadable response")
    } catch UseSmileIDSampleCatalogueError.timedOut {
      return .failed("Timed out")
    } catch {
      return .failed(error.localizedDescription)
    }
  }

  private static func ready<Item>(_ items: [Item]) -> UseSmileIDSampleCatalogue<Item> {
    items.isEmpty ? .empty : .ready(items)
  }
}
