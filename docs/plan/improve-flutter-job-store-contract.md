# Improve plan: give Flutter the job-store contract the other three apps already have

> **Executor instructions**: Follow this plan step by step. Run every verification command and
> confirm the expected result before moving to the next step. If anything in the "STOP conditions"
> section occurs, stop and report — do not improvise. When done, update this plan's row in
> `docs/plan/improve-plans-index.md`.
>
> **Drift check (run first)**:
> `git diff --stat 00834b2..HEAD -- flutter/sample_ui/lib flutter/app/lib flutter/app/test flutter/sample_ui/test`
> If any in-scope file changed since this plan was written, compare the "Current state" excerpts
> against the live code before proceeding; on a mismatch, treat it as a STOP condition.

## Status

- **Priority**: P1
- **Effort**: L
- **Risk**: MED
- **Depends on**: none
- **Category**: tech-debt (parity divergence + architecture gap)
- **Planned at**: commit `00834b2`, 2026-09-18

## Why this matters

This repo holds four sample apps — Android, iOS, Flutter and Expo — to a parity contract: the same
screens, the same ids, the same product strings, and the same data-layer semantics. Three of the four
apps own a **job store with eight operations**. Flutter's owns four.

Android (`android/sample-ui/.../data/UseSmileIDSampleJobStore.kt`), iOS
(`ios/SampleUI/Sources/SampleUI/Data/UseSmileIDSampleJobStore.swift`) and Expo
(`expo/sample-ui/src/data/use-smile-id-sample-job-store.ts`) each expose `add`, `find`,
`applyStatus` and `refresh` alongside `read`/`seedFixtures`/`remove`/`undoRemove`, plus a
`UseSmileIDSampleJobStatusSource` seam and a sealed `UseSmileIDSampleStatusRefresh` outcome type
whose labels are product strings shared across the apps. **Flutter has none of those four
operations, no seam and no outcome type.** Its detail page's refresh button calls a method that
performs no work at all.

Three concrete costs:

1. **There is nowhere to record a verification.** The whole point of these apps is to run a
   verification and show it in the list. On Android, iOS and Expo the store has `add`. On Flutter
   the repository interface has no write path for a new row at all, so the very first thing the SDK
   flow host must do when it lands has no method to call. This is the single largest structural
   difference between the two new ports.
2. **Flutter has invented a fifth wording for a shared product string.** The outcome vocabulary is
   `Still processing` / `No live token session to check with` / `Never submitted, so there is
   nothing to check` / `Submitted by a different partner`. Flutter instead carries
   `'Not submitted under a scanned token'` on the **model**, which also breaks the documented rule
   that the data layer draws nothing (see "Repo conventions" below).
3. **The refresh button reports the wrong thing for a real row.** See the excerpt below: for a job
   that *is* stored and *does* carry a session id, `refreshBlockedReason` returns null and the
   `??` falls through to `'Nothing stored to refresh'` — which is false. Today's fixture rows all
   carry a null session id so the path is unreached; it becomes wrong the moment a real row exists.

This is not the SDK flow host and it is not the token session. Both of those are planned separately
and are explicitly out of scope here. This plan builds the **store contract underneath them**, which
Expo already has and Flutter does not, so that when the flow host lands the two ports are a
comparable amount of work apart rather than a tranche apart.

## Current state

### The files

- `flutter/sample_ui/lib/src/data/use_smileid_sample_jobs_repository.dart` — the repository
  interface plus an in-memory implementation used by tests and previews. **Four methods.**
- `flutter/sample_ui/lib/src/model/use_smileid_sample_job.dart` — the row. Carries `sessionId`,
  `partnerId`, `sandbox` and `httpStatus` already, so no field is missing. Line 98 holds the
  display string that must move out.
- `flutter/app/lib/src/data/use_smileid_sample_preferences_jobs_repository.dart` — the
  `SharedPreferences`-backed implementation the shell installs.
- `flutter/app/lib/src/state/use_smileid_sample_providers.dart` — `UseSmileIDSampleJobsNotifier`
  at line 131, whose `build()` carries the comment `// READ ONLY.` at line 135.
- `flutter/app/lib/src/screens/use_smileid_sample_verification_details_tab.dart` — the detail page
  host; `_refresh()` at line 69.
