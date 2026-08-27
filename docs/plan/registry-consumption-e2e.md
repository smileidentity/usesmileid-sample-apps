# Proving the published SDK — registry and snapshot consumption, end to end

**Status:** planning. This is the lane `AGENTS.md` §Testing already names as *"Registry & companion
builds (candidate lane, not yet implemented)"*, written out. Nothing here changes an app's behaviour;
it changes what CI can prove about an artifact a partner will actually download.

Scope: all four apps, but Android first because it is the only one that exists. The lane is the same
shape on every platform, so §7 is a translation table rather than three more plans.

## 1. Why this is the highest-value post-release work

The repo's founding argument is in `AGENTS.md`: an SDK repo's own sample resolves the SDK by path, so
it *cannot* catch a defect that lives in the published artifact. These apps consume the published form,
which is the only configuration where a missing dependency, an absent packaged file, or a keep rule
that only fails under release minification will show up.

That argument is currently **unbanked**. The four apps do not yet run against the registry in CI, and
the lane that does exist stops well short of what the argument requires.

## 2. What exists today, read out of the workflows

Each SDK repo has `registry-consumption.yaml`. Android's is representative:

- **Trigger:** `workflow_dispatch` plus a weekly `cron: "0 4 * * 1"`.
- **Version resolution:** reads `<release>` from the Maven Central `maven-metadata.xml` for
  `usesmileid-bom`. That element is **the latest stable release, by definition** — a snapshot can never
  be selected by this lane.
- **Consumer:** the job **scaffolds a synthetic app inline** — it writes a `build.gradle.kts` in the
  workflow, borrowing only the AGP and Kotlin pins out of the repo. No repo module is built, and the
  four real sample apps are not involved.
- **Depth:** `./gradlew -p consumer :app:assembleRelease`. The header says it plainly:
  **"Build-and-link only."**

So it answers one question well — *does the published artifact resolve and link?* — and four questions
not at all.

## 3. The four gaps, in the order they cost us

1. **It never launches the app.** `AGENTS.md` already anticipates exactly this: *"dyld defects only
   fail at launch, so the lane must end by launching the app, not linking it."* A linked binary proves
   the graph resolved; it proves nothing about a missing runtime resource, an R8-stripped reflective
   entry point, or a native library absent for the device's ABI. Every one of those ships green today.
2. **It only ever tests the latest stable.** There is no snapshot lane, so a regression introduced
   after a release is invisible until the next release consumes it — which is the worst possible time to
   discover it. The recent weeks of publish-side trouble are the argument for this.
3. **The consumer is synthetic, not a real app.** A scaffolded `build.gradle.kts` with one activity does
   not exercise the SDK's UI, its camera, its ML models, or its networking. The four sample apps do, and
   they already exist for precisely this reason. Two lanes maintaining two different notions of "a
   consumer" is also two things to keep current.
4. **Companions are untested.** `AGENTS.md` calls for building *"alongside the companions real partner
   apps bring (a host-initialised Sentry on iOS; whatever the Flutter graph carries transitively)"*.
   Nothing does this. A shared-dependency version conflict between the SDK's Sentry and a partner's own
   is a class of defect this lane exists to find, and it has never run.

## 4. The lane this should become

One workflow per platform in **this** repo — not in the SDK repos — because the consuming host is what
this repo is. Four stages, and the value is concentrated in the last one.

| Stage | What it proves | Fails on |
|---|---|---|
| **Resolve** | the requested version exists and its POM/manifest is coherent | a broken publish, a missing transitive |
| **Build release** | it survives minification and resource shrinking with no app-side keep rules | keep-rule regressions, missing resources |
| **Launch** | the process reaches the product list | dyld/linkage failures, missing native libs, stripped entry points |
| **Drive** | a real journey runs — SDK mount, capture entry, a terminal result | anything the first three cannot see |

**Stage 4 is the point.** The existing device suite already knows how to do it: `AGENTS.md` requires
every device flow to open with *"launch → product list → SDK-mount assertions so packaging failures fail
conclusively"*. That assertion is already written. This lane's job is to point it at a registry-resolved
build instead of a locally built one.

### 4.1 Matrix: two versions, not one

- **`stable`** — the latest release, as today. Answers "is what partners have right now still sound?"
- **`snapshot`** — the current pre-release. Answers "did we break consumption since the release?", which
  is the question that actually shortens a release cycle.

Snapshot provisioning already differs per SDK — four different mechanisms, and one of them is a rolling
Maven pin whose contents change under a fixed coordinate. That is a real hazard for a cache-backed lane:
a cached snapshot is a *stale* snapshot, and a green run on stale bytes is worse than no run. So the
snapshot arm must resolve fresh every time and record the resolved build identifier in its summary, or
its green means nothing.

