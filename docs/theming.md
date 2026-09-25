---
description: How the sample apps theme themselves and the Smile ID SDK — the SDK's theme override, one design-token source generated per platform, semantic colours, dark mode, contrast, text scale and goldens.
---

# Theming

There are two layers, and the apps keep them apart. The **host app** has its own theme, generated from
the Smile ID design system. The **SDK flow** gets its colours only through the flow builder's public
`theme { }` override. This page shows both, and the rules that keep four platforms visually identical.
For the SDK's theme slots themselves, see
[Theming and Customization](https://docs.smileidentity.com/developer-resources/sdks/mobile/theming-and-customization).

## Prerequisites

- Any of the four apps, built from this repository.
- To regenerate design tokens: Python 3, and a checkout of the design system pointed to by
  `SMILE_DESIGN_SYSTEM`. The token source lives in a private repository, so partners read the vendored
  output rather than regenerating it.

## 1. Style the SDK only through `theme { }`

The sample never styles SDK screens any other way. The theme scenarios in `spec/scenarios.json` drive
the override:

| Scenario | What it shows |
|---|---|
| `brandDefault` | Smile ID branding, light or dark per the Settings switch. No override |
| `clashingHost` | A deliberately distant host theme (a different seed colour, corner radius and typeface), which exposes host-versus-SDK styling collisions |
| `partnerOverride` | A plausible partner palette through the same override, which shows which tokens follow it and which stay SDK-owned |

The Android override, from `android/app/…/flow/FlowBuilderConfig.kt`:

```kotlin
snapshot.theme.override?.let { palette ->
    theme {
        primaryColor = palette.primaryColor
        primaryForeground = palette.primaryForeground
        secondaryColor = palette.secondaryColor
        accentColor = palette.accentColor
        buttonShape = palette.buttonShape
        palette.fontFamily?.let { fontFamily = it }
    }
}
```

The iOS, Flutter and Expo equivalents are in each app's `FlowBuilderConfig` file (see
[`architecture.md`](architecture.md) §6). The palettes are stated once in `sample-ui`, in the SDK's own
types.

## 2. One token source, generated per platform

Colours, the type ramp, spacing, radii and shadows come from one design-token set.
`scripts/sync_design_tokens.py` vendors it into Kotlin, Swift, TypeScript and Dart:

```bash
scripts/sync_design_tokens.py --all      # vendor tokens for every platform
scripts/sync_design_tokens.py --check    # fail if a vendored file is stale
```

Never hand-edit generated tokens: change the generator instead. Where the design needs a value the
token set lacks, it is recorded as a delta in `spec/design-tokens.json`, not written as a literal.

## 3. Semantic roles, never raw values

Screens read semantic tokens such as `primary`, `surface` and `onSurface`, never a primitive, and never a
hex value. A hex literal in app code fails review. Light and dark are paired per role, so dark mode is a
lookup, not a second stylesheet.

## 4. Dark mode reaches the SDK too

Dark mode is the **Appearance** switch in Settings. Each app hands the same choice to the SDK's screens,
so the flow never changes theme halfway through the journey:

| Platform | How the SDK receives it |
|---|---|
| Android | The flow's subtree gets a rewritten `uiMode`, because the builder has no dark-mode parameter |
| iOS | The shell's `preferredColorScheme`, which the SDK's screens inherit |
| Flutter | The app's `themeMode` |
| Expo | `Appearance.setColorScheme`, which the SDK's `useColorScheme` reads |

The system bars follow the same choice. A dark screen with light status-bar icons is the classic miss.

## 5. Contrast is computed

The ink on a fill is chosen by WCAG relative luminance, and a test checks it. iOS still picks by a
perceptual grey, which disagrees on a few colours, and is in the [backlog](plan/backlog.md).

## 6. Text scales

Layouts are tested at the largest font scale and the narrowest width, and must not clip or ellipsise.
Measure chrome such as the floating nav bar rather than hard-coding its height.

## 7. Fonts are bundled and licensed

The apps bundle DM Sans, under the SIL Open Font License, and [`NOTICE`](../NOTICE) records it. The
in-app licences screens list registry dependencies only, so adding the bundled font there is in the
[backlog](plan/backlog.md).

## 8. Prove it with goldens

Every themed state is recorded in light and dark. Flutter and Expo baselines are recorded on CI, never on
a laptop (see [`testing.md`](testing.md)).

## Verify your integration

- [ ] The SDK is styled only through `theme { }`.
- [ ] Your app's dark-mode setting reaches the SDK's screens, and the status bar matches.
- [ ] No raw colour literal in your screens.
- [ ] Your screens hold at the largest text size.

## Common issues

| Symptom | Cause | Fix |
|---|---|---|
| The SDK flow ignores the theme | The override was set outside the builder, or after it was built | Set `theme { }` inside the builder |
| The app is dark but the SDK's screens are light | The SDK resolved the system setting, not the app's | Hand the app's choice to the SDK's subtree (§4) |
| Dark screens show light status-bar icons | The bars follow the system, not the app | Set the bars from the same setting |
| Labels clip at 200 % text | Fixed heights | Measure, and test at the largest scale |
| Golden tests fail on CI after passing locally | Baselines recorded on a Mac | Record on CI |

## Next step

[`testing.md`](testing.md) covers how each of these is tested.
