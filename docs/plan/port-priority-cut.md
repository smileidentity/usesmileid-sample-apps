# Port work after the review: the cut

This is the ranked list from `port-adversarial-review.md`. It puts every item on this branch into one
of three buckets and marks the cut line: the review's own findings, the 56 recorded in
`port-review-findings.md`, the five phases of `after-the-ports.md`, and the four `improve-*.md` plans.
Where it disagrees with an order those documents give, §5 says so and gives the replacement rather
than a parallel list.

**The rule the ranking follows.** An item is *do first* if it blocks something or a user can be
harmed by it; *do when convenient* if it is real and nothing waits on it; *close unfixed* if the cost
of doing it exceeds what it buys, with the reason written so nobody re-raises it. Two facts shape the
buckets more than anything else:

- **Neither Flutter nor Expo is shipped, and neither can run a verification.** Nothing in either app
  can harm a user today. Every Flutter and Expo item is therefore ranked by what it blocks, and the
  thing most of them block is the flow host.
- **Android is live on Play internal testing and iOS is in App Store review.** Those are the only
  places where "a user can be harmed" applies now.

Twelve items sit above the line. Roughly forty sit below it, and eighteen should never be done.

**Status, 2026-09-18.** Items 1 to 5 landed on this branch: `9c33b16` (the doctor gate), `a90bf69`
(the processing baseline and the twin rule), `213dc7e` (system back), `befc6f7` (the five one-liners)
and the two docs commits after them. Items 6 to 12 are open.

## 1. Do first

In order. Items 1 to 5 land on PR 103 before it merges; the branch is already held open for this.

