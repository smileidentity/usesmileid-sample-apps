import SwiftUI

public extension View {
  /// The platform's own alert, asking before an action that deletes something; the confirm action is destructive.
  func useSmileIDSampleConfirmation(
    isPresented: Binding<Bool>,
    title: String,
    message: String,
    confirmLabel: String,
    confirmTestId: String,
    onConfirm: @escaping () -> Void
  ) -> some View {
    alert(title, isPresented: isPresented) {
      Button(confirmLabel, role: .destructive, action: onConfirm)
        .accessibilityIdentifier(confirmTestId)
      Button("Cancel", role: .cancel) {}
    } message: {
      Text(message)
    }
  }
}
