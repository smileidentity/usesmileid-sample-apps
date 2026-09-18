# Improve plan: stop one unreadable row from erasing every stored verification on Flutter

> **Executor instructions**: Follow this plan step by step. Run every verification command and
> confirm the expected result before moving to the next step. If anything in the "STOP conditions"
> section occurs, stop and report — do not improvise. When done, update this plan's row in
> `docs/plan/improve-plans-index.md`.
>
> **Drift check (run first)**:
> `git diff --stat 00834b2..HEAD -- flutter/sample_ui/lib/src/model flutter/app/lib/src/data flutter/app/test expo/sample-ui/src/model expo/sample-ui/test`
> If any in-scope file changed since this plan was written, compare the "Current state" excerpts
> against the live code before proceeding; on a mismatch, treat it as a STOP condition.

## Status

- **Priority**: P1
- **Effort**: S
- **Risk**: LOW
- **Depends on**: none (can land before or after `improve-flutter-job-store-contract.md`; see
  "Maintenance notes" for the one interaction)
- **Category**: bug
- **Planned at**: commit `00834b2`, 2026-09-18

## Why this matters

The Flutter app and the Expo app persist the same data — the list of verifications the user has run
— as a JSON array in the platform's preference store. They read it back in two different ways, and
only one of them survives a partly-unreadable store.

**Expo rebuilds each row independently.** A row it cannot understand becomes `null` and is filtered
out; every other row survives.

**Flutter rebuilds the list inside one `try`, and its `catch` returns an empty list.** One
unreadable row therefore discards **every** stored verification, silently, on the next launch. The
comment above the `try` says the intent — "a sample must not refuse to start because an older write
left a shape it no longer understands" — and the code delivers a stronger consequence than the
comment promises: it does not refuse to start, it starts with nothing.

The failure is silent by construction. Nothing throws, nothing logs, the list simply renders its
empty state, and the user reads it as "I have run no verifications" rather than "this build could
not read your history."

This is latent today because the only rows a Flutter build has ever written were written by the same
build. It becomes live on the **first** shape change — which is the next thing scheduled, since the
SDK flow host will begin writing real rows, and Flutter's row already decodes its two enums with
`values.byName`, which throws on any name it does not recognise. Renaming or removing one product or
one status is then enough to erase a user's whole history on upgrade.

`docs/plan/port-patterns.md` §3 rule 5 is the governing rule and Flutter does not satisfy it:

> **Restored identifiers fall back, never throw.** An enum id read back from persistence or saved UI
> state resolves by lookup with a safe default; a rename must not crash a restore.

Flutter does not crash. It also does not fall back — it falls back to nothing, for the entire store.

A second, smaller gap: **neither port has a test for this at all.** Expo's behaviour is correct by
construction and untested; Flutter's is wrong and untested. Both get one.

## Current state

### The files

- `flutter/app/lib/src/data/use_smileid_sample_preferences_jobs_repository.dart` — the
  `SharedPreferences`-backed store. `_stored()` at line 67 is the whole problem.
- `flutter/sample_ui/lib/src/model/use_smileid_sample_job.dart` — the row. `fromJson` at line 21 is
  what throws.
- `expo/sample-ui/src/model/use-smile-id-sample-job.ts` — the Expo row. `smileIDSampleJobFrom` at
  line 34 is the behaviour to match.
- `expo/sample-ui/src/data/use-smile-id-sample-job-store.ts` — the Expo store. `load` at line 76 is
  the per-row filter; the storage key at line 15 is `'sample.jobs.v3'`.
- `flutter/app/test/use_smileid_sample_persistence_test.dart` — the existing persistence test file,
  the structural pattern to follow.
- `expo/sample-ui/test/use-smile-id-sample-job-store.test.ts` — the existing store test file.

### The Flutter code as it exists today

`flutter/app/lib/src/data/use_smileid_sample_preferences_jobs_repository.dart:67-85`:

