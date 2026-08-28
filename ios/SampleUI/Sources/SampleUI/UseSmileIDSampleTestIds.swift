/// The `sample_*` accessibility ids flows assert on, mirroring `spec/test-ids.json`.
/// Attach them to leaves: an id on a container overrides every child id underneath it.
public enum UseSmileIDSampleTestIds {
  public static let productsScreen = "sample_products_screen"
  public static let verificationsScreen = "sample_verifications_screen"
  public static let settingsScreen = "sample_settings_screen"

  public static let navProducts = "sample_nav_products"
  public static let navVerifications = "sample_nav_verifications"
  public static let navSettings = "sample_nav_settings"

  /// Every id above, so the spec test cannot pass by forgetting one.
  static let all = [
    productsScreen, verificationsScreen, settingsScreen,
    navProducts, navVerifications, navSettings
  ]
}
