# Improve plans: index

Written by a survey of the `flutter/` and `expo/` trees on 2026-09-18, at commit `00834b2`. The
survey was deliberately scoped to what a **diff cannot show** — divergence between the two ports and
between them and `android/`/`ios/`, architecture that will fight the next feature, and capabilities
that are structurally missing rather than individually broken.

It does **not** re-survey what `docs/plan/port-review-findings.md` already records (56 findings from
a multi-perspective review of both ports' merged diffs, with a status column separating verified from
asserted), `docs/plan/port-gaps-backlog.md` (decisions taken and debt surfaced),
`docs/plan/after-the-ports.md` (the phased plan) or `docs/plan/stacked-pr-sequencing.md`. Where a
plan below overlaps one of those, its row says so.

Each executor: read the plan fully before starting, honour its STOP conditions, and update your row.

## Execution order & status

| # | Plan | What it addresses | Priority | Effort | Depends on | Status |
|---|---|---|---|---|---|---|
| 1 | [`improve-expo-shell-wiring.md`](improve-expo-shell-wiring.md) | `expo/app` has no test lane at all, and four things `expo/sample-ui` implements and tests are reached by nothing in the shell — seeding, the dark-mode setting, the notice window, the floating nav bar. All six steps have landed (#107 and #108): the shell has a test lane, seeding, the dark-mode switch, the notice window, the floating nav bar, and the removal confirmation with its undo | P1 | M | none | DONE |
| 2 | [`improve-flutter-job-store-contract.md`](improve-flutter-job-store-contract.md) | Flutter's job store has four of the eight operations Android, iOS and Expo each own. No `add`, `find`, `applyStatus` or `refresh`, no status-source seam, no outcome type; the detail page's refresh does no work and reports the wrong message for a stored row | P1 | L | the flow host, as the first caller of every operation it adds (`port-priority-cut.md` item 9) | DONE — landed inside item 9's Flutter tranche, with `refresh` written once in a mixin both stores use |
| 3 | [`improve-port-store-restore-tolerance.md`](improve-port-store-restore-tolerance.md) | One unreadable stored row silently erases **every** verification on Flutter, where Expo drops the row and keeps the rest. Neither port tests the path. Only a write-back (`seedFixtures`, the future `add`) makes the erase permanent; a read alone hides | P1 | S | plan 2's `add`; substitute a default as Android and iOS do, rather than drop as Expo does (`port-priority-cut.md`) | DONE on both — each substitutes the first product and Processing and drops only a row with no id. Expo's `load` additionally threw on a non-object row, which took the whole read down rather than that row |
| 4 | [`improve-expo-structural-checks.md`](improve-expo-structural-checks.md) | The two checks that assert code properties rather than pictures — declared ids are attached to something, and a container does not absorb its children's semantics — exist on Flutter, and the first on iOS (`TestIdUsageTest`); Expo has neither. Expo's app-bar title carries no header role | P2 | M | none | TODO |

Status values: TODO | IN PROGRESS | DONE | BLOCKED (with one-line reason) | REJECTED (with one-line
rationale).

## New, or overlapping what is already recorded

- **1 — new.** `port-gaps-backlog.md` §5 records three Flutter cases of this shape ("a fixture that
  no caller uses proves only that the fixture is self-consistent"); these are the Expo equivalents
  and none of them is in that backlog. The stock tab bar against the designed floating bar is
  finding 10 of `port-review-findings.md`; the plan's step 6 is that finding's fix.
- **2 — new.** `after-the-ports.md` says the detail page has no status refresh "because a refresh is
  a call under a scanned session and no session exists", which is true of the *behaviour* on both
  ports. What it does not record is that Expo built the whole architecture under it and Flutter did
  not, so the two ports are a stub swap and a tranche apart respectively.
- **3 — new.** Not in either document. Latent today, live on the first shape change.
- **4 — partial overlap.** `port-gaps-backlog.md` §2 and §7 record both checks as owed by **Android
  and iOS**, though iOS already has the first as `TestIdUsageTest`; neither names Expo, because
  Flutter wrote them after the Expo tranche landed. The missing header role on Expo's app-bar title is
  new.

## Dependency notes

- No plan blocks another. All four can run in parallel, on separate branches.
- **2 and 3 both touch `flutter/app/lib/src/data/use_smileid_sample_preferences_jobs_repository.dart`.**
  Whichever lands second merges around `_stored()`. The conflicts are textual rather than semantic;
  3 is the smaller of the two, so landing it first is marginally cheaper.
- **1 and 4 both touch `expo/`** but no shared file. 1 changes `expo/app/app/**` and adds a shell
  test lane; 4 adds two tests under `expo/sample-ui/test/` and one prop in one component.
- Do **not** stack these as pull requests. `stacked-pr-sequencing.md` measured what a squash-only
  repo costs a stack: re-approval per PR is unavoidable, and a merge below dismisses the approval
  above. One PR in review at a time.

## Out of scope for every plan here

The **SDK flow host, the token session and the QR scanner** are deliberately absent from this repo;
both apps' journeys stop at `/flow/:productId/run` on purpose, and `after-the-ports.md` Phase 4 is
where they are planned. No plan here adds, stubs or references them. Plan 2 builds the store
operations a flow host will later call, which is a different thing and is scoped explicitly.

## Findings considered and rejected

Kept so nobody re-audits them.

- **Expo records no pixel baselines.** Superseded: every one of its 268 style-tree states now also
  records a PNG, painted by `expo/sample-ui/test/paint/` over the jest lane's yoga layout at 2×
  (786 wide) and content height. The style trees stay beside them: they are platform-independent,
  so a token or metric regression fails identically on any machine, while a PNG is host-rasterised
  and is recorded on the runner (`expo-goldens-recorded`). What the painter cannot draw — the native
  switch, the spinner, a sheet's grabber, glyphs the bundled face lacks — is a labelled placeholder
  listed in `PLACEHOLDERS`.
- **Expo presenting the five spec'd sheet paths as `expo-router` routes.** It looked like Android's
  old sheet-as-destination defect (`port-patterns.md` §2, R12). It is not: every sheet route sets
  `presentation: 'transparentModal'` with `animation: 'none'` and a transparent `contentStyle`, and
  each owning layout sets `unstable_settings.initialRouteName`, so a link to a sheet lands on the
  owner with the sheet over it. Verified at `expo/app/app/flow/[productId]/id-details/_layout.tsx:5,18-22`
  and `expo/app/app/profiles/_layout.tsx:5,13-21`. Correct as shipped.
- **Flutter's Riverpod providers being screen-scoped**, which would lose a result delivered as the
  user navigates away (`port-patterns.md` §3 rule 3). They are not: the root scope is installed at
  `flutter/app/lib/main.dart:30` and no provider in
  `flutter/app/lib/src/state/use_smileid_sample_providers.dart` is `autoDispose`. Process-lifetime
  as required.
- **Flutter's settings restore.** It reads each key with `getBool(key) ?? fallback` and normalises
  the SDK-refused pair on the way out
  (`flutter/app/lib/src/data/use_smileid_sample_preferences_settings_repository.dart:20-26`).
  Tolerant already; only the jobs store carries the problem plan 3 fixes.
- **Expo's test-id spec test asserting one direction.** `port-review-findings.md` records this for
  Android and Flutter. Expo's asserts the set **both** ways
  (`expo/sample-ui/test/use-smile-id-sample-test-ids-spec.test.ts:15-21`). Not a gap on Expo.
- **The launch-argument surface on both ports.** Flutter reads three of the declared arguments and
  Expo acts on almost none. Already recorded — `port-gaps-backlog.md` §5 for Flutter, and plan 1's
  maintenance note names the seven Expo defers and why each needs a surface that does not exist yet.
  No separate plan.
- **The component gallery existing on Android and Flutter and not on iOS or Expo.** Two of four, so
  it is not a four-way contract today; deciding whether it is one is a product call, not a defect.

## One thing owed to another document

`sample_env_chip` is declared in `spec/test-ids.json` and implemented by **no app** — a repo-wide
grep finds it only in the spec and the four declaration files. `port-gaps-backlog.md` §3 records two
shell ids in exactly that state and calls them "either dead entries or an owed feature". This is a
third, and belongs in that list. Plan 4 allowlists it with that reason rather than changing `spec/`,
because a spec change must land with four app-side updates.
