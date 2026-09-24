# Profiles: one source for "who is running this job"

**Status:** proposed 2026-09-25, on `fix/ports-device-findings`. All four apps. Not in Figma; the
design here is new and needs your sign-off before it is built.

**The report.** "I can't save the active profile; when I create a new profile and select it, it
doesn't show up when I want to run a job."

## 1. What is wrong today (read from the code, same on all four apps)

A profile and the job form are **two unrelated stores**, and the job only ever reads the form.

| # | Defect | Where (Android; the other three mirror it) |
|---|---|---|
| P1 | **A profile's details never reach a job.** The flow snapshot reads `forms.userDetails`; the active profile's `defaults` are read only by its own config page. So you create "Kobo Bank" with Ada's details, select it, tap a product, and meet an empty form. This is the "doesn't show up" half of the report. | `FlowLaunchSnapshot.kt:57`, `FlowFormDestinations.kt` |
| P2 | **The active profile cannot be edited.** The config page's only button saves *and* activates, and is disabled on the active profile, so an edit there is silently discarded. The other half of the report. | `ProfileDestinations.kt:88–110` |
| P3 | **"Remember these details for next time" does nothing.** The switch stores its own on/off state and no code reads it. | `UseSmileIDSampleForms.rememberDetails` |
| P4 | **Profiles live in memory.** Every created profile, its details and callback URL are lost when the app restarts. Also a "doesn't show up" cause. | `UseSmileIDSampleProfiles`: "In memory until profiles are a real account concern" |
| P5 | **Nothing ties first-run typing to anyone.** On a fresh install (no token, only the empty "Default profile") the details typed into the form belong to no profile, so they are retyped every launch. | same as P1 |
| P6 | **The profile can't be seen or changed where it matters.** The user-details form doesn't say whose details they are or offer a switch, and the switch sheet can't create a profile. | `UserDetailsScreen.kt`, `ProfileSwitchSheet.kt` |
| P7 | **A profile's name can't be edited**, yet it is what the SDK's consent screen shows as the partner, so "Default profile" reaches a real consent screen. | `ProfileConfigScreen.kt`; `partnerName = profiles.active.organisation` |

## 2. The model

**The active profile is the one source of the user's details.** The form becomes a *view* of it:

- Opening the user-details form **prefills it from the active profile**. Nothing needs retyping.
- What you type is a draft for this run. On **Continue**, a switch that reads **"Save to {profile}"**,
  **on by default**, writes the four fields back to the active profile. Switched off, the values
  are used for this run only and the profile is untouched. This replaces the switch that did nothing.
- **Profiles, the active profile and their callback URLs persist** in each app's existing settings
  storage (DataStore, UserDefaults, SharedPreferences, AsyncStorage). No new dependency.
- A **token that binds user details still wins**. The form is skipped as today, and nothing is
  written back to the profile. When a token binds only some fields, the rest prefill from the profile.

## 3. The screens

**User-details form (the first-run screen).** A new row at the top of the card:
**"Details for [avatar] Default profile ⌄"** (`sample_user_details_profile`). Tapping it opens the
existing switch sheet. Picking another profile refills the form from that profile, and the header
row updates. The "Save to {profile}" switch sits where "Remember these details" is now
(`sample_user_details_save_to_profile`, reusing the old switch's slot).

**Switch sheet.** Gains a last row, **"+ New profile"**, which opens the existing new-profile sheet.
A profile created from here **becomes active immediately**, since you were in the middle of choosing
who to run as. The profiles list keeps today's "created" toast with its "Make active" offer.

**Profile config page.** Two actions replace the one:
- **Save**: primary, enabled whenever something changed, on **any** profile, including the active
  one. This fixes P2.
- **Use this profile**: secondary, only on a non-active profile. It saves any edits and activates.
  On the active profile the button slot shows an "Active" badge instead.
- A **Name** row above the user details, so "Default profile" can become the organisation the SDK's
  consent screen names. This fixes P7.

**First install, no token and no profile.** The one "Default profile" is active and empty. The
first run's form is empty, with "Save to Default profile" on. After Continue, the details and the
person's name are saved, and the next run is prefilled. On the profile page the name can be changed
from "Default profile".

## 4. Decisions this settles

| Parked decision (`after-the-ports.md` Phase 1) | Proposed ruling |
|---|---|
| Should a profile's stored defaults seed the job form? | **Yes.** The form prefills from the active profile (P1). |
| Should "remember these details" remember anything? | **Yes, and it's renamed.** "Save to {profile}", on by default, writes back to the active profile on Continue (P3). |
| An edit to the active profile cannot be saved | **Save on every profile, plus "Use this profile" on the others** (P2). |
| Button 48 vs 52, glyph 21 vs 20 | **Not settled.** Design-token questions, not profile ones. |
| The two shell ids no app implements | **Not settled.** Unrelated to profiles. |

New calls this plan needs from you:

- **D1: Sign-out.** Today it clears the session and the form. With profiles persisted, should it also
  reset profiles to the single empty starter? **Recommended: yes**, since sign-out is what a partner
  uses to hand the phone over, but only after a confirmation dialog that says so.
- **D2: Switching profile with unsaved typing.** Recommended: switch and discard the typing silently.
  "Save to {profile}" is on by default, so typing someone didn't want saved is the rare case.

## 5. Build plan (one branch, four apps, Android first as the reference)

1. **Model and storage**, per platform: persist `profiles` + `activeId` + callback URLs; add
   `profile.rename(name)`; keep `seedProfiles` and the plain-launch starter.
2. **The form reads the profile**: prefill on entry; a per-run draft; "Save to {profile}" writes back
   on Continue; the token rules stay as they are.
3. **Screens**: the profile row on the form; "+ New profile" on the switch sheet; Save / "Use this
   profile" / Name on the config page.
4. **Spec**: `screens.json` (userDetails, profileSwitchSheet, profileConfig), `test-ids.json` (the new ids above), and a
   `decisions` entry recording these rulings as owner decisions dated when you approve.
5. **Tests on each platform, each failing on today's code**: a new profile's details prefill the form; saving the active
   profile's edits persists; the switch writes back only when on; profiles survive a restart; a
   token-bound field never writes back; sign-out resets as D1 decides.
6. **Goldens** for the three changed screens, light and dark and at 2x text, recorded on the runner.
7. **Device pass**, Flutter then Expo, each on the Oppo then the iPhone, plus native Android and iOS. The script:
   fresh install → run a job, typing details once → restart → run again and see the form prefilled
   → create a profile from the form's switcher → run as it → edit the active profile and see the edit
   persist.

## 6. Out of scope

A profile per environment or per token, and importing details from a token into a profile. The
token already carries its own bindings, and merging the two would blur which one a job used.