| # | Item | Why it is above the line | Size | Source |
|---|---|---|---|---|
| 1 | **Make PR 103's Expo lane green.** Move `expo-doctor`'s dependency-version check to a scheduled job that opens a bump PR; skip that one check in the PR gate and keep the other twenty. | The branch cannot merge red, and the gate turns red on every PR whenever Expo publishes a patch. `main` would be red today. | S | review §3.1 |
| 2 | **Flutter: system back must not exit the app on the four above-shell routes.** A `PopScope` per page routing through the same `onBack`; a `handlePopRoute` row in `use_smileid_sample_above_shell_back_test.dart`; fix the test comment that says pop threw on all four. | The fix on this branch repaired the arrow and left hardware back closing the app from Products → card. Same code, same PR. | S | C1 |
| 3 | **Restore the five load-bearing one-liners** (hunks 47, 50, 54, 59, 74 of `00834b2`) and the truncated typedef line in `golden_harness.dart`. | The settings-key never-reuse rule and two "deliberately absent" notes are gone from the code; a parity pass will undo each. AGENTS.md itself says these earn a line at the code. | S | C7 |
| 4 | **Expo baselines: fix the `processing` fixture (index 1), generalise the golden-pairs uniqueness check to every suite and axis, port Flutter's spec-driven coverage test and delete the eight count literals.** | Two Expo details states share one baseline; ten font-scale baselines equal their design-scale twins; five spec'd verifications states have no baseline; every Expo golden suite's coverage assertion is a hand-typed count. "Every state held to a baseline" is false on Expo until this lands. | S–M | review §3.4, §5.2 |
| 5 | **Fix the branch's own docs.** C2's recorded reason names the null guard; counts become 56, 11 and one comment number; the PR body lists nine docs; plan 1 marks step 3 done and restates its Current state; the backlog stops saying iOS lacks the id-attached check; `spec/README.md` stops claiming an accessibility-tree assertion. Note `c1071e0`'s wrong subject in the PR. | These documents are the record the next tranche reads. Four of them contradict the tree or each other today. | S | review §3.5–3.7 |
| 6 | **Make the skippable gates fail closed, then create `DESIGN_SYSTEM_TOKEN`.** A missing secret fails on same-repo PRs and `main` pushes and skips only on forks; the Python emitter test's skip follows the same rule. | The drift check has never run. Creating the secret alone means the next rotation silently returns to today. Minutes. | S | Phase 0 item 2, amended |
| 7 | **LANDED (#104).** **Flutter nav-bar clearance: measure the bar from the shell, as Android and iOS do.** Publish its laid-out height; consume it plus `spacingMd` in the three tabs; delete the fixed 96 in Settings; fix the test to pump at 320 and 393 with the real font and non-zero insets; make `_midWordBreaks` flag whitespace-free words and make the `truncated` half of the same predicate able to fire. | The last row sits under the bar at 320dp at default text size, and the test cannot see it. Expo's nav-bar mount (item 10) will copy whatever Flutter does, so fix it before it is copied. Reverses backlog decision 4. | S–M | C5; findings 8, 12 |
| 8 | **Stand up an emulator or simulator lane for Flutter and Expo in CI.** Android emulator on the ubuntu runner, or the iOS simulator on the macOS runner the iOS lane already uses; Maestro or `integration_test` for Flutter, Maestro or Detox for Expo. The twelve widget-tested behaviours become its first flows. | Neither port has a single device flow. Phase 3 waits on a locked handset for behaviours none of which need a camera. Nothing after this item can be called verified without it. | M | review §3.3; Phase 3 recast |
| 9 | **The flow host on Flutter and Expo, as one product's journey end to end, with the job-store contract built inside it.** Product tap → form → SDK flow → result → stored row → list → detail → refresh. Plan 2's four operations, seam and outcome type, plan 3's tolerance fix (substitute, the majority), the wrong-message fallthrough and the never-withdrawn refresh notice are written because this journey calls them, and a cold-start flow in item 8's lane is the definition of done. Restructure Flutter's above-shell routes into a real stack while `/run` is added to the tree. | It is the rest of the port, and the first caller for everything plans 2 and 3 would otherwise build unwired. See review §4.1 and §5.1. | L | Phase 4 first half; plans 2, 3 |
| 10 | **Expo shell wiring, restated** (plan 1 without step 3): shell test lane, `seedJobs` at cold start, Dark Mode drives the theme, `noticeWindow`, mount the floating nav bar with the clearance from item 7. Add `expo-router/testing-library` in step 1; it is a dev dependency, not a ruling. | Seeding is how the lane gets deterministic rows; the dark-mode switch is a user-visible control that does nothing; the designed nav bar is mounted zero times. All precede any Expo device flow. | M | findings 6, 7, 10; plan 1 |
| 11 | **Android and iOS: rule on the active-profile edit, then fix it.** Either a second always-enabled Save or a CTA that changes meaning when the profile is active. | A user edits the active profile, the only button is disabled, and the edit is dropped on leaving. Shipped on Android, in review on iOS. The one Phase 1 ruling with harm attached. | S after the ruling | Phase 1; backlog §4 |
| 12 | **Android and iOS: run the app-bar semantics predicate, fix if red.** The three assertions in backlog §7, as a test on each platform. | The only Phase 2 item a user can be harmed by (a screen reader cannot reach the title or the back control separately), on shipped apps, and no pixel changes so no baseline can find it. The test is cheap; the fix, if needed, is a line. | S | Phase 2 first item |

**The cut line is here.** Everything below is real and nothing waits on it.

## 2. Do when convenient

Grouped by what they share. Within a group, order does not matter.

**Spec and contract.**

- `sample_job_row_N`: Expo indexes the visible list (`verifications-screen.tsx:170`), the test at
  :183 follows, and `spec/test-ids.json` gains the sentence "N is the position in the visible,
  day-flattened list". Before any Expo flow that filters. (C4; finding 4)
- Id spec tests assert both directions on Android and Flutter; Android gains the id-attached check
  Flutter and iOS already have; Expo's nine unreached ids from plan 4 get a ruling each. (Phase 2;
  backlog §2 corrected; plan 4)
