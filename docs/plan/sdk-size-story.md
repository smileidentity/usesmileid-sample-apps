# What the SDK costs a release app — making the published size story answer the question

**Status:** planning. The measurement pipeline is **already built and already public** — this plan is
about what it says, not about building it.

## 1. Status: shipped, not planned

The size-analysis CI landed across all four SDK repos on 2026-07-16 and has been running since. Each
repo has `size.yaml` and `size-dependabot-sweep.yaml`, and the pipeline is more complete than "planned"
suggests:

- A release AAB / xcarchive is built and uploaded to Sentry Size Analysis.
- Triggers are deliberate: push to `main` establishes a baseline, a weekly cron keeps the trend line
  honest in a quiet week, and `workflow_dispatch` with a PR number produces a head-vs-base comparison on
  demand. Per-PR was rejected because a size delta is not something anyone acts on inside one review
  cycle and the build is expensive.
- **It already writes the public README.** The job regenerates a `## SDK Size` table, and if it changed,
  opens or refreshes a PR on a stable `automation/size-analysis` branch with auto-merge.

So the ask — *"we'd love to have it on the public readme to show the SDK size cost of a release app"* —
is **live in all four READMEs today**. What follows is the gap between what those tables show and what
that sentence actually asks for.

## 2. What the four tables say right now

| Repo | Headline rows | Download | Install |
|---|---|---|---|
| android | Sample app | 14.99 MB | 31.88 MB |
| ios-v12 | App total | 5.74 MB | 18.36 MB |
| flutter | Sample app (Android) | 18.84 MB | 42.43 MB |
| flutter | Sample app (iOS) | 10.69 MB | 26.80 MB |
| react-native-expo | Sample app (Android) | 28.90 MB | 76.23 MB |
| react-native-expo | Sample app (iOS) | 17.91 MB | 56.88 MB |

**The two cross-platform SDKs already publish both platforms; the two native ones publish one each** —
which is the right shape in both cases, since a native SDK has only one. **Flutter is the best of the four
and should be the model**, because its explainer already does the hard part — it says the per-package rows are the pub.dev
artefact (compressed archive, then unpacked in the cache), that those are Dart plus native *source*, and
that *"their compiled contribution to your app is what the Sample app rows measure."* Android's AAR
caveat is the same instinct applied to one column.

## 3. Three problems a partner will hit

**3.1 The tables are four different shapes, so nothing is comparable.** Android leaves Download and
Install empty (`—`) on every module row and fills only the Sample app row. iOS has no per-framework
Download column at all — correctly, because merged frameworks cannot be sized separately, and the README
says so. Flutter and Expo fill both columns per package, but mean the pub/npm artefact by it, not the
app contribution. A partner evaluating two platforms is reading two different questions' answers. Since
Flutter already resolves this well, the fix is to converge on its shape rather than design a new one.

**3.2 The headline numbers invite a false conclusion.** Read cold, the table set says Expo costs 28.90 MB
where Android costs 14.99 MB and iOS costs 5.74 MB — that iOS is a third of Android and Expo is twice it.
Some of that gap is real (a JS bundle and its engine; ML models packaged per ABI) and some is an artefact
of what each sample happens to bundle. **None of it is explained.** A number a partner can misread
against us is worse than no number.

Where the asymmetry actually is: **Android publishes per-module rows with both size columns empty** (`—`),
so nine of its eleven rows carry no number at all, while Flutter and Expo fill theirs and mean the
package artefact by it. The reader cannot tell that these are different questions without reading three
explainers.

**3.3 The tables answer the wrong question.** Every headline row is the **absolute size of a sample app**.
The question partners actually ask is the **marginal cost**: *what does adding Smile ID do to my app?*
Those differ by everything the sample carries that a partner's app already has — Compose, an HTTP client,
Kotlin's stdlib. Quoting an absolute total as a cost systematically overstates it.

## 4. Sentry or the local scripts? Both, doing different jobs

This has been measured two ways in this org, and the two are not competing — they answer different
questions, and each is bad at the other's.

**The local script method** built a realistic host app with the SDK **source-set switched**
(`src/noSdk` / `src/withSdk`, selected by a Gradle property) so the baseline genuinely contains no Smile
ID code while the rest of the app stays byte-identical. That produced the number partners actually want:

| Stage | Contents | Universal APK | arm64-v8a |
|---|---|---|---|
| baseline | host only, no Smile ID | 1.63 MB | 1.54 MB |
| + `usesmileid` + `mlkit-face` | selfie-capable | 5.02 MB | 4.74 MB |
| **delta** | **what the SDK costs** | **+3.39 MB** | **+3.20 MB** |

So SmartSelfie enrollment and authentication cost **≈3.2–3.4 MB** in a release R8 build **of that host**.
The qualifier is not pedantry: the delta depends on what the host already carries, which is exactly what
the overlap dividend below measures. Any figure published must say which host it was measured against,
or a partner will quote it as a universal constant and be wrong in both directions.
Document capture adds **≈+13.75 MB** on top, almost all of it the ML model. And the overlap dividend —
the saving from dependencies a real host already has — measured **16–22% on code and 0% on the model**.
That last figure is the most useful single fact in the whole exercise: **the model gets no overlap
dividend**, so a document-capable integration costs nearly full price no matter how big the host app is.