```dart
  List<UseSmileIDSampleJob> _stored() {
    final String? raw = _preferences.getString(useSmileIDSampleJobsKey);
    if (raw == null) {
      return const <UseSmileIDSampleJob>[];
    }
    // A store this build cannot read is treated as no store: a sample must not refuse to start
    // because an older write left a shape it no longer understands.
    try {
      return <UseSmileIDSampleJob>[
        for (final Object? each in jsonDecode(raw) as List<Object?>)
          UseSmileIDSampleJob.fromJson(each! as Map<String, Object?>),
      ]..sort(
        (UseSmileIDSampleJob a, UseSmileIDSampleJob b) =>
            b.createdAtMillis.compareTo(a.createdAtMillis),
      );
    } on Object {
      return const <UseSmileIDSampleJob>[];
    }
  }
```

`flutter/sample_ui/lib/src/model/use_smileid_sample_job.dart:20-35` — the four throwing expressions
are the two `!` null-assertions on `id`/`userId` and the two `values.byName` calls:

```dart
  /// Rebuilds a job from what the store wrote, defaulting anything an older write omitted.
  factory UseSmileIDSampleJob.fromJson(Map<String, Object?> json) =>
      UseSmileIDSampleJob(
        id: json['id']! as String,
        userId: json['userId']! as String,
        product: UseSmileIDSampleProduct.values.byName(
          json['product']! as String,
        ),
        status: UseSmileIDSampleStatus.values.byName(json['status']! as String),
        createdAtMillis: json['createdAtMillis']! as int,
        message: json['message'] as String? ?? '',
        httpStatus: json['httpStatus'] as int?,
        sandbox: json['sandbox'] as bool? ?? true,
        sessionId: json['sessionId'] as String?,
        partnerId: json['partnerId'] as String?,
      );
```

### The Expo code to match

`expo/sample-ui/src/model/use-smile-id-sample-job.ts:33-49` — note that it returns `null` rather
than throwing, resolves both enums by lookup, and requires only `id` and `product`:

```ts
/// Rebuilds a row read back from storage, resolving both enums by lookup so a rename cannot crash a restore.
export const smileIDSampleJobFrom = (raw: Record<string, unknown>): UseSmileIDSampleJob | null => {
  const product = smileIDSampleProductFrom(typeof raw.product === 'string' ? raw.product : null);
  if (product === null || typeof raw.id !== 'string' || raw.id.length === 0) return null;
  return {
    id: raw.id,
    userId: typeof raw.userId === 'string' ? raw.userId : '',
    product,
    status: smileIDSampleStatusFrom(typeof raw.status === 'string' ? raw.status : null),
    createdAtMillis: typeof raw.createdAtMillis === 'number' ? raw.createdAtMillis : 0,
    message: typeof raw.message === 'string' ? raw.message : '',
    httpStatus: typeof raw.httpStatus === 'number' ? raw.httpStatus : null,
    sandbox: raw.sandbox !== false,
    sessionId: typeof raw.sessionId === 'string' ? raw.sessionId : null,
    partnerId: typeof raw.partnerId === 'string' ? raw.partnerId : null,
  };
};
```

`expo/sample-ui/src/data/use-smile-id-sample-job-store.ts:76-95` — the whole-blob guard stays (a
`JSON.parse` failure still reads as empty), and the per-row filter is what saves the readable rows:

```ts
  load: async () => {
    const raw = await AsyncStorage.getItem(STORAGE_KEY);
    if (raw === null) { set({ jobs: [] }); return; }
    let parsed: unknown = null;
    try { parsed = JSON.parse(raw); } catch {
      // A store that no longer parses reads as empty rather than taking the screen down with it.
      set({ jobs: [] }); return;
    }
    const rows = Array.isArray(parsed) ? parsed : [];
    const jobs = rows
      .map((row) => smileIDSampleJobFrom(row as Record<string, unknown>))
      .filter((job): job is UseSmileIDSampleJob => job !== null);
    set({ jobs: ordered(jobs) });
  },
```

### Repo conventions you must match

Quoted here because the executor has not read `AGENTS.md` or `docs/plan/port-patterns.md`.

- **"The doc comment is the documentation; inline comments are the exception."** Every type,
  function and non-obvious property carries a `///` doc comment of **one line**. An inline `//` is
  earned only by something the code cannot say. **No multi-line comments anywhere.** The two
  existing inline comments quoted above are the style to match: one line, stating the constraint.
- **`docs/plan/port-patterns.md` §3 rule 5** — "Restored identifiers fall back, never throw. An enum
  id read back from persistence or saved UI state resolves by lookup with a safe default; a rename
  must not crash a restore."
