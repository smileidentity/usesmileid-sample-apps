# Device-suite cycle time — getting a PR verified in minutes, not hours

**Status:** PROPOSED 2026-08-27, nothing implemented. Written from measurements taken on 2026-08-26
while landing the sheet-layering and stroke work, so every number below is observed rather than
estimated.

**The problem in one line:** verifying a PR costs ~2 hours of device time, all of it in the Maestro
suite, and on the day it was measured the suite returned **zero findings** across four runs.

---

## 1. Where the time actually goes

| Stage | Measured | Findings it produced that day |
|---|---|---|
| `android/verify.sh` — tokens, notices, lint, unit tests, goldens, minified release assemble | 1m 33s – 3m | the contrast-band violation, spec drift, a stale generated token |
| Golden re-record + reading them | 15s + review | the filter chips, the setting-row dividers, both stroke regressions |
| Android CI | ~12m | nothing (it runs `verify.sh`) |
| **Maestro suite, debug** | **36m – 53m** | **nothing** |
| **Maestro suite, release** | **36m – 42m** | **nothing** |

Four full-suite runs that day: 41m15s, 53m30s, 36m09s, 41m55s. The suite is ~95 % of the cost of
verifying a change and produced none of the day's findings — every real defect was caught by the
2-minute gate or by looking at a golden.

**Two costs the table hides.** Two further suites *collapsed* mid-run and had to be repeated
(§5), and the wall-clock spread across identical runs is 17 minutes, which is transport variance
rather than test work.

## 2. The four levers, best payoff first

### 2.1 Shard the suite — and it need not cost disk

The suite is eight independent flows run **serially on one device**. Maestro shards natively
(`--shard-split`). The objection is disk: four AVDs is 20 GB+, and this machine hosts toolchains for
four platforms.

**Multiple emulator instances can run off a single AVD.** `emulator -avd <one> -read-only` boots
extra instances that share the AVD directory and write to temp; add `-no-snapshot-save` and they
leave nothing behind. The marginal disk cost of instances 2..N is transient, so "four emulators" is
really "one AVD, four processes" — RAM and CPU become the limit, not disk. Even two instances halves
the wall clock.

**Also consider an ATD system image** (`google_atd` / `aosp_atd`): purpose-built for automated
testing, stripped of the apps and UI a normal image carries, materially smaller on disk and lighter
on RAM. **Verify first** whether the SDK's ML Kit path needs Play services and whether `google_atd`
carries enough of them. Likely fine — the public flows deliberately stop at the capture screen and
never complete one — but confirm rather than assume.

### 2.2 Measure the wireless-adb tax before buying anything

Identical flows ran 36m and 53m on the same phone. Maestro dumps the view hierarchy once per
assertion, and `settings.yaml` alone is 241 commands on debug / 266 on release — **every dump
crosses Wi-Fi.** A local emulator talks over loopback.

**The experiment is one flow and costs nothing:** run `verifications.yaml` against a local emulator,
then the same flow on the phone, and compare. If the gap is large, moving routine runs local beats
parallelism *and* removes the failure class in §5.

### 2.3 Stop running release on every PR

The release suite cost ~42m and found nothing debug did not. "Release builds are first-class"
(AGENTS.md) is right — minification defects only surface there — but the **cadence** can change
without weakening it:

- **every PR:** debug
- **merge to main, and nightly:** release
- **PRs touching packaging:** release too — Gradle files, proguard rules, the manifest, dependency
  or SDK-version bumps

That is a stated risk boundary rather than a silent gap, and it halves per-PR device time today.

### 2.4 Select flows by what changed

The stroke-and-copy change ran `sdk-flow`, `token-session` and `profiles` — none of which it could
affect. `.github/workflows/android.yml` already has path filters; the same idea maps paths → flow
sets.

Two guards make it safe, and both are load-bearing:

1. **Default to the full suite** when a changed path is not in the map. A green partial run must
   never be mistakable for a green full run.
2. **A label that forces everything**, for when the author knows better than the map.

Most PRs land at 1–2 flows, i.e. ~5 minutes on today's hardware.

## 3. The deeper fix: move work down the pyramid

Of everything verified on 2026-08-26, only three facts were genuinely device-only:

- the screen is visible behind a sheet's scrim — and only a **screenshot** can show it, because
  Android drops the windows below a modal from the accessibility tree
- cold and warm deep links resolve to the right owner and back stack
- the release build behaves like the debug build

The strokes, the copy and the section headings were fully covered by goldens and the contrast tests
in about two minutes. Deep-link and back-stack behaviour could largely move into in-process
Compose/Robolectric tests running in seconds — `UseSmileIDSampleRoutesSpecTest` already covers the
link **resolver** that way, and the same approach reaches the layer actually opening.

## 4. Batch, don't repeat

The device pass earns its place **once per batch**, not once per PR. The 2026-08-26 PR carried four
logical changes and amortised one device pass across all of them. For a stack of PRs, run the full
suite on the stack tip.

## 5. The flakiness tax, and the one-line guard

Two suites collapsed that day with a signature worth recognising:

- four flows failing in **milliseconds**, one taking 16m for a 2m flow
- a failure screenshot showing a **blank white screen**
- `MaestroSessionManager` teardown exceptions in the log

Both collapses happened while the phone was **discharging** (51 % and falling, on wireless adb).
The same suites then passed 8/8 twice on AC power. A millisecond failure is always the harness.

`tools/verify/maestro.sh` refuses a run below `VERIFY_MIN_BATTERY` (20 %) **when discharging** — but
51 % is well above that floor, so the floor is not the signal. For a **full-suite** run the useful
signal is simply whether the device is on AC at all.

Also: write suite output to a file rather than a pipe. A dead reader once left Maestro blocked on
its final write, hung for ~20 minutes after the run had effectively finished.

## 6. Suggested order

| # | Step | Cost | Effect |
|---|---|---|---|
| 1 | Measure one flow: local emulator vs wireless phone (§2.2) | minutes | tells you whether transport is the problem |
| 2 | Relevance-based flow selection + debug-only per PR (§2.3, §2.4) | config | typical PR → ~5 min |
| 3 | Two emulator instances off one AVD, if RAM allows (§2.1) | none on disk | halves what remains |
| 4 | Full suite on the physical device nightly, or on a device cloud | — | keeps the coverage, off the PR path |
| 5 | Require AC for a full-suite run (§5) | one line | removes the collapse class |

## 7. What not to do

Do not keep the current cadence and simply trust it less. That is close to what happened on
2026-08-26: two hours were paid, two runs were untrustworthy, and it took a branch-vs-`main`
comparison plus a clean reinstall to establish that nothing had regressed at all.