- `flutter/sample_ui/lib/src/screens/use_smileid_sample_verification_details_screen.dart` — the
  screen. It already takes a `refreshNotice` string (line 50) and draws it in a toast (line 112).
  **This screen does not change.**
- `flutter/sample_ui/lib/sample_ui.dart` — the barrel. Every public file is exported here; `data/`
  exports are at lines 37–38.
- `flutter/sample_ui/test/state/use_smileid_sample_jobs_test.dart` — the store's test file; line
  266 asserts `refreshBlockedReason`, so that assertion has to move with the code.

### The reference implementations to mirror

**`expo/sample-ui/src/data/use-smile-id-sample-job-status-source.ts`, in full** — this is the shape
Flutter needs, in Dart. Android's `UseSmileIDSampleJobStatusSource.kt` is the same type, comment for
comment, so these two agreeing is the contract:

```ts
import type { UseSmileIDSampleStatus } from '../model/use-smile-id-sample-status';

/// What a refresh did, so the screen can say so. The labels are product strings, identical across the four apps.
export type UseSmileIDSampleStatusRefresh =
  | { readonly kind: 'updated'; readonly status: UseSmileIDSampleStatus; readonly message: string; readonly httpCode: number }
  /// 202 — still running; the row already says Processing.
  | { readonly kind: 'stillProcessing' }
  /// No live session, so no credential to ask with. A precondition, not an error.
  | { readonly kind: 'noSession' }
  /// Never submitted under a scanned session, so there is no server-side job.
  | { readonly kind: 'noServerJob' }
  /// Submitted by a different partner, so this session's credential is for another account.
  | { readonly kind: 'partnerMismatch' }
  | { readonly kind: 'failed'; readonly reason: string };

/// The one network call the app owns, behind a seam so the refresh orchestration tests off-device.
export type UseSmileIDSampleJobStatusSource = {
  /// Maps the HTTP exchange onto an outcome and lets a transport failure throw — the store owns reporting it.
  check: (jobId: string, token: string, sandbox: boolean) => Promise<UseSmileIDSampleStatusRefresh>;
};

/// What each outcome says on screen. Kept beside the type so four apps cannot word them differently.
export const smileIDSampleRefreshLabel = (outcome: UseSmileIDSampleStatusRefresh): string => {
  switch (outcome.kind) {
    case 'updated':
      return outcome.message;
    case 'stillProcessing':
      return 'Still processing';
    case 'noSession':
      return 'No live token session to check with';
    case 'noServerJob':
      return 'Never submitted, so there is nothing to check';
    case 'partnerMismatch':
      return 'Submitted by a different partner';
    case 'failed':
      return outcome.reason;
  }
};
```

**`expo/sample-ui/src/data/use-smile-id-sample-job-store.ts:17-22`** — the minimal session value a
refresh needs. It is *not* the token session feature; it is three fields:

```ts
/// A live token session, as much of it as a refresh needs to decide whether it may ask.
export type UseSmileIDSampleRefreshSession = {
  readonly token: string;
  readonly partnerId: string | null;
  readonly expiresAtMillis: number;
};
```

**`expo/sample-ui/src/data/use-smile-id-sample-job-store.ts:97-104` (`add`), `:128-148`
(`applyStatus`), `:150-187` (`refresh` and `find`)** — the orchestration to mirror. Every comment
here states a constraint that was paid for; carry the equivalent constraint into Dart:

```ts
  /// A no-op on an id already stored, which is what makes a repeated result delivery harmless.
  add: async (job) => {
    const current = get().jobs ?? [];
    if (current.some((row) => row.id === job.id)) return;
    const next = ordered([...current, job]);
    set({ jobs: next });
    await persist(next);
  },

  /// The one write that overwrites, and the only one that reports whether the row was still there.
  applyStatus: async (jobId, status, message, httpStatus) => {
    let existed = false;
    // Read and write inside one updater: a delete landing between a find and a write would be
    // resurrected by the write, and this is the JavaScript equivalent of one update statement.
    set((state) => {
      const current = state.jobs ?? [];
      existed = current.some((row) => row.id === jobId);
      if (!existed) return state;
      return { ...state, jobs: current.map((row) => row.id === jobId ? { ...row, status, message, httpStatus } : row) };
    });
    // Re-read, never a value captured before the await: a remove landing in that window is
    // already absent from what this writes, where a captured array would resurrect the row.
    if (existed) await persist(get().jobs ?? []);
    return existed;
  },

  /// The whole refresh sequence, owned by what owns the rows. Null means one is already in flight.
  refresh: async (jobId, session, nowMillis, source) => {
    if (inFlight.has(jobId)) return null;
    inFlight.add(jobId);
    try {
      const row = get().find(jobId);
      if (row === null) return { kind: 'failed', reason: 'The verification is no longer stored' };
      if (row.sessionId === null) return { kind: 'noServerJob' };
      if (session === null || session.expiresAtMillis <= nowMillis) return { kind: 'noSession' };
      // The partner, not the session: tokens expire and the same partner holds a newer one.
      if (session.partnerId !== row.partnerId) return { kind: 'partnerMismatch' };

      let outcome: UseSmileIDSampleStatusRefresh;
      try {
        // The row's environment, never the toggle: a row outlives the toggle that produced it.
        outcome = await source.check(jobId, session.token, row.sandbox);
      } catch (error) {
        // The type, never the message: this text goes on screen and a client error carries the URL.
        const name = error instanceof Error ? error.name : 'Error';
        return { kind: 'failed', reason: `Unexpected error: ${name}` };
      }
      if (outcome.kind !== 'updated') return outcome;

      const written = await get().applyStatus(jobId, outcome.status, outcome.message, outcome.httpCode);
      return written ? outcome : { kind: 'failed', reason: 'The verification is no longer stored' };
    } finally {
      // Released even when the caller was cancelled, or the row is silently unrefreshable for the
      // rest of the process — which is what a `finally` buys that an early return does not.
      inFlight.delete(jobId);
    }
  },

  find: (jobId) => (get().jobs ?? []).find((row) => row.id === jobId) ?? null,
```

**`expo/app/app/(tabs)/verifications/[jobId].tsx:12-15`** — how the shell supplies a source while
no scanner exists. Flutter does the same thing:

```tsx
/// No scanned session exists yet, so every refresh reports why rather than doing nothing.
const source: UseSmileIDSampleJobStatusSource = {
  check: async () => ({ kind: 'noSession' }),
};
```

### The Flutter code as it exists today

`flutter/sample_ui/lib/src/data/use_smileid_sample_jobs_repository.dart:5-18` — the whole
interface:

```dart
/// Where the verifications are kept, so the screen never knows what is doing the keeping.
abstract interface class UseSmileIDSampleJobsRepository {
  /// Every stored job, newest first, or null while the store has not answered.
  Future<List<UseSmileIDSampleJob>?> read();

  /// Adds the design's eleven, ignoring any whose id is already stored.
  Future<void> seedFixtures(int nowMillis);

  /// The count is what was TAKEN: an id matching nothing must not spend a still-undoable batch.
  Future<int> remove(Set<String> ids);

  /// Puts the last removal back, once. A second call restores nothing.
  Future<void> undoRemove();
}
```

`flutter/sample_ui/lib/src/model/use_smileid_sample_job.dart:97-99` — the display string that has
to leave the model:

```dart
  /// Why this job cannot be refreshed, or null when it can be.
  String? get refreshBlockedReason =>
      sessionId == null ? 'Not submitted under a scanned token' : null;
```

`flutter/app/lib/src/screens/use_smileid_sample_verification_details_tab.dart:68-75` — the refresh
that does nothing, and whose `??` reports the wrong message for a stored row:

```dart
  /// Re-reads the job, or says why it cannot be re-read.
  Future<void> _refresh() async {
    final String notice =
        _stored()?.refreshBlockedReason ?? 'Nothing stored to refresh';
    if (mounted) {
      setState(() => _refreshNotice = notice);
    }
  }
```

`flutter/app/lib/src/state/use_smileid_sample_providers.dart:131-157` — the notifier:

```dart
class UseSmileIDSampleJobsNotifier
    extends AsyncNotifier<List<UseSmileIDSampleJob>> {
  @override
  Future<List<UseSmileIDSampleJob>> build() async {
    // READ ONLY.
    return await ref.watch(useSmileIDSampleJobsRepositoryProvider).read() ??
        const <UseSmileIDSampleJob>[];
  }

  /// Hides rows and returns how many were taken, which is what the confirmation reports.
  Future<int> removeJobs(Set<String> ids) async { … }

  /// Puts the last removal back.
  Future<void> undoRemoval() async { … }
}
```

### Repo conventions you must match

Quoted here because the executor has not read `AGENTS.md` or `docs/plan/port-patterns.md`.

- **"The doc comment is the documentation; inline comments are the exception."** Every type,
  function and non-obvious property carries a `///` doc comment of **one line**. An inline `//` is
  earned only by something the code cannot say — a measured constraint, a platform trap, an order
  that looks arbitrary and is not. **No multi-line comments anywhere.** When you carry one of the
  Expo comments across, keep it to one line.
- **`docs/plan/port-patterns.md` §3 rule 4 — "Store the code, render the text."** `httpStatus`
  persists as the integer; "200 OK" is composed where the row is drawn. **No display strings in the
  data layer.** This is why `refreshBlockedReason` must leave the model: it is a sentence that goes
  on screen, living on a persisted row.
- **`docs/plan/port-patterns.md` §3 rule 1 — "A refresh reads the row, never the current toggle."**
  The environment and session a job was submitted under are recorded on its row; a status refresh
  uses those. **"The outcome labels are product strings and stay identical across the four apps."**
- **`docs/plan/port-patterns.md` §3 rule 2 — "The status write is atomic and honest about
  deletion."** One update, reporting whether a row still existed — a delete landing mid-refresh must
  win, never resurrect the row. No find-then-write pair.
- **`docs/plan/port-patterns.md` §3 rule 3 corollary** — "any in-flight guard the refresh holds must
  release even when the caller was cancelled — a cancelled coroutine/task skipping its cleanup
  leaves the row silently unrefreshable." In Dart that is a `finally`.
- **`docs/plan/port-patterns.md` §5 — the guard matches on partner, not session.** A token always
  carries a `partner_id` and tokens expire, so a person legitimately holds a *new* session for the
  same partner and must still refresh rows an earlier session created. The outcome is
  `partnerMismatch`, not a session mismatch.
- **Commits**: a single conventional-commit subject line, `type: summary`. No body, no attribution
  trailers. Example from `git log`: `fix: guard duplicate frame delivery`.
- **Dart style**: this repo writes explicit types on locals and in collection literals (see the
  excerpts above — `final List<UseSmileIDSampleJob> stored = …`). Match it; `dart format` will not
  add them for you.

## Commands you will need

Run from the repo root unless stated. **Use Flutter's bundled `dart`, not a Homebrew one** — the two
disagree on formatting and CI uses Flutter's (`docs/plan/after-the-ports.md` item 9).

| Purpose | Command | Expected on success |
|---|---|---|
| Resolve | `cd flutter/sample_ui && flutter pub get` and `cd flutter/app && flutter pub get` | exit 0 |
| Format check | `cd flutter && dart format --output=none --set-exit-if-changed sample_ui app` | exit 0 |
| Analyze (library) | `cd flutter/sample_ui && flutter analyze` | `No issues found!` |
| Analyze (shell) | `cd flutter/app && flutter analyze` | `No issues found!` |
| Tests (library) | `cd flutter/sample_ui && flutter test` | all pass |
| Tests (shell) | `cd flutter/app && flutter test` | all pass |
| Full gate | `flutter/verify.sh` | prints `OK` |

`flutter/verify.sh` also checks design tokens and icons and builds a release APK, so it is slow. Run
it once at the end, not per step.

## Scope

**In scope** (the only files you may modify or create):

- `flutter/sample_ui/lib/src/data/use_smileid_sample_job_status_source.dart` (create)
- `flutter/sample_ui/lib/src/data/use_smileid_sample_jobs_repository.dart`
- `flutter/sample_ui/lib/src/model/use_smileid_sample_job.dart`
- `flutter/sample_ui/lib/sample_ui.dart` (one added export)
- `flutter/sample_ui/test/state/use_smileid_sample_jobs_test.dart`
- `flutter/sample_ui/test/state/use_smileid_sample_job_refresh_test.dart` (create)
- `flutter/app/lib/src/data/use_smileid_sample_preferences_jobs_repository.dart`
- `flutter/app/lib/src/state/use_smileid_sample_providers.dart`
- `flutter/app/lib/src/screens/use_smileid_sample_verification_details_tab.dart`
- `flutter/app/test/use_smileid_sample_verification_details_test.dart`

