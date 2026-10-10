import Foundation

/// The user IDs SmartSelfie Authentication can run as: this partner's jobs in this environment that enrol a user and were not refused or failed, newest first, once each.
public func useSmileIDSamplePreviousAuthUserIds(_ jobs: [UseSmileIDSampleJob], partnerId: String?, sandbox: Bool) -> [String] {
  guard let partnerId else { return [] }
  var seen = Set<String>()
  return jobs
    .filter { $0.partnerId == partnerId && $0.sandbox == sandbox }
    .filter { $0.product.enrollsUser && $0.status != .blocked && $0.status != .error && !$0.userId.trimmingCharacters(in: .whitespaces).isEmpty }
    .sorted { $0.createdAt > $1.createdAt }
    .map(\.userId)
    .filter { seen.insert($0).inserted }
}
