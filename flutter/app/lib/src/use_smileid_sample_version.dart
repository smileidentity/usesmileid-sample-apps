/// The footer line in settings: the app's display name and its version.
///
/// Written out rather than read from the bundle, because reading it needs a plugin and this is one
/// string. A test pins it against `pubspec.yaml`, which is what stops the two drifting apart.
const String useSmileIDSampleVersionLabel = 'Smile ID · 1.0.0';