**What the local method could not do**, recorded honestly at the time: it measured APK and AAB **file**
sizes, because `bundletool` was not installed, so Play *delivery* size went unmeasured. And AAB file size
diverges sharply from delivery size — in that run the baseline's AAB was **larger** than its universal
APK. A file-size proxy is not merely imprecise here; it points the wrong way.

**What Sentry does that the scripts cannot:** Download and Install size as the **stores themselves**
compute them, which our own README already calls *"usually the one people mean"*; a continuous trend line;
threshold status checks; and the automated README publish. What Sentry **cannot** do is produce a delta,
because there is only ever one app in the pipeline.

### 4.1 The recommendation

**Keep Sentry as the pipeline. Adopt the local method as a second arm inside it.** Concretely: give the
sample app the same `noSdk` / `withSdk` source-set switch, build both arms in the existing lane, upload
both to Sentry, and publish the difference. That yields a store-accurate **delta** — which neither
approach reaches alone — from one pipeline, one set of secrets, and one place to maintain.

Replacing Sentry with the scripts would trade the store-accurate numbers, the trend line and the
automation for a file-size proxy that has already been shown to mislead. Keeping only Sentry leaves the
partner's actual question unanswered. The combination is the only option that answers it.

So each README's headline becomes two numbers:

- **Adding Smile ID costs +X MB download / +Y MB install** — measured against the byte-identical baseline.
  This is the answer, and it goes first.
- **A fully-featured sample app is Z MB** — kept, because it bounds the worst case and the pipeline
  already produces it.

Plus one shared paragraph explaining why the four platforms differ, and three rules carried over from the
local work: **never quote a debug number** (the measured baseline was 20.9 MB debug against 1.63 MB
release, −91.8%), **native `.so` files are stored uncompressed** so per-ABI packaging dominates and asset
savings are smaller than they look, and **measure against a realistic host, not an empty one**, or the
overlap dividend is invisible and the cost overstated.

One thing the local run flagged that the delta arm inherits: **the SDK cannot be measured without an ML
provider.** A selfie host has to reference `FaceDetectorAnalyzer`, which lives in `mlkit-face`, so a
"`usesmileid` alone" configuration does not compile. That is correct behaviour, not a defect — but it means
the smallest publishable delta is *SDK plus a provider*, and the table should say so rather than imply a
smaller floor exists.

## 5. Known tail — smaller than it was

<!-- INTERNAL-ONLY:START reason=internal-ci-history-and-dates -->
Two of the three things this plan originally listed here are **already closed, verified 2026-08-11**: the
upload-quota pressure was retired by moving the lane from per-PR to weekly across all four repos, and the
stale `automation/size-analysis-{android,ios}` branches were deleted, leaving only the live one. The Expo
test-APK R8 rule also landed as a config plugin.
<!-- INTERNAL-ONLY:END -->

What remains is one genuinely open CI item: a **reusable size-report workflow with budget gates**. Today a
regression is visible in a trend line nobody is required to look at. A budget gate is what turns the
measurement into a signal — and it is the natural place for the treemap-sanity and stale-prose checks that
were folded into it.

The staleness risk in §3 stands regardless, and is the same failure mode as the consumption plan's: **a
green run that proves nothing.** A frozen table reads exactly like a current one.

## 6. Work items

| ID | Item | Notes |
|---|---|---|
| SIZ-1 | Adopt **Flutter's** table shape across the other three | Flutter is already the best of the four: both platforms present, and an explainer that says the per-package rows are pub.dev artefacts whose compiled contribution the sample rows measure. Copy it rather than invent a shape |
| SIZ-2 | `noSdk`/`withSdk` source-set switch in the sample, both arms uploaded to Sentry | §4.1. Byte-identical baseline is the whole point — a stubbed-at-runtime baseline is not one |
| SIZ-3 | Publish **+delta** as the headline, keep the absolute total beneath it | The number that answers the question partners ask |
| SIZ-4 | One shared explainer paragraph on why platforms differ | Prevents the cross-platform misread |
| SIZ-5 | Fill Android's empty per-module columns, or drop them and say why | Nine of eleven rows currently carry no number |
| SIZ-6 | Staleness guard: fail the lane when its own README PR has not merged | A frozen table must not read as a current one |
| SIZ-7 | Reusable size-report workflow + **budget gates** | The one open CI item; turns the trend line into a signal. Absorbs the treemap-sanity and stale-prose checks |
| SIZ-8 | State the "no ML provider" floor in the explainer | §4.1 — the smallest honest delta is SDK + a provider |

## 7. Landing order

SIZ-6 first, and it is the cheapest item here: until a stale table fails loudly, every other number in
this plan can silently be wrong. SIZ-2 and SIZ-3 next, on Android only — one platform with a real delta
published is worth more than four with absolute totals. SIZ-1 and SIZ-4 once there is a second platform to
be consistent *with*; doing them first would standardise a shape we are about to change. SIZ-5 and SIZ-8 alongside whichever
table they touch. SIZ-7 last and separately — budget gates are only meaningful once the number being
gated is the delta rather than the absolute.