- One owner table in `spec/README.md` for spec debt, replacing the entries spread across three docs
  and an allowlist: the two shell ids, `sample_env_chip`, `sample_license_link`, the licences-screen
  wording, the consent form's required contact, button 48 against 52, glyph 21 against 20,
  `screens.json:456` against :683, and whether `components.json` is informative or owed a check.
  (Phase 1 items 3 and 4; backlog §3; review §3.5, §4.3)
- A dead-export check: `knip` on the Expo workspace, unused-code rules on Flutter. (review §4.3)
- An envelope-pumping helper for layout predicates: narrowest width, largest scale, real font,
  non-zero inset. (review §5.2)

**Android and iOS, shipped and cosmetic or unverified.**

- The literal backticks in "Tap `Hide from List` to confirm", both platforms; baselines move.
- The job row's secondary line takes the board's caption on Android; row height moves.
- iOS ink: check the 12 differing colours against WCAG AA first; fix the function only if one fails.
- `UseSmileIDSampleStatusBadge` doc comment on Android, one line.

**Flutter and Expo, before either ships.** User-visible controls that do nothing, and divergences.

- Sign out is a no-op on Expo and inert on Flutter; four Settings rows carrying a URL do nothing; the
  Expo detail page's copy buttons are wired to a no-op. (finding 5; §3 built-never-wired)
- The DEBUG section ships in release builds on Flutter only.
- Expo's empty-state copy diverges from all three siblings; four Expo weight overrides bypass
  `atWeight`; Flutter's pickers are partial sheets against `fullSheet`, once the spec's reason is
  known (review §5.3).
- Cold start: a cold deep link paints the empty state first on Flutter and never loads the store on
  Expo; the profile store resets twice when the cold-start URL resolves; the settings store's `loaded`
  flag is never read. Item 8's flows start cold and will exercise all four.
- `WidgetRef` used across an await after navigation; AsyncStorage failures unhandled; `continueEnabled`
  ignores the test id it is given; the wrapped profile-row layout drops the selected check.
- Two sources of truth for the same four field labels, already disagreeing. The one duplication worth
  fixing.
- The nine asserted tests that cannot fail: fix each so it reds on the defect it names, or delete it.
  Deleting is acceptable. (§3 tests-that-cannot-fail)
- Rulings that shape the flow host's inputs, decided while item 9 is in flight rather than before
  it: whether profile defaults seed the job form, and whether "remember these details" remembers
  anything. (Phase 1)
- The notice overlay's `width: '100%'` becomes `left: 0, right: 0`, one line, when next in the file.
  (C8)

## 3. Close unfixed

Each with the reason, so it is not raised again.

