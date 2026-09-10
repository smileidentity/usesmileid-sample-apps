import Foundation

/// Reads the pre-SwiftData JSON document so an upgrade keeps its rows; one shot, and harmless to repeat.
struct UseSmileIDSampleJobImport {
  private let url: URL

  init(url: URL) {
    self.url = url
  }

  /// The rows to hand the store: empty on a fresh install, nil for a document this build must not consume and must not delete.
  func pending() -> [UseSmileIDSampleJobRecord]? {
    // Absent is a fresh install; present but unreadable must not read as "no rows" and get the document deleted.
    guard FileManager.default.fileExists(atPath: url.path) else { return [] }
    guard let data = try? Data(contentsOf: url) else { return nil }
    guard let file = try? JSONDecoder().decode(UseSmileIDSampleJobFile.self, from: data) else {
      // Not a document at all, so nothing is lost by clearing it out of the way.
      return []
    }
    guard file.version == UseSmileIDSampleJobFile.currentVersion else { return nil }
    return file.jobs
  }

  /// Called only after the rows are committed, so a failure between the two repeats the import.
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
