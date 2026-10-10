import Foundation

/// The user IDs SmartSelfie Authentication can run as: from jobs that enrol a user and were not refused or failed, newest first, once each.
public func useSmileIDSamplePreviousAuthUserIds(_ jobs: [UseSmileIDSampleJob]) -> [String] {
  var seen = Set<String>()
  return jobs
    .filter { $0.product.enrollsUser && $0.status != .blocked && $0.status != .error && !$0.userId.trimmingCharacters(in: .whitespaces).isEmpty }
    .sorted { $0.createdAt > $1.createdAt }
    .map(\.userId)
    .filter { seen.insert($0).inserted }
}
