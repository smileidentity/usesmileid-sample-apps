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
| `launch-args.json` | Canonical automation argument names, and how each platform accepts them | **implemented on Android 2026-08-14**; `seedProfiles` added 2026-09-04 on Android, owed by the three ports with their parsers; cross-platform entry point still to confirm |
| `result-card.schema.json` | The result card's fields and types | **implemented on Android 2026-08-14**; `sdkVersion` blocked on the SDK, see the field's `blocked` note |
| `test-ids.json` | The `sample_*` accessibility IDs flows assert on | scaffold: grows with each screen |
| `app-identity.json` | Application ids, display names and URL schemes per platform, plus the ids reserved by the SDK repos' development samples | settled |
| `routes.json` | The shared route table — ids, deep-link paths, typed arguments and the per-platform binding | **added 2026-08-13** |
| `screens.json` | 20 screens, 57 states, each linked to its design node or marked `"design": "in-repo"` where the design has no frame; plus who owns each screen (sample vs SDK) and the open questions the design set raised | **filled 2026-08-12**; document features added 2026-09-28 |
| `components.json` | All 34 components with owner, design-system contract, tokens, states, reuse, and the build order | **filled 2026-08-12** |
| `design-tokens.json` | The design-system source, per-platform consumption, and the verified deltas between the design file and the token source | **filled 2026-08-12** |
| `bundled-assets.json` | Third-party assets bundled in the tree (the DM Sans font, the Material Symbols icons), which every licences screen lists alongside the registry dependencies | settled |
| `store-art.json` | The made-up organisation, initials and session the store screenshots show, read by the Android and iOS store-art tests | settled |
| `catalogue-fixture.json` | The country, ID-type and document lists a device flow sees under `catalogue=fixture`, in the API's response shape. A UI test input of about a dozen rows, not a copy of the API | added 2026-09-28 |
| `catalogue-rules.json` | Test cases for turning an API response into the form's rows: which ID types the form can satisfy, repeated types, sub-types, the countries each product offers, and how "Capture as" becomes `DocumentCaptureConfig` | added 2026-09-28 |
| `id-number-hints.json` | Test cases for the ID-number hint computed from a type's regex, and the regexes every platform's engine must compile | added 2026-09-28 |

## `screens.json` entry shape

One entry per screen, with its states listed separately — most design frames are *states* of a
screen, not screens, and modelling them that way is what keeps four implementations aligned. Each
state carries its design node so every engineer and agent resolves the same source, and a design
change shows up as a reviewable diff:

```json
{
  "id": "verifications",
  "title": "Verifications",
  "owner": "sample",
  "board": "02",
  "route": "tab",
  "states": [
    { "state": "default", "node": "5206-2410" },
    { "state": "selectMode", "node": "5206-2441", "note": "NavBar hidden, selection bar replaces it." }
  ],
  "components": ["FilterChip", "JobRow", "StatusBadge", "SelectionBar"],
  "testIds": ["sample_verifications_screen", "sample_job_row"]
}
```

Resolve a node to its design URL with the top-level `urlTemplate`. `owner` is load-bearing:
`sample` means this repo builds it, `sdk` means the SDK renders it inside its own flow and we must
not rebuild it. `components` must name entries that exist in `components.json` — a sub-element goes
in that component's `parts`, not here.

Top level carries `designVersion` — bump it whenever the design file changes, because that bump is
the checklist telling you which four app PRs are now owed.

## Where UI work starts

`docs/architecture.md` covers the build order (tokens → primitives → composites → screens), and
routing and state per platform. A screen and its route land in one PR. Read it before opening a UI PR.

## Consuming `spec/` from an app

Read the JSON at build or test time; do not transcribe it into constants by hand. Each app's
validation test asserts, at minimum:

- its scenario enum contains exactly the IDs in `scenarios.json`, no more and no fewer
- its result card exposes every field in `result-card.schema.json`, with matching types
- every ID the app declares is in `test-ids.json`; Expo also asserts the reverse, and iOS that every
  declared ID is applied in source. No app inspects an accessibility tree for them; only a device flow
  keyed off the spec does that

## Spec debt

Every place where the spec, the design and the apps disagree, with what was decided. Add a row when you
find one, and delete it in the pull request that closes it.

| Item | Today | Decision |
|---|---|---|
| `sample_env_chip` in `test-ids.json` | Android and iOS attach it to their chip component, but no shipped screen shows the chip: the result card publishes the environment instead. Flutter and Expo have no chip | Kept, so the chip carries its id if it ever returns. Flutter and Expo excuse it in their id checks |
| `sample_license_link` in `test-ids.json` | Attached on Android and iOS; Flutter and Expo have no notice that links a page | Present only where the platform's graph yields a notice whose text cannot travel (the `licenses` note in `screens.json` says so). Flutter and Expo excuse it |
| Licences-screen wording in `screens.json` | Described Android's two sections, which Flutter and Expo cannot produce | Describes the property instead: full text where it travels, a link where it cannot |
| Consent form's required fields | The spec listed only the two names; the design labels email and phone optional; the SDK rejects a submission with neither | The SDK wins. Every app requires an email or a phone unless the token binds one, and `screens.json` says so. The design labels are owed a correction |
| Button height 48 against 52 | The design board draws 48; the design system's `button.height` is 52 | 52, the design-system token |
| Card glyph 21 against 20 | The design board draws 21; `size.icon-md` is 20 | 20, the design-system token |
| Verifications list `refreshing` state in `screens.json` | The design draws a pull-to-refresh on the list (node 5206-2608); no app builds it. Refresh exists only on a verification's detail screen | Not built. Jobs are stored on the device, and no endpoint lists a partner's jobs, so a list-wide pull has nothing to ask. The state stays in `screens.json` because the design has it |
| `components.json` | Consumed by nothing but comments in golden tests | Informative: it records owners, tokens and states for a reader, and no test asserts it. A value that must hold belongs in a file an app test reads |

