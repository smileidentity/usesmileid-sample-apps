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
| `screens.json` | Screen inventory, each with its design source and `designVersion` | **empty — filled from the design file (phase F0)** |
| `design-tokens.json` | SDK token references plus this app's additions | **empty — filled from the design file (phase F1)** |

## `screens.json` entry shape

`screens.json` starts empty on purpose: it is filled once from the design file so that every
engineer and agent resolves the same design source for a screen, and so a design change shows up as
a reviewable diff. One entry per screen:

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

## Consuming `spec/` from an app

Read the JSON at build or test time; do not transcribe it into constants by hand. Each app's
validation test asserts, at minimum:

- its scenario enum contains exactly the IDs in `scenarios.json`, no more and no fewer
- its result card exposes every field in `result-card.schema.json`, with matching types
- every ID in `test-ids.json` that the app's screens should carry is actually present in its
  accessibility tree