- **Dart style**: explicit types on locals and in collection literals, as in the excerpts above.
  `dart format` will not add them for you.
- **Do not change what `toJson` writes.** This plan changes reading only. A round-trip must still
  produce an identical row.
- **Commits**: a single conventional-commit subject line, `type: summary`. No body, no attribution
  trailers. Example from `git log`: `fix: guard duplicate frame delivery`.

## Commands you will need

**Use Flutter's bundled `dart`, not a Homebrew one** — the two disagree on formatting and CI uses
Flutter's (`docs/plan/after-the-ports.md` item 9). `expo/verify.sh` needs pnpm 9 and exits 1 on
anything else.

| Purpose | Command | Expected on success |
|---|---|---|
| Flutter resolve | `cd flutter/sample_ui && flutter pub get` and `cd flutter/app && flutter pub get` | exit 0 |
| Flutter format check | `cd flutter && dart format --output=none --set-exit-if-changed sample_ui app` | exit 0 |
| Flutter analyze | `cd flutter/sample_ui && flutter analyze` and `cd flutter/app && flutter analyze` | `No issues found!` |
| Flutter tests | `cd flutter/sample_ui && flutter test` and `cd flutter/app && flutter test` | all pass |
| Flutter full gate | `flutter/verify.sh` | prints `OK` |
| Expo install | `cd expo && pnpm install --frozen-lockfile` | exit 0 |
| Expo lint | `cd expo && pnpm exec eslint .` | exit 0 |
| Expo library tests | `cd expo && pnpm --filter @smileid/sample-ui exec jest --ci` | all pass |

## Scope

**In scope** (the only files you may modify or create):

- `flutter/sample_ui/lib/src/model/use_smileid_sample_job.dart`
- `flutter/app/lib/src/data/use_smileid_sample_preferences_jobs_repository.dart`
- `flutter/app/test/use_smileid_sample_persistence_test.dart`
- `expo/sample-ui/test/use-smile-id-sample-job-store.test.ts`

**Out of scope** (do NOT touch, even though they look related):

- **`expo/sample-ui/src/`.** Expo's reading behaviour is already correct; this plan gives it a test
  and brings Flutter to it. If you believe an Expo source change is needed, that is a STOP
  condition.
- **`toJson` on either platform, and the storage keys.** Changing what is written, or bumping
  Flutter's key from `'jobs'` to a versioned one, is a migration decision that belongs with a shape
  change, not with this fix. Note it in the index instead.
- **`android/` and `ios/`.** They persist through Room and a typed store respectively and do not
  carry this shape. Do not reach into them.
- **`flutter/app/lib/src/data/use_smileid_sample_preferences_settings_repository.dart`.** Its
  `read()` already falls back per key with `getBool(key) ?? fallback` and is correct.
- **The profile store on either platform.** Profiles are in memory by design
  (`docs/plan/port-patterns.md` §3 rule 8), so there is nothing to restore.
- **`spec/`** — any change there must land with four app-side updates and is a separate decision.
- **Any golden baseline** under `flutter/sample_ui/test/goldens/` or `expo/sample-ui/test/goldens/`.
  Nothing here should change a rendered tree. If one moves, that is a STOP condition.

## Git workflow

- Branch: `improve/port-store-restore-tolerance`
- One conventional-commit subject line per step. No body, no attribution trailers.
- Do **not** push, open a PR, or run the `create-pr` skill.

## Steps

### Step 1: make the Flutter row rebuild fall back instead of throwing

In `flutter/sample_ui/lib/src/model/use_smileid_sample_job.dart`, replace the `fromJson` factory at
lines 20–35 with a **static method returning a nullable row**, matching Expo's contract:

```dart
  /// Rebuilds a row read back from storage, resolving both enums by lookup so a rename cannot crash a restore.
  static UseSmileIDSampleJob? fromStored(Map<String, Object?> json) { … }
```

It must:

- return `null` when `id` is absent, not a `String`, or empty
- return `null` when `product` does not resolve — resolve it with a **lookup that does not throw**,
  not `values.byName`. Use
  `UseSmileIDSampleProduct.values.where((p) => p.name == name).firstOrNull` (from
  `package:collection`, if already a dependency) or an explicit `for` loop returning null. Check
  `flutter/sample_ui/pubspec.yaml` before adding any import; **do not add a dependency** — if the
  only clean way needs one, use a loop instead.
