# Profiles: one source for "who is running this job"

**Status:** approved 2026-09-25, building on `fix/ports-device-findings`. All four apps. These screens
aren't in Figma; the design is here.

**The report.** "I can't save the active profile; when I create a new profile and select it, it
doesn't show up when I want to run a job."

**Who uses it.** Sales and product colleagues show the Portal different results by running jobs as
different people. So a profile is a persona: a name for the demo, plus the details its jobs carry.
Switching persona has to take one tap, and a persona has to survive a restart.

## 1. What is wrong today (read from the code, same on all four apps)

A profile and the job form are **two unrelated stores**, and the job only ever reads the form.

| # | Defect | Where (Android; the other three mirror it) |
|---|---|---|
| P1 | **A profile's details never reach a job.** The flow snapshot reads `forms.userDetails`, and the active profile's `defaults` are only read by its own config page. | `FlowLaunchSnapshot.kt:57` |
| P2 | **The active profile can't be edited.** The config page's only button saves *and* activates. On the active profile that button is disabled, so any edit is silently thrown away. | `ProfileDestinations.kt` |
| P3 | **"Remember these details for next time" does nothing.** Nothing reads it. | `UseSmileIDSampleForms.rememberDetails` |
| P4 | **Profiles are kept in memory only**, so a restart loses them. | `UseSmileIDSampleProfiles` |
| P5 | **First-run typing belongs to nobody**, so it's retyped on every launch. | same as P1 |
| P6 | **The form doesn't say whose details they are**, and offers no way to switch. The switch sheet can't create a profile. | `UserDetailsScreen.kt`, `ProfileSwitchSheet.kt` |
| P7 | **A profile's name can't be edited**, yet the SDK's consent screen shows it as the partner. A placeholder, "Default profile", therefore reaches a real consent screen. | `ProfileConfigScreen.kt` |
| P8 | **An empty "Default profile" looks like a set-up profile.** People assume it holds preset details and never fill it in. | `UseSmileIDSampleProfiles.starter()` |

## 2. The model

- **No profile is a real state (null), not an empty placeholder.** A plain first launch has no
  profiles and no active profile. The products header, the settings card and the form all say
  "No profile yet", in words. This replaces the "Default profile" starter (P8).
- **The active profile is the only source of the user's details.** Opening the form fills it from the
  active profile. What you type is a draft for this run only.
- **One switch decides whether the draft is kept.** It's on by default.
  - With a profile active, it reads **"Save to {name}"**. On Continue, the draft is written back to
    that profile.
  - With no profile, it reads **"Save as a profile"**. On Continue, it creates a profile from the
    draft and makes it active.
  - Switched off, the draft runs once and nothing is stored.
  - It replaces "Remember these details", which did nothing (P3, P5). It keeps that switch's test id,
    because ids are stable.
- **Profiles are stored on the device.** The list, the active id and each profile's callback URL use
  each app's existing settings storage:

  | App | Store |
  |---|---|
  | Android | DataStore, via `UseSmileIDSampleStore` |
  | iOS | UserDefaults, via `UseSmileIDSampleStore`'s settings storage |
  | Flutter | shared_preferences |
  | Expo | AsyncStorage |

  This fixes P4.
  - Profiles are per install, with nothing synced. Each colleague builds their own personas.
  - Profiles are one JSON value under one new key, `sample_profiles`. It holds `{version: 1,
    activeId, profiles: [...]}`.
  - A value that is missing or can't be decoded reads as **no profiles**. It never throws, and it
    never falls back to fixtures.
- **Fixtures are never stored.** A `seedProfiles` launch uses the three fixtures in memory only and
  writes nothing, so an automation run can't leave made-up people in a colleague's list.
- **A token that binds user details still wins.** A bound field shows as provided, and is never
  written back or stored. When the token binds everything, the form is skipped and nothing is stored.
- **What the consent screen names as the partner:**
  - The active profile's name.
  - With no profile, or a profile with a blank name, it's **"Smile ID"**. The app is Smile ID's own,
    so that is true, unlike a placeholder.
- **The partner id without a token** stays the active profile's id. With no profile it's `p-1`, the
  id the first profile gets and the value a plain launch sends today, so nothing changes on the wire.
  A token's partner id still wins, as before.

## 3. The screens

**User-details form.**
- **A profile row at the top of the card**, labelled "Profile" (`sample_user_details_profile`). It
  shows "[avatar] {name} ⌄", or "No profile yet ⌄" when there is none. Tapping it opens the switch
  sheet.
- **Picking another profile refills the form** from that profile and discards the typing (D2).
- **With no profile, an extra first row appears: "Organisation (optional)"**, with the placeholder
  "Shown on the consent screen" (`sample_user_details_field_organisation`). What's typed there becomes
  the new profile's name. If it's left blank, the profile takes the person's name.
- **The save switch** sits where "Remember" was, shown once the form is valid, as today.

**Switch sheet.**
- **It gains a last row, "+ New profile"** (`sample_profile_switch_new`). That row opens the
  new-profile sheet.
- **A profile created from the sheet becomes active immediately**, because the person was choosing who
  to run as.
