# `spec/` — the cross-app contract

Four apps, one journey. Everything here is **data, not code**, so all four implementations agree by
construction instead of by review. Each app ships a unit test that validates itself against these
files; when they disagree, the app is wrong.

Rules:

1. **`spec/` changes first.** Add the scenario, screen or field here, then implement it in the four
   apps. A PR that adds one to a single app without touching `spec/` is a bug.
2. **IDs are stable forever.** Device flows, golden tests and CI lanes key off them. Rename an ID
   and you have broken every flow in the repo — deprecate instead, and remove in a deliberate
   sweep.
3. **`si_*` IDs belong to the SDK.** Reference them, never define them here. This repo owns
   `sample_*` IDs only.
4. **No design values copied from the SDK.** `design-tokens.json` references the SDK's public theme
   tokens and carries only genuine additions. A duplicated palette drifts silently ×4.

## Files

| File | Owns | Status |
|---|---|---|
| `scenarios.json` | Every scenario the drawer offers — flow and theme | scaffold: IDs settled, per-scenario expectations to firm up with the first app |
| `launch-args.json` | Canonical automation argument names, and how each platform accepts them | scaffold: Android/iOS mechanisms settled, cross-platform entry point to confirm |
| `result-card.schema.json` | The result card's fields and types | scaffold: field set settled |
| `test-ids.json` | The `sample_*` accessibility IDs flows assert on | scaffold: grows with each screen |
| `app-identity.json` | Application ids, display names and URL schemes per platform, plus the ids reserved by the SDK repos' development samples | settled |
| `screens.json` | 14 screens, 38 states, each linked to its design node; plus who owns each screen (sample vs SDK) and the open questions the design set raised | **filled 2026-08-12** |
| `components.json` | All 34 components with owner, design-system contract, tokens, states, reuse, and the build order | **filled 2026-08-12** |
| `design-tokens.json` | The design-system source, per-platform consumption, and the verified deltas between the design file and the token source | **filled 2026-08-12** |

## `screens.json` entry shape

One entry per screen, with its states listed separately — most design frames are *states* of a
screen, not screens, and modelling them that way is what keeps four implementations aligned. Each
state carries its design node so every engineer and agent resolves the same source, and a design
change shows up as a reviewable diff:

```json
{
  "id": "home",
  "title": "Home",
  "designUrl": "https://www.figma.com/design/<fileKey>/<name>?node-id=<nodeId>",
  "states": ["default", "loading", "error"],
  "entryRoutes": ["fullscreen", "shell"],
  "testIds": ["sample_home_start_button"],
  "notes": null
}
```

Top level carries `designVersion` — bump it whenever the design file changes, because that bump is
the checklist telling you which four app PRs are now owed.

## Where UI work starts

`docs/plan/ui-work-plan.md` sequences the build (tokens → primitives → composites → screens, Android
first as the reference for the other three) and carries the flags the design set raised. Read it
before opening a UI PR.

## Consuming `spec/` from an app

Read the JSON at build or test time; do not transcribe it into constants by hand. Each app's
validation test asserts, at minimum:

- its scenario enum contains exactly the IDs in `scenarios.json`, no more and no fewer
- its result card exposes every field in `result-card.schema.json`, with matching types
- every ID in `test-ids.json` that the app's screens should carry is actually present in its
  accessibility tree
