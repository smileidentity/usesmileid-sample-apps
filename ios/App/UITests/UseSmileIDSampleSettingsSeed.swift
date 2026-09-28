// The store's own persistence keys, not `spec/launch-args.json` arguments: nothing in the app parses
// them, and `UserDefaults` gives a launch value precedence over the persisted one for that launch only.

/// The six switches at their shipped defaults, passed on every launch: they persist, so a test inheriting the last one's settings proves nothing.
let useSmileIDSampleSettingsSeed = [
  "-enhanced_smart_selfie", "true",
  "-agent_mode", "false",
  "-dark_mode", "false",
  "-consent_step", "true",
  "-instructions_step", "true",
  "-preview_step", "true"
]
