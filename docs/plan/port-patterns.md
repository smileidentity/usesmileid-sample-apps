# Porting the Android template — the patterns, per platform

The Android app is the reference implementation the iOS, Flutter and Expo apps mirror
(AGENTS.md: same screen, same file name, same relative folder). Most of what a port needs it
gets for free by mirroring the tree. This document records the part that does **not** transfer
by copying: the patterns the Android code encodes, what each one translates to per platform,
and the semantic rules a port must hold even where the idiom differs. Read it before starting
a port; treat a divergence from it the way a spec divergence is treated — explained in the PR
or fixed.

## 1. Inherited by mirroring the tree

File names are the unit ports mirror, so the current Android inventory is the contract:

- Every spec screen has its own file, including the sheets (`NewProfileSheet`,
  `ProfileSwitchSheet`, `IdTypePickerSheet`) — but a sheet file is a **layer**, not a route. See
  §2's sheet row before wiring one.
- Routes live in per-area destination files (Products / Verifications / Settings / FlowForm /
  Profile / Token / Dev), and the flow-journey policy (`FlowJourney`) is a separate unit from
  nav plumbing. The five sheet paths in `spec/routes.json` are **not** among those destinations.
- The flow-launch logic is four units: the snapshot, the builder config ("the one place that
  decides what the SDK is handed"), the preflight gate, and the token-binding rules.
- Domain enums live in `model/`, never inside component files; the persistence layer lives in
  `data/`, separate from the `state/` holders. The dependency direction is one-way:
  components may import model, never the reverse.
- Shared components exist once: the labelled section surface, the transient-notice host, the
  setting-row divider. A port that hand-rolls a second copy of any of these has diverged.

## 2. The translation table

| Pattern | Android (template) | iOS | Flutter | Expo |
|---|---|---|---|---|
| Network seam: interface in the shared UI library, adapter in the shell | Kotlin interface + Retrofit adapter | protocol + URLSession adapter | abstract class + shell impl | TS interface + fetch adapter |
| Screen-level UI state: a plain holder class beside the screen — never a ViewModel-equivalent | class + `remember`/`rememberSaveable` | `ObservableObject` + `@Published` | notifier / plain class | hook |
| Removal notice: a consume-once, buffered event | `Channel(BUFFERED)` exposed as a Flow | buffered single-consumer `AsyncStream` | single-subscription `Stream` | emitter with a queued backlog |
| "Not loaded yet" is not "empty" | nullable list, null until the first store emission | `Optional` | nullable | `T[] \| null` |
| Bottom-chrome clearance | measured chrome height via `contentPadding` | real safe-area/chrome insets | ditto | ditto |
| List derivations recompute on data change, never on a clock tick | `remember(keys)` + one coarse `derivedStateOf` day-bucket | computed + `onChange` | `select` | `useMemo` |
| **A sheet is a layer over the screen that owns it, never a destination** (R12) | boolean the owner holds + `ModalBottomSheet`, removed from composition when hidden | `.sheet(isPresented:)` on the owning view | `showModalBottomSheet` from the owning route | owner-held state + the platform sheet |
| **A sheet's deep link resolves to its OWNER's link plus a sheet request** | `UseSmileIDSampleSheetLinks` maps path → owner URI + enum; owner consumes it | same mapping, presenting view consumes | ditto | ditto |

Insets and presentation stay platform-native (AGENTS.md) — the clearance rule translates as
"derive from the platform's measured chrome", not as copying any constant.

**The iOS column is written to the iOS 15 floor**, which `sample-apps-plan.md` §9.1 settled by
measurement: `SampleUI` above it cannot be consumed by the SDK repo's iOS 15.0 Sample, which deletes
the compile-against-HEAD gate the two-consumer split exists to provide. So the state row reads
`ObservableObject` + `@Published` and not `@Observable`, and navigation is `NavigationView` with
`.navigationViewStyle(.stack)` rather than `NavigationStack`. These are the SDK's own documented
iOS-15 exceptions, not a downgrade to fix later. One consequence a port meets on its first two-level
link: that idiom drops a push made while another is in flight, so the iOS router lands a linked path
one level per finished transition, unanimated (`ios-port-hardening.md` §7).

**The two sheet rows are the one place a literal mirror of the tree gives the wrong answer.**
Android shipped every sheet as a `@Destination`, so the navigation host replaced the screen
underneath and the sheet's scrim covered a flat grey void; it was fixed on 2026-08-26. iOS,
Flutter and React Native present sheets over the presenter by construction, so they should be
**checked, not changed** — the risk is a port copying Android's old file layout and re-creating a
routed sheet where the platform already does the right thing. One caution for whoever checks:
a device flow cannot assert what is behind a modal, because Android drops the windows below one
from the accessibility tree. A screenshot is the only evidence.

**That caution is Android's alone.** iOS keeps the presenter's ids queryable behind a presented
sheet, so `testASheetLinkOpensThePickerOverItsOwner` asserts both halves — the sheet is up and its
owner is open underneath — with no screenshot. Proven by stopping the link from opening the owner
and watching the second assertion fail. Whoever ports the sheets to Flutter or Expo should check
which of the two their platform behaves like rather than assume Android's limitation travels.

## 3. Semantic rules the idioms must preserve

1. **A refresh reads the row, never the current toggle.** The environment and session a job
   was submitted under are recorded on its row; a status refresh uses those. A row submitted
   under a different session reports a session-mismatch outcome instead of sending the other
   session's credential. The outcome labels are product strings and stay identical across the
   four apps.
2. **The status write is atomic and honest about deletion.** One update statement, reporting
   whether a row still existed — a delete landing mid-refresh must win, never resurrect the
   row. No find-then-write pair.
3. **Writes outlive the screen that launched them.** A result the SDK delivers exactly once
   must persist even if the user rotates or navigates at that instant; the write path runs on
   a process-lifetime scope. Reads and refreshes stay screen-scoped so leaving cancels them.
   Corollary: any in-flight guard the refresh holds must release even when the caller was
   cancelled — a cancelled coroutine/task skipping its cleanup leaves the row silently
   unrefreshable.
4. **Store the code, render the text.** `httpStatus` persists as the integer; "200 OK" is
   composed where the row is drawn. No display strings in the data layer.
5. **Restored identifiers fall back, never throw.** An enum id read back from persistence or
   saved UI state resolves by lookup with a safe default; a rename must not crash a restore.
6. **One screen-state shape.** A screen takes one state value plus callbacks — no flat
   parameter lists. Each holder documents, per field, what survives recreation (Android:
   `rememberSaveable`; iOS: scene restoration; Flutter: `RestorationMixin`; Expo: navigation
   state). That written policy is part of the template, not decoration.
7. **The data layer draws nothing.** No UI-framework state types inside stores; confirmations
   cross to the UI as events, and one shared transient-notice host renders them.
8. **Fixture data arrives by launch argument, never by default.** A store's constructor default
   is what a partner sees on a fresh install, so it carries no example anything: the profile
   store starts as one empty `Default profile` and the job store starts empty. The design's
   fixtures are reached through `seedJobs` and `seedProfiles` from `spec/launch-args.json`, and
   a unit test on each platform asserts both the plain default and the launch choice. Profiles
   are in memory, so that argument is per launch and a cold start by link shows the starter.
   Why the rule exists: `play-release-android.md` §7.4.

## 4. Discipline that travels

- Comments are one-line constraint statements. Dependency declarations carry no explainer
  comments; version-pin *rationales* on each manifest (Gradle catalog, Podfile/Package.swift,
  pubspec, package.json) are kept, one line each — deleting them silently unpins.
- The public state machinery a partner copies (token decoding, the persistence layer, the
  stores' remove/undo contract) ships documented in the platform's doc-comment idiom.

**Copy and API deliberately disagree here.** The store methods are `remove`/`undoRemove` and the
test ids are `sample_selection_remove`/`sample_details_delete`, but every user-facing label says
**Hide** — "Hide from List", "Hide", and "N verifications hidden from App list". The rows are
hidden from this app's list and nothing is deleted at the API, so the copy says so. Port the copy
and the ids exactly as they are: renaming either half breaks a four-platform contract or re-tells
the lie.
- After each port lands, re-run a correctness/security/perf/tests pass against it: the bug
  classes the template's audit caught — concurrency seams around new persistence — are exactly
  what a fresh port re-introduces.

## 5. Session mismatch — the guard matches on partner, not session

Confirmed against the sandbox: the status endpoint is token-agnostic **within** an environment
(a different session token of the same environment reads the job fine) and rejects
cross-environment reads (401). The apps' local session-mismatch outcome was therefore stricter
than the server.

**Owner ruling 2026-08-27: refresh when the partner ids match.** A token always carries a
`partner_id`, and tokens expire — so a person legitimately holds a *new* session for the same
partner and must still be able to refresh the rows an earlier session created. Matching on the
session made every expiry silently orphan its own rows.

**Built on Android 2026-08-28**, so a port mirrors what ships rather than the guard it replaced: the
row carries `partnerId` (schema v3), the guard compares that, and the outcome is `PartnerMismatch` —
"Submitted by a different partner".

What that costs, and what every port inherits:

- **The row has to store the partner.** The session carries `partnerId` from its own claim; the
  row stored only `sessionId`. Persisting it is a schema change, not a predicate change.
- **The outcome is renamed.** "Submitted under a different token session" describes the rule
  that is going away; the row now reports a different *partner*.
- **Cross-environment reads stop being pre-empted.** The request already uses the row's own
  environment, so a mismatched pair now gets the server's real 401 instead of a local refusal.
  The app no longer answers a question the server is willing to answer.
- **Fixture rows are untouched.** They persist no session at all and return "never submitted"
  before any of this is reached.
