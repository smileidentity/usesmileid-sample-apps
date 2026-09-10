import SwiftUI

/// Token accessors that are the same in both schemes.
public enum UseSmileIDSampleTheme {
  /// The full ramp; display styles name a family the system does not ship, so both slots resolve to DM Sans.
  public static let type = SmileTypeStyles(display: "DM Sans", body: "DM Sans")
}

/// One radius per named surface. The values come from `SmileSpacing`; this fixes where each applies.
public enum UseSmileIDSampleShapes {
  public static let card = SmileSpacing.radiusSurface
  public static let tile = SmileSpacing.radiusLg
  /// The verifications row's tile: node 5206-2410 draws 10, the one radius no token carries.
  public static let rowTile: CGFloat = 10
  public static let field = SmileSpacing.radiusField
  public static let pill = SmileSpacing.radiusPill
  public static let chip = SmileSpacing.radiusChip
  public static let sheet = SmileSpacing.radiusSurface
}

public extension EnvironmentValues {
  /// The active scheme's colours. Populated by ``SwiftUI/View/useSmileIDSampleTheme()``.
  @Entry var useSmileIDSampleColors: UseSmileIDSampleColors = .light

  /// How long a transient notice stays; the shell overrides it, and the default is the product's.
  @Entry var useSmileIDSampleNoticeWindow: TimeInterval = 5
}

private struct UseSmileIDSampleThemeModifier: ViewModifier {
  @Environment(\.colorScheme) private var colorScheme

  func body(content: Content) -> some View {
    content.environment(\.useSmileIDSampleColors, colorScheme == .dark ? .dark : .light)
  }
}

public extension View {
  /// Publishes the active scheme's token colours to the subtree; the SDK is not re-themed, resolving the same tokens itself.
  func useSmileIDSampleTheme() -> some View {
    modifier(UseSmileIDSampleThemeModifier())
  }
}
