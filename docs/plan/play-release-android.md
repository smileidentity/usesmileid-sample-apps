# Shipping the Android sample to Play

**Status:** SHIPPED. REL-A1 through REL-A17 landed 2026-08-28 and the app is live on Play's internal
testing track. §7.3 records what the release actually proved and §7.4 what is left, none of it blocking:
the camera panel needs a device, one rendered panel is visually weak, and production promotion is a
Console action. §7 tracks each item. Runs in parallel with the iOS port and shares no
files with it. Android is the first of the four apps to reach a store, so every decision here sets a
pattern the other three copy — §8 records what travels and what is Play-specific.

Scope: the Google Play listing for `com.usesmileid.sample.android`, the release build that backs
it, and the store-art pipeline. Not the app's behaviour: the app is feature-complete through #30 and
this plan adds no screens.

**Settled up front, so the work does not open by re-asking.** All owner rulings 2026-08-27:

- v12 is a **new publication, not an update** — a different application id was never going to be an
  update anyway, so this makes it deliberate rather than incidental.
- `targetSdk = 37` is **accepted by Play today**, so REL-A14 is a periodic re-check, not a blocker.
- The **v11 upload key is reused** (§3).
- The **store title takes the spec name**, "UseSmileID Sample", on the understanding that a store title
  is one of the cheapest things on a listing to change later — and it changed: the title became
  "Smile ID" on 2026-09-14 (§7.4).
- **Data safety mirrors v11 wherever the two apps behave the same** — and §6.1 shows they do, on every
  question the form asks.
- **Phone-only. No tablet art** — §6.2 is the code that decides it.
- The **launcher icon sources have landed** in `svgs/`, one per platform.

**One further owner ruling, 2026-08-28:** the four sample apps take a single `com.usesmileid.sample.*` id
family, so Android publishes as `com.usesmileid.sample.android`. It is free to change today and permanent
from the first upload, which is why it lands with this tranche rather than after it.
`spec/app-identity.json` carries both the decision and the debt it creates: the Flutter and Expo ids are
held by SDK-repo development samples, which owe a rename before either of those apps is built. Android and
iOS collide with nothing — and the iOS app, which landed while this branch was open, follows here:
`ios/App/project.yml` now declares `com.usesmileid.sample.ios`, which is what its own spec test
asserts. The Kotlin namespace is unchanged — it is not an identity.

## 1. What is blocking, read out of the build files

Four items. One is irreversible, one is invisible until someone looks at a launcher.

1. **Release builds are signed with the debug key.** `android/app/build.gradle.kts:45` —
   `signingConfig = signingConfigs.getByName("debug")`. Every release build this repo has produced — the
   one `verify.sh` assembles, the ones the device suite runs on — has never been uploadable. Fixing it
   changes no behaviour, but signing identity is **permanent from the first upload**, which makes this
   the only item here that cannot be corrected afterwards. §3 says exactly what to do.
   **Resolved (REL-A2).** `release` takes an `upload` signing config guarded on the keystore existing,
   so only a build that held the upload key is uploadable.
2. **There is no launcher icon wired.** `android/app/src/main/res/` holds `values/` and `values-night/`
   and nothing else — no density buckets, no adaptive icon, no `ic_launcher`. The app ships the platform
   default today. The art now exists; §4 covers why it cannot be dropped in as-is.
   **Resolved (REL-A1).** Adaptive icon with background, foreground and monochrome layers, legacy
   density PNGs for API 24–25, and the listing PNG; §4.1 records what the mask check measured.
3. **`versionCode = 1` and `versionName = "1.0.0"` are hard-coded** (`:29–30`) with no bump mechanism.
   versionCode is monotonic and non-reusable on Play, so a wasted upload burns an integer permanently.
   **Resolved (REL-A3).** versionCode comes from a `VERSION_CODE` property, one derived source for every
   track; versionName stays the hand-bumped marketing version the settings footer already renders.
4. **There is no release lane.** `.github/workflows/android.yml` is the per-PR lane. `verify.sh`
   assembles a release APK (line 47) but nothing builds or validates a bundle.

**Checked and cleared, so it does not linger as a suspicion:** minSdk is consistent — the app and
`sample-ui` both declare 24 and the SDK's own library convention plugin also sets 24, so there is no
manifest-merger conflict to find.

## 2. Capturing the screenshots

This is where the plan changed once the repo was read properly, and the change is worth the space.

**`storeshots-mcp` renders; it does not capture.** The agent picks screens and writes headlines,
storeshots turns raw frames into store-dimension art. Something else produces the frames — and this
repo already has the better half of that something.

### 2.1 Roborazzi is already the capture engine, and nobody noticed

`sample-ui` runs **Roborazzi 1.72.0** (`libs.versions.toml:28`), gated by `verify.sh:45`
(`verifyRoborazziDebug`), with committed goldens in `sample-ui/src/test/screenshots/`. The set already
covers, light and dark, nearly every screen a store listing wants — `product_grid_light.png`,
`screen_products_token_linked_light.png`, `screen_scan_token_light.png`,
`screen_verification_details_no_probes_dark.png`, `screen_settings_consent_bound_light.png`, and more.

Three properties make that the right raw-frame source rather than a coincidence:

- **It renders on the JVM at a declared device spec.** No emulator, no AVD drift, no flake — and the
  spec is a parameter, so the same composable can be rendered at whatever pixel size a preset wants.
- **It is already determinism-hardened for exactly the reason store art needs.** `sample-ui/build.gradle.kts:72`
  pins the recorder's timezone and locale *because goldens render clock times*. That work is done.
