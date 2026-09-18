# Flutter and Expo ports: an adversarial review

Read at `29c57d5` (`feat/expo-states-goldens`, PR 103) against `origin/main` at `2d9ba17` on
2026-09-18, by a reader from a different model lineage than the one that wrote the code and ran its
three prior review passes. The brief was to falsify: every conclusion below was assumed wrong until
the code said otherwise. Where a claim held, that is said in a line. The effort went where it did not.

What was checked: each claim in §1 against the code and the git history, by content rather than by
name; each pending plan in `docs/plan/` against the tree it describes; the tests the ports added, for
whether they can fail. What was not: nothing ran on a device or emulator, and no model outside this
one has read the code. `port-priority-cut.md` beside this file holds the ranked list; this file holds
the evidence. The verdicts describe the tree at `29c57d5`; the cut's items 1 to 5 were then applied on
this branch, and each "what to do" below that they cover is done.

## 1. Verdicts

### C1. The back crash is fixed and the fix is right: partially overturned

Upheld: three of the four routes threw, commit `826ff89` moves the four `onBack` handlers to explicit
`context.go` destinations, and those destinations are the majority behaviour. A cold link to
`/flow/x/id-details` sends back to the consent form on Android too (a deliberate `FlowGraph` ruling at
`docs/plan/navigation-hardening-android.md:179-184`) and on Expo; iOS is the outlier and pops to
Products. `spec/routes.json` and `spec/screens.json` carry no back or parent field, so there is no
written rule to break.

Overturned in two places.

- **The fourth route never crashed.** `/profiles/:profileId` is a child of `/profiles`
  (`flutter/app/lib/src/use_smileid_sample_routes.dart:194-202`), so its stack had two pages and `pop`
  worked. The regression test's doc comment says pop "threw on every one of them"; the findings doc
  correctly says three. The comment overclaims and should say so.
- **System back now exits the app from the same four routes.** Every navigation call in `flutter/` is
  `context.go` (13 calls, zero `push`), so each above-shell route is a one-page root stack, warm or
  cold. The only `PopScope` in the tree is the shell's (`use_smileid_sample_shell.dart:34`). go_router's
  `popRoute` returns false when no navigator can pop, and `WidgetsApp` then calls `SystemNavigator.pop`.
  Products, tap a card, press hardware back: the app closes, where the on-screen arrow goes to Products.
  The regression test (`flutter/app/test/use_smileid_sample_above_shell_back_test.dart`) calls
  `onBack()` directly and never exercises `handlePopRoute`, so it cannot see this.

Why the prior verification missed it: the probe reproduced the crash the reviewer named and stopped.
Nobody asked what the other back path did on the same routes.

What to do: a `PopScope` on each above-shell page that routes system back through the same `onBack`,
and a `handlePopRoute` row in the existing test, which then proves both paths land in one place. The
root cause is go-only navigation. Nesting `id-details` under `details` would give go_router a real
stack, and that restructuring belongs with the flow host, which adds `/run` to the same tree.

### C2. The `consumeRemoval` race was correctly rejected: upheld, for a different reason

The rejection stands. The store is bare zustand with no middleware
(`expo/sample-ui/src/data/use-smile-id-sample-job-store.ts:72`); the AsyncStorage write follows the
in-memory `set`. There is one consumer, in an effect rather than in render
(`expo/app/app/(tabs)/verifications.tsx:31-36`). StrictMode is enabled nowhere. Even with it on, the
second effect run re-reads the store and hits the `count === null` guard at :34.

"Synchronous, so safe" is true and not what protects the code. The safeguards are the single
consumer, consuming in an effect, and the null guard. The first two die on the first tab badge or the
first `await` added to the function; the guard survives both. The reasoning recorded in
`port-review-findings.md` §4 should name the guard, or the next reader takes "synchronous" as licence
to add a second consumer. No code change.

### C3. One unreadable row erases every Flutter verification: mechanism upheld, priority overstated

Mechanism: `_stored()` is one comprehension in one `try` returning `const []`
(`flutter/app/lib/src/data/use_smileid_sample_preferences_jobs_repository.dart:74-84`), and `fromJson`
has seven throwing expressions (`flutter/sample_ui/lib/src/model/use_smileid_sample_job.dart:23-29`).