### 4.2 Companions

A third arm, cheap to add once stage 4 exists: the same app plus the dependencies real partners bring.
Start with what `AGENTS.md` already names — a host-initialised Sentry, and whatever the Flutter graph
pulls transitively — because both are observed partner behaviour rather than invented cases. Conflicting
versions fail at resolve; initialisation order failures fail at launch. Both are stages we now have.

## 5. Improving the E2E infrastructure underneath it

None of the above is worth building on a flaky base. Four things are known to make device runs lie, all
of them learned the hard way rather than theorised, and each has a mechanical fix that belongs in the
harness rather than in a reviewer's memory:

1. **A pass can verify the wrong binary.** Nothing in the sample UI identifies which build is running,
   and a second Smile ID sample installed alongside is enough to make every screen observation
   meaningless. **Fix:** assert the package under test *first, every time*, and surface a build
   identifier in the accessibility tree so a flow can assert on it rather than trust the installer.
2. **A stale store fakes a clean run.** Re-running a flow does not clear persisted state; comparing a
   red flow across two branches needs uninstall-plus-reinstall per arm. **Fix:** make a clean install
   the lane's default rather than an operator's discipline.
3. **First cold start after install exceeds the default assertion timeout** on release builds. **Fix:**
   a warm-start step before the first assertion — the suite already has one; it must be mandatory in
   this lane rather than optional.
4. **Read state from the accessibility tree, never from a screenshot or a log poll.** Logs should be
   written to a file and read at the end, not polled. This is already the contract; the lane needs to
   inherit it explicitly because CI is where the temptation to `sleep` and grep is strongest.

The general principle worth writing into the lane: **a green run must be able to say what it proved.**
Every arm ends by emitting the resolved SDK version, the package it drove, and the assertions it
cleared, into the job summary. A lane that cannot answer "what did this prove?" eventually proves
nothing while staying green.

## 6. Work items

| ID | Item | Notes |
|---|---|---|
| CON-A1 | Build-identifier surface: version + variant readable from the accessibility tree | Precondition for every other item. Fixes the wrong-binary class outright |
| CON-A2 | Clean-install default in the device runner (uninstall → install → warm start) | Folds gaps 2 and 3 into the harness |
| CON-A3 | `registry-consumption.yaml` in this repo: resolve → build release → launch → drive, `stable` arm | The lane `AGENTS.md` specifies; Android first |
| CON-A4 | `snapshot` arm, resolving fresh with no cache, recording the resolved build id | Never reuse a cached snapshot |
| CON-A5 | Job-summary contract: resolved version, package driven, assertions cleared | So a green run states what it proved |
| CON-A6 | Companion arm: host-initialised Sentry, transitive graph conflicts | After CON-A3 works |
| CON-A7 | Retire or narrow the SDK-repo `registry-consumption.yaml` to resolve-and-link | Two definitions of "a consumer" is one too many. **Needs the SDK repos' agreement** |
| CON-A8 | Failure triage doc: which stage failed ⇒ which class of defect | Turns a red lane into an actionable one |
| CON-A9 | Port CON-A1…A5 to iOS, then Flutter and Expo | §7 |

## 7. Parity — the same lane, per platform

| Platform | Launch + drive | Snapshot source shape |
|---|---|---|
| Android | Maestro on a Gradle Managed Device | rolling Maven pin — resolve fresh, never cache |
| iOS | XCUITest on a pinned simulator | Swift package pre-release; a tag is not a version |
| Flutter | Maestro | pub pre-release, plus the iOS plugin resolution its own lane already checks separately |
| Expo | Maestro | npm dist-tag; `--legacy-peer-deps` silently drops peers, so resolve strictly and fail loudly |

The stage names, the job-summary contract and the assertion set are identical across all four. Only
resolution and the runner differ — which is the same split `spec/launch-args.json` already uses for
argument delivery.

## 8. Landing order

CON-A1 and CON-A2 first: they are harness fixes, they make every existing device run more trustworthy
immediately, and nothing later is believable without them. CON-A3 next, `stable` only, on Android only —
one platform proving the four stages is worth more than four platforms proving two. CON-A4 as soon as
A3 is green, because the snapshot arm is where the recurring pain actually lives. CON-A5 alongside A4,
while the summary format is still cheap to change.

CON-A6 and CON-A8 after the lane has run enough times to be trusted. CON-A7 is a conversation with the
SDK repos, not a code change, and should not block anything. CON-A9 rides with each port rather than
arriving as a separate project.
