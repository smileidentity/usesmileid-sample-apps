// The store's own persistence keys, not `spec/launch-args.json` arguments: nothing in the app parses
// them, and `UserDefaults` gives a launch value precedence over the persisted one for that launch only.

/// Every switch at its default and the appearance pinned light, on every launch: both persist, and light frees a run from the simulator's theme.
let useSmileIDSampleSettingsSeed = [
  "-enhanced_smart_selfie", "true",
  "-agent_mode", "false",
  "-appearance", "light",
  "-consent_step", "true",
  "-instructions_step", "true",
  "-preview_step", "true",
  "-gallery_upload", "false",
  "-allow_skip_back", "false",
  "-selfie_first", "false"
]
