// The store's own persistence keys, not `spec/launch-args.json` arguments: nothing in the app parses
// them, and `UserDefaults` gives a launch value precedence over the persisted one for that launch only.

/// The seven switches at their defaults, passed on every launch because they persist from one test to the next.
let useSmileIDSampleSettingsSeed = [
  "-enhanced_smart_selfie", "true",
  "-agent_mode", "false",
  "-dark_mode", "false",
  "-consent_step", "true",
  "-instructions_step", "true",
  "-preview_step", "true",
  "-gallery_upload", "false"
]
