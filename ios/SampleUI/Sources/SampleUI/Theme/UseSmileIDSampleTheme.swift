import SwiftUI

/// Token accessors that are the same in both schemes.
public enum UseSmileIDSampleTheme {
  /// The full ramp. Display styles name a family the design system does not ship, so both slots
  /// resolve to DM Sans — the same substitution the Compose theme makes.
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

  /// How long a transient notice stays. The shell overrides it from `noticeWindow`; the default is
  /// the product's, so a library consumer that publishes nothing gets the real behaviour.
  @Entry var useSmileIDSampleNoticeWindow: TimeInterval = 5
}

private struct UseSmileIDSampleThemeModifier: ViewModifier {
  @Environment(\.colorScheme) private var colorScheme

  func body(content: Content) -> some View {
    content.environment(\.useSmileIDSampleColors, colorScheme == .dark ? .dark : .light)
  }
}

public extension View {
  /// Resolves the token colours for the active scheme and publishes them to the subtree.
  ///
  /// The SDK is not re-themed here: it resolves the same tokens internally, so host chrome and the
  /// flow stay continuous without either side sharing code.
  func useSmileIDSampleTheme() -> some View {
    modifier(UseSmileIDSampleThemeModifier())
  }
}