- **It is already staleness-gated.** `:78` declares the screenshot directory as a task input so a changed
  golden invalidates the task. Store art wants the identical treatment, and can reuse the mechanism
  instead of inventing one.

Meanwhile Maestro has **no `takeScreenshot` anywhere** in its eight flows today, so routing store art
through Maestro would be new work in the harder medium.

### 2.2 The one frame Roborazzi cannot produce

A live camera preview cannot be rendered off-device. So the SDK's capture screen — arguably the most
persuasive panel in the set — needs a real device or emulator, and that is Maestro's job.

The split is therefore **five frames off-device, one on**, and it is principled rather than a
compromise: host UI is a pure function of state and renders deterministically; a camera feed is not.

| Panel | Source | Why |
|---|---|---|
| Products grid | Roborazzi | pure state |
| Token session (linked, counting down) | Roborazzi | pure state; clock already pinned |
| SDK capture in flight | **Maestro on a device** | camera preview cannot render off-device |
| Verifications list, filters populated | Roborazzi | pure state, fixtures seeded |
| Verification details + result card | Roborazzi | pure state |
| Settings composing the journey | Roborazzi | pure state |

For the Maestro frame, pin the emulator with **Gradle Managed Devices** rather than a local AVD, so the
one non-deterministic panel is at least reproducible from a declared image.

### 2.3 Where this sits against the testing contract

Stated plainly so no reviewer reads it as a violation. The contract bans *asserting* on screenshots and
coordinates. Here the frames are an **output artefact, never an oracle**. Goldens remain the assertion
channel and are untouched — store art is a separate output directory from a separate Gradle task, so a
store-art change can never quietly repaint a golden. The Maestro capture flow asserts on `sample_*` ids
to confirm it is on the right screen *before* capturing, which is the contract being followed.

`mobile-mcp` is genuinely useful here, but only upstream of the pipeline: driving the app by hand to
decide *which* states photograph well is exploration, and its screenshots must never become the
committed artefact. That is the same boundary the device-verify guidance already draws.

### 2.4 PII discipline, because store art is published

A published frame must never carry a real name, ID number, partner id or token. The sandbox test
identities settled earlier cover every state the art needs — `Clearwater / Amina Fatou` for a clear
result, `Xeroxley` for attention, `Dangerfield` for blocked — `sample_token_simulate` mints a fixture
token so the session card and countdown can be shown without a real JWT ever existing, and `seedJobs`
populates the list. The whole set is capturable with zero real credentials, which is what makes it safe
to publish *and* safe to run unattended in CI.

### 2.5 Rendering, and what to use where

| Preset | Dimensions | Used for |
|---|---|---|
| `android-phone` | 1080 × 1920 | the phone set |
| `android-tablet` | 1600 × 2560 | **not used** — phone-only, see §6.2. Listed so a later tablet pass knows the preset exists |
| `play-feature-graphic` | 1024 × 500 | the feature graphic — `android/play/feature-graphic.png`, rendered by the same script and gated by the release lane. Play will not publish a listing without one, which the first pass through Console is what surfaced |

Tools are `list_presets`, `compose_screenshot`, `generate_set`, `create_showcase` and
`validate_screenshot`. Layout variants are `text-top`, `text-bottom` and `tilted`; mixing them is what
stops six panels reading as one template repeated.

**Use the CLI in CI and the MCP server locally.** The CLI is the same engine, and a CI lane must
not depend on an agent being in the loop. Local install: `claude mcp add storeshots -- npx -y storeshots-mcp`.

**Correction, checked against the registry 2026-08-28:** `npx storeshots` does not resolve — there is no
package by that name, and the command 404s. The CLI ships *inside* `storeshots-mcp`, which declares two
binaries (`storeshots-mcp` for the server, `storeshots` for the CLI), so the invocation is
`npx -p storeshots-mcp storeshots <command>`, or a devDependency on `storeshots-mcp` and a plain
`storeshots` on the path. The engine claim itself holds. Its commands are `presets`, `compose`,
`showcase` and `validate` — there is no `generate_set` on the CLI, so rendering a six-panel set is six
`compose` calls from a script rather than one command, which is what REL-A11 has to write.
The render path is pure — same frame plus same headline gives the same pixels — which is what makes the
generated art committable, diffable in review, and gate-able for staleness alongside the design tokens
and third-party notices `verify.sh` already checks.

**Tooling honestly assessed, since the question was asked.** storeshots covers framing, dimensions,
headline typography and locale-correct casing, and validates its own output — that is the whole
production half. Translation lives in the agent by design. There is no Play Console MCP worth wiring:
publishing is a solved, non-interactive problem and `r0adkll/upload-google-play` already does it in v11
(§3). The Figma MCP is available if the feature graphic wants composing from the design system rather
than from a screenshot. Beyond that, adding tools would add moving parts without removing work.

### 2.6 Two things only a review of the output caught

Both were invisible in the raw frames and obvious in the finished panels, which is the argument for
committing the rendered set rather than only the frames.

**A frame is not a screenshot: it needs a status bar.** The panels render the app edge to edge from
y=0, but the device frame storeshots draws has a punch-hole and rounded corners over that area. The
app bar landed underneath both — the camera cutout sat between "Verifications" and "Select", and
beside the "Smile ID" title. Measured against a solid probe rendered through the same frame: the
screen is drawn at 0.689 scale, the corners eat the top ~61px of the source and the punch-hole spans
source y 70–96. `StoreArtTest` therefore insets its content by **40dp**, which clears both, and the
band reads as a status bar. The check is that the top 120px of every frame is a single colour.

