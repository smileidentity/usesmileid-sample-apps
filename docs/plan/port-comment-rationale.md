# Reasoning relocated from multi-paragraph doc comments

`AGENTS.md` requires a one-line doc comment and says the reasoning behind a decision belongs in
`docs/plan/`, "reviewed, searchable and read on purpose — a paragraph above a function is none of
those and goes stale where nobody looks."

The ports left 86 multi-paragraph doc comments. Each declaration keeps a one-line comment; everything
the longer form said is below, keyed by the declaration it sat above. Nothing was deleted.

## `flutter/app/lib/src/data/use_smileid_sample_preferences_jobs_repository.dart`

**`class UseSmileIDSamplePreferencesJobsRepository`**

- One JSON array under one key: the twin's database buys query and scale this sample never needs.

## `flutter/app/lib/src/data/use_smileid_sample_preferences_settings_repository.dart`

**`class UseSmileIDSamplePreferencesSettingsRepository`**

- It lives in the shell rather than in `sample_ui` because the plugin is a platform binding.

**`UseSmileIDSamplePreferencesSettingsRepository(this._preferences);`**

- Not const: the write queue below is per-store mutable state, and every caller reaches this through [open] rather than constructing a constant.

## `flutter/app/lib/src/screens/use_smileid_sample_licenses_tab.dart`

**`class UseSmileIDSampleLicensesTab extends ConsumerWidget {`**

- Reads Flutter's own licence registry rather than a committed asset.

## `flutter/app/lib/src/screens/use_smileid_sample_products_tab.dart`

**`class UseSmileIDSampleProductsTab extends ConsumerWidget {`**

- No session yet, so the header shows the active profile and nothing else; the session card and the scan it leads to arrive with the token store.

## `flutter/app/lib/src/screens/use_smileid_sample_profiles_tab.dart`

**`class UseSmileIDSampleProfilesTab extends ConsumerStatefulWidget {`**

- The created confirmation is shown HERE rather than in the sheet, because the sheet is gone by the time there is anything to confirm.

## `flutter/app/lib/src/screens/use_smileid_sample_settings_tab.dart`

**`class UseSmileIDSampleSettingsTab extends ConsumerStatefulWidget {`**

- Nothing here holds the values: the notifier writes through the repository and takes back what was stored, which is how the capture mutex reaches both persistence paths rather than one.

## `flutter/app/lib/src/screens/use_smileid_sample_verification_details_tab.dart`

**`Future<void> _refresh() async {`**

- Every job this app can hold today ran under no session, so this always reports rather than fetches; the request itself arrives with the scanner that mints a session.

## `flutter/app/lib/src/screens/use_smileid_sample_verifications_tab.dart`

**`class UseSmileIDSampleVerificationsTab extends ConsumerWidget {`**

- A launch with no arguments shows the empty state, because fixtures reach a screen only through `seedJobs` and never as the store's default.

## `flutter/app/lib/src/state/use_smileid_sample_providers.dart`

**`final Provider<UseSmileIDSampleSettings>`**