**Out of scope** (do NOT touch, even though they look related):

- **The SDK flow host, the token session and the QR scanner.** They are deliberately absent from
  this repo and are planned separately. You are building the store methods a flow host will later
  call — you are not building the flow host, not adding a `/flow/:productId/run` route, and not
  adding a scanner, a token record or a session store. `UseSmileIDSampleRefreshSession` is a
  three-field value object, not a feature; the detail page passes `null` for it.
- **`flutter/sample_ui/lib/src/screens/use_smileid_sample_verification_details_screen.dart`.** The
  screen already takes `refreshNotice` and draws it. Its signature does not change. If you believe
  it must, that is a STOP condition.
- **Anything under `expo/`, `android/` or `ios/`.** They are the reference; this plan brings Flutter
  to them. If you find a defect in one of them, report it rather than fixing it.
- **`spec/`** — any change there must land with four app-side updates and is a separate decision.
- **Any golden baseline under `flutter/sample_ui/test/goldens/`.** No step here should move a pixel.
  If any baseline changes or is reported stale, that is a STOP condition.
- **A real HTTP implementation of the seam.** No `http` or `dio` dependency, no network call. The
  shell supplies a stub source exactly as Expo does.

## Git workflow

- Branch: `improve/flutter-job-store-contract`
- One conventional-commit subject line per step. No body, no attribution trailers.
- Do **not** push, open a PR, or run the `create-pr` skill.

## Steps

### Step 1: add the status-source seam and the outcome type

Create `flutter/sample_ui/lib/src/data/use_smileid_sample_job_status_source.dart` holding, in Dart:

- `UseSmileIDSampleJobStatusSource` — an `abstract interface class` with one method:
  `Future<UseSmileIDSampleStatusRefresh> check({required String jobId, required String token,
  required bool sandbox})`. Doc comment, one line: that implementations map the HTTP exchange onto
  the outcome and let a transport failure throw, because the store owns reporting it.
- `UseSmileIDSampleStatusRefresh` — a `sealed class` with six subclasses matching the Expo union
  exactly: `Updated(status, message, httpCode)`, `StillProcessing`, `NoSession`, `NoServerJob`,
  `PartnerMismatch`, `Failed(reason)`. Carry each one-line doc comment across from the Expo/Android
  file quoted above.
- `UseSmileIDSampleRefreshSession` — an immutable class with `token`, `partnerId` (nullable) and
  `expiresAtMillis`, and the one-line doc comment "A live token session, as much of it as a refresh
  needs to decide whether it may ask."
- A top-level function `String useSmileIDSampleRefreshLabel(UseSmileIDSampleStatusRefresh outcome)`
  returning, by switch: `Updated` → its `message`; `StillProcessing` → `Still processing`;
  `NoSession` → `No live token session to check with`; `NoServerJob` → `Never submitted, so there
  is nothing to check`; `PartnerMismatch` → `Submitted by a different partner`; `Failed` → its
  `reason`. **These six strings must be byte-identical to the Expo ones quoted above.**

Export the new file from `flutter/sample_ui/lib/sample_ui.dart`, keeping the export list
alphabetical within its `src/data/` block (lines 37–38).

**Verify**: `cd flutter/sample_ui && flutter analyze` → `No issues found!`. Then
`grep -c "Still processing\|No live token session to check with\|Never submitted, so there is nothing to check\|Submitted by a different partner" flutter/sample_ui/lib/src/data/use_smileid_sample_job_status_source.dart`
→ `4`.

**Commit**: `feat: add the Flutter job status-source seam and its outcomes`

### Step 2: take the display string off the model

In `flutter/sample_ui/lib/src/model/use_smileid_sample_job.dart`, delete the
`refreshBlockedReason` getter at lines 97–99. Nothing else in the model changes — every field the
refresh needs (`sessionId`, `partnerId`, `sandbox`, `httpStatus`) is already there.

