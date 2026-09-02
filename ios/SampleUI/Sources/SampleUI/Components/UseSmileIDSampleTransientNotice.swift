import SwiftUI

/// One transient confirmation: what it says and the single action it may offer.
public struct UseSmileIDSampleTransientNotice: Equatable, Sendable {
  public let message: String
  public let actionLabel: String?

  public init(message: String, actionLabel: String? = nil) {
    self.message = message
    self.actionLabel = actionLabel
  }
}

/// Renders a notice and owns its auto-dismiss window. Padding stays the caller's: every screen
/// clears different chrome.
public struct UseSmileIDSampleTransientNoticeHost: View {
  private let notice: UseSmileIDSampleTransientNotice?
  private let window: TimeInterval
  private let onAction: () -> Void
  private let onDismiss: () -> Void

  public init(
    notice: UseSmileIDSampleTransientNotice?,
    // Long enough to act on, short enough not to outlive its cause.
    window: TimeInterval = 5,
    onAction: @escaping () -> Void = {},
    onDismiss: @escaping () -> Void
  ) {
    self.notice = notice
    self.window = window
    self.onAction = onAction
    self.onDismiss = onDismiss
  }

  public var body: some View {
    if let notice {
      UseSmileIDSampleToast(
        message: notice.message,
        actionLabel: notice.actionLabel,
        onAction: notice.actionLabel == nil ? nil : {
          onAction()
          onDismiss()
        }
      )
      // Keyed on the notice, so a different one restarts the window.
      .task(id: notice) {
        try? await Task.sleep(nanoseconds: UInt64(window * 1e9))
        guard !Task.isCancelled else { return }
        onDismiss()
      }
    }
  }
}