**Mixing layout variants made the set look like different devices.** The plan suggested alternating
`text-top`, `text-bottom` and `tilted` so six panels would not read as one template repeated. In the
finished strip that instead put the phone at a different height and size in every panel, which reads
as inconsistency rather than variety. All panels now use `text-top`, so the device sits at y=201
throughout. Variety comes from the headlines and the screens, which is enough.

**A headline must not carry a count.** The first set opened with "Six products, one integration", which
is wrong the day a product is added or removed and needs a re-render nobody will remember to do. The
headlines are imperative verb plus concrete object, each true to the panel it sits above, and none of
them states a number. They also take their nouns from `docs-v3` rather than inventing new ones: it
calls the record a **verification result** (28 uses) and describes one by its **status** and
**message**, whose values — `clear`, `attention`, `block` — are the words on the app's own status
pills. Two earlier drafts read as developer shorthand ("every field of a result") or trailed a clause
("every run and its status"); the docs' vocabulary fixed both. The details panel then took its
descriptor from the screen's own title, "Verification details", rather than naming two of the five
fields it shows.

**The headlines came off on 2026-09-14** (owner ruling): every panel is now the screen alone — storeshots'
background, gradient and frame with the whole device centred, composed by `scripts/compose-store-panel.mjs`
because storeshots refuses an empty headline, then validated by storeshots as before. The listing copy
carries the words, so the two rules above now govern that copy rather than the art.

**The phone got taller on 2026-09-18.** The frames were recorded at `w360dp-h640dp`, a 16:9 device that
cut the products grid at its third row; `StoreArtTest` now records at `w360dp-h800dp` (1080×2400, 20:9).
And storeshots shapes the drawn screen like the canvas — 16:9 here — and sizes it for a headline; the
composer now keeps the capture's aspect and fills the panel (90% of the width or a 3% vertical margin),
on both stores.

### 2.7 What building the pipeline changed

Three corrections, all found by running it rather than by reading:

- **Gradle Managed Devices cannot host the camera capture.** GMD starts and stops its emulator around a
  Gradle *test task*, and Maestro is not one, so a GMD block would declare an image nothing uses. The
  image is pinned in the flow's header instead — a Pixel-class AVD on API 34, at 1080x2400 so the frame
  needs no rescaling next to the five rendered panels.
- **The capture flow lives in `android/maestro/store/`, not beside the suite.** Folder runs are
  non-recursive, which is how `subflows/` stays out of the suite; a top-level `store-shots.yaml` would
  have joined every per-PR device run, needing a camera and writing a file on each one.
- **The capture screen still has no `si_*` id**, so the landmark that proves the preview is up before
  anything is written is the SDK's own shipped button text, "Start Capture". The assertions run before
  the capture, never on it.

**One naming trap, recorded so nobody "fixes" it.** `UseSmileIDSampleProduct` carries two names for the
first product: `label` is "SmartSelfie Enrollment", used in the verifications list and details, while
`cardTitle` is "Registration", a short form for the products card's narrow text column. Both therefore
appear in the store panels. The listing follows `label`, per §5's ruling. They are not in conflict and
neither should be changed to match the other.

## 3. Signing — reuse the v11 upload key

The key v11 already uses is an **upload key**, and the name is the important part: it means v11 is on
**Play App Signing** — Google holds the app signing key, and the repository only ever holds what
authenticates an upload.


**So reusing it is correct, and it is the low-friction answer.** Play permits one upload key across many
apps in an account, and enrolls each new app with its own freshly generated app signing key, so
`com.usesmileid.sample.android` gets cryptographic separation for free while we distribute no new
secret. Enrollment is not optional for a new app in any case.

Two things to be deliberate about rather than discover:

- **Blast radius.** One upload key now authenticates two listings. For sample apps that is acceptable;
  it is worth writing down so a future rotation knows it touches both.
- **Never reuse the app signing key.** Play Console will offer to sign the new app with an *existing
  app's* signing key. Decline it — that couples the two listings permanently for no benefit.

The keystore is not committed to the v11 repository and must not be committed here either. It is
materialised in CI from a base64 repository secret at build time. Copy v11's
`if (uploadKeystoreFile.exists())` guard as well — it lets a contributor without the secret still build a
release variant, which is why `verify.sh` works on any machine.

**One deliberate divergence from v11, decided while writing the guard.** v11 leaves the release variant
*unsigned* when the keystore is absent; here it falls back to the debug config, because `verify.sh`
assembles the APK the release device suite installs and an unsigned APK cannot be installed. The fallback
keys off the keystore file's absence alone, so it cannot mask a missing secret: a keystore present without
its password fails `packageRelease` with *SigningConfig "upload" is missing required property
"storePassword"*, and a wrong password fails with *Keystore was tampered with, or password was incorrect*.
Both were run. A missing CI secret therefore fails at build time rather than at upload.

The one case that leaves is a publish lane whose keystore never materialised at all, which would otherwise
produce a perfectly successful debug-signed bundle. `-PREQUIRE_UPLOAD_SIGNING=true` refuses to build one,
and **REL-A15 must pass it on both tracks** — that is the property's only caller, and the reason it exists.
It also requires `VERSION_CODE`, because the `?: 1` default is otherwise reachable from a publish lane and
uploading it would burn versionCode 1 permanently. Putting both checks in the build rather than in a
workflow step covers a bundle built by hand as well.


### 3.1 One versionCode scheme across every track

Play requires each upload's `versionCode` to exceed every earlier upload for the app, **across all
tracks**. So the internal and production workflows must derive it the same way: two schemes that
disagree in magnitude make one track unpublishable. v12 uses `git rev-list --count HEAD` in both, read by
`versionCode = findProperty("VERSION_CODE")?.toString()?.toInt() ?: 1`.