In `flutter/sample_ui/test/state/use_smileid_sample_jobs_test.dart`, delete the assertion at line
266 that reads `refreshBlockedReason`. Do not replace it here; step 4 covers the behaviour it was
standing in for.

**Verify**: `grep -rn "refreshBlockedReason" flutter/` → **no matches at all**. Then
`cd flutter/sample_ui && flutter analyze && flutter test` → analyze clean, all tests pass.

**Commit**: `refactor: take the refresh sentence off the Flutter job row`

### Step 3: extend the repository with the four missing operations

In `flutter/sample_ui/lib/src/data/use_smileid_sample_jobs_repository.dart`, add to
`UseSmileIDSampleJobsRepository`:

```dart
  /// Records a verification. A no-op on an id already stored, so a repeated result delivery is harmless.
  Future<void> add(UseSmileIDSampleJob job);

  /// One row by id, or null when this build never stored it.
  Future<UseSmileIDSampleJob?> find(String jobId);

  /// The one write that overwrites, reporting whether the row was still there.
  Future<bool> applyStatus({
    required String jobId,
    required UseSmileIDSampleStatus status,
    required String message,
    required int httpStatus,
  });

  /// The whole refresh sequence. Null means one is already in flight for this row.
  Future<UseSmileIDSampleStatusRefresh?> refresh({
    required String jobId,
    required UseSmileIDSampleRefreshSession? session,
    required int nowMillis,
    required UseSmileIDSampleJobStatusSource source,
  });
```

Implement all four in **both** implementations — `UseSmileIDSampleMemoryJobsRepository` in this same
file, and `UseSmileIDSamplePreferencesJobsRepository` in
`flutter/app/lib/src/data/use_smileid_sample_preferences_jobs_repository.dart`. Mirror the Expo
orchestration quoted above, with these Dart-specific requirements:

- **`refresh` is identical in both implementations**, so write it once. Put the sequence in a
  `mixin` in the library file, or in a private base — whichever keeps `flutter analyze` clean. It
  must be the same code, because it is the part that encodes the contract, and two copies will
  drift.
- **The in-flight guard is a `Set<String>` held per repository instance**, added to on entry and
  removed in a **`finally`** — never on the return paths. An early return that skips the release
  leaves the row silently unrefreshable for the rest of the process.
- **`applyStatus` must not read-then-write across an await.** Read the stored list, compute the new
  list, and write, with no `await` between the existence check and the write of the derived list.
  Return whether the row existed.
- **`refresh` calls `applyStatus` and returns `Failed('The verification is no longer stored')` when
  it reports false** — a delete landing mid-refresh wins.
- **Catch order in `refresh`**: catch the source's throw and return
  `Failed('Unexpected error: ${error.runtimeType}')`. The **type, never the message** — this text
  goes on screen and a client exception carries the request URL.
- **`add` is keyed on id** and returns without writing when the id is already stored.

**Verify**: `cd flutter/sample_ui && flutter analyze` and `cd flutter/app && flutter analyze` →
both `No issues found!`. Then
`grep -c "Future<void> add\|Future<UseSmileIDSampleJob?> find\|Future<bool> applyStatus\|Future<UseSmileIDSampleStatusRefresh?> refresh" flutter/sample_ui/lib/src/data/use_smileid_sample_jobs_repository.dart`
→ at least `4`.

**Commit**: `feat: give the Flutter jobs repository add, find, applyStatus and refresh`

### Step 4: test the refresh sequence off-device

Create `flutter/sample_ui/test/state/use_smileid_sample_job_refresh_test.dart`, modelled
structurally on the existing `flutter/sample_ui/test/state/use_smileid_sample_jobs_test.dart` (read
it first for the `setUp` and fixture idiom this repo uses).

**Expo's equivalent suite already exists and covers exactly these cases** — read
`expo/sample-ui/test/use-smile-id-sample-job-store.test.ts:159-291` (`describe('refresh')`) before
writing, and port its cases one for one. Where a case name there has no row in the table below, port
it anyway.

Drive `UseSmileIDSampleMemoryJobsRepository` with a fake `UseSmileIDSampleJobStatusSource`. Cover,
one test each:

| Case | Arrange | Expect |
|---|---|---|
| no session | a row with a `sessionId`, `session: null` | `NoSession`, and the source was never called |
| expired session | `session.expiresAtMillis <= nowMillis` | `NoSession`, source never called |
| never submitted | a row whose `sessionId` is null | `NoServerJob`, source never called |
| partner mismatch | row `partnerId` ≠ session `partnerId` | `PartnerMismatch`, source never called |
| updated | source returns `Updated` | the outcome is `Updated` **and** a subsequent `find` shows the new status, message and httpStatus |
| row deleted mid-refresh | source's `check` removes the row before returning `Updated` | `Failed('The verification is no longer stored')`, and the row is **not** resurrected |
| transport throws | source throws a `StateError` | `Failed` whose reason contains `StateError` and **not** the exception's message |
| already in flight | a second `refresh` for the same id while the first is awaiting | the second returns `null` |
| guard released after a throw | source throws, then refresh the same id again | the second call is **not** `null` |
| the row's environment is used | a row with `sandbox: false` | the source received `sandbox: false`, whatever any other state says |

Also add one test asserting the six labels: build each outcome and assert
`useSmileIDSampleRefreshLabel` returns the exact string. **Then assert the same six strings exist in
Expo's source file**, so the two cannot drift, by reading
`../../../expo/sample-ui/src/data/use-smile-id-sample-job-status-source.ts` from the test and
checking each label appears in it. (`flutter/app/test/use_smileid_sample_test_id_call_sites_test.dart`
is the existing precedent in this repo for a test that reads a sibling file off disk with
`dart:io`.)

**Verify**: `cd flutter/sample_ui && flutter test` → all pass, at least 11 new tests.

**Commit**: `test: pin the Flutter refresh sequence and its outcome labels`

### Step 5: expose the operations on the notifier and wire the detail page

In `flutter/app/lib/src/state/use_smileid_sample_providers.dart`, on
`UseSmileIDSampleJobsNotifier`:

- Replace the `// READ ONLY.` comment at line 135 — it is now false.
- Add `Future<void> addJob(UseSmileIDSampleJob job)` which calls the repository's `add` and then
  `ref.invalidateSelf()`, matching how `removeJobs` at line 141 does it.
- Add `Future<UseSmileIDSampleStatusRefresh?> refreshJob({required String jobId, required
  UseSmileIDSampleRefreshSession? session, required int nowMillis, required
  UseSmileIDSampleJobStatusSource source})` which calls the repository's `refresh` and, when the
  outcome is `Updated`, calls `ref.invalidateSelf()` so the list and the row redraw.

In `flutter/app/lib/src/screens/use_smileid_sample_verification_details_tab.dart`, replace
`_refresh()` (lines 68–75) so that it:

- declares a file-level stub source, exactly as Expo does at
  `expo/app/app/(tabs)/verifications/[jobId].tsx:12-15` — a `check` that returns `NoSession`, with
  the one-line comment "No scanned session exists yet, so every refresh reports why rather than
  doing nothing."
- calls `ref.read(useSmileIDSampleJobsProvider.notifier).refreshJob(jobId: widget.jobId,
  session: null, nowMillis: DateTime.now().millisecondsSinceEpoch, source: _source)`
- on `null` (already in flight) leaves `_refreshNotice` untouched
- otherwise sets `_refreshNotice` to `useSmileIDSampleRefreshLabel(outcome)`
- keeps the existing `if (mounted)` guard before `setState`.

Do **not** change `UseSmileIDSampleVerificationDetailsScreen`'s signature; it already takes
`refreshNotice`.

**Verify**: `cd flutter/app && flutter analyze` → `No issues found!`. Then
`grep -n "READ ONLY" flutter/app/lib/src/state/use_smileid_sample_providers.dart` → no matches.

**Commit**: `feat: run the Flutter detail refresh through the store`

### Step 6: assert the wiring from the app's own start-up path

Add to `flutter/app/test/use_smileid_sample_verification_details_test.dart` (read the file first and
follow its existing `ProviderScope` setup — it builds a container at line 36 and reads it at line 49):

- Opening the detail page of a stored row and tapping refresh shows the toast
  `No live token session to check with` — **not** `Nothing stored to refresh`, and **not**
  `Not submitted under a scanned token`.