Reachability today: none. The only writer is the repository's own `toJson`, which emits every key with
the right type. The schema and both enums have one commit each, dated 2026-09-17. Flutter is at
`1.0.0+1`, with no release, no CHANGELOG and no release plan. A bad row needs a hand-edited
preferences file or a future enum rename.

What `improve-port-store-restore-tolerance.md` misses:

- **Hide versus erase.** A read only hides rows; the blob is untouched. `remove` returns 0 and writes
  nothing when the store reads empty (:48-50). `seedFixtures` writes `[...stored, ...fixtures]` back
  (:28-37) and permanently replaces the blob with fixtures. The planned `add` will do the same on the
  first real verification after a bad row. That escalation is the reason to fix this, and the plan's
  "discards every stored verification on the next launch" describes only the read.
- **"Match Expo" creates a third behaviour.** Expo drops a row with an unknown product
  (`use-smile-id-sample-job.ts:33-49`); Android substitutes the first product or `Processing`
  (`UseSmileIDSampleJobEntity.kt:33-40`) and iOS does the same
  (`UseSmileIDSampleJobRecord.swift:72-73`). Substitute is the majority and the port-patterns rule.
- **Sequence.** Land it in the same change as `add`, whose first caller is the flow host. §4 argues why.

### C4. The Expo row test ids break the shared id contract: upheld, with the spec silent

3 against 1. Android (`VerificationsScreen.kt:130-133`), iOS (`VerificationsScreen.swift:223-237`) and
Flutter (`use_smileid_sample_verifications_screen.dart:100-106`) index the visible, day-flattened
list and say so in comments. Expo indexes the store
(`expo/sample-ui/src/screens/verifications-screen.tsx:170`). `spec/test-ids.json:109-111` says only
"suffixed with index" and never defines N. Expo's own test pins the divergent semantics
(`use-smile-id-sample-verifications.test.tsx:180-185`: tap the blocked chip, then press
`sample_selection_checkbox_${fixtures.indexOf(job)}`).

Unobservable today. All 13 Android Maestro hits are `sample_job_row_0` with no filter tapped. The iOS
XCUITest (`UseSmileIDSampleVerificationsUITests.swift:86-101`) and the Flutter widget test that filter
first assume visible indexing and pass on their own platforms. Expo has no device flows. Porting the iOS
"empty the active filter" test to Expo verbatim goes red.

Fix: `visible.indexOf(job)` at :170, the test at :183, and one sentence in the spec. Expo is the one
that is wrong, and the spec owed the sentence first.

### C5. The clearance formula is sound: overturned

The formula (`flutter/sample_ui/lib/src/components/use_smileid_sample_nav_bar.dart:300-304`) is
`40 + 58·s + viewPadding.bottom`. The 58 is the token's `minHeight` (:168-171), whose content is
`20 + 13.6·s` and stays under 58 through 2×. It does not grow with text. The element that does grow is
the pill label, a `Text` with no `maxLines`, `softWrap: false` or `overflow` (:284-290), so it wraps.
The bar's real height is `24 + vp + max(49 + L·16·s, 58)`, L being the label's line count. The formula
covers it only when `49 + 16·L·s ≤ 58·s + 16`: always for one line, above 1.27× for two lines, never
for three. It scales the one term that is constant and omits the one that varies.

Where the label wraps: the per-tab budget is `(W − 114)/3 − 16`. "Verifications" in DM Sans Bold at
10px is 63.0 wide (measured from `assets/fonts/DMSans-Bold.ttf`; kerning ignored). Flutter breaks an
over-wide single word at character boundaries.

| width | scale | lines | bar | formula | slack |
|---|---|---|---|---|---|
| 393 | 1.0 | 1 | 105 | 98 | +9 (matches `nav_bar_light.png`) |
| 393 | 1.3 | 2 | 114.6 | 115.4 | +0.8, inside the measurement error |
| 320 | 1.0 | 2 | 105 | 98 | **−7** |
| 320 | 1.75 | 3 | 157 | 141.5 | **−15.5** |
| 320 | 2.0 | 3 | 169 | 156 | **−13** |

At 320dp the last row sits under the bar at the default text size. 320 is inside the supported
envelope: the iOS 15 floor includes the first-generation iPhone SE, and Android's smallest phone
bucket is 320dp.

