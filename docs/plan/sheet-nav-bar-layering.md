# Where a Flutter sheet sits relative to the nav bar

Closes the defect left open by `port-priority-cut.md` item 8: the floating nav bar was drawn over
the bottom of a partial sheet and took the taps meant for it.

## What was measured

Pixel 5 emulator, API 34, 1080x2340 at 440dpi, gesture navigation — the same profile
`.github/workflows/flutter-device.yml` boots. Bounds are display pixels from `uiautomator dump`.

With the scenario drawer open over settings, the pill sat at y2073–2230 and
`sample_theme_item_partnerOverride` at y2087–2208, wholly inside it. Its centre, (540, 2147), falls
in the pill's *verifications* segment (x322–577), and tapping there switched tab. The switch sheet
over products fails the same way: `sample_profile_row_p-3` at y2021–2208 activates nothing and
switches tab. The nav ids were in the hierarchy the whole time, and a screenshot shows the pill
drawn opaque over the sheet, undimmed — so "the bar is behind the scrim" was not true of the build.
The scrim ran y136–822 only: down to the sheet's top edge, never over the bar.

## Scope, on all four platforms

Flutter has five sheets. Two are exposed, and both are exposed for the same reason: the sheet is
shown on the *branch* navigator, which lives inside `Scaffold.body`, and `bottomNavigationBar` is
painted after the body.

| sheet | owner | bar on the owner | exposed |
|---|---|---|---|
| `/debug/scenarios` | settings tab | yes | **yes** |
| `/profiles/switch` | products tab | yes | **yes** |
| `/profiles/new` | `/profiles`, above the shell | no | no |
| country picker | `/flow/:productId/id-details`, above the shell | no | no |
| ID type picker | same | no | no |

The three siblings do not have it, and none of them avoids it by reserving room:

- **Android** — `ModalBottomSheet` is its own dialog window, above the activity's content where the
  pill is drawn. Its nav bar is mounted the same way Flutter's was, over the content in a `Box`, so
  the window is the only thing separating them.
- **iOS** — `.sheet` is attached at the root of `UseSmileIDSampleShell`, above the stack that holds
  `bottomChrome`. A sheet covers the pill by construction.
- **Expo** — `@expo/ui`'s `BottomSheet` is the same Material 3 sheet in its own dialog window on
  Android, and a SwiftUI sheet on iOS.

Two claims carried into this work were wrong. The pickers are not "fine because they are full
height" — they are partial sheets, against `fullSheet` in `spec/routes.json`, and they are fine only
because nothing above the shell draws a bar. And the fix moves **no** baseline: all 164 were
re-recorded with and without it and compared byte for byte. No golden poses a sheet through its
presentation helper — they render the content widget directly — which is why the sheet's chrome, and
anything drawn over it, was invisible to the hostless lane.

## The decision

**D1. Present the sheet on the root navigator.** `useRootNavigator: true` on both helpers in
`use_smileid_sample_bottom_sheet.dart`.

Three answers were available.

- *Reserve the bar's height inside the sheet.* Rejected. It moves the rows out from under the pill
  but leaves it drawn over the sheet and still eating that strip, and a bright pill over a dimmed
  page is the wrong picture regardless of what it covers.
- *Stand the bar down while a sheet is up*, as Expo's #114 does for select mode and as the shell
  already does via `_showsSelectionBar`. Rejected — not because it fails, but because it costs an
  owner ruling it does not need to. #102 decided that "a sheet is a layer over its owner, so the bar
  belongs to the page behind the scrim", and `use_smileid_sample_routes_test.dart` asserts it.
- *Present above the shell.* Taken. It makes #102's sentence true instead of reversing it: the bar
  stays owned by the page, the scrim covers it, and dismissing gives it back. It is what iOS already
  does, and `spec/components.json` already required it — the sheet's scrim covers "the screen
  beneath", which a scrim stopping at the sheet's top edge did not.

No `spec/` change is owed and no route predicate changes. `useSmileIDSampleShowsNavBar` still
answers true for `/debug/scenarios`, because the page behind it still has a bar.

**D2. The status bar is now dimmed with the rest of the page.** The scrim runs from y0 rather than
y136, because the root navigator sits above the shell's `SafeArea`. The picker sheets already
looked like this; the two in-shell sheets were the odd ones out.

## What pins it

Two lanes, because no baseline can see it. In the widget lane, a shell test opens the drawer at
393x852, asserts the last row and the bar actually overlap — otherwise the tap below proves nothing
— then taps the row's centre and reads its selected flag. Reverting the fix reds it with "the tap
reached the bar and switched tab"; a no-op `selectTheme` reds the other half; pointing the
precondition at the first theme row reds the precondition. On the device, `deep-links.yaml` asserts
the bar is out of reach while the sheet is up, taps the last row, reads `selected: true`, and
asserts the bar is back after dismissing.

## Found here, not fixed here

`/profiles/switch` and `/profiles/new` are not deep-linkable on Flutter. Both match
`/profiles/:profileId` and render a profile page for a profile called "switch" or "new". Android and
iOS both resolve them to the owner with the sheet open, which is what `spec/routes.json` requires of
a sheet path. It is a routing gap rather than a layering one, and it needs its own device proof.
