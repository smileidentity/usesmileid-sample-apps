# Offline storage for the verification rows

Written 2026-09-09, against the four apps as they stand: Android on Room, iOS on a JSON document,
Flutter and Expo not built.

One document rather than three, because the decision that matters is not which library each platform
picks — it is that all three owe Room's migration guarantee, and that is the part a per-platform doc
would each quietly skip. Read D4 before D1, D5 or D6.

**Owner ruling, 2026-09-09.** iOS moves to SwiftData and the sample app takes an iOS 17 floor, so a
Core Data → SwiftData step never has to happen later. This supersedes `ios-port-hardening.md` §12,
which chose a file; read that section for what the file bought before changing any of this.

## Where each app is today

| App | Store | What guarantees a migration |
|---|---|---|
| Android | Room 2.8.4 | Schemas 1–3 committed as JSON, `UseSmileIDSampleJobMigrationTest`, and `@ColumnInfo(defaultValue = …)` on the three `bound*` columns. Build-enforced: a column with neither a default nor a migration fails. |
| iOS | One JSON document in Application Support, replaced atomically | A hand-written `init(from:)` using `decodeIfPresent`, one legacy-row fixture, and a `version` field that nothing reads. |
| Flutter | None — the package holds one generated tokens file | — |
| Expo | None — there is no `expo/` directory | — |

The asymmetry is not that iOS is unguarded. `testAnUnknownProductOrStatusIdFallsBackRatherThanFailingToLoad`
uses a fixture omitting all six later fields and asserts the row still loads, so a future field added
as a plain `decode` would red it. The asymmetry is that Android's guarantee is enforced by the build
and iOS's is one fixture that a developer updating tests could reasonably delete.

Blast radius, in §12's own words: the file is one document, so "one undecodable row is every row" —
and an empty list is indistinguishable from "no verifications yet".

## D1. iOS takes SwiftData, and `SampleUI` takes the 17 floor

The store type lives in `SampleUI/Sources/SampleUI/Data/`; only its instantiation is in the shell. So
it is the **library's** `platforms: [.iOS(.v15)]` that moves to `.v17`, not the shell's
`deploymentTarget`. Two facts made that affordable rather than reckless:

- The 15 floor exists to keep the SDK repo's Sample compiling this UI against SDK HEAD. That consumer
  is **not wired up yet**: `ios-v12` has no `.gitmodules`, and `ios-v12/Sample`'s project references
  no `SampleUI` package — the only match in it is its own `SampleUITests` target name. Nothing
  enforces the floor today.
- The shell's UI-test runner is already pinned at 16.4, because `XCUISystem.open` needs it. Part of
  the tree is above 15 already.

**Why SwiftData rather than Core Data.** §12 rejected Core Data because it "would add a model file to
review". That objection does not survive SwiftData: the schema is code — `@Model` — so there is no
`.xcdatamodeld` resource to process in a SwiftPM library at all. Both are system frameworks, so
neither costs a dependency and neither appears in the generated notices. Recorded so it is not
re-argued: the "avoid a future migration" case for skipping Core Data is weaker than it sounds,
because `ModelContainer` and `NSPersistentContainer` can open the same SQLite file. The real reason
is simply less machinery — SwiftData now, rather than Core Data plus a later interop step.

**Not chosen: hand-rolled SQLite.** §12's reasoning stands — more code than the store it replaces.

**The cost this accepts, on the record.** A partner on iOS 15 or 16 cannot run the reference app,
while the SDK they are integrating supports 15. That is the only substantive objection; it was put to
the owner and ruled on. Everything else here is work, not risk.

**The commitment it creates, and who has to hear it.** When `ios-v12/Sample` is wired in, it has to
move to iOS 17 too, while the SDK itself stays at 15. A demo app requiring more than the SDK it
demonstrates is normal, but the iOS SDK repo should be told rather than discover it at wiring time.
See OQ1.

## D2. What the iOS port must not lose

The store is nine public methods, a storage protocol and an `AsyncStream`, with **36 tests** across
`UseSmileIDSampleJobStoreTest` and `UseSmileIDSampleJobStoreRefreshTest`. The port is done when all
36 pass without being rewritten to suit the new store — a test edited to match the implementation
proves the implementation, not the behaviour. Specifically:

- **Actor isolation.** The store is an `actor`, which is what replaces Android's `Mutex`,
  `NonCancellable` and process-lifetime write scope. `ModelContext` is not `Sendable`, so the
  replacement is `@ModelActor`, which gives an actor-isolated context rather than a main-actor one.
  A `@MainActor` container would move every write onto the main thread and change what the
  cancellation test is testing.
- **A write outlives the view that launched it.** Proven today by cancelling the launching task and
  asserting the row landed. Still an unstructured `Task`, not `.task`.
- **Insert-ignore.** `add` must not overwrite a row it already wrote, so a repeated delivery of one
  job id is a no-op. In SwiftData that is a fetch-by-id before insert, not a plain insert —
  `@Attribute(.unique)` upserts instead of ignoring, which is the opposite of what this needs.
- **A delete that reports what it took**, because `undoRemove` restores exactly that and an unknown
  id must not spend the undo. That is §12's deliberate divergence from Android; keep it, and see OQ2.
- **The storage seam.** `UseSmileIDSampleJobStorage` exists so tests use memory and the app uses the
  real thing. Its SwiftData equivalent is `ModelContainer(isStoredInMemoryOnly: true)`, which is
  cleaner and removes the protocol.
- **The listener and `yield` mechanism stays.** SwiftData pushes nothing outside a SwiftUI `@Query`,
  and a store is not a view.

## D2b. What the port cost, and the two things it changed

