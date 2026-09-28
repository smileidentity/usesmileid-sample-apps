import SwiftUI

/// Skeleton rows show only after `delay`, so a fast answer never flashes, then for at least `minimumShown`.
@MainActor
public final class UseSmileIDSampleSkeletonGate: ObservableObject {
  @Published public private(set) var visible = false

  public nonisolated static let delayNanoseconds: UInt64 = 300000000
  public nonisolated static let minimumShownNanoseconds: UInt64 = 400000000

  private let delay: UInt64
  private let minimumShown: UInt64
  private var shownAt: UInt64 = 0
  private var pending: Task<Void, Never>?

  public init(delay: UInt64 = delayNanoseconds, minimumShown: UInt64 = minimumShownNanoseconds) {
    self.delay = delay
    self.minimumShown = minimumShown
  }

  public func loading(_ isLoading: Bool) {
    pending?.cancel()
    pending = Task { [weak self] in
      guard let self else { return }
      if isLoading {
        guard !visible else { return }
        try? await Task.sleep(nanoseconds: delay)
        guard !Task.isCancelled else { return }
        shownAt = DispatchTime.now().uptimeNanoseconds
        visible = true
      } else if visible {
        let elapsed = DispatchTime.now().uptimeNanoseconds - shownAt
        if elapsed < minimumShown {
          try? await Task.sleep(nanoseconds: minimumShown - elapsed)
        }
        guard !Task.isCancelled else { return }
        visible = false
      }
    }
  }
}

/// Six OptionRow-shaped placeholders; one element to accessibility, announcing `announcement`.
public struct UseSmileIDSampleSkeletonRows: View {
  private let announcement: String
  private let leadingCircle: Bool
  private let testId: String?

  @State private var pulsed = false
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @Environment(\.useSmileIDSampleColors) private var colors
  @ScaledMetric(relativeTo: .body) private var rowHeight: CGFloat = SmileSpacing.sizeControlMd

  public init(announcement: String, leadingCircle: Bool = false, testId: String? = nil) {
    self.announcement = announcement
    self.leadingCircle = leadingCircle
    self.testId = testId
  }

  public var body: some View {
    VStack(spacing: SmileSpacing.spacingXxs) {
      ForEach(Self.widths.indices, id: \.self) { index in
        row(width: Self.widths[index])
      }
    }
    .frame(maxWidth: .infinity)
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(announcement)
    .useSmileIDSampleTestId(testId)
    .onAppear {
      guard !reduceMotion else { return }
      withAnimation(.easeInOut(duration: SmileMotion.skeletonDuration).repeatForever(autoreverses: true)) {
        pulsed = true
      }
    }
  }

  private var fill: Color {
    pulsed && !reduceMotion ? colors.skeletonHighlight : colors.skeleton
  }

  private func row(width: CGFloat) -> some View {
    HStack(spacing: SmileSpacing.spacingSm) {
      if leadingCircle {
        Circle().fill(fill).frame(width: 19, height: 19)
      }
      GeometryReader { proxy in
        RoundedRectangle(cornerRadius: UseSmileIDSampleShapes.field, style: .continuous)
          .fill(fill)
          .frame(width: proxy.size.width * width, height: 12)
          .frame(maxHeight: .infinity, alignment: .center)
      }
    }
    .padding(.horizontal, SmileSpacing.spacingSm)
    .frame(height: rowHeight)
  }

  /// Six widths so the rows do not read as a table.
  private static let widths: [CGFloat] = [0.72, 0.48, 0.64, 0.56, 0.80, 0.40]
}

public extension EnvironmentValues {
  /// How long a loading list waits before its skeleton rows show; zero shows them at once, as a still frame needs.
  @Entry var useSmileIDSampleSkeletonDelay: UInt64 = UseSmileIDSampleSkeletonGate.delayNanoseconds
}