- **With no profiles**, the sheet shows only that row.
- **The profiles list keeps today's behaviour**: creating a profile there doesn't activate it, and the
  "created" toast offers "Make active".

**Profile config page.**
- **A "Name" row** (`sample_profile_config_name`) in its own "PROFILE" section, above the user
  details. This fixes P7.
- **Save** (`sample_profile_config_save`, as today) is the primary button, on every profile, including
  the active one. It's enabled only when something changed. It saves and goes back (P2).
- **"Use this profile"** (`sample_profile_config_use`) is secondary and appears only on a profile that
  isn't active. It saves any edits, activates the profile and goes back.
- **An "Active" caption** replaces that button on the active profile.

**Products header avatar and settings profile card.** With no profile, they show a neutral "+" avatar
and read "No profile yet". The avatar opens the switch sheet, which offers "+ New profile". The card
opens the profiles list, which already has a Create action.

**Sign-out (D1).**
- **It asks first.** A native confirmation reads: "Sign out? This ends the token session and deletes
  every profile on this device." The actions are Cancel and **Sign out** (`sample_sign_out_confirm`,
  destructive).
- **Confirming resets the app** to no profile, an empty form and no session.

## 4. Updating an installed app

The Android and iOS apps are already on the Play Store and the App Store. Neither ever stored a
profile, since profiles were kept in memory only. An update is therefore safe on both:
- **An installed app has no stored profile to read.** After the update it reads `sample_profiles` as
  missing, which means no profile.
- **Settings and the token session are untouched.** They keep their keys and formats.
- **Saved form state doesn't carry across an update.** An update ends the process and discards the
  saved instance state. The restore still reads the new list defensively, so an old eight-item save
  can't index past its end.
- **Tests will prove it.** Each platform gets a test that opens a store containing only the old
  released keys (settings and a token), and checks that it reads as no profiles, with the settings
  intact. Another test feeds each platform corrupt `sample_profiles` JSON and checks that it reads as
  no profiles.
- **Backup is not an issue on Android.** Its `allowBackup` is already `false`, so nothing is
  restored after a reinstall. The Expo Android app restores AsyncStorage after a reinstall; its
  `allowBackup` is set to `false` to match.

## 5. Decisions

| Decision | Ruling |
|---|---|
| A profile's stored details seed the job form | **Yes**: the form fills from the active profile (P1). |
| "Remember these details" | **Replaced** by the save switch, on by default (P3, P5). |
| An edit to the active profile can't be saved | **Save on every profile, plus "Use this profile" on the others** (P2). |
| D1: sign-out | **Deletes all profiles**, after a confirmation (approved). |
| D2: switching profile with unsaved typing | **The typing is discarded** (approved). |
| D3: a first launch's profile | **None (null)**, not an empty "Default profile" (approved). |
| D4: the partner name with no profile | **"Smile ID"**. |
| The two shell ids no app implements | **Deleted** (approved). |
| Button height 48 vs 52, glyph 21 vs 20 | **Read from Figma** (`5206-3776` for the button, `5206-4036` for the glyph) if it's connected. If not, the apps keep what they ship now, and the PR says so. |

## 6. Build order (one branch, Android first as the reference)

1. **Model:**
   - An optional active profile; `add`, `update(id, name, details, callbackUrl)`, `setActive`
     and `clear`.
   - A JSON codec that treats bad input as no profiles.
   - Store read and write, skipped for `seedProfiles`.
2. **Form:**
   - Fill it on entry, once the profiles have loaded. It never overwrites typing after the system
     recreates the screen.
   - The save switch, applied on Continue.
   - The organisation row with no profile.
   - The profile row, and a switch sheet with "+ New profile".
3. **Config page:** the Name row, Save, "Use this profile", and the "Active" caption.
4. **The no-profile header avatar and settings card**, plus the sign-out confirmation.
5. **Spec:**
   - `test-ids.json` and `screens.json`: the new ids and the new screen states.
   - Retire the `Default profile` wording.
6. **Tests on each platform, each failing on today's code:**
   - A plain launch has no profile.
   - The form fills from the active profile.
   - Continue with the switch on creates or updates a profile. With it off, nothing is stored.
   - A token-bound field is never stored.
   - The active profile's edits save.
   - Profiles survive a restart.
   - Corrupt or missing data reads as no profiles.
   - A `seedProfiles` launch writes nothing.
   - Sign-out needs confirming, and clears everything.
7. **Goldens:** the changed screens, light and dark, recorded on the runner.
8. **Emulator and simulator pass:** an Android emulator and an iOS simulator run all four apps.
   - The steps: a fresh install shows no profile → run a job, typing once → restart → the form is
     filled → switch to a new profile from the form → run as it → edit the active profile and save
     it → sign out, confirm, and see no profile.
   - Capture can't run on a simulator, so each run stops at the SDK's first screen. The consent
     screen is where the partner name shows.

## 7. Out of scope

- **Deleting a single profile.** Sign-out clears them all.
- **Syncing profiles** between devices.
- **A profile per environment.**
- **Copying a token's details into a profile.** The token carries its own details, and merging the
  two would blur which one a job used.