### 3.2 What the two publish workflows do differently from v11

Three deliberate changes, beyond dropping the release-notes generation §5 rejects:

- **The internal lane is `workflow_dispatch` only.** v11 publishes internal on every push to `main`.
  Here that would perform the very first upload automatically, which is the one action reserved for an
  owner because it fixes the signing identity and creates the listing. Adding the push trigger is a
  one-line change once the listing exists.
- **Both lanes compute `versionCode` with the same command**, which is the §3.1 defect not being
  ported.
- **Secrets reach Gradle as `ORG_GRADLE_PROJECT_*` environment variables, never as `-P` arguments**, so
  the keystore password does not appear in the runner's process list.

Both lanes set `-PREQUIRE_UPLOAD_SIGNING=true`, so a run whose keystore secret failed to materialise
fails at the bundle step instead of producing a debug-signed artefact that only Play would reject.

These workflow files name their secrets in the clear, because a workflow cannot reference a secret
without naming it and the names are not themselves sensitive. Only secret values must never be
committed.

**The rule that survives the flip:** v12 uses one monotonic `versionCode` scheme across every track,
derived from a single source, because Play compares each upload against every prior upload for the app
regardless of which track it went to.

## 4. The launcher icon — one source, two different treatments

`svgs/` now holds `android.svg`, `ios.svg`, `flutter.svg` and `react-native-expo.svg`: 512 × 512, a
`#F9F0E7` rounded-rect ground at `rx="114"`, the Smile ID mark, and a per-platform badge. `.DS_Store` in
that directory is already covered by `.gitignore:46`.

**The Play listing icon is the SVG as-is** — 512 × 512 is exactly what Play asks for, and Play wants the
corners baked in. Render straight to a 32-bit PNG.

**The launcher icon is not**, and dropping the SVG in as one layer produces a visibly wrong icon:

- Android adaptive icons are **layered** — background plus foreground — and the launcher applies *its
  own* mask. Art with a rounded rect already baked in gets rounded twice, which reads as a sloppy inset
  square on any launcher using a circular or squircle mask.
- Only the **centre 72 × 72 dp of a 108 × 108 dp canvas is guaranteed visible** — about 67%, roughly a
  341 px safe box on a 512 px canvas. The per-platform badge sits off-centre, so it is precisely the
  element at risk of being masked away.

So REL-A1 decomposes the source: `#F9F0E7` becomes a flat background layer with **no** radius, the mark
and badge become the foreground scaled to sit inside the safe box, and the result gets checked against a
circle, a squircle and a rounded square rather than against one launcher. A monochrome layer is worth
adding at the same time for themed icons on Android 13+.

### 4.1 What the mask check actually measured, and where this plan was optimistic

The 341 px figure above is the *viewport* the launcher masks inside — it is not the safe area. Every
mask is inscribed in that square, so the guaranteed-visible region is the square's inscribed **circle**,
radius 170.7. Scaling the art to fill the 341 px square is therefore still wrong, and visibly so: the
first attempt did exactly that and the badge, the blue block and the arch were all clipped on the
circle. Corners of the content box are the first thing a round mask takes.

Rather than argue the geometry, each candidate scale was rendered and the clipped pixels counted —
content rendered on a chroma key, masked by the circle, opaque pixels compared before and after:

| Foreground scale | Content px | Inside the circle | Clipped |
|---|---|---|---|
| 0.824 (fill the square) | 44,718 | 41,537 | **3,181** |
| 0.72 | 34,148 | 33,600 | 548 |
| 0.68 | 30,673 | 30,595 | 78 |
| **0.66** | 28,808 | 28,808 | **0** |
| 0.65 (shipped) | 28,032 | 28,032 | 0 |

So 0.66 is the boundary and 0.65 ships, with the monochrome layer measured the same way (boundary
0.82, ships at 0.80 — it holds only the mark, which has a different bounding box). The round legacy
icon is a separate case and was measured separately: its mask is the full 512 canvas rather than the
341 viewport, so it ships at 0.95 where 1.0 would still not clip. Reusing the adaptive scale there
made the icon look shrunken, which the contact sheet caught.

**One tooling trap worth writing down.** Quick Look renders SVG onto opaque white, so a naive
render gives white corners rather than transparent ones, and any alpha-based measurement over it
reads 100% opaque and proves nothing. Both bugs were live here before the pixel counts were checked
against a chroma key instead. The shipped PNGs rebuild their alpha from the known ground geometry —
rounded rect at `rx=114` scaled per density, circle for the round variant.

## 5. The copy, and the voice ruling

**Owner instruction: Play wording follows `docs-v3`.** That is a rewrite rather than a copy-edit, and
worth naming, because the two voices are opposites.

v11's listing reads: *"Africa's foremost solution"*, *"cutting-edge verification SDKs"*, *"Witness the
efficiency of our SmartSelfie capture feature"*, *"But that's not all!"*, *"embark on a journey"*.

`docs-v3` does the opposite — the product name leads, the tense is present, the mechanism is concrete,
and the use case arrives as "is suitable for". Document Verification *"confirms the authenticity of an
identity document and that it belongs to the person presenting it … authenticates the document (checking
security features, the machine-readable zone, and barcodes), extracts the information printed on it, and
compares the photo on the document against the submitted selfie."* No superlatives, no second person, no
exhortation.

The full description is therefore **assembled from the six product pages**, trimmed to length, with the
SmartSelfie™ trademark preserved as `docs-v3` writes it. Deriving rather than inventing also means a docs
change has a known blast radius:

| Product | Source in `docs-v3/base-documentation/products/` |
|---|---|
| SmartSelfie™ Enrollment | `biometric-authentication/smartselfie-tm-registration.md` |
| SmartSelfie™ Authentication | `biometric-authentication/smartselfie-tm-authentication.md` |
| Document Verification | `onboarding-with-biometrics/document-verification.md` |
| Enhanced Document Verification | `onboarding-with-biometrics/enhanced-document-verification.md` |
| Biometric KYC | `onboarding-with-biometrics/biometric-kyc.md` |
| Enhanced KYC | `onboarding-without-biometrics/enhanced-kyc.md` |

Limits are counted, not estimated: title 30, short description 80, full description 4000, release notes
500. They are now asserted by `UseSmileIDSamplePlayListingTest` rather than counted once, because Play
truncates silently instead of rejecting.

**One exception to "follow `docs-v3`", ruled by the owner 2026-08-28.** The two sources name the first
product differently: `docs-v3` calls it SmartSelfie™ Registration, the app's own product list calls it
SmartSelfie™ Enrollment. The listing takes **Enrollment**, so the store copy and the store screenshots
agree with each other — a partner reading the listing next to the app should not see two names for one
product. The trademark still renders as `docs-v3` writes it. Everything else in the copy follows
`docs-v3` unchanged.

**Owner ruling 2026-09-14: the per-product paragraphs come out of Play's description.** They restated
`docs-v3` in full, so every product change meant re-editing the listing. The six product names stay,
because **Play indexes the full description for search** and those names are what a partner searches
for; what goes is the mechanism paragraph under each, which `docs.smileidentity.com` already owns and
keeps current. The description drops from 3022 characters to 1016.

**Play moved first and alone.** The App Store description is per-version metadata and version
20260913.1211.103 was sitting in Apple's review queue when this was ruled, so editing it would have
meant touching a submitted version. `ios/store/description.txt` took this text on 2026-09-16, so the
two files are identical again; pushing it to App Store Connect waits for that submission to clear, and
that plan's §7.2 holds the action. What still diverges is therefore the *published* App Store listing
against this repository, not the two files: until that push lands, the live listing carries the
per-product paragraphs and Play does not. `scripts/check_store_listing.py` holds the invariant that
outlives the gap either way — both listings name the same six products. Apple is unaffected by the
search argument, because the App Store does not index the description at all.

**Release notes are v11's other defect, and this is where it stops.** v11 generates "What's new" with
`git log --pretty=format:'- [%ad] %s' --date=short -n 5`, which is why the live listing shows
`- [2026-08-07] 🚢 release: prep 11.2.0 — release notes and smileid-security bump (#961)` to partners —
PR numbers, emoji and internal shorthand. v12 writes them by hand, in the listing's voice, and never
references a PR or a planning item. That also means dropping the generate-release-notes step when the
workflows are copied, not adapting it.

## 6. The two answers that came from the code

### 6.1 Data safety — v11 and v12 match, so the answers carry over

Checked rather than assumed, because "answer it the same way" is only safe if the behaviour is the same.

| Form question | v11 | v12 | Same? |
|---|---|---|---|
| Collects Personal info | yes | yes — user details go to the API with a submission | yes |
| Collects Photos and videos | yes | yes — selfies and document images | yes |
| Collects Device or other IDs | yes | yes | yes |
| Shares App activity, App info and performance | yes | yes — both SDKs bundle Sentry (v11 8.37.1, v12 8.53.0) | yes |
| Encrypted in transit | yes | yes | yes |
| Deletion can be requested | yes | yes | yes |

**The local job database changes none of it, and an earlier draft of this plan was wrong to say it
might.** Play's form asks about data **collected** — meaning transmitted off the device — and **shared**
with third parties. On-device storage that never egresses is explicitly outside that definition, and
`AndroidManifest.xml:17` sets `android:allowBackup="false"`, so the Room database has no cloud-backup
path off the device either. It is not a data-safety fact at all.

The one thing that was worth verifying rather than assuming is Sentry, since it is what backs v11's
*sharing* declaration: both SDKs carry it, so that answer holds too. Net result — REL-A12 transcribes
v11's answers and records this table as the reason, rather than re-deriving them.

### 6.2 Tablets — the UI is flexible, but it is not adaptive. Ship phone-only

The belief worth testing was that the UI is already responsive. It stretches; it does not adapt. What
the code says:

- **No window size classes anywhere.** No `WindowSizeClass`, no `calculateWindowSizeClass`, no
  `windowWidthSizeClass` — and no `material3-adaptive` or `material3-window-size-class` entry in
  `libs.versions.toml` at all. There is no breakpoint in the app to hit.
- **The two width-aware call sites are not layout decisions.** `ScanTokenScreen.kt:150` uses
  `BoxWithConstraints` to size the viewfinder, and `SdkFlowScreen.kt:131–138` *overrides*
  `LocalConfiguration` for the SDK flow. Neither reads a breakpoint.
- **Exactly one width is verified.** `GoldenTest.kt:36` pins every golden to
  `qualifiers = "w411dp-h891dp-xhdpi"`, and the comment at `:100` records why that width was chosen —
  *"411dp hid a nav-bar clip that the device showed"*. Width-specific defects have already been found
  here at one width; there is no evidence about any other.

So a tablet build lays out and runs, because `fillMaxWidth` content stretches and nothing crashes. What
it produces is a single-column phone layout inflated to ten inches, which is not something to photograph
at 1600 × 2560 and put on a listing. Declaring large-screen support with no adaptive layout also invites
Play Console's own large-screen quality warnings.

**Phone-only, and this is reversible on purpose.** Tablet screenshots can be added to a live listing at
any time, and doing it properly is a feature — `material3-adaptive`, a two-pane verifications list, a
second golden width — not a release chore. Recorded as deferred work rather than as a gap.