- Overridden with a value already read, so the first frame is the stored appearance rather than the default one, which would flash light before it settled dark (R9's cold start).

**`class UseSmileIDSampleProfilesNotifier`**

- The store is mutable and keeps its identity across a switch, so a new state object would say nothing; this notifies instead, rather than duplicating the store's rules in a second shape.

**`final AsyncNotifierProvider<`**

- Asynchronous on purpose: the list's third state is NOT LOADED YET, and collapsing it to an empty list makes a first frame claim there is nothing stored before anything has been read.

**`final FutureProvider<UseSmileIDSampleLicenses>`**

- Asynchronous because the registry streams them: the list is a megabyte of text and parsing it on the first frame would stall the launch the notices are not part of.

## `flutter/app/lib/src/use_smileid_sample_journey.dart`

**`abstract final class UseSmileIDSampleJourney {`**

- One place rather than one per screen: the order is the journey's, and a second copy is how two entry points come to disagree about which form a product needs.

**`static String firstStepFor(UseSmileIDSampleProduct product) =>`**

- A token that already binds those details skips this step on the twin; no token session exists here yet, so nothing skips it.

## `flutter/app/lib/src/use_smileid_sample_launch.dart`

**`class UseSmileIDSampleLaunch {`**

- The cold-start link the engine hands over before the first frame, so no plugin or native shim is involved.

**`String get location {`**

- A custom-scheme link arrives whole — `usesmileid-sample-flutter://settings`.

**`Future<void> useSmileIDSampleApplyLaunch(`**

- One function rather than a few lines in `main`, so a test drives the SAME path the app does. A test that seeds by hand proves its own arrangement rather than the app's.

## `flutter/app/lib/src/use_smileid_sample_remove_jobs.dart`

**`Future<void> useSmileIDSampleRemoveJobs(WidgetRef ref, Set<String> ids) async {`**

- Two apps' worth of experience says the paths must not diverge — a removal has to leave select mode, show its confirmation and fall the filter back, whichever affordance fired it.

## `flutter/app/lib/src/use_smileid_sample_routes.dart`

**`abstract final class UseSmileIDSampleRoutes {`**

- The three tab roots are the only ones with a screen today; the rest are here because the paths are the contract four apps share, and a route helper that arrives with its screen arrives late.

**`bool useSmileIDSampleShowsNavBar(String location) => UseSmileIDSampleRoutes`**

- It takes the destination and nothing else. Testing membership of a tab's branch instead put a bar on pushed screens the design draws without one, which is the defect R13 was written for.

**`String useSmileIDSamplePageBehind(String location) =>`**

- The picker paths nest under the form they cover, so they resolve to themselves and get no bar.

**`GoRouter useSmileIDSampleRouter({String? initialLocation}) => GoRouter(`**

- Routes pushed inside a branch keep that tab's stack; the flow and profile routes will sit above the shell so they cover the bar, and arrive with the screens they show.

## `flutter/app/lib/src/use_smileid_sample_shell.dart`

**`class UseSmileIDSampleShell extends ConsumerWidget {`**

- It floats rather than sitting in `bottomNavigationBar`, which is R13.

## `flutter/app/lib/src/use_smileid_sample_version.dart`

**`const String useSmileIDSampleVersionLabel = 'Smile ID · 1.0.0';`**

- Written out rather than read from the bundle, because reading it needs a plugin and this is one string. A test pins it against `pubspec.yaml`, which is what stops the two drifting apart.

## `flutter/app/test/use_smileid_sample_states_test.dart`

**`void main() {`**

- A route and a screen that exist separately prove nothing about each other, which is how a component sat goldened and uncalled for eight months earlier in this port.

**`Future<void> tapRow(WidgetTester tester, Finder row) async {`**

- Stopping as soon as the row enters the viewport is not enough: the nav bar FLOATS over the list, so a row that has only just appeared is under it and the tap lands on the bar.

## `flutter/app/test/use_smileid_sample_test_id_call_sites_test.dart`

**`void main() {`**

- The spec test checks the other direction — that a declared id exists in `spec/`.
- It lives in the app rather than in `sample_ui` because the sheet ids are supplied by whichever host PRESENTS the sheet, so only a host sees both halves.

## `flutter/sample_ui/lib/src/components/use_smileid_sample_avatar.dart`

**`Color avatarColorForProfile(int profileIndex) =>`**

- Position, not a hash of the initials, which reproduces no design order and differs per platform.

## `flutter/sample_ui/lib/src/components/use_smileid_sample_bottom_sheet.dart`

**`Future<T?> showUseSmileIDSampleSheet<T>({`**

- The owning screen presents this and holds the boolean; a sheet is never a route of its own.

## `flutter/sample_ui/lib/src/components/use_smileid_sample_glyphs.dart`

**`abstract final class UseSmileIDSampleGlyphs {`**

- The two families are deliberately not interchangeable — `spec/components.json` → conventions. All decorative: the enclosing control supplies the label.

## `flutter/sample_ui/lib/src/components/use_smileid_sample_job_row.dart`

**`class UseSmileIDSampleJobRow extends StatelessWidget {`**

- Select mode's checkbox is not a slot — the design puts it beside the card, and inside it cost the title its width.

## `flutter/sample_ui/lib/src/components/use_smileid_sample_key_value_edit_row.dart`

**`class UseSmileIDSampleKeyValueEditRow extends StatefulWidget {`**

- The field NAME is title-coloured and only the PLACEHOLDER is muted; Android had that inverted.

## `flutter/sample_ui/lib/src/components/use_smileid_sample_nav_bar.dart`

**`class UseSmileIDSampleNavBar extends StatelessWidget {`**

- The bar FLOATS over the content: the list scrolls underneath it and the background stays continuous, so a screen's own trailing spacer is what lets its last row scroll clear.

**`double useSmileIDSampleNavBarClearance(BuildContext context) =>`**

- The bar is not a bottom-bar slot and insets nothing (R13).

## `flutter/sample_ui/lib/src/components/use_smileid_sample_option_row.dart`

**`class UseSmileIDSampleOptionRow extends StatelessWidget {`**

- An unselected row is TRANSPARENT over the sheet, not white; only the selected one takes a fill.

## `flutter/sample_ui/lib/src/components/use_smileid_sample_product_card.dart`

**`class _CardLabel extends StatelessWidget {`**

- The Compose twin steps the title down before wrapping, which Flutter cannot do here.

## `flutter/sample_ui/lib/src/components/use_smileid_sample_product_grid.dart`

**`class UseSmileIDSampleProductGrid extends StatelessWidget {`**

- Rows rather than a lazy grid, because the host screen already scrolls; each row takes its tallest card's height so a two-line title beside a one-line one still yields two equal cards.

## `flutter/sample_ui/lib/src/components/use_smileid_sample_profile_row.dart`

**`class UseSmileIDSampleProfileRow extends StatelessWidget {`**

- The avatar fill is the caller's to pass, and its default is the same value [UseSmileIDSampleAvatar] defaults to: two different defaults drew one profile navy in the list and blue in the summary.

## `flutter/sample_ui/lib/src/components/use_smileid_sample_scan_sheet.dart`

**`class UseSmileIDSampleScanSheet extends StatelessWidget {`**

- Simulate is a product feature, not scaffolding — it is how a flow reaches the session states with no QR source.

## `flutter/sample_ui/lib/src/components/use_smileid_sample_select_trigger.dart`

**`class UseSmileIDSampleSelectTrigger extends StatelessWidget {`**

- Disabled is load-bearing: the ID-type trigger stays greyed until a country is chosen.

## `flutter/sample_ui/lib/src/components/use_smileid_sample_selection_bar.dart`

**`class UseSmileIDSampleSelectionBar extends StatelessWidget {`**

- The action reads Hide from List, never Remove or Delete: the row is hidden from this app's list and nothing is deleted at the API.

## `flutter/sample_ui/lib/src/components/use_smileid_sample_session_card.dart`

**`class UseSmileIDSampleSessionCard extends StatelessWidget {`**

- [remaining] arrives formatted, because the deadline is absolute and the ticking is the screen's.

**`class _SessionSurface extends StatelessWidget {`**

- A flexible leading column, not a wrap: the card grows rather than the action sliding under the text.

## `flutter/sample_ui/lib/src/components/use_smileid_sample_swipe_action.dart`

**`class UseSmileIDSampleSwipeAction extends StatelessWidget {`**

- Labelled Hide, matching the selection bar — both paths hide the row from this app's list rather than deleting anything at the API.

## `flutter/sample_ui/lib/src/components/use_smileid_sample_toast.dart`

**`class UseSmileIDSampleToast extends StatelessWidget {`**

- Keeps the `sample_toast*` ids — the design node is named "toast", and renaming churns four apps.

## `flutter/sample_ui/lib/src/components/use_smileid_sample_top_app_bar.dart`

**`class UseSmileIDSampleTopAppBar extends StatelessWidget {`**

- The system back gesture stays the platform's regardless of this visual.

## `flutter/sample_ui/lib/src/data/use_smileid_sample_jobs_repository.dart`

**`abstract interface class UseSmileIDSampleJobsRepository {`**

- Read returns null for NOT LOADED YET, which is a third state and not an empty list.

**`List<UseSmileIDSampleJob> useSmileIDSampleJobFixtures(`**

- Five hours apart, so the eleven span three calendar day groups and the header's TODAY, YESTERDAY and dated forms are all exercised by one seeded launch.

## `flutter/sample_ui/lib/src/data/use_smileid_sample_settings_repository.dart`

**`abstract interface class UseSmileIDSampleSettingsRepository {`**

- The seam exists because this package runs under eight hosts.

**`abstract final class UseSmileIDSampleSettingsKeys {`**

- `enhanced_smart_selfie` is a NEW key, never the old one reused: `smile_to_capture = true` meant the opposite, so a reused key would read every upgraded install backwards.

## `flutter/sample_ui/lib/src/model/use_smileid_sample_job.dart`

**`String get createdAtLabel {`**

- UTC and not local, unlike the list's clock: a job id travels to support with its timestamp, and a local one cannot be compared against a server log without knowing the phone's zone.

**`bool? get httpSucceeded =>`**

- Null is neither: a job that never reached the API has no transport outcome to report, and colouring it red would accuse the server of refusing a request it never saw.

**`String? get refreshBlockedReason =>`**

- A fixture ran under no session, so it can never refresh — which is most of what this app has until the scanner lands, and the reason the affordance reports rather than fails silently.

**`enum UseSmileIDSampleJobFilter {`**

- There is no Processing chip, deliberately: a processing job is reachable only under All, and a port that adds a fourth chip has invented a filter the design does not have.

## `flutter/sample_ui/lib/src/model/use_smileid_sample_licenses.dart`

**`static Future<UseSmileIDSampleLicenses> bundled({`**

- The toolchain regenerates them from the resolved graph on every build, so unlike a committed asset they cannot go stale, and they already cover the engine's C++ dependencies.

## `flutter/sample_ui/lib/src/screens/use_smileid_sample_licenses_screen.dart`

**`class UseSmileIDSampleLicensesScreen extends StatefulWidget {`**

- A flat list rather than the rounded section cards the rest of the app uses: two hundred rows inside one card compose all of them at once.

## `flutter/sample_ui/lib/src/screens/use_smileid_sample_picker_sheets.dart`

**`class UseSmileIDSampleCountryPickerSheet extends StatefulWidget {`**

- The query is this sheet's own and resets on every open: a stale filter would hide the option a reader came back for.

## `flutter/sample_ui/lib/src/screens/use_smileid_sample_products_screen.dart`

**`class _Header extends StatelessWidget {`**

- The environment chip is deliberately absent — node 5447:1705 keeps it hidden, because the environment is a property of the session token and the result card is what publishes it.

## `flutter/sample_ui/lib/src/screens/use_smileid_sample_profile_config_screen.dart`

**`class UseSmileIDSampleProfileConfigScreen extends StatelessWidget {`**

- The title is the PROFILE'S NAME rather than a static heading, so a reader who arrived by deep link knows which profile they are editing.

## `flutter/sample_ui/lib/src/screens/use_smileid_sample_profile_sheets.dart`

**`class UseSmileIDSampleProfileSwitchSheet extends StatelessWidget {`**

- The selected row takes a fill and a check here, where the profiles LIST marks the active one in its caption instead — two surfaces, two conventions, both from the design.

## `flutter/sample_ui/lib/src/screens/use_smileid_sample_scenario_drawer.dart`

**`class UseSmileIDSampleScenarioDrawer extends StatelessWidget {`**

- A debug affordance the design does not cover, and a shipped feature rather than scaffolding: it is how a human and an automated flow both say what the environment should do.

## `flutter/sample_ui/lib/src/screens/use_smileid_sample_settings_screen.dart`

**`final bool opensInApp;`**

- Both legal pages wrap their document in an embedded PDF, which a mobile browser shows as a stub rather than the document, so those two hand off to the browser instead.

## `flutter/sample_ui/lib/src/screens/use_smileid_sample_user_details_screen.dart`

**`class UseSmileIDSampleUserDetailsScreen extends StatelessWidget {`**

- It opens EMPTY, including for a profile that has defaults saved: the twin asks for them every time rather than assuming, and `docs/plan/port-gaps-backlog.md` carries the open question.

## `flutter/sample_ui/lib/src/screens/use_smileid_sample_verification_details_screen.dart`

**`class UseSmileIDSampleVerificationDetailsScreen extends StatelessWidget {`**

- A missing job is a reachable state rather than an error: a deep link can name a job this build never stored, and the page says which id it looked for.

**`class UseSmileIDSampleJobLookup {`**

- A plain nullable cannot tell those apart, and the difference decides whether the page shows the empty state or nothing at all.

## `flutter/sample_ui/lib/src/screens/use_smileid_sample_verifications_screen.dart`

**`final int nowMillis;`**

- Midnight is what actually matters, so a caller ticking every second must round this down or the grouping is rebuilt sixty times a minute for a header that changes once a day.

**`class UseSmileIDSampleVerificationsScreen extends StatelessWidget {`**

- There is no app bar and no search field on this screen; the title is the list's first row and scrolls with it, which is what the design draws.

## `flutter/sample_ui/lib/src/state/use_smileid_sample_id_details.dart`

**`enum UseSmileIDSampleCountry {`**

- Hardcoded here rather than taken from the SDK or `spec/`: no spec file carries the table, and declaration order IS display order, so it is not alphabetical by accident.

## `flutter/sample_ui/lib/src/state/use_smileid_sample_profiles.dart`

**`enum UseSmileIDSampleUserField {`**

- The ids are camelCase because they suffix the test ids, and a device flow keys off those.

**`class UseSmileIDSampleProfiles {`**

- In memory, like the twin: profiles are not an account concern yet, so nothing here is persisted and a launch with no arguments starts from one empty starter.

## `flutter/sample_ui/lib/src/state/use_smileid_sample_settings.dart`

**`@immutable`**

- The capture mutex lives in [withSetting] and [normalised], not the constructor: a stored state can predate the rule, so refusing the pair here would crash an app that already saved it.

## `flutter/sample_ui/lib/src/state/use_smileid_sample_user_details_requirement.dart`

**`class UseSmileIDSampleUserDetailsRequirement {`**

- The default asks for everything, and that is the only shape reachable until a token session exists: a token that binds a field lifts its clause and disables its row.

**`String get prompt {`**

- This cannot answer that on its own: a requirement asking for three fields says so whether or not they have been typed, and only the screen holds what was typed.

## `flutter/sample_ui/lib/src/theme/use_smileid_sample_label_type.dart`

**`TextStyle useSmileIDSampleLabelStyle(TextStyle base) {`**

- Flutter's `height` is a RATIO of the font size where Compose's `lineHeight` is absolute, so raising the size from 10 to 11 would stretch the line box unless the ratio is recomputed.

## `flutter/sample_ui/lib/src/use_smileid_sample_test_ids.dart`

**`abstract final class UseSmileIDSampleTestIds {`**

- Ids a screen assigns per row arrive with that screen; these are the ones a component owns.

## `flutter/sample_ui/test/golden/golden_harness.dart`

**`Future<void> loadSampleFonts() async {`**

- Material Icons goes with them: without it the search field's glyph records as an empty box, and a baseline that cannot draw a mark is not coverage of it.

**`Future<void> Function(WidgetTester tester)? afterPump,`**

- A widget that holds its own state cannot be handed one, and lifting that state out so a golden can pose it would distort the component for the test's benefit.

**`typedef UseSmileIDSampleTextScaleFindings = ({`**

- What the text-scale pass found: text ellipsised where it could have wrapped, and words broken where the text offered no break.
- Returned rather than asserted so the rule itself is testable — `flutter_test` marks a test failed by a nested `expect` even when the caller catches it.

**`Future<void> assertSurvivesMaxTextScale(`**

- Flutter throws on a layout overflow by itself, so this adds the two it does not see: text ellipsised inside its own box, and a word broken where nothing offered a break.

**`bool _breaksCleanly(String text, int index) {`**

- Whitespace always offers one.

## `flutter/sample_ui/test/golden/golden_harness_test.dart`

**`void main() {`**

- Each narrowing was principled and each could have made it toothless, so both directions are asserted: what it must still catch, and what it must stop reporting.

## `flutter/sample_ui/test/golden/verification_details_golden_test.dart`

**`void main() {`**

- Timestamps are built in UTC and rendered in UTC, so the baselines are identical in any zone — the list's own goldens use local wall-clock components for the same reason.

## `flutter/sample_ui/test/golden/verifications_screen_golden_test.dart`

**`void main() {`**

- Every timestamp is built from LOCAL wall-clock components and rendered back to local ones.

## `flutter/sample_ui/test/spec/use_smileid_sample_golden_coverage_test.dart`

**`void main() {`**

- A coverage claim nobody checks drifts the moment a state is added to the spec, and the drift is invisible: the suite stays green because the missing state has no test to fail.

## `flutter/sample_ui/test/state/use_smileid_sample_top_app_bar_semantics_test.dart`

**`void main() {`**

- Found when the detail page became the app bar's first caller.

