import Foundation

/// This partner's enrolling runs in this environment, not refused or failed, newest first, one per user.
public func useSmileIDSamplePreviousAuthUsers(_ jobs: [UseSmileIDSampleJob], partnerId: String?, sandbox: Bool) -> [UseSmileIDSampleJob] {
  guard let partnerId else { return [] }
  var seen = Set<String>()
  return jobs
    .filter { $0.partnerId == partnerId && $0.sandbox == sandbox }
    .filter { $0.product.enrollsUser && $0.status != .blocked && $0.status != .error && !$0.userId.trimmingCharacters(in: .whitespaces).isEmpty }
    .sorted { $0.createdAt > $1.createdAt }
    .filter { seen.insert($0.userId).inserted }
}
