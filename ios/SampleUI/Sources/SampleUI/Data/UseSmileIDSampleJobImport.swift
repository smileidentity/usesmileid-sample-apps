import Foundation

/// Reads the JSON document the store used before SwiftData, so an upgrade keeps its rows.
///
/// One shot: the file is removed once its rows are in. Re-running it is harmless anyway, because the
/// insert ignores an id already stored — which is what makes a crash mid-import safe.
struct UseSmileIDSampleJobImport: Sendable {
  private let url: URL

  init(url: URL) {
    self.url = url
  }

  /// The rows to hand the store — empty on a fresh install, and nil where the document has to be
  /// left exactly where it is.
  ///
  /// Nil is a version this build does not know how to read. Consuming it would delete rows a later
  /// build could have imported, which is the one mistake here that cannot be undone.
  func pending() -> [UseSmileIDSampleJobRecord]? {
    guard let data = try? Data(contentsOf: url) else { return [] }
    guard let file = try? JSONDecoder().decode(UseSmileIDSampleJobFile.self, from: data) else {
      // Not a document at all, so nothing is lost by clearing it out of the way.
      return []
    }
    guard file.version == UseSmileIDSampleJobFile.currentVersion else { return nil }
    return file.jobs
  }

  /// Called only after the rows are committed, so a failure between the two repeats the import
  /// rather than losing it.
  func done() {
    try? FileManager.default.removeItem(at: url)
  }

  static var defaultURL: URL? {
    FileManager.default
      .urls(for: .applicationSupportDirectory, in: .userDomainMask)
      .first?
      .appendingPathComponent("usesmileid_sample_jobs.json")
  }
}