- resolve `status` by the same non-throwing lookup, defaulting to the same status Expo's
  `smileIDSampleStatusFrom` defaults to when given an unknown name. **Read
  `expo/sample-ui/src/model/use-smile-id-sample-status.ts` and use whatever default it uses** — do
  not choose your own.
- default `userId` to `''`, `message` to `''`, `createdAtMillis` to `0`, `sandbox` to `true` unless
  the stored value is exactly `false`, and `httpStatus`/`sessionId`/`partnerId` to null when absent
  or of the wrong type.

Keep the old name available only if something outside the In-scope list calls it — check first with
`grep -rn "fromJson" flutter/`. If the only caller is the preferences repository, rename outright.

**Verify**: `cd flutter/sample_ui && flutter analyze` → `No issues found!`. Then
`grep -n "values.byName" flutter/sample_ui/lib/src/model/use_smileid_sample_job.dart` → no matches.

**Commit**: `fix: resolve a restored Flutter job row by lookup rather than by throwing`

### Step 2: keep the readable rows when one row is unreadable

In `flutter/app/lib/src/data/use_smileid_sample_preferences_jobs_repository.dart`, rewrite
`_stored()` (lines 67–85) so that:

- a `null` stored string still returns an empty list
- the **whole-blob** decode keeps its `try` — a string that is not valid JSON, or that decodes to
  something other than a `List`, still reads as an empty store. Keep the existing one-line comment,
  which states exactly that intent.
- **each row is rebuilt separately**, through step 1's nullable `fromStored`, and a `null` result is
  skipped rather than aborting the list
- the surviving rows are sorted newest first, as today

Add one inline comment, one line, saying why the per-row skip exists — that one row this build
cannot read must not take the rest of the history with it.

**Verify**: `cd flutter/app && flutter analyze` → `No issues found!`. Then
`cd flutter && dart format --output=none --set-exit-if-changed sample_ui app` → exit 0.

**Commit**: `fix: keep the readable Flutter verifications when one stored row cannot be read`

### Step 3: pin the behaviour on Flutter

Add to `flutter/app/test/use_smileid_sample_persistence_test.dart`. Read the file first — it uses
`SharedPreferences.setMockInitialValues` and builds a `ProviderScope` container at line 89; follow
that idiom, and seed the store by writing the JSON string under the key
`useSmileIDSampleJobsKey` directly, so the test exercises the real read path.

Four tests:

| Name | Arrange | Expect |
|---|---|---|
| a row this build cannot read does not take the others with it | three rows, the middle one carrying `"product": "somethingRemoved"` | the other two are read, in newest-first order |
| a row with an unknown status still loads | one row with `"status": "somethingNew"` | the row loads, at the default status Expo uses |
| a row with no id is dropped | one valid row and one with `id` missing | one row |
| a store that is not JSON reads as empty rather than throwing | the key set to `not json` | an empty list, no exception |

Add one more asserting the round trip is unchanged: write rows through the repository, read them
back, and assert every field matches — this is what proves step 1 did not change the written shape.

**Verify**: `cd flutter/app && flutter test` → all pass, 5 new tests. Then delete the per-row skip
you added in step 2, re-run, and confirm the first test **fails**; restore it. (A check has to be
proved against the thing it protects — `docs/plan/port-gaps-backlog.md` §5 records a test in this
repo that passed with the code it defended deleted.)

**Commit**: `test: prove one unreadable Flutter row leaves the rest readable`

### Step 4: pin the same behaviour on Expo

Add a `describe('load')` block to `expo/sample-ui/test/use-smile-id-sample-job-store.test.ts`. The
file already has blocks for `add`, `remove and undo`, `applyStatus`, `refresh` and `the fixtures` —
follow their `beforeEach` and AsyncStorage-mock idiom exactly.

The same four cases as step 3, seeding `AsyncStorage` under the store's key
(`'sample.jobs.v3'`, at `expo/sample-ui/src/data/use-smile-id-sample-job-store.ts:15`). Expo's
source does not change — these tests should pass on the first run. **If any of them fails, that is a
STOP condition**, because it means Expo's behaviour is not what this plan states.

