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

| Repo | Headline row | Download | Install |
|---|---|---|---|
| android | Sample app | 14.99 MB | 31.88 MB |
| ios-v12 | App total | 5.74 MB | 18.36 MB |
| flutter | per-package rows | filled | filled |
| react-native-expo | Sample app (Android) | 28.90 MB | 76.23 MB |

The Android table's explainer is already the most honest thing in the set: *"AAR size … is not the amount
added to your app: your app's R8 pass strips what you don't use, and the Sample app row shows the real
impact."*

## 3. Three problems a partner will hit

**3.1 The tables are four different shapes, so nothing is comparable.** Android leaves Download and
Install empty (`—`) on every module row and fills only the Sample app row. iOS has no per-framework
Download column at all — correctly, because merged frameworks cannot be sized separately, and the README
says so. Flutter and Expo fill both columns per package. A partner evaluating two platforms is reading
two different questions' answers.

**3.2 The headline numbers invite a false conclusion.** Read cold, the table set says Expo costs 28.90 MB
where Android costs 14.99 MB and iOS costs 5.74 MB — that iOS is a third of Android and Expo is twice it.
Some of that gap is real (a JS bundle and its engine; ML models packaged per ABI) and some is an artefact
of what each sample happens to bundle. **None of it is explained.** A number a partner can misread
against us is worse than no number.

Also worth catching: Expo's row is labelled *"Sample app (Android)"*, so there is **no iOS figure in the
Expo table at all**, and nothing says why.

**3.3 The tables answer the wrong question.** Every headline row is the **absolute size of a sample app**.
The question partners actually ask is the **marginal cost**: *what does adding Smile ID do to my app?*
Those differ by everything the sample carries that a partner's app already has — Compose, an HTTP client,
Kotlin's stdlib. Quoting an absolute total as a cost systematically overstates it.

## 4. The fix: publish a delta, and say what it is a delta of

The mechanism already exists in this org's integration work: a host app measured **without** the SDK, then
the same app **with** it, yields the marginal cost directly. That baseline-then-delta measurement has been
done by hand at least once. Productising it is the whole of this plan.

So each README's headline becomes two numbers, not one:

- **Adding Smile ID costs +X MB download / +Y MB install** — the delta against the same app without it.
  This is the number that answers the question and the number that belongs at the top.
- **A fully-featured sample app is Z MB** — kept, because it bounds the worst case and it is what the
  pipeline already measures.

And one paragraph, identical in all four READMEs, saying **why the four numbers differ** — JS engine and
bundle on Expo, per-ABI native ML models on Android, merged binaries on iOS — so a cross-platform reader
draws the right conclusion instead of an available one.

The delta arm needs a baseline app that is honest: same minification, same shrinking, same ABIs, differing
only by the SDK dependency. The existing lane already builds release-representative artefacts on all four
platforms, so the second build is a variant of a solved problem rather than a new one.

## 5. Known tail, from the lane's own operation

Three things the running pipeline has surfaced that this plan should close alongside the above: the
Flutter lane has been constrained by upload quota; the Expo release measurement depends on R8 and resource
shrinking being on, which the Expo template defaults *off*; and the `automation/size-analysis` branches go
stale when a run's PR is not merged, which quietly freezes the published table at an old value while the
lane keeps reporting success.

That last one matters most and is the same failure mode as §5 of the consumption plan: **a green run that
proves nothing.** A stale table is indistinguishable from a current one to a reader.

## 6. Work items

| ID | Item | Notes |
|---|---|---|
| SIZ-1 | One table shape across four READMEs, with per-platform columns only where they are meaningful | iOS's missing Download column is correct and stays — the *shape* unifies, not the physics |
| SIZ-2 | Baseline arm: same app, same release config, no SDK | The delta's denominator. Reuses the existing release build |
| SIZ-3 | Publish **+delta** as the headline, keep the absolute total beneath it | The number that answers the question partners ask |
| SIZ-4 | One shared explainer paragraph on why platforms differ | Prevents the cross-platform misread |
| SIZ-5 | An iOS figure in the Expo table, or a sentence saying why there is none | Today it is silently absent |
| SIZ-6 | Staleness guard: fail the lane when its own README PR has not merged | A frozen table must not read as a current one |
| SIZ-7 | Close the quota and shrink-config tail on the Flutter and Expo lanes | Pre-existing, and it is what makes those two rows trustworthy |

## 7. Landing order

SIZ-6 first, and it is the cheapest item here: until a stale table fails loudly, every other number in
this plan can silently be wrong. SIZ-2 and SIZ-3 next, on Android only — one platform with a real delta
published is worth more than four with absolute totals. SIZ-1 and SIZ-4 once there is a second platform to
be consistent *with*; doing them first would standardise a shape we are about to change. SIZ-5 and SIZ-7
whenever their platforms are next touched.
