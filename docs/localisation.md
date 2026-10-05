---
description: How the sample apps are translated — one string source in spec/, generated per platform, the Language setting, device language versus in-app language, right to left, and how to add a language.
---

# Localisation

The four apps ship in English, French, Arabic and Hebrew, the same languages as the SDK's own samples.
Every string a person reads is translated, including the SDK's screens. The instrumentation stays in
English on purpose: the result card, the scenario drawer and the DEBUG section are read by automated
flows and by the team, so they stay readable whatever language the device uses. Made-up fixture data
(seeded profiles and verifications) also stays in English.

For the SDK's own localisation API, see the SDK reference at
[docs.smileidentity.com](https://docs.smileidentity.com).

## Prerequisites

- Any of the four apps, built from this repository.
- To regenerate strings: Python 3.

## 1. One source, generated per platform

The strings live once, in `spec/l10n/`, and `scripts/sync_l10n.py` writes each platform's files from
them. Do not edit a generated file by hand; each `verify.sh` runs `sync_l10n.py --check` and fails
when an output is stale.

| Source | Holds |
|---|---|
| `spec/l10n/languages.json` | The languages the apps ship: id, name in its own language, direction |
| `spec/l10n/app/en.json` | The app's own strings, the base language |
| `spec/l10n/app/{fr,ar,he}.json` | The same keys, translated; a missing or extra key fails the check |
| `spec/l10n/sdk/{fr,ar,he}.json` | Overrides for the SDK's `si_*` strings |
| `spec/l10n/sdk-arguments.json` | Each platform's placeholder for SDK strings that take an argument |

Arguments are named in the source (`{profile}`, `{count}`). The generator writes `%1$s` on Android,
`%1$@` on iOS, and keeps `{name}` on Flutter and Expo.

| Platform | App strings (in `sample-ui`) | SDK overrides (in the app shell) |
|---|---|---|
| Android | `res/values*/sample_strings.xml` and `UseSmileIDSampleStrings.kt` | `res/values-*/sdk_strings.xml`, `res/xml/locales_config.xml` |
| iOS | `Resources/*.lproj/Localizable.strings` and `UseSmileIDSampleStrings.swift` | `App/Sources/Localization/*.lproj/Localizable.strings` |
| Flutter | `use_smileid_sample_strings.dart` | `app/lib/l10n/intl_*.arb` |
| Expo | `use-smile-id-sample-strings.ts` | `app/src/l10n/*.json`, registered with `UseSmileIDLocalizations` |

The SDK overrides live in the shell, not in `sample-ui`, for two reasons. On iOS the SDK reads its strings
from the main bundle. And each SDK repository compiles `sample-ui` into its own sample, which carries its
own overrides.

## 2. The Language setting

Settings has a LANGUAGE section with a Language row, which opens a sheet: System, then each language
under its own name. System is the default, and its label names the language it resolves to, for example
"System (Français)". The `appLocale` launch argument overrides the setting for one launch and is never
saved.

System follows the device's language list and picks the first language the app ships, or English if it
ships none of them. A named language pins the app, as Light or Dark pins the appearance.

| Platform | Device language changes while the app runs | A pick in the app |
|---|---|---|
| Android | Applies at once: the activity is recreated and strings re-resolve | Applies at once |
| iOS | iOS ends the app; it opens in the new language | Applies on the next launch, and the sheet says so |
| Flutter | Applies at once | Applies at once |
| Expo | Applies at once, through `expo-localization` | Applies at once; a change of direction reloads the app |

iOS waits for the next launch because the SDK reads its strings in the language the process started
with. A pick writes `AppleLanguages` and the Settings row keeps naming the running language until then.

## 3. Right to left

Arabic and Hebrew lay the app out right to left. Directional marks (back and forward arrows, the row
chevron) mirror; everything else keeps its shape.

| Platform | How the direction is set |
|---|---|
| Android | `LocalLayoutDirection` from the resolved locale; directional icons are `autoMirrored` |
| iOS | The system, from the launch language |
| Flutter | `MaterialApp.locale`, with `flutter_localizations` |
| Expo | `I18nManager.forceRTL`, then `reloadAppAsync()`, because React Native fixes the direction at start |

Flutter's own Material and Cupertino text (tooltips, menus, pickers) follows the app's language through
`flutter_localizations`.

## 4. Add a language

1. Add the language to `spec/l10n/languages.json`.
2. Add `spec/l10n/app/<id>.json` with every key in `en.json`, and `spec/l10n/sdk/<id>.json` with the
   SDK overrides.
3. Run `python3 scripts/sync_l10n.py` to regenerate every platform.
4. Add the language to each app's language model (the Language sheet's rows), then run each platform's
   `verify.sh`.

Have a native speaker review new strings before release.

## 5. Tests

- `scripts/test_sync_l10n.py` checks that every language has every key and that arguments agree.
- `sync_l10n.py --check`, in every `verify.sh`, fails when a generated file differs from the source.
- Each app tests its language model: what System resolves to, each row's label, and the stored default.
- Goldens stay in English, plus Settings and the ID details form in Arabic to prove right to left.
- Device flows cover the Language sheet by its deep link: a pick changes the app's language, and
  System brings the device's language back.
