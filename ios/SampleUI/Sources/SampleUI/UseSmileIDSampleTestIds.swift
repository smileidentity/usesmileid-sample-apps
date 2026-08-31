/// The `sample_*` ids from `spec/test-ids.json`. Attach to leaves — a container id overrides children.
public enum UseSmileIDSampleTestIds {
  public static let productsScreen = "sample_products_screen"
  public static let verificationsScreen = "sample_verifications_screen"
  public static let settingsScreen = "sample_settings_screen"

  public static let navProducts = "sample_nav_products"
  public static let navVerifications = "sample_nav_verifications"
  public static let navSettings = "sample_nav_settings"

  /// The bar carries the first, its action the second. Both sit on leaves: an identifier on the
  /// bar itself would override the action's.
  public static let toast = "sample_toast"
  public static let toastUndo = "sample_toast_undo"

  public static let jobRow = "sample_job_row"
  public static let jobRowStatus = "sample_job_row_status"
  public static let filterChip = "sample_filter_chip"
  public static let filterCount = "sample_filter_count"
  public static let selectionBar = "sample_selection_bar"
  public static let selectionCheckbox = "sample_selection_checkbox"
  public static let selectionCount = "sample_selection_count"
  public static let selectionRemove = "sample_selection_remove"

  /// Every id above, so the spec test cannot pass by omission.
  static let all = [
    productsScreen, verificationsScreen, settingsScreen,
    navProducts, navVerifications, navSettings,
    toast, toastUndo,
    jobRow, jobRowStatus, filterChip, filterCount,
    selectionBar, selectionCheckbox, selectionCount, selectionRemove
  ]
}
