/// The flow scenarios the drawer offers, asserted against `spec/scenarios.json` by a unit test.
enum UseSmileIDSampleScenario {
  /// Happy path.
  normal('normal', 'Normal', 'Happy path with valid sandbox credentials.'),

  /// A structurally valid token that has already expired.
  expiredToken(
    'expiredToken',
    'Expired token',
    'Token is valid but expired, so the SDK must refresh before it can submit.',
  ),

  /// A refresh that resolves with an unusable token.
  badRefresh(
    'badRefresh',
    'Refresh fails',
    'Refresh returns an unusable token, so the failure path must surface.',
  ),

  /// No host result callback at all.
  noCallback(
    'noCallback',
    'No result callback',
    'Host provides no result callback; the SDK must not crash or hang.',
  ),

  /// A host callback that throws immediately.
  throwingCallback(
    'throwingCallback',
    'Throwing callback',
    'Host callback throws; it must not corrupt SDK state.',
  ),

  /// Submission without connectivity, then with it.
  offlineRetry(
    'offlineRetry',
    'Offline then retry',
    'Submission starts with no connectivity, then it returns.',
  );

  const UseSmileIDSampleScenario(this.id, this.label, this.description);

  /// The stable id automation passes and the result card publishes.
  final String id;

  /// The drawer row's title.
  final String label;

  /// The drawer row's explanation.
  final String description;

  /// Resolves an id from a launch argument, falling back rather than throwing on a rename.
  static UseSmileIDSampleScenario? byId(String? id) =>
      values.where((UseSmileIDSampleScenario it) => it.id == id).firstOrNull;
}

/// Theme scenarios apply on top of any flow scenario, through the SDK's public theme override.
enum UseSmileIDSampleThemeScenario {
  /// Ship state.
  brandDefault(
    'brandDefault',
    'Brand default',
    'Ship state: Smile ID branding, light or dark per the Settings switch.',
  ),

  /// A deliberately distant host theme.
  clashingHost(
    'clashingHost',
    'Clashing host',
    'A deliberately distant host theme, to expose host-versus-SDK collisions.',
  ),

  /// A plausible partner palette.
  partnerOverride(
    'partnerOverride',
    'Partner override',
    'A plausible partner palette through the same public override.',
  );

  const UseSmileIDSampleThemeScenario(this.id, this.label, this.description);

  /// The stable id automation passes and the result card publishes.
  final String id;

  /// The drawer row's title.
  final String label;

  /// The drawer row's explanation.
  final String description;

  /// Resolves an id from a launch argument, falling back rather than throwing on a rename.
  static UseSmileIDSampleThemeScenario? byId(String? id) => values
      .where((UseSmileIDSampleThemeScenario it) => it.id == id)
      .firstOrNull;
}
