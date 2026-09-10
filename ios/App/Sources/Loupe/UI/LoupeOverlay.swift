import SwiftUI

/// A draggable pill over the app showing what the traffic is doing, tapped to open the loupe.
///
/// Bottom trailing by default: the top is where a navigation bar puts its buttons, and an overlay
/// that covers one is an overlay that breaks the app it is meant to observe.
///
/// Borrowed from DebugOverlay-Android: a shake nobody is told about is a feature nobody uses, and a
/// count that is always on screen is what makes a stall or a burst of failures noticeable at all.
struct LoupeOverlay: View {
  let store: LoupeStore
  let onOpen: () -> Void

  /// Kept per launch rather than persisted: where it belongs depends on the screen under it.
  @State private var offset: CGSize = .zero
  @State private var drag: CGSize = .zero

  var body: some View {
    GeometryReader { proxy in
      pill
        .offset(x: offset.width + drag.width, y: offset.height + drag.height)
        .gesture(
          DragGesture()
            .onChanged { drag = $0.translation }
            .onEnded { value in
              offset = clamped(offset + value.translation, in: proxy.size)
              drag = .zero
            }
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
    }
    .padding(.horizontal, 12)
    .padding(.bottom, 4)
    .allowsHitTesting(true)
  }

  private var pill: some View {
    Button(action: onOpen) {
      HStack(spacing: 6) {
        Image(systemName: "magnifyingglass")
        Text(summary)
          .font(.caption2.monospacedDigit().weight(.semibold))
      }
      .padding(.horizontal, 10)
      .padding(.vertical, 6)
      .background(.thinMaterial, in: Capsule())
      .overlay(Capsule().strokeBorder(tint.opacity(0.6), lineWidth: 1))
      .foregroundStyle(tint)
    }
    .buttonStyle(.plain)
    .accessibilityIdentifier("sample_loupe_overlay")
    .accessibilityLabel("Network loupe, \(summary)")
  }

  /// In-flight first: a request that has not come back is the thing worth interrupting for.
  private var summary: String {
    let inFlight = store.inFlightCount
    if inFlight > 0 {
      return "\(inFlight) in flight"
    }
    let failures = store.failureCount
    if failures > 0 {
      return "\(store.records.count) · \(failures) failed"
    }
    return String(store.records.count)
  }

  private var tint: Color {
    if store.failureCount > 0 {
      return .orange
    }
    return store.inFlightCount > 0 ? .blue : .secondary
  }

  /// Kept inside the container so a drag cannot strand it off-screen with no way back.
  private func clamped(_ offset: CGSize, in size: CGSize) -> CGSize {
    CGSize(
      width: min(0, max(-(size.width - 96), offset.width)),
      height: max(-(size.height - 44), min(0, offset.height))
    )
  }
}

private func + (lhs: CGSize, rhs: CGSize) -> CGSize {
  CGSize(width: lhs.width + rhs.width, height: lhs.height + rhs.height)
}