| Item | Reason |
|---|---|
| **Allow merge commits** (Phase 0 item 1) | The collapse cost two live approvals, not seven. PRs #100–#102 then landed serially against `main` with three approvals in 37 minutes and no setting change. The process rule already in `after-the-ports.md` solved the problem; changing the history model for it is an owner ruling to raise only if stacks return. |
| **Finding 11's remainder**: Android's 72 multi-line KDoc blocks, Flutter's 40 two-line `///`, Expo's 29 two-line runs | AGENTS.md already says to trim on the way past. A retrospective pass over the originals would repeat what C7 found: nine invariants dropped for a rule met literally. |
| **The `consumeRemoval` race** and its reverted fix | Rejection stands; the null guard rules out every variant including StrictMode. Item 5 records the right reason. |
| **Duplication**: eleven inline radii, `FontWeight.values[...]` in four places, the controller-sync block in three widgets, the avatar hue formula, the re-typed trademark | No observable effect and two-day-old code. Fix the one that already disagrees (the field labels, above); revisit the rest only when the duplicated value changes. |
| **Performance**: the verifications list builds every row eagerly and scans the job list five times per build; the licences screen mounts 74 rows and their SVGs | A sample app with tens of rows. Measure on a device in item 8's lane before touching either. |
| **`isComplete` as a second completeness rule** only a test exercises; **the memory store breaks the `read()` ordering contract** the real store honours | Neither is on a production path. Delete the test-only rule and align the double when next in the file, or leave them. |
| **Nine scenario description strings unread and drifted**; **two token-ring exports with no consumers**; **`UseSmileIDSampleStatus.role` read by no production code** | Dead data drifts by definition. Delete the strings rather than wire them. The ring exports and `role` belong to the token session and are closed until it lands. |
| **Finding 12**: the clearance test sweeps one tab root | Superseded by item 7. Selection changes only tint, so the sweep was immaterial to height. |
| **Phase 3 as a phase** | Superseded by item 8. Twelve behaviours become flows in a lane, not a pass on a handset. |
| **Plans 2 and 3 as standalone plans** | Folded into item 9. Building a store contract with no caller is the pattern `port-review-findings.md` §5 warns about. |
| **The two shell ids and `sample_env_chip`** as separate items | Into the owner table above. Decide after item 9 shows whether a nested launch exists. |
| **Expo recording style trees rather than pixels** | The improve index already rejects this correctly. Item 8's lane is where layout outcomes get seen on Expo; the style trees stay for what they can see. |
| **The component gallery on two of four platforms** | Not a four-way contract. A product call, not a defect. |
| **iOS as the "outlier" on cold-link back-stack shape** (backlog decision 3, §2) | Stack shape is a platform idiom. Specify where back lands; let iOS build the stack iOS users expect. Review §5.3. |
| **A shared `maxTextScale` for all four platforms** | iOS Dynamic Type exceeds it; the backlog already says 3× fails. Declare the ceiling per platform rather than pinning iOS to Android's. Review §5.3. |

## 4. What the buckets say about the 56

Of the findings doc's 56: three were fixed on this branch and two of those need the follow-ups in
items 2 and 5. Nine are verified open; four of them are above the line (as parts of items 4, 7, 10,
12), three are below it, one is superseded and one is closed. Of the 39 asserted, nineteen are below
the line grouped by what they share, and the rest are closed with reasons in §3. Two were rejected and
stay rejected, one with corrected reasoning. Most of the list should not be done, and the list now
says which.

## 5. Reorderings against the existing documents

**`after-the-ports.md`.** Phase 0 item 1 is closed; item 2 becomes item 6 here, amended to fail
closed. Phase 1's active-profile ruling is item 11; its profile-defaults and remember-switch rulings
move into item 9's flight; the button, glyph and shell-id questions go to the owner table; the
`expo-router/testing-library` question is not a ruling and goes into item 10. Phase 2's app-bar check
is item 12 and the rest of Phase 2 is below the line. Phase 3 is replaced by item 8. Phase 4's flow
host moves ahead of Phases 2 and 3 as item 9, and absorbs plans 2 and 3; the token session follows
it as before. The sequencing rules at the end of that document stand, with one addition: a tranche
ends at a flow that runs cold in the lane.

**`port-review-findings.md` §2, "highest value first".** That order is 4, 5, 6, 7, 8, 9, 10, 11, 12.
By harm and blocking it is: 9's twins (item 12), then 6, 7 and 10 together (item 10), then 8 with 12
(item 7), then 4 and 5 below the line, then 11 closed for the originals. §4's `consumeRemoval`
reasoning is corrected in item 5; its overlay rejection stands with the fragility noted.

**`improve-plans-index.md`.** Plan 1 stays P1 with step 3 removed and its Current state restated.
Plans 2 and 3 are not run as plans; their steps become part of item 9's tranche, with plan 3's
behaviour changed from "match Expo" to "substitute, as Android and iOS do". Plan 4 drops to below the
line, with its iOS claim corrected. The index's "Findings considered and rejected" all stand.

**`port-gaps-backlog.md`.** Decision 4 (compute the clearance) is reversed by item 7. Decision 3's
"iOS is the outlier" is closed as a legitimate divergence. §2's "neither has this assertion today" is
corrected in item 5. Decision 8 (collapse the stack) stands on the evidence, with the cost restated as
two approvals and one shallow review rather than seven.