### 6.3 App access — no special access, and the build agrees

**Owner ruling 2026-08-27: answer "all functionality is available without special access."** No reviewer
credentials, no access instructions. An earlier draft of this plan called it a rejection risk; the build
says otherwise, so the risk was imagined and the ruling is the correct one.

What makes it true, checked because a wrong "no" here is what gets a submission rejected: **Simulate is
not debug-gated.** `UseSmileIDSampleScanSheet.kt:53` states the intent —*"Simulate is a product feature,
not scaffolding"*— and there is no `BuildConfig.DEBUG` or `probes` condition on it anywhere. The app's
only debug gates are the result card (`VerificationsDestinations.kt:155`), the scenario drawer
(`SettingsDestinations.kt:76`) and SDK logging (`FlowBuilderConfig.kt:82`), none of which gates a
feature.

So on the production build a reviewer mints a fixture token from the scan sheet and reaches the token
session, its bindings, its countdown, the expiry state and the flow handoff — alongside every host screen,
which never needed a credential to begin with. Nothing is behind a login, a paywall, or a token we would
have to issue. **A consequence worth protecting, and a checklist line is too weak for it:** if Simulate ever moves behind
a debug or `probes` gate, this answer becomes false and the listing is misdeclared — a compliance problem,
not a cosmetic one. Checklists rot; assertions do not. So the guard is a test that the scan sheet's
Simulate affordance is present under release configuration, failing the build rather than the review.

## 7. Work items

| ID | Item | Status | Notes |
|---|---|---|---|
| REL-A1 | Adaptive launcher icon decomposed from `svgs/android.svg`, plus monochrome layer and the 512×512 listing PNG | **DONE 2026-08-28** — §4.1; safe scale measured, not assumed | §4. Two treatments of one source; check against three masks |
| REL-A2 | Release signing: reuse the v11 upload key, `exists()` guard, CI secrets | **DONE 2026-08-28** — build side only; the CI secrets are wired by A15 | §3. The irreversible one |
| REL-A3 | One monotonic `versionCode` source across all tracks, and a `versionName` scheme | **DONE 2026-08-28** | §3.1. Do not copy v11's two-scheme split |
| REL-A4 | App bundle + ABI splits | **DONE 2026-08-28** — §7.1; language splits deliberately off | The A3 size ruling landing, not a second decision |
| REL-A5 | `android/play/` as the home for title, descriptions and release notes | **DONE 2026-08-28** — owner ruling: no fastlane | The upload action reads `whatsnew/whatsnew-en-US` directly; the rest is filled in Console |
| REL-A6 | Draft the copy from §5's sources, counted against every limit | **DONE 2026-08-28** — counted by a test, not by hand | Derived from `docs-v3`, not written fresh |
| REL-A7 | Hand-written release notes; drop v11's git-log generation step | **DONE 2026-08-28** — generation step dropped, not adapted | Fixes the defect rather than porting it |
| REL-A8 | Store-art Gradle task: Roborazzi at store device specs, own output dir, own staleness input | **DONE 2026-08-28** — `StoreArtTest`, own directory and own staleness input | §2.1. Must not share a directory with goldens |
| REL-A9 | `android/maestro/store-shots.yaml` for the camera panel only, on a Gradle Managed Device | **FLOW READY 2026-08-28** — five panels rendered without it; the frame needs a device; §2.7 | §2.2. One frame, not six |
| REL-A10 | Fixture-only capture data: test identities, simulated token, `seedJobs` | **DONE 2026-08-28** — verified: the fixtures carry no names at all | §2.4. Safe to publish and safe in CI |
| REL-A11 | `storeshots` render script: presets, headlines, committed art | **DONE 2026-08-28** — `android/play/render-store-art.sh` | CLI, not the MCP server |
| REL-A12 | Transcribe v11's data-safety answers; commit §6.1's comparison as the reason | **DONE 2026-08-28** — `docs/play-data-safety.md` | §6.1. No re-derivation |
| REL-A13 | Declare no special access, and add a **test** that Simulate survives release configuration | **DONE 2026-08-28** — two tests, both mutation-checked | §6.3. The declaration's truth depends on it, so assert it rather than remember it |
| REL-A14 | Periodic `targetSdk` re-check against Play's floor | **DONE 2026-08-28** — recorded as a dated recurring check | 37 accepted today; the floor moves annually |
| REL-A15 | Publish workflows adapted from v11: internal and production tracks | **DONE 2026-08-28** — dispatch-only until the listing exists | Copy the signing and upload steps, not the version or notes steps. Both tracks pass `-PREQUIRE_UPLOAD_SIGNING=true` and the same `VERSION_CODE` command (§3) |
| REL-A16 | Release CI lane: bundle, `validate_screenshot` over the art, fail on stale art | **DONE 2026-08-28** — `release-check.yml`; stale-art gating already lives in the per-PR lane | Mirrors the existing tokens/notices gates |
| REL-A17 | The gate: art regenerates byte-identically, `verify.sh` green, nothing owed | **WALKED 2026-08-28** — §7.2; three items owed, each dated | Last, as a gate rather than as work |

### 7.1 What the bundle recovered, measured

The size ruling asked for packaging, so here is what packaging returned, built and measured on this
tree rather than estimated:

| Artefact | Size |
|---|---|
| Universal release APK (`assembleRelease`) | 69.7 MB |
| App bundle (`bundleRelease`) | 39.7 MB |
| Delivered download, arm64-v8a phone | **14.2 MB** |
| Delivered download, armeabi-v7a phone | **13.1 MB** |