Built 2026-09-09. All 36 store tests pass with their assertions untouched; what changed is their
construction, which was unavoidable — the seam moved from `Data` to a `ModelContainer`. Two
decisions the implementation forced, recorded because neither followed from the plan:

- **`UseSmileIDSampleJobStorage` is gone rather than reimplemented.** It existed to swap bytes: a
  file in an app, memory in a test. Its replacement is `ModelContainer(isStoredInMemoryOnly:)`, so
  the protocol and both its implementations had nothing left to do. The tests that seeded it with a
  JSON string became import tests, which is where that behaviour moved rather than being dropped.
- **The store degrades to memory when its container cannot open.** A partner's history is then
  invisible, which is bad — but trapping on launch is worse, and the empty state already says the
  rows are missing rather than absent. Recorded as the lesser of two, not as a good outcome.

## D3. Migrating the rows already on devices

A one-shot importer, not a fresh start: on first launch, if the JSON document exists, import its rows
and then remove it. It is testable without a device, because the JSON fixture is already in the test
suite, and it must be idempotent — a crash mid-import must neither double the rows nor lose them.

This is where the `version` field finally earns the comment it already carries. Version 1 means "the
JSON shape those tests describe", and the importer is what reads it.

**One rule the tests found rather than the plan.** A document from an *unknown* version is left
exactly where it is, not consumed. Treating "cannot read this" the same as "nothing to import" would
delete rows a later build could have imported, and that is the one mistake here that cannot be
undone. An undecodable document is a different case and is cleared out of the way: nothing is lost
by removing something that was never a document. Six cases cover this, including that importing
twice over the same container keeps one row each — which is what makes a crash between committing
the rows and deleting the file safe rather than duplicating.

## D4. The migration contract all three platforms owe Room's

Read this before picking a library, because it is the requirement, not the library.

Room's guarantee is build-enforced. SwiftData's is not: `VersionedSchema` and `SchemaMigrationPlan`
are ordinary code, and nothing fails if you add a property and forget them. `drift` and
`expo-sqlite` are the same — a migration you did not write is a runtime problem, not a build one.

So on every platform the parity item is a **test, not a configuration**: one stored-schema fixture
per released version, asserting rows written under an older schema still load. Android gets this free
from its committed schema JSONs; the other three have to write it deliberately.

On iOS that is `UseSmileIDSampleJobSchemaTest`: a store written under v1 through the released
`VersionedSchema` and reopened, the declared version pinned against the migration plan's first
stage, and the nullable columns asserted to survive being absent, because nil is not a zero. A
version added without a case there is exactly the gap this section exists to prevent.

Without that, this whole change swaps a hand-maintained decode discipline for a hand-maintained
migration plan and gains nothing on the axis that motivated it. A store that loses a partner's
verification history silently is worse than a JSON file, because it looks like it worked.

## D5. Flutter takes `drift`

Room-shaped and the only option in the Dart ecosystem that meets D4 without hand-rolling it: codegen,
typed queries, and a schema that can be dumped and committed the way Android's is, with generated
migration steps and a test helper that verifies each step against the dumped schema.

`sqflite` alone was considered and rejected. It is the engine, not the contract — choosing it would
put Flutter exactly where iOS is today: a working store with a hand-maintained migration story.

## D6. Expo takes `expo-sqlite`, with a typed migration layer on top

`expo-sqlite` is first-party, ships with Expo, and is the right engine. On its own its migration story
is the `user_version` pragma and hand-written SQL, which does not meet D4.

Recommendation is `expo-sqlite` plus `drizzle-orm`, whose `drizzle-kit` generates migration SQL that
gets committed — the closest thing in this ecosystem to Android's committed schemas, and it satisfies
D4 by construction rather than by discipline.

`AsyncStorage` is the wrong shape and is recorded here so it is not proposed later: a key-value store
rewriting one blob is precisely what iOS is moving away from, one undecodable blob being every row.

## Dependencies

Decided rather than left pending, because these are for apps that do not exist yet and a decision
with no implementation date should not also carry an open approval. None of them is an SDK
dependency, so the registry-only rule is untouched.

| Platform | Package | Why it is not optional |
|---|---|---|
| iOS | none | SwiftData is a system framework. It will not appear in the generated notices. |
| Flutter | `drift`, `drift_dev`, `sqlite3_flutter_libs` | D4. `sqflite` alone cannot meet it. |
| Expo | `expo-sqlite` | The engine; first-party. |
| Expo | `drizzle-orm`, `drizzle-kit` | D4. Without it, migrations are hand-written SQL. |

Whoever builds those apps adds them under the ask-first rule at that point, citing this table rather
than re-deriving the choice. On iOS the notices generator walks the products the app links, so any
future third-party dependency there either appears in the notices automatically or fails the build —
additions on that platform are self-documenting.

## Settled, and what is genuinely still open

- **The iOS SDK repo's floor is not a blocker, and is not a question for now.** `ios-v12` has no
  submodule wiring and its Sample references no `SampleUI` package, so nothing depends on this
  library's floor today. The ruling is that the sample app takes 17 while the SDK stays at 15, and
  the PR that finally wires `sample-ui` into `ios-v12/Sample` is the one that carries that Sample's
  floor change. It is recorded here so that PR's author finds a decision rather than a surprise.
- **Android's undo divergence is scheduled, not open.** Removing an id it has no row for silently
  discards the undo, where iOS guards on what the removal actually took. Nothing reachable passes an
  unknown id, so it is hardening; it follows on Android's own store, after this port.
- **D5 and D6 have no implementation date**, Flutter and Expo having no apps. That is the one thing
  here genuinely waiting on something else, and what it waits on is those apps existing.
