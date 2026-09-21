# Where a Flutter sheet sits relative to the nav bar

Closes the defect left open by `port-priority-cut.md` item 8: the floating nav bar was drawn over
the bottom of a partial sheet and took the taps meant for it.

## What was measured

Pixel 5 emulator, API 34, 1080x2340 at 440dpi — the profile `flutter-device.yml` boots. Bounds are
display pixels from `uiautomator dump`.

With the drawer open over settings, the pill sat at y2073–2230 and `sample_theme_item_partnerOverride`
at y2087–2208, wholly inside it. The row's centre falls in the pill's *verifications* segment, and
tapping it switched tab. The switch sheet over products fails the same way at
`sample_profile_row_p-3`. The scrim ran y136–822 — down to the sheet's top edge, never over the bar,
which a screenshot shows drawn opaque and undimmed in front of it.

## Scope, on all four platforms

Flutter has five sheets. Two are exposed, both because the sheet is shown on the *branch* navigator,
inside `Scaffold.body`, and `bottomNavigationBar` is painted after the body.

| sheet | owner | bar on the owner | exposed |
|---|---|---|---|
| `/debug/scenarios` | settings tab | yes | **yes** |
| `/profiles/switch` | products tab | yes | **yes** |
| `/profiles/new` | `/profiles`, above the shell | no | no |
| country picker | `/flow/:productId/id-details`, above the shell | no | no |
| ID type picker | same | no | no |

No sibling has it, and none avoids it by reserving room: Android and Expo put the sheet in its own
dialog window, above the content where the pill is drawn; iOS attaches `.sheet` at the root of the
shell, above the stack holding `bottomChrome`.

Two inherited claims were wrong. The pickers are not fine "because they are full height" — they are
partial sheets, against `fullSheet` in `spec/routes.json`, and are fine only because nothing above
the shell draws a bar. And the fix moves **no** baseline: all 164 were re-recorded with and without
it and compared byte for byte. No golden poses a sheet through its presentation helper, which is why
the hostless lane could not see this.

## The decision

**D1. Present on the root navigator.** `useRootNavigator: true` on both helpers.

- *Reserve the bar's height inside the sheet.* Rejected: it moves the rows out from under the pill
  but leaves it drawn over the sheet and still eating that strip.
- *Stand the bar down while a sheet is up*, as Expo's #114 does for select mode and the shell already
  does via `_showsSelectionBar`. Rejected — not because it fails, but because it costs an owner
  ruling it does not need. #102 decided the bar "belongs to the page behind the scrim", and
  `use_smileid_sample_routes_test.dart` asserts it.
- *Present above the shell.* Taken. It makes #102's sentence true rather than reversing it: the bar
  stays owned by the page, the scrim covers it, and dismissing gives it back. It is what iOS already
  does, and `spec/components.json` already required the scrim to cover "the screen beneath".

No `spec/` change is owed and no route predicate changes.

**D2. The status bar is dimmed with the rest of the page**, because the root navigator sits above the
shell's `SafeArea`. The picker sheets already looked like this.

## What pins it

Two lanes, because no baseline can see it. A shell test opens the drawer at 393x852, asserts the last
row and the bar actually overlap, then taps the row's centre and reads its selected flag. On the
device, `deep-links.yaml` asserts the bar is out of reach, taps the last row, reads `selected: true`,
and asserts the bar is back after dismissing. Four mutations red them: reverting the fix, a no-op
`selectTheme`, the precondition pointed at the first theme row, and the device flow's tap deleted.

## Found here, not fixed here

`/profiles/switch` and `/profiles/new` are not deep-linkable on Flutter: both match
`/profiles/:profileId` and render a page for a profile of that name. Android and iOS resolve both to
the owner with the sheet open, which is what `spec/routes.json` requires of a sheet path. A routing
gap rather than a layering one, and it needs its own device proof.