`bundletool get-size total --dimensions=ABI` reports 13.8–15.8 MB across every configuration the
bundle can serve. The three ABIs a given phone never runs and the density buckets it never reads are
what the split removes; the 21.3 MB the bundled barcode model added is most of it.

**Language splits are deliberately off**, which is the one place this diverges from the defaults.
`appLocale` exists to render the app *and the SDK's own strings* in a locale that is not the device's,
and an install carrying only the device's language cannot do that — a defect that would appear on a
Play install and on no other lane. The SDK ships no localized resources today, so the price is a
handful of androidx locales now and correctness the day it does.

### 7.2 REL-A17: the gate, walked 2026-08-28

**§1's four blockers.**

| # | Blocker | State |
|---|---|---|
| 1 | Release signed with the debug key | Closed by REL-A2, and proved against the real upload key: the store opens, its only alias is `upload`, and the release APK and bundle both carry that certificate's fingerprint |
| 2 | No launcher icon | Closed by REL-A1, checked against a circle, a squircle and a rounded square, with the safe scale measured rather than assumed (§4.1) |
| 3 | Hard-coded `versionCode` | Closed by REL-A3; a blank, non-numeric or non-positive value now fails the build, and a publish build without one fails before it can burn an integer |
| 4 | No release lane | Closed by REL-A15 (publish) and REL-A16 (pre-flight bundle). Stale store art already fails the per-PR lane through `verifyRoborazziDebug` |

**§6's three answers.**

| Question | State |
|---|---|
| 6.1 Data safety | Transcribed into `docs/play-data-safety.md` with §6.1's comparison as the recorded reason |
| 6.2 Tablets | Still phone-only. No adaptive dependency was added and no tablet art exists, so the answer that made it a deferral has not changed |
| 6.3 App access | Declared as no special access, and both halves of that claim are now asserted by tests that were mutation-checked — each was made to fail on a change that compiles, then restored |

**The determinism criterion, run rather than asserted.** A full `recordRoborazziDebug --rerun-tasks`
reproduces all five panels byte-for-byte; their git blob hashes are unchanged. `android/verify.sh` is
green on a machine holding no signing secret, which is the state a fresh clone is in.

### 7.3 What the release proved, 2026-08-28

The plan's claims were checked against Play rather than against the build:

| Claim | How it was confirmed |
|---|---|
| The upload key is the v11 one and signing is correct | Console's upload certificate reads `80:11:95:8A:…:27:2C`, the keystore's own fingerprint. Signing identity is now fixed permanently, and it is the right key |
| ABI and density splits recover the size | Console reports **15.1 MB for new installs** against a 69.7 MB universal APK — within a megabyte of what `bundletool` predicted |
| One monotonic versionCode across tracks | 33 uploaded by hand, 37 published by CI, correctly ordered |
| The publish lane works end to end | The internal workflow ran green: keystore decoded from the secret, bundle signed, service account accepted the upload |
| The listing copy fits | Play accepted title, both descriptions and the release notes unchanged |

**Internal testing does not trigger Google's full review**, which is why release 33 was live within
minutes while the app was still Draft. The heavy review starts on the first promotion to closed
testing, so that promotion is worth making early rather than under deadline.

**The service account is reused from v11, like the upload key.** It already held the grant for this
app, so nothing had to be created. The cost is the same one §3 accepted for the key and is recorded for
the same reason: **one credential now has release rights to two listings**, so a future rotation
touches both.

### 7.4 Post-release follow-ups

None of these blocks anything, and none of them belongs to Android's critical path any more.

- ~~**The release shipped the design's three fixture profiles.**~~ **Found 2026-09-04, fixed with this
  note, `versionName` 1.0.1.** `UseSmileIDSampleProfiles` defaulted to UpTech Finance, Kazi Microlending
  and PesaLink, so every install showed them, the active one's organisation reached the SDK's consent
  screen as the partner name, and its id was the partner id handed to the SDK whenever no token session
  was linked. A plain launch now carries one empty `Default profile`; the three sit behind a new
  `seedProfiles` launch argument mirroring `seedJobs`, and a unit test holds both the default and the
  launch choice. REL-A10 audited what the flows *seed* and what the frames *show*; the profile store's
  constructor default was neither, which is how it passed — see §8.
- **The taller panels owe a Console upload.** `android/play/screenshots/` (five panels) and
  `android/play/feature-graphic.png` were re-rendered on 2026-09-18 from 20:9 frames (§2.6); the live
  listing still serves the 16:9 set until the owner replaces those six files by hand.
- **The camera panel (REL-A9)** needs a device. The flow and its output path are written; five panels
  are published and the sixth drops in without rework.
- **The `verification_details` panel is the weak one.** Hiding the debug result card left that screen
  sparse. Ship it, drop to four, or swap in a denser state — screenshots are editable on a live listing
  at any time.
- **The internal lane is still dispatch-only.** It was deliberate while the first upload was an owner
  action; now the listing exists, `push: branches: [main]` would make every merge an internal build.
  It needs a **path filter** when it lands, or a docs-only merge publishes a release and burns a
  versionCode for nothing. Two guards it does *not* need, so nobody adds them later: the versionCode is
  already monotonic because it is the commit count, and a `push` trigger cannot fire from a fork, so the
  secrets are not reachable that way.
- ~~The app carries two privacy policy URLs.~~ **Fixed here.** The simulated token's consent notice
  pointed at `usesmileid.com/privacy-policy`, which returns 200 but redirects to `smile.id/` — the
  homepage, not the policy. Every reference now uses `smile.id/privacy-policy`, the one that actually
  serves the page, which is also what the listing declares.