- Opening the detail page of a row whose `sessionId` is null and tapping refresh shows
  `Never submitted, so there is nothing to check`.
- A job added through `addJob` appears in the list the verifications screen renders.

These must drive the real providers and the real screen, not call the repository directly.
`docs/plan/port-gaps-backlog.md` §5 records three Flutter tests that passed while the feature was
broken, each because the test arranged its own world instead of the app's.

**Verify**: `cd flutter/app && flutter test` → all pass, 3 new tests. Then `flutter/verify.sh` →
prints `OK`.

**Commit**: `test: prove the Flutter refresh reaches the screen`

## Test plan

| File | Cases |
|---|---|
| `flutter/sample_ui/test/state/use_smileid_sample_job_refresh_test.dart` (create) | the ten rows of the table in step 4, plus the six labels and the cross-check against Expo's file |
| `flutter/app/test/use_smileid_sample_verification_details_test.dart` (extend) | the three cases in step 6 |
| `flutter/sample_ui/test/state/use_smileid_sample_jobs_test.dart` (edit) | remove the `refreshBlockedReason` assertion at line 266; add one asserting `add` is a no-op on a stored id |

Structural patterns to follow: `flutter/sample_ui/test/state/use_smileid_sample_jobs_test.dart` for
repository tests, `flutter/app/test/use_smileid_sample_verification_actions_test.dart` for
container-and-widget tests.

## Done criteria

All must hold:

- [ ] `flutter/verify.sh` prints `OK`
- [ ] `grep -rn "refreshBlockedReason" flutter/` returns nothing
- [ ] `grep -rn "Nothing stored to refresh" flutter/` returns nothing
- [ ] `grep -c "Still processing" flutter/sample_ui/lib/src/data/use_smileid_sample_job_status_source.dart` returns at least 1, and the same for the other five labels
- [ ] `cd flutter/sample_ui && flutter test` passes with at least 11 new tests
- [ ] `cd flutter/app && flutter test` passes with 3 new tests
- [ ] `git status --porcelain flutter/sample_ui/test/goldens` is empty (no baseline re-recorded)
- [ ] `git status --porcelain` lists no file outside the In-scope list — in particular nothing under
      `expo/`, `android/`, `ios/` or `spec/`
- [ ] this plan's row in `docs/plan/improve-plans-index.md` is updated

## STOP conditions

Stop and report — do not improvise — if:

- The code at any "Current state" excerpt does not match what you find.
- Any golden baseline under `flutter/sample_ui/test/goldens/` changes, is written, or is reported
  obsolete. Re-recording baselines is out of scope: a changed picture means this work altered
  rendering, and a human must read every changed mark.
- `UseSmileIDSampleVerificationDetailsScreen`'s signature appears to need a change.
- Sharing `refresh` between the two repository implementations cannot be done without a change
  outside the In-scope list.
- Expo's six label strings do not match what is quoted in this plan — that means the contract moved
  and the four apps need deciding together, not aligning to a stale copy.
- You find yourself adding a token session, a scanner, a `/flow/:productId/run` route, or a real
  HTTP client. All four are out of scope; report what you think is needed instead.
- Any verification fails twice after a reasonable fix attempt.

## Maintenance notes

- **What a reviewer should scrutinise**: that `refresh` exists once rather than twice, that the
  in-flight release is in a `finally`, and that no new display string was added to the data layer.
  Those three are the reasons this plan exists.
- **What lands on top of this**: the SDK flow host will call `addJob`, and the token session will
  supply the real `UseSmileIDSampleRefreshSession` and replace the stub source with an HTTP one.
  Both were left out deliberately. When the flow host lands, `addJob` is the only new store call it
  should need.
- **The `partnerId` guard is a 2026-08-27 owner ruling** (`docs/plan/port-patterns.md` §5): refresh
  when the *partner* ids match, not the session ids, because tokens expire and the same partner
  legitimately holds a newer session. Do not "tighten" it to a session comparison later.
- `docs/plan/after-the-ports.md` says the detail page has no status refresh "because a refresh is a
  call under a scanned session and no session exists". That remains true of the *behaviour* on both
  ports after this plan — what changes is that Flutter now has the same architecture underneath it
  as the other three apps, so the two ports are the same distance from a working refresh. Consider
  updating that sentence when this lands.