Why the test passes (`flutter/sample_ui/test/use_smileid_sample_nav_bar_clearance_test.dart`): it
pumps at the default 800-logical-pixel surface (212.7 per label, one line at every scale), never sets
`tester.view.physicalSize`, does not call `loadSampleFonts` so it measures the FlutterTest placeholder
rather than DM Sans, and replaces `MediaQuery` with a bare `MediaQueryData(textScaler:)` so
`viewPadding` is 0 on both sides of the inequality. The one-tab-root sweep the findings doc records
(#12) is immaterial: selection changes only tint. The text-scale predicate cannot see the wrap either:
`_midWordBreaks` in `golden_harness.dart` returns empty for any whitespace-free text, so
"Verifi / cations" is exempt. That is another instance of mechanism M1, a predicate narrowed until the
case is exempt, in the same file the findings doc already names for #8.

The siblings measure. Android: `Modifier.onSizeChanged { chrome.navBarHeight = ... }`
(`UseSmileIDSampleShell.kt:154-156`), consumed as `PaddingValues(bottom = navBarHeight + spacingMd)`.
iOS: `.safeAreaInset(edge: .bottom) { bar() }` (`UseSmileIDSampleStack.swift:14`), sized from the
laid-out bar. Expo has not mounted the pill, so it has no clearance problem yet. Flutter is the odd one
out and inconsistent with itself: Settings reserves `bottomInset` and a fixed `_navBarClearance = 96`
(`use_smileid_sample_settings_screen.dart:182,304,386`).

"Computed, pinned by a test" was convenience. Backlog decision 4 should be reversed. What to do, in
order: measure the bar from the shell and publish its height, as the twins do (parity, not a
divergence); do not cap the label to one line, since that ellipsises "Verifications" from about 1.3×
on a 393 device and the predicate forbids it; fix the test regardless, with the real font, 320 and 393
widths and non-zero insets; make `_midWordBreaks` flag whitespace-free words that break; delete the
duplicate 96.

### C6. Collapsing seven reviewed PRs into two was right: upheld on content, overstated on what was lost

By content. For each of PRs 91–97, the PR's own patch against its stack base was split into added
lines and every line tested for presence on `main`; misses were traced with `git log -S`; stack tops
were also diffed against the squash commits for #98 and #99. Nothing was lost: zero of 128 Flutter and
235 Expo test names, zero golden PNGs (main has 164 against the stacks' 84), zero `.snap` files, zero
spec or string content. The only content absent from `main` is about 90 lines of multi-paragraph
comment across 12 files, every one of which #98 or #99 carried into `main` and #102 later removed in a
reviewed trim.

The prior verification's method was unsound even though its conclusion was right. `gh`'s `files`
field caps at 100 entries, so a file-list comparison was blind to 148 of PR 91's 248 files and 11 of
PR 92's 111. It could not have found a loss in the files it never saw.

"Seven reviewed PRs" overstates it. #93 and #94 carried live approvals. #92's was dismissed by
GitHub's default base retarget when #89's branch was deleted, not by a stale-review setting. #91 and
#95 had bot suggestions only. #96 and #97 were never reviewed. The collapse discarded two approvals and
six bot suggestions. Its real cost is depth: #99 is a 28-commit, 318-file, +43k-line squash approved
once, which is necessarily shallower than per-tranche review. Serial PRs against `main`, which
#100–#102 then did (three approvals in 37 minutes, no collapse), avoided the choice without a repo
setting. §4 returns to this under Phase 0.

### C7. Relocating the doc comments improved the codebase: partially overturned

The mechanics hold exactly as claimed. Commit `00834b2` touched 60 Flutter files and two docs; it
removed 239 lines and added 2; every changed line is a `///` line; zero non-comment lines, zero blank
lines, zero `ignore` directives; 150 of 152 removed text lines appear verbatim in the rationale doc
and the other two became the kept one-liner; all 86 declaration anchors resolve in today's tree.

Three parts of the claim fail.

- **Expo was never touched.** Zero Expo files in the commit; the rationale doc mentions Expo zero
  times. Expo still carries 29 two-line inline runs.
- **Nine of 80 relocations dropped a load-bearing invariant** with nothing left at the code to carry
  it (strong: hunks 47, 50, 54, 59, 74; weaker: 05, 35, 52, 53). The worst is
  `use_smileid_sample_settings_repository.dart`, where "`enhanced_smart_selfie` is a NEW key, never
  the old one reused: `smile_to_capture = true` meant the opposite, so a reused key would read every
  upgraded install backwards" became "The head-turn challenge." AGENTS.md line 201 names exactly this
  case, "a value that must not change and why", as earning a comment at the code. The text-scale
  findings typedef in `golden_harness.dart` was truncated mid-list and now names one of the record's
  two fields, and the nested-`expect` trap that justifies the typedef's existence is gone from the
  code. The user-details screen lost "opens EMPTY, including for a profile with defaults saved", so a
  deliberate non-prefill now reads as an omission to fix. Two "deliberately absent" notes (the
  environment chip, the Processing chip) went the same way; a parity pass will add both back.
- **The link is one-way.** No code file references `port-comment-rationale.md`. Its anchors are
  pinned by no test and drift on the first rename. It is accurate today and a graveyard: 60 file
  headings, no topics, no decisions, reachable only by grepping a symbol. "Read on purpose" it is not.

Also: 40 two-line `///` blocks remain in `flutter/`, so the literal rule is still unmet; Android
carries 72 multi-line KDoc blocks in 54 files, untouched; and the four counts across the branch (67
blocks in 38 files, 74 in 57, 80 hunks in 60, 86 entries) were never reconciled.

What to do: restore five one-liners (hunks 47, 50, 54, 59, 74) and fix the typedef line, in PR 103.
Keep the doc; do not add 60 back-reference lines. Close the Android remainder and the 40 two-liners
unfixed: the rule already says to trim on the way past, and a retrospective pass over the originals
would repeat the mistake this one made.

### C8. The notice overlay needs no explicit left/right: upheld, fragile

In the Yoga vendored with RN 0.86.3 (`AbsoluteLayout.cpp`), an absolute child with no row-axis inset
falls through `alignAbsoluteChild` to flex-start, which is parent padding plus border, here 0; the
percentage width resolves against the parent's full width. The box is identical to `left: 0,
right: 0` today.

The correctness rests on the parent (`verifications.tsx:52`, `flex: 1`, no padding) having no
horizontal padding or border, not on `width: '100%'`. Add `paddingHorizontal` to the parent and the
child overflows right by that amount. "The same pattern is merged in profiles" proves nothing: both
copies share the assumption and would be wrong together. No test can see it, because jest has no
layout engine and Expo's baselines are style trees. A one-line hardening when next in the file.

## 2. The verification methods, attacked

Each row asks what would have made the check fail, and whether that was ruled out.

| Claim | How it was verified | What would have made it fail | Ruled out? |
|---|---|---|---|
| C1 crash fixed | Probe test against the real router, arrow `onBack()` | The other back path (system) on the same routes | No. Found exiting the app. |
| C1 "reproduced on all three routes" | Three routes probed | The fourth route in the same fix | No. It never threw; the test comment says it did. |
| C2 race rejected | Reasoning: synchronous | A second consumer, StrictMode, an `await` | Partly. The null guard is what rules them out, and it is not what the reasoning cites. |
| C3 erase | Reading the `try` | A writer that produces a bad row; a write-back after a bad read | No. Neither reachability nor hide-versus-erase was asked. |
| C4 id contract | Comparing Expo with Android's comment | The spec's own definition; iOS and Flutter; a flow that filters | Partly. iOS and Flutter were not read; the spec is silent. |
| C5 formula | Test sweeps five scales | The narrowest width, the real font, a non-zero inset, a wrapping label | No. The test fixes every one of those at the value where the formula is trivially true. |
| C6 no content lost | File lists compared | Content changed under a surviving name; files past `gh`'s 100 cap | No. 159 files were never listed. Content check now done, and nothing was lost. |
| C7 comments | Only `///` lines touched; tests green | A one-liner that no longer carries the invariant | No. Green tests cannot see a comment. Nine hunks read worse. |
| C8 overlay | "Host sets width 100%; same pattern merged" | A parent with padding | No. The argument was by analogy to a copy of itself. |

The pattern: seven of nine checks confirmed what they set out to confirm and stopped at the first
matching evidence. The two that found something (C1's probe, the count of green tests) found what
the reviewer had named, which is what a probe is for. The question that finds the rest is "what else
does this code do on the same input", and it was asked nowhere.

## 3. What no document on this branch records

### 3.1 PR 103 is red

The Expo `verify` job fails in 36 seconds at `expo-doctor`: six packages are one patch behind what the
Expo SDK now expects (`expo` 57.0.23 against ~57.0.24 and five siblings). `main` was green on this lane
yesterday and would be red today; Expo published the patches in between. The red is environmental,
and the gate is a time bomb: it consults the registry for "latest patch" and turns red on every PR
whenever upstream publishes. The PR body's "CI runs it in full here" is currently false.

Fix: run the dependency-version check in a scheduled job that opens a bump PR, and skip it in the PR
gate (`expo-doctor` reads an environment switch for that check; confirm the name against the
installed version). Keep the other 20 doctor checks in the gate.

### 3.2 Two gates are fail-open, and one of them has never run

`android.yml`, `flutter.yml`, `expo.yml` and `ios.yml` all check out the design system only
`if: env.DESIGN_SYSTEM_TOKEN != ''`, emit a `::warning` when skipped, and pass
`SMILE_TOKENS_OPTIONAL=1` so `sync_design_tokens.py --check` does not run. The job stays green. The
secret has never existed, so the drift check has never run on `main`, on any PR, ever. The same shape
appears inside `scripts/` unit tests: the CI log shows `skipped=1` for
`test_the_ramp_has_the_same_membership_as_the_compose_one` ("no design system on this machine").

`after-the-ports.md` Phase 0 says "create the secret". That is half the fix. The other half is that a
missing secret must fail on same-repo PRs and `main` pushes, and skip only on forks, or the next
rotation silently regresses to today. The existing memory of this repo already holds the rule: a
green no-op never proves the real lane ran.

### 3.3 Neither port has a device or emulator lane anywhere

Zero Maestro, Patrol, integration_test or Detox files under `flutter/` or `expo/`. CI runs
`flutter test` and jest. By contrast iOS runs `UseSmileIDSampleUITests` on a simulator in CI, and
Android has 15 Maestro flows that run against a local handset. Phase 3 of `after-the-ports.md` waits on
a locked physical handset for twelve behaviours none of which touch a camera. An Android emulator in
CI, or the iOS simulator on the macOS runner the iOS lane already uses, runs every one of them, and
the Flutter and Expo apps both build for iOS. Only the flow host needs a camera, and the SDK repos
already have a replay kit for that. See §5.

### 3.4 Expo's screen-state goldens are not what the PR titles say

PR 102 is titled "every state held to a baseline". On Flutter that is true and spec-driven
(`use_smileid_sample_golden_coverage_test.dart` reads `spec/screens.json`, asserts both directions,
requires the PNG, carries five written exemptions). On Expo it is not:

- **A fourth vacuity mechanism (M4): the baseline is invariant to the axis the test varies.**
  `use-smile-id-sample-verifications.test.tsx:65` poses `processing` with the default `fixtures[0]`,
  whose status is Clear (the Processing fixture is index 1). Both `verificationDetails processing`
  snapshots are byte-identical to `clear`, 27,420 bytes each. The comment above says "the badge and
  the message both move"; neither moves. In `use-smile-id-sample-font-scale.test.tsx:19-52`, 10 of 18
  "layout changes with the font scale" entries are byte-identical to their design-scale twins in
  other files, because the style-tree renderer does no text layout and only components that read
  `PixelRatio.getFontScale` can differ. Those 10 baselines prove nothing the design-scale ones do not,
  and the file sits outside the golden-pairs uniqueness check
  (`use-smile-id-sample-golden-pairs.test.ts:30-38` lists seven files, not this one).
- **Eight unrecorded M3 instances, one shape.** Every Expo golden suite ends with "records both
  schemes for every state" asserting `table.length × schemes.length === <literal>` (font-scale:109,
  composites:435, forms:192, primitives:152, screen-composites:177, profiles-screens:177,
  screens:130, verifications:140). The literal is a hand-typed count of the actual's own source.
  `screens.test.tsx:128` is named for "every state spec/screens.json lists" and never reads the spec:
  the spec lists settings {default, altProfile, newlyCreatedProfile}; the table records {default,
  withDebugSection, agentModeOn, consentBoundByToken}; the count is 20 either way. `verifications:140`
  passes at 18 with five spec list states absent (selectMode, itemsSelected, afterDelete,
  swipeToDelete, refreshing).
- Flutter's PNGs came out clean: 0 duplicates of 164, no orphans, every mapping name has a literal.

### 3.5 Factual errors in the existing docs and spec

- `port-gaps-backlog.md` §2 says the "declared id attached to nothing" check is owed by Android and
  iOS and "neither has this assertion today". iOS has it: `TestIdUsageTest` asserts every declared id
  is applied in source. Android does not. The improve index repeats the claim.
- `spec/README.md:73-77` says each app asserts the spec's ids are "present in its accessibility
  tree". No app checks a tree; iOS greps source, the other three check declaration lists.
- `spec/components.json` (65 KB) is consumed by nothing but comments in golden tests, on all four
  platforms. It is either informative or owed a check; today it is neither and reads as a contract.
- Flutter lacks `sample_license_link` (spec :301) and the `sample_scan_token_screen` root id; both
  pass because three of four id spec tests assert one direction only. The findings doc knows about
  the direction; it does not list these two.
- Backlog §3 says two shell ids are implemented by no app; the improve index adds `sample_env_chip`
  as a third. Both are right, and the list now lives in two places.

### 3.6 Improve plan 1 is stale against its own branch

`improve-expo-shell-wiring.md` says it surveyed the tree at `00834b2` and lists the removal
confirmation and Undo as reached by nothing in the shell; its "Current state" says
`(tabs)/verifications.tsx` "calls `remove` and nothing else" (line 47), and step 3 tells the executor
to wire the notice. Commits `1b199cf` and `67a6b2b`, three commits below `00834b2` on the same
branch, did exactly that (`verifications.tsx:14-46`). The plan's own first STOP condition, "the code
at any Current state excerpt does not match what you find", fires on the first excerpt an executor
checks. Steps 1, 2, 4, 5 and 6 still describe real gaps.

### 3.7 Housekeeping the branch should fix before it merges

- Commit `c1071e0` adds `port-gaps-backlog.md` under the subject "feat: wire the verifications undo
  to the transient notice". It cannot be fixed without a rewrite; note it in the PR.
- The PR body says "two planning docs come with it". The branch carries nine.
- `port-review-findings.md` says 57 findings; 31 + 25 is 56. It says twelve tests cannot fail and
  names eleven. The improve index inherits 57.
- The comment counts 67, 74, 80 and 86 name the same work in four documents.

## 4. The pending plans, argued with

### 4.1 The phasing is in the wrong order

`after-the-ports.md` runs settings, then rulings, then Android and iOS debt, then a device pass, then
the flow host. Three dependencies say otherwise.

**The flow host is the first caller for most of Phase 2 and all of plans 2 and 3.** The findings doc's
own third pattern is "wiring is the step that gets skipped: eleven affordances exist, are tested, and
reach nothing", and the backlog's own lesson is "a fixture that no caller uses proves only that the
fixture is self-consistent". `improve-flutter-job-store-contract.md` proposes building `add`, `find`,
`applyStatus`, `refresh`, a status-source seam and an outcome type with no caller, so that "when the
flow host lands, `addJob` is the only new store call it should need". That is the pattern the
document is warning about, applied to an API instead of a component. Build the store contract inside
the flow-host tranche, where its first caller shapes it and a device run proves it. The same holds for
plan 3, which fixes a write-back that only `add` and `seedFixtures` perform.

**Nothing in Flutter or Expo can harm a user until the flow host lands**, because neither app can run
a verification and neither is shipped. Every Flutter and Expo item in the findings doc is therefore
"blocks something" at most, and the thing most of them block is the flow host. Android and iOS are
shipped (Play internal testing, App Store review), so the Phase 2 items that touch them are the only
ones where "a user can be harmed" applies today. That is an argument for doing the two harm-bearing
Phase 2 items now and the rest of Phase 2 whenever, not for doing all of Phase 2 before the flow
host.

**Phase 3 is a lane, not a phase.** Twelve widget-tested behaviours wait on a handset that no adb
command unlocks, and none of them needs a camera. Stand up an emulator lane (§3.3) and they become a
CI job that also verifies the flow host's UI half. The handset is needed for capture only, and for
capture the SDK repos' replay kit removes even that.

Reordered: the branch's own fixes (§3.7, C1, C5, C7) → fail-closed gates (§3.2) and the doctor time
bomb (§3.1) → the emulator lane → the flow host on Flutter and Expo, with the job-store contract,
tolerance fix and status refresh built inside it → Expo shell wiring (plan 1, restated) → the two
harm-bearing Phase 2 items on Android and iOS → the rest of Phase 1 and 2 as convenient → the token
session. `port-priority-cut.md` carries this as buckets.

On **Phase 0's merge-commit setting**: the collapse cost two approvals, and `#100–#102` then showed
that serial PRs against `main` need no setting change. The recommendation to enable merge commits
changes the repo's history model for a problem the process rule already solved. It is an owner ruling,
not a Phase 0 setting, and the review recommends against raising it.

### 4.2 The Flutter job-store gap is sized right, and Expo's is undersized

"Flutter owns 4 of 8" is exactly right: `read`, `seedFixtures`, `remove`, `undoRemove`
(`use_smileid_sample_jobs_repository.dart:6-18`) against `add`, `find`, `applyStatus`, `refresh` on
Android (`UseSmileIDSampleJobStore.kt`), iOS (`UseSmileIDSampleJobStore.swift`) and Expo
(`use-smile-id-sample-job-store.ts:32-51`). Android and iOS also carry a six-case outcome type and a
real HTTP status source injected in the shell (`RetrofitJobStatusSource.kt`,
`UseSmileIDSampleStatusApi.swift`). Expo has the type and union and a stub that always answers
`noSession` (`(tabs)/verifications/[jobId].tsx:13-15`), and no HTTP source anywhere under `expo/`.
So "Expo swaps a stub" undersizes Expo: it is a stub swap plus an HTTP adapter plus the token session,
against Flutter's tranche plus the same two. Both are Phase 4 work. Neither should start before it.

### 4.3 What is missing from the plans entirely

Each of these is a capability nobody has proposed, as distinct from an item nobody has prioritised.

1. **An emulator or simulator lane for Flutter and Expo** (§3.3). It is the only thing that turns
   "device-verified" from a human with a phone into a check that runs on every PR, and its absence is
   why Phase 3 exists as a phase.
2. **A fail-closed rule for every skippable check** (§3.2). Any step that can skip must fail when its
   precondition is missing in a context where it should be present. Two instances exist today; the
   rule is one `if:` per workflow.
3. **A dead-export check.** Eleven affordances reach nothing, and every one was found by a reader
   grepping for callers. `knip` for the Expo workspace and `dart analyze`'s unused-code rules (or
   `dart_code_linter`) for Flutter find an exported symbol with zero call sites mechanically. Plan 4
   proposes id-attached and semantics checks; neither is this.
4. **A baseline-uniqueness rule** (§3.4 and §5.2). Thirty lines in a file that exists.
5. **A negative fixture for every parity and spec test.** The backlog records the tell ("delete the
   line it defends and confirm the test notices") as a habit. It has no mechanism. See §5.2.
6. **A single owner list for spec debt.** The two dead shell ids, `sample_env_chip`,
   `sample_license_link`, `components.json`, the licences-screen wording, the consent-form required
   fields and the button and glyph sizes are recorded across three documents and one allowlist. One
   table in `spec/README.md` with an owner and a date would replace all of them.

## 5. Staff work

### 5.1 The one structural change: slice vertically, and end every tranche at a flow that runs

The ports were built horizontally: twelve PRs of primitives, composites, screens, stores and forms, on
two platforms, before either app made a single SDK call. That ordering is the common cause of the
findings that matter most on this branch. Eleven affordances reach nothing because nothing needed
them yet. Flutter's store has four operations because nothing called the other four. The status
refresh reports the wrong message for a real row because no real row has ever existed. Twelve
behaviours have widget tests only because no flow ever ran. The 43k-line squash exists because the
stack grew wide before anything landed narrow. And the Expo notice shows a count with nothing to
count, because rows come from a flow the app cannot run.

The change: the next tranche is one product's journey, end to end, on one platform. Product tap →
form → SDK flow → result → stored row → list → detail → refresh, with the job-store operations, the
outcome type and the status source written because that journey calls them, and a Maestro or
integration_test flow that starts the app cold and walks the journey on an emulator as the tranche's
definition of done. The parity contract then follows a working slice instead of leading a set of
unwired parts, and the second platform ports a journey that has been seen to work rather than a set
of screens that have been seen to render. This is the after-the-ports document's Phase 4 with the
order inverted: the flow first, and the debt that the flow does not touch afterwards or never.

### 5.2 The test that should exist and does not

Twelve findings were tests that could not fail, by three mechanisms. This review found a fourth and a
fifth, and eight more instances of the third:

- **M4: the artefact cannot see the axis the test varies.** Expo's `processing` snapshot equals
  `clear`; ten enlarged-font snapshots equal their design-scale twins. The renderer or the fixture is
  blind to the dimension the test's name promises.
- **M5: the harness default selects the regime where the predicate is trivially true.** The
  clearance test runs at 800 wide with a placeholder font and zero insets. Every one of those defaults
  is the value at which the inequality holds for free.

The generic catcher for all five is a mutation gate ("break the line it defends; the test must go
red"), and this repo already states that as a habit. As a mechanism it costs a CI lane per platform,
and it is the right long-term answer for the spec and parity tests. Two cheaper checks catch M4 and M5
now and would have caught both live instances on their first run:

1. **Baseline uniqueness.** Generalise `use-smile-id-sample-golden-pairs.test.ts:117`, which already
   asserts "differs from the state it starts in" for six hand-listed pairs, into a rule over every
   suite: within one scheme no two entries may hash equal, and every font-scale entry must differ from
   its design-scale twin, unless named in the explained list with a reason. Flutter's golden coverage
   test already has the shape; the identical-pair trap is already in this machine's memory. Then
   replace the eight count literals with the Flutter coverage test's form: read the spec, take two set
   differences, write down each exemption.
2. **Envelope pumping.** Every layout predicate runs at the boundary of the supported envelope: the
   narrowest width the floor supports (320), the largest declared scale, the real font, a non-zero
   inset. A harness helper that supplies those four and a lint that a clearance or wrap test uses it.
   The clearance test would have failed at 320 and 1.0×.

The eight count literals are the cheapest fix of all and the most instructive: a test named for the
spec that never reads the spec is the shape every M3 instance shares.

### 5.3 Where the parity contract is the wrong tool

The after-the-ports document says the contract "held well: where the two disagreed it was because one
had a defect". That is true of the pixel layer the design specifies and false in six places the
contract is pushing together anyway.

- **Back-stack shape on a cold deep link.** Android synthesises a parent stack; iOS uses per-tab
  ownership; the ports chose Android's and listed iOS as owing a change. Stack shape is a platform
  idiom: iOS has edge-swipe and no system back button, Android has predictive back. Specify where back
  *lands*, which the spec does not do today, and let each platform build the stack its users expect.
- **Nav-bar clearance.** Android and iOS measure; Flutter computed because a formula could be pinned
  by a test. The contract is on the outcome (content clears the bar), not the method. C5 shows what
  happens when the method is treated as the contract.
- **Text-scale ceiling.** `maxTextScale` is one number across four platforms. Android's font scale
  stops near 2× and is non-linear from 14; iOS Dynamic Type's accessibility sizes run past 3×. The
  backlog already records "3× still fails". A shared ceiling that iOS exceeds is a parity artefact,
  not a design decision; declare it per platform.
- **Partial sheets.** Flutter's two pickers are partial sheets against a spec that says `fullSheet`.
  Before "aligning", check why the spec says so: the iOS 15 floor has no `presentationDetents`, so
  full sheets may be a floor constraint that leaked into the spec. If it is, Flutter's partial sheet
  is the better UX and the spec owes the reason, not Flutter the change.
- **The licences screen.** Already recorded correctly in the backlog: the spec describes Android's
  classpath, and two platforms cannot follow it.
- **Persistence tolerance.** Expo drops, Android and iOS substitute, and plan 3 would make Flutter a
  copy of Expo. Pick the majority once and write it into `port-patterns.md`, rather than letting each
  port copy whichever sibling it was ported from.

## 6. What this review could not check

- Nothing ran on a device, emulator or simulator. C1's system-back exit and C5's 320dp underflow are
  derived from the framework's source and measured font metrics, not observed. Both are cheap to
  observe once an emulator lane exists, and both should be.
- No test suite ran in the review worktree, which has no `.dart_tool` or `node_modules`. Every
  "would fail" and "cannot fail" statement is from reading the test against the code.
- Whether `DESIGN_SYSTEM_TOKEN` is configured on the repository. Only its use is visible; its absence
  is inferred from the branch's own statement and the skip in every log read.
- Branch protection on the repository returned 404, so whether stale-review dismissal is also on is
  unknown. The dismissals observed came from base retargeting.
- How deep the single approvals on #98 and #99 went.
- Whether any Flutter debug build has reached a tester's phone. Inferred unshipped from the version,
  the absence of a CHANGELOG or release plan, and the dates.
- Three of the C1, C3 and C4 sibling comparisons were read once each by a single investigator. The
  Android and iOS line references were spot-checked, not re-derived.