- **The Flutter and Expo id rename is deferred, ruled 2026-08-28.** Both development samples still hold
  ids this repository's apps are specified to take, but neither app exists yet, so no SDK repo is
  touched for it now. The rename travels with the sample-ui port to the four SDKs — that is when those
  apps get built and when the collision first becomes real. `spec/app-identity.json` carries the target
  ids so the work is a lookup rather than a re-decision.
- ~~**The rename to "Smile ID" is owed, and it carries a sentence with it.**~~ **Done 2026-09-14.** The iOS
  app shipped under the store name "Smile ID" on 2026-09-13 (its plan's §5), so its description opened
  *"Smile ID is the reference app…"* while `full-description.txt` here still opened *"UseSmileID Sample
  is…"*. Launcher label, Play title, Settings footer and that first sentence moved together, so both
  listings now open on the same sentence. The bodies then diverged again by ruling, see §5.
  The Console takes title and description by hand (REL-A5: no fastlane), and both were pasted: the
  live listing reads "Smile ID", carries the shorter description, and serves all five wordless panels
  byte-identical to `android/play/screenshots/`, verified 2026-09-17. What a listing edit cannot carry
  is the launcher label, which is in the binary and needs an internal publish.
- ~~**Data safety owes two rows.**~~ **Done, verified 2026-09-17** against the published Data safety
  page rather than against this file: Personal info declares Name, Email address, User IDs, Phone
  number and Other info. `docs/play-data-safety.md` now records the published answers, which differ
  from this plan's derivation in two places.
- **REL-A14 stays a calendar item.** `targetSdk` is re-checked against Play's floor annually;
  `docs/play-data-safety.md` holds the date it was last done.
- **Production promotion is a Console action**, and production is reviewed again on promotion.
- **Both publish workflows derive `versionCode` from `git rev-list --count HEAD`, and that is kept
  deliberately (owner ruling 2026-09-17).** Two workflows is the right shape — a branch goes to
  internal for people to try, production is a later and separate decision — so the count stays. Two
  consequences to respect when dispatching, because Play enforces both: **dispatching twice on one
  ref** gives the same code and the second upload is rejected (it happened 2026-09-07, production took
  56 and the internal run died eleven seconds later), and **dispatching from a branch behind main**
  gives a *lower* code, which Play refuses outright. Reading the highest code off Play and adding one
  would remove both; it was weighed and deferred, not missed.

## 8. Parity — what the other three inherit

Unchanged: capture from committed, deterministic renders rather than by hand; fixture-only data in
published frames; copy derived from the `docs-v3` product pages; store art committed and staleness-gated;
release notes written by a person. Flutter and Expo also inherit §7.1 wholesale, because their Android
builds package the same four ABIs and carry the same `appLocale` argument: app bundle, ABI and density
splits on, language splits off.

**What the Android release learned that the other three should not re-learn.** Each of these cost real
time here:

- **A rendered frame is not a screenshot — it needs a status-bar inset.** Panels render edge to edge
  from y=0, but every device frame draws a cutout and rounded corners over that band, so the app bar
  ends up underneath. Android needed 40dp. iOS will need more, and the Dynamic Island is a larger
  obstruction than a punch-hole.
- **Use one layout variant for the whole set.** Alternating `text-top`/`text-bottom`/`tilted` was meant
  to stop the panels reading as one template; in the finished strip it just made the device a different
  size and height in every panel, which reads as inconsistency.
- **Headlines take their nouns from `docs-v3` and never state a count.** "Six products" is wrong the day
  a product is added. `docs-v3` calls the record a *verification result* and describes it by *status*
  and *message*; those words are also what the app's status pills say. *Since 2026-09-14 the panels
  carry no headline at all (§2.6), so this rule now governs the listing copy.*
- **Whatever directory the store art lands in must contain only store art.** The review strip sitting
  among the panels failed the release lane, which validated it as a phone screenshot.
- **Check the rendered output, not the raw frames.** Both the cutout collision and the variant problem
  were invisible in the frames and obvious in the finished panels. That is the argument for committing
  the rendered set rather than only its inputs.
- **Every default is a fixture until proven otherwise.** REL-A10 audited what the flows seed and what
  the frames show; the profile store's constructor default was neither, and the release shipped three
  fictional partners (§7.4). Before a store build, read every state holder's default for literal data
  and put each behind a launch argument; each port's own split is tracked in its plan.

Platform-specific: iOS swaps to the `ios-phone` (1320 × 2868) and `ipad-13` (2064 × 2752) presets, and its
off-device renderer is snapshot tests rather than Roborazzi, with XCUITest for the camera panel. Worth
knowing before someone debugs it: storeshots flattens the alpha channel on every output *because App Store
Connect rejects it* — an iOS trap the tool already absorbs. Flutter and Expo take the Android presets for
Play and the iOS presets for the App Store. All four listings share one set of product paragraphs, and each
takes its own icon from `svgs/`.

## 9. Landing order

REL-A2 and REL-A3 first and together: signing and versioning are what make any upload possible, and REL-A2
is the item that cannot be revised later. REL-A4 alongside them — packaging, not behaviour, and the ruling
is already made. REL-A1 next, because an app wearing the default robot cannot be shown to anyone, and it
now has its source art.

Then the art, in dependency order: REL-A10 is a precondition rather than a follow-up, REL-A8 and REL-A9
produce frames, REL-A11 renders them. REL-A5 through REL-A7 and REL-A12/A13 need no build at all, so they
are the right work for anyone blocked on §6.

REL-A15 and REL-A16 once there is something to upload and something to gate. REL-A14 at any point. REL-A17
last: re-walk §1 and §6 and merge only when every item is either done or carries a dated decision.
