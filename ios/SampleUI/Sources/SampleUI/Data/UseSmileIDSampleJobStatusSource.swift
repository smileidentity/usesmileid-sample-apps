import Foundation

/// The one network call the app owns, behind a seam so the refresh orchestration tests off-device.
public protocol UseSmileIDSampleJobStatusSource: Sendable {
  /// Maps the HTTP exchange onto an outcome and lets a transport failure throw: the store owns
  /// turning one into something a screen can say.
  func check(jobId: String, token: String, sandbox: Bool) async throws -> UseSmileIDSampleStatusRefresh
}

/// What a refresh did, so the screen can say so.
public enum UseSmileIDSampleStatusRefresh: Equatable, Sendable {
  case updated(status: UseSmileIDSampleStatus, message: String, httpCode: Int)
  /// 202 — still running; the row already says Processing.
  case stillProcessing
  /// No live session, so no credential to ask with. A precondition, not an error.
  case noSession
  /// Never submitted under a scanned session, so there is no server-side job.
  case noServerJob
  /// Submitted by a different partner, so this session's credential is for another account.
  case partnerMismatch
  case failed(reason: String)
}
