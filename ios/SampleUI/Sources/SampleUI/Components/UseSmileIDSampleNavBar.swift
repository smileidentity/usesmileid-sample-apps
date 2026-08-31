import SwiftUI

/// The three destinations the nav bar switches between. The token affordance is not one of them.
public enum UseSmileIDSampleNavItem: String, CaseIterable, Sendable {
  case products, verifications, settings

  public var label: String {
    rawValue.prefix(1).uppercased() + rawValue.dropFirst()
  }

  public var testId: String {
    switch self {
    case .products: UseSmileIDSampleTestIds.navProducts
    case .verifications: UseSmileIDSampleTestIds.navVerifications
    case .settings: UseSmileIDSampleTestIds.navSettings
    }
  }

  public var icon: SmileIcon {
    switch self {
    case .products: SmileIcons.products
    case .verifications: SmileIcons.verifications
    case .settings: SmileIcons.settings
    }
  }
}

/// The countdown ring: green rather than primary, driven by remaining time rather than a duration.
public struct UseSmileIDSampleTokenRing: View {
  private let progress: Double

  public init(progress: Double) {
    self.progress = progress
  }

  public var body: some View {
    ZStack {
      Circle().stroke(smileTokenRing.opacity(smileTokenRingTrackOpacity), lineWidth: Self.width)
      Circle()
        .trim(from: 0, to: min(max(progress, 0), 1))
        .stroke(smileTokenRing, style: StrokeStyle(lineWidth: Self.width, lineCap: .round))
        .rotationEffect(.degrees(-90))
    }
  }

  private static var width: CGFloat {
    3
  }
}

/// A floating pill of three tabs, plus a detached token button that navigates rather than switching
/// tab. `sessionProgress` drives its ring, 1 fresh to 0 expired.
///
/// The pill has its own fill: the design recesses it below the page, which this app's page colour
/// cannot express without hiding the bar. See the `navBarFill` delta.
public struct UseSmileIDSampleNavBar: View {
  private let selected: UseSmileIDSampleNavItem
  private let sessionProgress: Double?
  private let onSelect: (UseSmileIDSampleNavItem) -> Void
  private let onToken: () -> Void

  @ScaledMetric(relativeTo: .body) private var tokenSize: CGFloat = 56
  @Environment(\.useSmileIDSampleColors) private var colors

  public init(
    selected: UseSmileIDSampleNavItem,
    sessionProgress: Double? = nil,
    onSelect: @escaping (UseSmileIDSampleNavItem) -> Void,
    onToken: @escaping () -> Void
  ) {
    self.selected = selected
    self.sessionProgress = sessionProgress
    self.onSelect = onSelect
    self.onToken = onToken
  }

  public var body: some View {
    HStack(spacing: SmileSpacing.spacingXs) {
      HStack(spacing: 0) {
        ForEach(UseSmileIDSampleNavItem.allCases, id: \.self) { item in
          tab(item)
        }
      }
      .padding(.horizontal, SmileSpacing.spacingXs)
      .padding(.vertical, SmileSpacing.spacingXxs)
      .frame(maxWidth: .infinity)
      .background(Capsule().fill(colors.navBar).shadow(radius: Self.elevation))
      token
    }
    .padding(.horizontal, SmileSpacing.spacingMd)
    .padding(.vertical, SmileSpacing.spacingSm)
  }

  private func tab(_ item: UseSmileIDSampleNavItem) -> some View {
    Button { onSelect(item) } label: {
      UseSmileIDSampleText(item.label, style: UseSmileIDSampleTheme.type.tabFont)
        .foregroundColor(item == selected ? colors.foreground : colors.textMuted)
        .frame(maxWidth: .infinity, minHeight: SmileSpacing.sizeControlMd)
        .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .accessibilityAddTraits(item == selected ? [.isButton, .isSelected] : .isButton)
    .useSmileIDSampleTestId(item.testId)
  }

  /// The ring is painted outside the button's bounds rather than laid out around it: sized into the
  /// layout it pushed the bar off a 393pt screen.
  private var token: some View {
    Button(action: onToken) {
      VStack(spacing: 0) {
        UseSmileIDSampleIcon(SmileIcons.tokenScan, tint: colors.foreground, size: SmileSpacing.sizeIconSm)
        UseSmileIDSampleText("Token", style: UseSmileIDSampleTheme.type.textStyleOverline.with(size: 9))
          .foregroundColor(colors.foreground)
      }
      .frame(minWidth: tokenSize, minHeight: tokenSize)
      .background(Circle().fill(colors.navBar).shadow(radius: Self.elevation))
      .overlay {
        if let sessionProgress {
          UseSmileIDSampleTokenRing(progress: sessionProgress).padding(-Self.ringBleed)
        }
      }
    }
    .buttonStyle(.plain)
    .useSmileIDSampleTestId(UseSmileIDSampleTestIds.navToken)
  }

  private static var elevation: CGFloat {
    8
  }

  private static var ringBleed: CGFloat {
    3
  }
}