**Verify**: `cd expo && pnpm --filter @smileid/sample-ui exec jest --ci` → all pass, 4 new tests, no
new or obsolete snapshots. Then `cd expo && pnpm exec eslint .` → exit 0.

**Commit**: `test: pin the Expo store's per-row restore tolerance`

### Step 5: run both gates

**Verify**: `flutter/verify.sh` → prints `OK`. Then `cd expo && ./verify.sh` → prints `OK`.

No commit — this step only confirms.

## Test plan

| File | Cases |
|---|---|
| `flutter/app/test/use_smileid_sample_persistence_test.dart` | the four rows of step 3's table, plus the round-trip assertion |
| `expo/sample-ui/test/use-smile-id-sample-job-store.test.ts` | the same four, in a new `describe('load')` |

Structural patterns: `flutter/app/test/use_smileid_sample_persistence_test.dart`'s existing tests
(`'a stored pair the SDK refuses is dropped on the way out'` at line 69 is the closest shape) and
`expo/sample-ui/test/use-smile-id-sample-job-store.test.ts`'s `describe('applyStatus')` block.

The step-3 falsification — delete the guard, watch the test red, restore it — is part of the test
plan, not optional. It is the only thing that distinguishes a test from a test that cannot fail.

## Done criteria

All must hold:

- [ ] `flutter/verify.sh` prints `OK`
- [ ] `cd expo && ./verify.sh` prints `OK`
- [ ] `grep -rn "values.byName" flutter/sample_ui/lib/src/model/use_smileid_sample_job.dart` returns nothing
- [ ] `cd flutter/app && flutter test` passes with 5 new tests
- [ ] `cd expo && pnpm --filter @smileid/sample-ui exec jest --ci` passes with 4 new tests and no
      written or obsolete snapshots
- [ ] `git status --porcelain expo/sample-ui/src` is empty (no Expo source change)
- [ ] `git status --porcelain flutter/sample_ui/test/goldens expo/sample-ui/test/goldens` is empty
- [ ] `git status --porcelain` lists no file outside the In-scope list
- [ ] this plan's row in `docs/plan/improve-plans-index.md` is updated

## STOP conditions

Stop and report — do not improvise — if:

- The code at any "Current state" excerpt does not match what you find.
- Any of step 4's Expo tests fails. That means Expo's restore behaviour is not what this plan
  describes, and the two ports need aligning on a decision rather than on this plan's assumption.
- Making the Flutter lookup non-throwing needs a new package dependency.
- `grep -rn "fromJson" flutter/` shows a caller outside
  `flutter/app/lib/src/data/use_smileid_sample_preferences_jobs_repository.dart` that this plan does
  not list.
- In step 3, deleting the per-row skip does **not** make the first test fail. The test is then
  proving something other than its name.
- Any golden baseline changes, is written, or is reported obsolete.
- Any verification fails twice after a reasonable fix attempt.

## Maintenance notes

- **What a reviewer should scrutinise**: that the whole-blob `try` survived. Dropping it would make
  a corrupt string throw at start-up, which is a worse failure than the one being fixed. The change
  is *narrowing* the catch from the whole list to one row, not removing it.
- **The one interaction with `improve-flutter-job-store-contract.md`**: that plan adds `add`,
  `find`, `applyStatus` and `refresh` to the same repository. Whichever lands second will need to
  merge around `_stored()`. Neither blocks the other, and the conflicts are textual rather than
  semantic.
- **What is deliberately deferred**: Flutter's storage key is the bare string `'jobs'`
  (`use_smileid_sample_preferences_jobs_repository.dart`, the `useSmileIDSampleJobsKey` constant),
  where Expo's is `'sample.jobs.v3'` and Android's store carries Room migrations. A versioned key
  lets a future breaking shape change start clean instead of silently dropping rows. That is a
  migration decision to take when a shape actually changes, with all four apps in the room — not
  here.
- **Why this matters more after the flow host lands**: today every stored row was written by the
  build reading it. Once real verifications are recorded and products or statuses can be added or
  renamed between releases, this read path is the one that decides whether a user's history survives
  an upgrade.
