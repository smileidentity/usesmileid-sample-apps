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
| Screen-level UI state: a plain holder class beside the screen — never a ViewModel-equivalent | class + `remember`/`rememberSaveable` | `@Observable` class | notifier / plain class | hook |
| Removal notice: a consume-once, buffered event | `Channel(BUFFERED)` exposed as a Flow | buffered single-consumer `AsyncStream` | single-subscription `Stream` | emitter with a queued backlog |
| "Not loaded yet" is not "empty" | nullable list, null until the first store emission | `Optional` | nullable | `T[] \| null` |
| Bottom-chrome clearance | measured chrome height via `contentPadding` | real safe-area/chrome insets | ditto | ditto |
| List derivations recompute on data change, never on a clock tick | `remember(keys)` + one coarse `derivedStateOf` day-bucket | computed + `onChange` | `select` | `useMemo` |
| **A sheet is a layer over the screen that owns it, never a destination** (R12) | boolean the owner holds + `ModalBottomSheet`, removed from composition when hidden | `.sheet(isPresented:)` on the owning view | `showModalBottomSheet` from the owning route | owner-held state + the platform sheet |
| **A sheet's deep link resolves to its OWNER's link plus a sheet request** | `UseSmileIDSampleSheetLinks` maps path → owner URI + enum; owner consumes it | same mapping, presenting view consumes | ditto | ditto |

Insets and presentation stay platform-native (AGENTS.md) — the clearance rule translates as
"derive from the platform's measured chrome", not as copying any constant.

**The two sheet rows are the one place a literal mirror of the tree gives the wrong answer.**
Android shipped every sheet as a `@Destination`, so the navigation host replaced the screen
underneath and the sheet's scrim covered a flat grey void; it was fixed on 2026-08-26. iOS,
Flutter and React Native present sheets over the presenter by construction, so they should be
**checked, not changed** — the risk is a port copying Android's old file layout and re-creating a
routed sheet where the platform already does the right thing. One caution for whoever checks:
a device flow cannot assert what is behind a modal, because Android drops the windows below one
from the accessibility tree. A screenshot is the only evidence.

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

## 5. Session mismatch — server behaviour confirmed, one ruling owed

Confirmed against the sandbox: the status endpoint is token-agnostic **within** an environment
(a different session token of the same environment reads the job fine) and rejects
cross-environment reads (401). The apps' local session-mismatch outcome is therefore stricter
than the server. Either keep it as a deliberate UX guard — a row always reports under the
session that created it — or relax it to a documented note; whichever way, all four apps adopt
the same ruling.
