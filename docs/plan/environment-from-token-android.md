# Environment from the token, and Settings finished — Android

**Status:** Phases one and two shipped; only the visual refresh is left. PR #27 merged **2026-08-25**
with the environment chain — ENV-A1 → A6 and ENV-A12 — so a token's `api_url` decides the environment
and no Settings row can. Phase two, **2026-08-25**, closes Settings: ENV-A7, A8, A9, A14, A15 and A16
shipped as one PR, and **ENV-A11 was cut** (§4 and §4.1 row 6 carry the reason). Phase three is
`products-visual-refresh-android.md`, which ENV-A13 has moved into. §4's table carries the per-item
status, and §1 is annotated where phase one changed what it describes.

**Two things phase two found that this plan had wrong**, both corrected in place rather than only
here: §8's preflight bullet asked for a test the SDK cannot support (`validate()` is
`validateBuilder`, which sees neither the capture rule nor the consent rule), and §ENV-A8 and §6.6
named `FlowPreflight.Misconfigured` as the path an invalid flow takes when it is really
`onResult(Failure(BuilderValidationException))`. The behaviour is unchanged and arguably better — the
SDK's own message lands on the result card — but a port implementing the paragraph as written would
have looked for a gate that cannot exist.

Written against the app as merged on `main` after PR #26 (token session complete), the SDK as
published (`com.usesmileid:usesmileid:12.0.2`, read from source rather than assumed), and `spec/` at
version 1. Six of the items below are ask-first under `AGENTS.md` and are gathered in §6 rather than
decided here.

**The correction this plan carries.** `token-session-android.md` §2.1 recorded, from two tokens
decoded on 2026-08-19, that a Portal token carries **no environment claim**, and logged a Portal ask
for one. That ask has landed: a real 8h token decoded on **2026-08-24** carries an **`api_url`**
claim. §2 below is the replacement text, and correcting §2.1 in place is ENV-A12 — leaving a
superseded fact in a plan four platforms read is how a port implements last month's contract.

**What that unblocks rather than decides.** The owner ruled on 2026-08-19 that **"the token wins and
drives `useSandbox`"**, blocked only on the claim existing. So the direction is settled. What is not
settled is everything the ruling could not anticipate: `api_url` is a **URL, not a boolean**, and the
real token observed pointed at a **production** host — so "a token means sandbox" is wrong, and a
host→environment mapping with a defined unrecognised-host behaviour has to be designed. §6 carries
that and five more.

**A second design correction, from the same frame.** Node **5206:2898** re-read on 2026-08-24 renames
the first CAPTURE row from *Smile to capture / Passive capture — smile detection* to **Enhanced
SmartSelfie™ / Face capture uses head-turns**, and draws it **ON**. That inverts the setting's meaning
and its default, supersedes the owner decision of 2026-08-13 recorded in `spec/components.json`, and
turns the agent-mode mutex from a nicety into a requirement (§ENV-A7). The same frame settles the
documentation domain and contradicts the version footer (§6.8), and confirms that Settings has no
ENVIRONMENT section to remove.

**Scope widened on request (2026-08-24):** the plan now also has to leave the app with **no dead
affordance anywhere** — §4.1 is that gate, and it exists because the other three platforms port what
this app does, so a no-op shipped here is a no-op ported four times.

**The one-line goal:** the token decides which environment a job goes to, the Production toggle stops
existing, every switch left on Settings does what the screen says it does, and nothing a finger can
reach does nothing.

Companion reading: `products-visual-refresh-android.md` (the 5447:1701 refresh — it answers §6.5 and
half of §6.10, and its PVR-A3 must land before ENV-A13), `token-session-android.md` §2.1 (superseded by §2 here) and §5 (where each piece of
session state belongs), `navigation-plan.md` §7.3 (the entry gate ENV-A2 changes the inputs to), and
`sample-apps-plan.md` §8.1–§8.2 (the two design-conformance gaps §10 rules on).

---

## 1. What exists today, verified

The five rows phase one changed say so, so this table can still be read as the starting state
without misreporting the tree.

| Piece | State |
|---|---|
| `UseSmileIDSampleAppState.useSandbox` | was `launchArgs.sandbox ?: settings.useSandbox`. **PR #27:** now `session?.environment != Production`, and still the only place environment is decided |
| `environmentPinned` | was `launchArgs.sandbox != null`, with Settings rendering the row read-only. **PR #27: deleted** — with no user control there is nothing to pin |
| `UseSmileIDSampleSettings.production` | was a persisted `Boolean` under DataStore key `production`. **PR #27: deleted**; the key is inert because nothing reads it (see the migration note in §ENV-A7) |
| Production row (Settings) | was a switch in an `ENVIRONMENT` section marked **not in the design**. **PR #27: deleted** with its section |
| `ProfileEnvChip` (Products header) | **is** in the design — `spec/components.json` composite, Figma nodes 5206-2391 (products) / 5206-3138 (settings). **PR #27: hidden, not deleted** — the component, its tokens, its `sample_env_chip` id and its golden all survive; no shipped screen renders it (§6.5) |
| Environment → SDK | `FlowLaunchSnapshot.sandbox` → `partnerConfig { useSandbox = … }`. Snapshot taken **once at entry** (R2) |
| Environment → jobs | every Room row stores its own `sandbox`; `refresh` reads `row.sandbox`, never the current setting |
| `smileToCapture`, `agentMode`, `consentStep`, `instructionsStep`, `previewStep` | **persisted, rendered, and read by nothing.** No consumer outside the store and the screen |
| `darkMode` | real: the app theme, and a rewritten `uiMode` for the SDK subtree |
| ABOUT / LEGAL rows | five rows render; `onNavRowClick = {}`. `onSignOut = {}` too |
| `appLocale` launch argument | parsed and spec-tested; no consumer |

Two of these deserve saying plainly, because they are the actual size of the job:

**Five of the seven Settings switches are write-only.** `grep` for each field returns the data class,
the store, and the screen — and nothing else. `UseSmileIDSampleSettings`' own KDoc says "three of
these decide whether a step is composed into the flow at all"; `FlowLaunchSnapshot` has no `settings`
field, so none of them do. `spec/test-ids.json` is more specific still — it already declares
`sample_setting_agent_mode` → "`SelfieCaptureConfig.allowAgentMode`" and the three step switches →
"include/omit `consent()` / `instructions()` / `preview()`". So ENV-A7 and ENV-A8 are **implementing
a contract that already exists**, not proposing one. That keeps them off the ask-first list.

**Environment is already correct everywhere downstream.** The snapshot is read once at entry and the
job row keeps its own environment for life. Whatever §6.2 rules about mid-session changes, the
machinery that would make a wrong ruling dangerous is already the right shape.

---

## 2. What a Portal token carries — replacing `token-session-android.md` §2.1's finding 1

Finding 1 of that section read: *"There is no environment claim. Nothing named `env`, `is_sandbox`,
`environment`, `mode` … Portal ask: add an environment claim."* Decoding a real 8h Portal token on
**2026-08-24** supersedes it: the token carries **`api_url`**.

Three consequences, and each is a decision rather than a mechanical read:

1. **It is a URL, not a boolean.** The SDK takes a boolean and nothing else (§3), so the host must
   own a host→environment mapping. §6.1 is that ruling.
2. **The real token pointed at a production host.** So the intuition "a token means sandbox" — which
   the sample's whole fixture path assumes, and which `AGENTS.md` reinforces with *"automation and
   local runs use sandbox only"* — is false. A scanned token can put this app on the live
   environment, which is the entire reason §6.4 has to be answered before ENV-A2 lands.
3. **The claim sits at the top level, confirmed against a decoded token (2026-08-24)** — beside
   `partner_id`, `key_id`, `aud`, `exp`, `iat`, `nbf` and `iss`, exactly where §2.1's claim set implied.
   Not under `payload`. The decoder reads it with `json.string("api_url")` alongside `partner_id`.

4. **The value carries a path, and that decides the matching rule.** The observed value is
   `https://api.smileidentity.com/v3` — a **`/v3` path segment and no trailing slash**, while the SDK's
   own constant is `https://api.smileidentity.com/`. A whole-string comparison against either the SDK's
   constant or a bare origin therefore **fails on a real token**, and it fails silently: the decoder
   returns no environment and the app falls back, which looks like working software. Parse the host and
   compare that, which §6.1 already specifies — this is the evidence for why.

Everything else in §2.1 stands unchanged — no `jti`, `iat` present, `nbf` present and ignored, PII
values are 30-character vault references, and neither observed token bound consent.

---

## 3. What the SDK will accept, and what it ignores

Read from 12.0.2 source, not assumed:

- **`partnerConfig { useSandbox: Boolean }`** (`PartnerConfig`, `ConfigBuilder`) is the whole public
  surface. There is no base-URL override on the builder.
- The boolean resolves through **`internal object SmileIDUrls`** to exactly two hosts:
  `https://testapi.smileidentity.com/` and `https://api.smileidentity.com/`. `internal`, so the host
  cannot reference the constants and must carry its own copy — which
  `UseSmileIDSampleStatusApi` already does, for the same two strings.
- **The SDK ignores `api_url` entirely.** `TokenPayload.fromClaim` reads only `given_names`,
  `last_name`, `email`, `phone_number` and `consent` out of `payload` and documents that *"all other
  keys in the claim are ignored"*; `grep` for `api_url` across the SDK returns nothing. So a token
  whose `api_url` says production, submitted with `useSandbox = true`, reaches sandbox — the host is
  the only thing standing between the claim and the wrong environment.

That last point is the one worth escalating: **the SDK could read its own token's `api_url` and
route itself**, and every one of the four hosts is otherwise going to reimplement the same two-string
map. §6.7 records it as an SDK ask rather than folding it into this plan, because this app must keep
working against 12.0.2 either way.

Two more SDK facts the Settings work turns on:

- **`allowAgentMode` and `enableEnhancedLiveness` are mutually exclusive.**
  `FlowValidator.validateSelfie()` raises `AgentModeWithEnhancedLivenessException`
  (`BUILDER_AGENT_MODE_WITH_ENHANCED_LIVENESS`) at `IssueSeverity.ERROR`, which blocks the build.
  `spec/test-ids.json` currently says of Smile to capture: *"ON means enhanced liveness OFF, so it and
  agent mode write different fields and cannot fight."* **They can fight.** Smile to capture OFF plus
  Agent mode ON sets both, and the run is refused. The spec's rationale is wrong and four platforms
  would have implemented it; correcting that line is part of ENV-A4.
- **The consent screen cannot simply be omitted.** `appendConsentRule` requires a consent screen *or*
  a pre-supplied `consentInformation`, unless the token binds consent. **§6.6 rules that the app does
  neither**: `consentStep = false` simply omits `consent { }`, and if that makes the flow invalid the
  SDK's validator says so and the run is blocked with its message. `consentInformation` is therefore
  **not used anywhere in this plan** — noted because the API exists and looks like the obvious answer.

---

## 4. The work items

| Id | What | Priority | Depends on | Status |
|---|---|---|---|---|
| ENV-A1 | Decode `api_url`; two-host helper → environment; session carries it | **P1** | §6.1 *(answered)* | **Shipped** PR #27 |
| ENV-A2 | Environment resolves from the session; `production` **and** `environmentPinned` deleted, one-time clear | **P1** | A1 *(§6.2–6.4 answered)* | **Shipped** PR #27 |
| ENV-A3 | Delete the Settings `ENVIRONMENT` section; hide the Products chip; re-record goldens | **P1** | A2 *(§6.5 answered)* | **Shipped** PR #27 — twelve goldens named, twenty-six moved |
| ENV-A4 | `spec/` follows in the same PR — five files; `sandbox` **out**, `probes` **in** | **P1** | A2, A3 | **Shipped** PR #27 for the environment half; the `probes` entry and the ENV-A7 renames follow with phase two |
| ENV-A5 | Environment onto the result card — now the **only** way a run proves its environment | **P1** | A4 | **Shipped** PR #27 |
| ENV-A6 | Repair `launch-args.yaml`; Simulate mints either host so automation picks environment | **P1** | A3, A5 | **Shipped** PR #27 |
| ENV-A7 | **Enhanced SmartSelfie™**: rename, default ON, both capture switches reach the SDK, mutex enforced | **P1** | §6.9 *(polarity answered)* | **Shipped** — new DataStore key (no migration, ruled 2026-08-25), mutex in `UseSmileIDSampleSettings` |
| ENV-A8 | Step switches reach the SDK; consent is include-or-omit, token wins | **P1** | §6.6 *(answered)* | **Shipped** — the journey is a named step list, so the composition is testable |
| ENV-A9 | ABOUT / LEGAL rows open their (now settled) URLs; Sign out stops being a dead tap | P2 | §6.8 *(URLs answered)* | **Shipped** — a view intent rather than a Custom Tab, which would need a dependency |
| ENV-A10 | Coverage: unit, golden and device, for everything above | P2 | A3, A6–A9, A13–A15 | **Shipped** for the Settings half — `settings.yaml`, four new golden states, and the generator's failure path; A13's coverage goes with phase three |
| ENV-A11 | `appLocale` gets its consumer | P3 — rider | A6 | **CUT 2026-08-25**, said out loud rather than dropped. Two reasons: applying a locale below API 33 needs `androidx.appcompat` (an ask-first dependency) or a Compose configuration override, and `sample-ui` has **no string resources at all**, so the only thing an override could change today is the SDK's own strings. It belongs with the localisation work §10 already defers, which starts by extracting those strings |
| ENV-A12 | Correct `token-session-android.md` §2.1 | P1 | — | **Shipped** PR #27 |
| ENV-A13 | One reusable **SmartSelfie™** mark; lands in `cardFamily` | **P1** | §6.10, **PVR-A3 first** | **Phase three** — moved into `products-visual-refresh-android.md`, which creates `cardFamily` |
| ENV-A14 | Third-party notices: generated, shipped **in-app**, mirrored to `docs-v3` | P2 | §6.11 *(approved)* | **Shipped** — `:app:generateLicenses` / `:app:checkLicenses`, 205 open-source components and 17 under Google's terms; the `docs-v3` page stays that repo's own PR |
| ENV-A15 | The functional-completeness gate — nothing shipped is a no-op | **P1** | §4.1 | **Shipped** — §4.1 re-walked, rows 1–4, 8 and 11 empty, the rest dated |
| ENV-A16 | Probe surfaces: Scenarios row debug-only; result card behind the new `probes` argument | **P1** | §6.13, §6.14 *(approved)* | **Shipped**; `probes` also reads off a deep link's query, because a VIEW intent carries no extras |

### ENV-A1 — decode `api_url` into the session

`UseSmileIDSampleTokenDecoder.decode` gains one claim read beside `partner_id`, and
`UseSmileIDSampleTokenSession` gains one field. The field is **not** a `Boolean`: store what the
token said and resolve it at the edge, so an unrecognised host stays reportable instead of collapsing
into `true` at parse time.

```kotlin
/** The environment the token was minted for, from its own `api_url` claim. Null when the claim is absent. */
val environment: UseSmileIDSampleEnvironment? = null,
```

The map is the host, not the URL, and it is **a two-entry helper** per the 2026-08-24 ruling (§6.1):
`testapi.smileidentity.com` → Sandbox, `api.smileidentity.com` → Production, compared on the parsed
host and case-insensitively, ignoring scheme, port, path and trailing slash. Comparing whole strings
would reject `https://api.smileidentity.com` for want of the slash the SDK's own constant carries, and
that failure would present as "the token has no environment". The helper lives beside
`UseSmileIDSampleStatusApi`, which already holds both host strings.

Two rules that are cheap now and expensive later:

- **A malformed or unrecognised `api_url` is not a decode failure.** `decode` rejects only structural
  problems today (three segments, base64url, `iat`/`exp`); an unknown host must leave the session
  decodable with `environment = null`, so §6.1's ruling decides the behaviour instead of the parser
  pre-empting it.
- **`api_url` is not a credential and may be shown.** It is a public API host. `UseSmileIDSampleTokenSession.toString()`
  and `UseSmileIDSampleTokenBindings.toString()` are redacted because they carry the token and vault
  references; the environment can join the redacted `toString` as a value rather than a presence flag.

### ENV-A2 — environment resolves from the session

`UseSmileIDSampleAppState` keeps being the only place that decides, which is the property worth
preserving. The expression changes and the field list shrinks:

```kotlin
/** The only place the environment is decided, so every screen and the builder cannot disagree. */
val useSandbox: Boolean get() = session?.environment != UseSmileIDSampleEnvironment.Production
```

Both inputs are now settled: §6.1 gives the two-host helper and §6.3 removed the launch-argument
override, so `useSandbox` is a plain read of the session's environment with no `launchArgs` term at
all.

**One asymmetry, recorded as harmless rather than fixed.** `app.session` is the store's *live* record
and `useSandbox` does not check expiry, while `buildSnapshot` uses `takeUnless { it.hasExpired(...) }`.
A run can never use an expired session — `FlowPreflight` gates on `sessionExpired` first — so this
costs nothing at flow entry, and §6.15 closed without adding an environment display, so there is no
second reader to disagree with it. Left as is deliberately: `useSandbox` is a plain expression and
adding an expiry term to it would imply a caller that needs one.

What the item covers:

- `UseSmileIDSampleSettings.production` and `useSandbox`, `UseSmileIDSampleSetting.Production`, and
  the store's `PRODUCTION` key and its branch in `key()` all go.
- **`environmentPinned` goes** — §6.3 removed the launch-argument override, so the property, its
  Settings copy and `spec/launch-args.json`'s `sandbox` entry all go together.
- **The one-time clear — superseded 2026-08-25, see §ENV-A7: no migration ships, because the app is
  unreleased and the key is unread either way.** As originally written: `production = true` is
  persisted, and with the row gone there is no UI left
  to clear it — a device that has it set would submit to the live environment with no way back. The
  mechanism is a `DataMigration<Preferences>` passed to `preferencesDataStore(produceMigrations = …)`
  whose `shouldMigrate` is "the key is present" and whose `migrate` removes it; it is self-terminating
  and needs no version counter or marker key.

  **Correcting the framing, because it changes who is affected:** the manifest sets
  `android:allowBackup="false"`, so this state does **not** survive a reinstall — uninstall takes
  `/data/data` with it. It survives an in-place **update**, which is every developer and internal
  tester device that has run this app with the toggle on. The population is small and internal, not
  partner-wide. That makes the migration cheap insurance rather than an emergency, and it is still
  worth writing: the alternative is a device that silently submits live jobs and a person who cannot
  tell why. §6.4 may decide it is not worth it; the decision should be made on the real population.

### ENV-A3 — the Settings section goes, the chip stops rendering

**The Settings `ENVIRONMENT` section goes whole** — label, row, and the `environment` /
`environmentPinned` fields of `UseSmileIDSampleSettingsState`. Clean: the section was never in the
design, and `spec/screens.json` says so in its own `sections` list.

**The chip is hidden, not deleted** (§6.5, from design node 5447:1705 which carries
`hidden="true"`). That distinction decides the work:

- `ProductsScreen` stops rendering `UseSmileIDSampleProfileEnvChip`, and the header keeps the avatar
  button beside it (`products-visual-refresh-android.md` §7.5).
- **`UseSmileIDSampleProfileEnvChip.kt` stays**, and so does its `spec/components.json` entry —
  annotated hidden-on-products with the node id, not removed. Nothing has to be justified as a deleted
  design component, which is what the earlier delete-or-move question was about.
- `sample_env_chip` stays in `UseSmileIDSampleTestIds` and in `spec/test-ids.json`, because the
  component that carries it still exists.

**Goldens — twelve images, and the count is not what the chip's own names suggest**, because every
products golden contains the header:

| Golden | Fate |
|---|---|
| `screen_products_production` light + dark | **deleted** — no production state is reachable from the app |
| `screen_products`, `_token_linked`, `_token_expired`, `_in_flight`, light + dark | **re-recorded** (8) — the header loses the chip |
| `screen_settings` light + dark | **re-recorded** — a section leaves the list |
| `profile_env_chip` light + dark | **unchanged** — the composite golden renders the component directly, and the component does not change |

`ScreenCompositeGoldenTest.profile_env_chip_max_font_scale` is a predicate rather than an image and is
likewise unaffected. The product-card and grid goldens move too, but under
`products-visual-refresh-android.md` PVR-A12, not here — do not re-record them twice.

### ENV-A4 — `spec/` follows, in the same PR

`AGENTS.md`: every `spec/` change lands with the four app-side updates or an explicit note saying
which platform follows and why. Android is the only app that exists, so the note is the whole
mechanism — and the ask in §6 is what makes the change legitimate in the first place.

| File | Change |
|---|---|
| `launch-args.json` | `sandbox`'s description says environment comes from "the app's own environment control, which defaults to sandbox". Rewrite for §6.3's answer. Keep the "automation must never run with `sandbox=false`" line — it is the reason §6.3 matters |
| `screens.json` | `settings.sections` loses the `ENVIRONMENT (one row: Production …)` entry and `settings.testIds` loses `sample_setting_production`; the `production` state goes from `settings` and from `products`; `products.components` loses or keeps `ProfileEnvChip` per §6.5 |
| `components.json` | `ProfileEnvChip` deleted or its `usedBy` and `metrics.role` restated. **Do not silently drop a designed component** — if it goes, the entry records the ruling that removed it, the way the two 2026-08-13 decisions are recorded |
| `test-ids.json` | `sample_setting_production` deleted; `sample_env_chip` follows the chip; `sample_setting_smile_to_capture`'s "cannot fight" rationale corrected per §3; add `sample_result_environment` (ENV-A5) |
| `result-card.schema.json` | one new field (ENV-A5) |

`UseSmileIDSampleTestIdsSpecTest` asserts app ids ⊆ spec ids, one way — so removing an id from the app
alone passes silently and removing it from the spec alone fails. Delete from both in one commit.

### ENV-A5 — environment onto the result card

The card is `spec/result-card.schema.json` and it has **no environment field**. Today the device suite
asserts environment on `sample_env_chip`; once environment is a token property that is the wrong
surface, and since the chip stops rendering on Products (§6.5) there is no surface at all. A run would
have no way to prove
which environment it submitted to — the exact failure the card exists to prevent, and the one
`AGENTS.md` calls out when it says a probe that never acquired the camera passes vacuously.

Add `environment` as a required string enum `["sandbox", "production"]`, rendered under
`sample_result_environment`. Required rather than optional: a card that omits it when it does not know
is indistinguishable from a card whose field never reached the tree, and `launch-args.yaml`'s own
comment already makes that distinction the point of asserting every field.

### ENV-A6 — `android/maestro/launch-args.yaml`

Two blocks die and one is new:

- **The `sandbox: false` block is deleted outright.** §6.3 removed the argument, so there is nothing
  left to pass. Worth recording why it should not simply be rewritten: it was the only place in the
  repo that contradicted `spec/launch-args.json`'s own rule that *automation must never run with
  `sandbox=false`*. Removing the argument removes the contradiction rather than papering over it.
- The whole *"Absent, the Settings toggle owns the choice"* block goes — it taps
  `sample_setting_production` four times and asserts the three supporting strings.
- New: link a token whose `api_url` names each host and assert `sample_result_environment`. The
  Simulate path is what makes this runnable without a real Portal token, so
  `UseSmileIDSampleFlowTokens` must be able to mint both — see ENV-A10.

`grep` confirms no other flow references the chip, the row, or either environment word.

### ENV-A7 — Enhanced SmartSelfie™, and both capture switches reach the SDK

**The design changed, and it changed the meaning, not just the words.** Node 5206:2898, re-read
2026-08-24 — the row is the `CaptureModeRow` component instance (5206:2913), which is why a
metadata-only read returns no text and `spec/components.json` already warns about exactly that:

| | Before | After (design) |
|---|---|---|
| Title | Smile to capture | **Enhanced SmartSelfie™** |
| Supporting | Passive capture — smile detection | **Face capture uses head-turns** |
| Default | ON | **ON** |
| Means | `enableEnhancedLiveness = false` (inverted) | `enableEnhancedLiveness = true` (**direct**) |

So the label is renamed, the polarity inverts, and because the default stays visually ON the app's
**default capture behaviour flips** from passive smile capture to the head-turn challenge. That is the
substance of this item; the rename is the easy half.

**It supersedes a recorded owner decision.** `spec/components.json` carries *"OWNER DECISION
2026-08-13: 'Smile to capture' ON means enhanced liveness OFF"* twice — on the `SettingRow` component
and in `settingsToSdkMapping`. Both must be rewritten and both must say they were superseded by the
2026-08-24 frame, not silently replaced. §6.9 is the ask, because it also renames a test id.

**One consequence of the new key that is intended but silent, and belongs in the PR.** A device that
had *Smile to capture ON* (enhanced OFF) reads the new key as absent and takes its default —
**enhanced ON**. So capture behaviour changes under that user without them touching anything. That is
the design's intent rather than a migration bug, but it reads as a regression on a device unless
someone wrote it down first.

**Three traps, in the order they will bite.**

1. **The stored value must not be reinterpreted.** `smile_to_capture = true` meant *enhanced OFF*;
   `enhanced_smart_selfie = true` means *enhanced ON*. Reusing the DataStore key would hand every
   existing device the exact opposite of what it chose. Use a **new key**
   (`enhanced_smart_selfie`), which is the whole fix: nothing reads the old one, so its value is inert.

   **Owner ruling 2026-08-25: no migration.** This plan asked for a `DataMigration<Preferences>`
   dropping both dead keys, and `UseSmileIDSampleRetiredSettingKeys` was written for `production` in
   PR #27. It is **deleted**, and this item does not add to it: the app is unreleased, so no partner
   device carries either key, and a compatibility shim for state nobody has is exactly what an
   unreleased app should not ship. Behaviour is identical either way — both keys are unread, so they
   sit in the file doing nothing rather than being tidied away on the next launch. The ports inherit
   the same rule: **rename the key, do not migrate it.** If this app is ever released and a stored key
   has to be retired after that, the mechanism comes back with a reason.
2. **The mutex stops being optional.** Enhanced liveness now defaults **on**, so a single tap on Agent
   mode sets both and `FlowValidator.validateSelfie()` raises `AgentModeWithEnhancedLivenessException`
   at ERROR severity — a blocked run from the app's own default state plus one tap. Before this
   change the default pair was safe and the mutex was defence in depth. Enforce it in
   `UseSmileIDSampleSettings` (a `withSetting` returning the corrected pair) rather than in the screen,
   so both platforms' persistence paths and all four ports inherit one rule: turning Agent mode ON
   turns Enhanced SmartSelfie™ OFF, and turning Enhanced SmartSelfie™ ON turns Agent mode OFF, each
   with the supporting line saying which one moved.
3. **`spec/test-ids.json` is now doubly wrong.** It says the two *"write different fields and cannot
   fight"*. They write different fields **and they fight** — that was already true (§3) and the new
   default makes it reachable by accident. Ported as written it is four apps that can build an
   unbuildable flow from their default state.

**The wiring.** `FlowLaunchSnapshot` gains the two fields it needs — pass the two, not the whole
settings object, because the snapshot's contract is "read once at entry, never re-read" (R2) and a
whole object invites a later reader to pull something live out of it:

```kotlin
val allowAgentMode: Boolean,
val enableEnhancedLiveness: Boolean,
```

`selfieCapture()` in `FlowBuilderConfig` stops hard-coding and reads them. One behaviour change worth
a device check rather than a shrug: `SmartSelfieEnrollment` passes `enhancedLiveness = true`
unconditionally today, so enrollment already ignores this setting. Under the new default the observable
behaviour of enrollment is unchanged, which is the one piece of luck in this item — the risky change
is to the other five products, which flip from passive to head-turn.

### ENV-A8 — the step switches reach the SDK

`journeyFor` reads three more snapshot fields. All three are plain include-or-omit, which is what
`spec/test-ids.json` already describes — so this item implements a contract rather than proposing one.

**Instructions and preview** are unconstrained omissions: no validator requires either,
`appendPreviewRule` caps previews rather than demanding one, and preview must follow a capture, which
the current composition already guarantees. Document flows emit two previews and **both go together** —
a half-applied toggle would be a silent divergence between the two document products.

**Consent** follows §6.6: ON adds `consent { }`, OFF omits it, and a token consent binding wins over
both. The third case is already implemented and currently **invisible** — `journeyFor` omits
`consent { }` when the token binds it and nothing tells the reader. A switch showing ON while the token
has taken the decision away is a lie the screen tells, so the row needs an overridden supporting line,
which is the one part of the deleted Production row's treatment worth keeping.

**When OFF produces an invalid flow, let it — but not by the route this paragraph first claimed.**
No token consent plus no consent screen is an ERROR from `appendConsentRule`, and per §6.6 that is the
intended demonstration. **Corrected 2026-08-25:** the host pre-flight cannot see it (see §8), so
`FlowPreflight.Misconfigured` and `recordBlocked` are *not* the path. The SDK refuses the flow itself:
`build()` returns `Invalid`, the SDK calls `onResult(Failure(BuilderValidationException))` carrying its
own message and suggested fix, and the app records a Failed result and lands on the details screen —
so the message reaches `sample_result_last_error`, which is the evidence channel a device flow reads
anyway. The requirement is unchanged and still met: the app says why.

### ENV-A9 — ABOUT, LEGAL and Sign out

Five rows and a destructive row, all wired to `{}`. No route exists for any of them in
`spec/routes.json` and no screen in `spec/screens.json`, which is the answer rather than a gap:
**open them externally**, with a Custom Tab falling back to `ACTION_VIEW`. That adds no route, no
screen, no spec surface, and it is what a partner app does.

**The documentation domain is settled by evidence, not by asking.** The design's supporting line reads
**`docs.usesmileid.com`** (text node 5206:2973) while `spec/screens.json` records
`docs.smileidentity.com`. Resolved on 2026-08-24: both are CNAMEs to the same GitBook host
(`1c35f2a3fd-hosting.gitbook.io`) and `https://docs.smileidentity.com/` answers **307 →
`https://docs.usesmileid.com/`**. The apex domains agree — `smileidentity.com` 301s to
`usesmileid.com`. So the design is current, the spec is legacy, and `docs.usesmileid.com` is the
canonical string to ship. `spec/screens.json` → `copy.aboutDocs` is corrected in ENV-A4.

**The version footer follows the design** (ruled 2026-08-24, §6.8). It becomes
**`Smile ID Sample App · 1.0.0`** — `SettingsDestinations.kt`'s `APP_DISPLAY_NAME` and
`spec/screens.json` → `copy.footer` both change. It does **not** touch `spec/app-identity.json`: that
file's `UseSmileID Sample` is the launcher label and store identity, the footer is brand copy, and
after this change the two legitimately differ. Record that in the spec so the next reader does not
"fix" it.

**Sign out.** There is no auth, so there is nothing to sign out of. It is a designed row, so it stays —
but it must do something honest. The defensible act is "clear the local session and the saved form
details, then return to Products", which is real, reversible, and matches the word. §6.8 rules on it;
what it must not do is stay a dead tap on a screen this plan claims is complete.

**Open-source licenses is not a link and not a one-liner** — it became ENV-A14.

### ENV-A10 — coverage

No detail here on purpose: §8 is the whole item, and duplicating it is how the two drift. The item
exists in the table so that "coverage" has an id, a priority and a dependency list like everything
else, rather than being the part that quietly does not happen.

### ENV-A16 — probe surfaces go debug-only

Per §6.13. Two surfaces, two different mechanisms, because only one of them is free.

**The Settings DEBUG section** — wrap it in `BuildConfig.DEBUG`. It lives in `SettingsDestinations`
(the shell), not in `sample-ui`, because `sample-ui` runs under eight identities and must not read a
host's build config. So the screen takes the section as a nullable slot and the shell decides whether
to fill it — which is the same shape `versionLabel` already uses for the same reason.

**The result card** — hidden on release unless the `probes` argument (§6.14) asks for it, always on in
debug. Same placement rule: `VerificationDetailsScreen` takes a `showProbes: Boolean`, the shell
computes `BuildConfig.DEBUG || launchArgs.probes`, and `sample-ui` stays identity-agnostic.

**Do not compile either out with a source-set trick.** A `debug`-only source set would mean the release
variant never compiles the code, which is exactly the configuration `AGENTS.md` wants exercised — and
it would make the `probes` argument impossible. A runtime flag keeps the code on the release classpath,
minified and shrunk like everything else, which is where consumption defects actually surface.

**Note for the localisation work (deferred, §10).** The Scenarios drawer is the natural host for the
locale and RTL flows once they exist — it is already the "drive the app into a state" surface, and
`appLocale` (ENV-A11) is already the mechanism `spec/launch-args.json` specifies for it.

### ENV-A11 — `appLocale` (rider, drop it freely)

Parsed, spec-tested, and read by nothing — the same write-only shape as the five switches, found in
the same sweep. `AppCompatDelegate.setApplicationLocales(LocaleListCompat.forLanguageTags(tag))`
applied once at launch is the whole consumer. It is folded in only because ENV-A6 already has
`launch-args.yaml` open and ENV-A10 already has the device suite open, so the marginal cost is one
assertion. It is unrelated to environment and should be the first thing cut if the PR gets large;
say so in the PR rather than dropping it silently.

### ENV-A12 — correct `token-session-android.md` §2.1

Replace finding 1 and delete the Portal ask it carries. Leave the other five findings alone. Add the
2026-08-24 decode to that section's provenance line so the reason the text changed is on the page —
`AGENTS.md` precedence is `AGENTS.md > docs/ > spec/ > code`, which means a stale `docs/` statement
outranks the code that contradicts it.

### ENV-A13 — one reusable SmartSelfie™ mark

The mark now appears in the product name (`Enhanced SmartSelfie™`, ENV-A7) and the product labels
already say `SmartSelfie Enrollment` and `SmartSelfie Authentication`. Rendering it in more than one
place by hand is how three of the eight hosts end up with a bare `SmartSelfie`.

**What the sources actually say, because they disagree:**

| Source | Renders |
|---|---|
| Settings design, node 5206:2913 (2026-08-24) | `Enhanced SmartSelfie™` |
| Partner docs (`docs-v3`) | `SmartSelfie™` on **every** occurrence — `SmartSelfie™ Registration`, `SmartSelfie™ Compare`, `SmartSelfie™ Authentication` |
| Products grid, node 5206-4037 | `SmartSelfie Enrollment`, `SmartSelfie Auth` — **no mark** |
| App + `spec/scenarios.json` | `SmartSelfie Enrollment`, `SmartSelfie Authentication` — no mark |
| SDK `strings.xml` | the name does not appear at all |

The products grid frame is **already known stale** against two owner rulings — it draws five cards
where the owner ruled six, and `SmartSelfie Auth` where the owner ruled the full
`SmartSelfie Authentication`. So its missing mark is weak evidence, and the partner docs are strong
evidence. §6.10 is the ruling; this item is what makes the ruling one edit instead of eight.

**The shape, and it is not only a composable.** The name lives inside `UseSmileIDSampleProduct`'s
labels and inside `spec/scenarios.json` — it is **data before it is UI**, so a composable alone cannot
own it. Two pieces:

```kotlin
/** The trademarked product name, in one place, so eight hosts render the mark identically. */
object UseSmileIDSampleMarks {
    const val SMART_SELFIE = "SmartSelfie\u2122"
}
```

with the product labels composed from it, plus a small `UseSmileIDSampleMarkText` **only if** §6.10
rules the mark needs its own type treatment. It belongs in `sample-ui`: `AGENTS.md` forbids reading an
application id there, and a product name is a brand string, not an identity string.

**Three things that make this less trivial than it looks.**

- **Do not fake the superscript.** The design renders the plain U+2122 glyph, which the typeface already
  draws raised and small. Reimplementing it as a smaller font size with a baseline shift diverges per
  platform, breaks at maximum font scale, and is the kind of thing the structural predicates exist to
  catch. Confirm against the design's text run before writing any `AnnotatedString`.
- **Screen readers announce it.** TalkBack and VoiceOver read ™ aloud, so every product card becomes
  "SmartSelfie trade mark Enrollment". If §6.10 puts the mark on the product labels, the visible label
  and the accessibility label must differ — the mark visually, the plain name in `contentDescription`
  / `semantics`. This is a real regression the goldens cannot see.
- **It breaks two device flows.** `deep-links.yaml:60` asserts the literal text
  `"SmartSelfie Enrollment"` and `launch-args.yaml:97` / `deep-links.yaml:37` assert `"Biometric KYC"`.
  Adding the mark to product labels breaks the first. Sweep every `assertVisible: "…"` in
  `android/maestro/` in the same change, and prefer moving those assertions onto `sample_*` ids, which
  is what the testing contract asks for anyway.

### ENV-A14 — third-party notices, generated and shipped in the app

The design's row is **Open-source licenses**, and reading the resolved dependency graph on 2026-08-24
found the reason it cannot be a plain list under that heading: **four of them are not open source** —
Play Integrity, ML Kit (three artifacts) and the low-light-boost library all ship under Google's own
terms. §6.11 carries the table, the generator rules and the full inventory.

**Three pieces of work:**

1. **A build-time generator** that resolves the release runtime classpath, walks **parent** POMs,
   consults a small reviewed override table, keeps multiple licences per artifact, and **fails** on
   anything it cannot identify. Output: one `licenses.json`.
2. **An in-app screen** rendering it, built from `UseSmileIDSampleSectionSurface`,
   `UseSmileIDSampleSettingRow` and `UseSmileIDSampleTopAppBar` — no new runtime dependency, and the
   one screen in the app that must not look bolted on. Two sections: open-source components with their
   licence text, and Google services under their own terms. This is a new screen, so it needs a
   `spec/screens.json` entry, a `spec/routes.json` route and a `sample_*` id — the first genuinely new
   route this plan adds, which is why §6.11 is ask-first.
3. **The `docs-v3` page**, rendered from the same file, as the partner-facing copy.

**Why in-app rather than a link, since this reverses the earlier recommendation:** Apache-2.0 §4 asks
that the notice travel with the distribution, and this graph is overwhelmingly Apache-2.0. A URL is a
weaker discharge than shipping the text, which is why major apps ship an acknowledgements screen. The
docs page stays — it is the copy partners can lift for their own listing, not the thing that satisfies
the obligation.

### ENV-A15 — the functional-completeness gate

The ports copy this app, so a no-op here becomes four no-ops. §4.1 is the ledger and the acceptance
criterion; this item is the work of emptying it. It is listed separately from ENV-A9 because ENV-A9 is
the Settings rows and this is the sweep that proves nothing else was missed.

## 4.1 The functional-completeness ledger

Swept 2026-08-24 across every destination file and every screen, not sampled. This is the gate ENV-A15
closes: **the other three platforms port what this app does, so anything left dead here ships four
times.** The good news first — the sweep found far less than the brief implies.

**Wired and working** (no action): every product card, the header avatar and profile-switch sheet, the
token float and scan entry, the session card's Scan action; the verifications filter chips, row tap,
select mode, selection removal, the undo toast, and swipe-to-delete; verification details' back,
delete, per-field copy and pull-to-refresh; both pre-flow forms with the country and ID-type pickers;
the whole profiles area — switch, list, config save, new profile; the scanner's paste, manual entry,
simulate, torch and back; the scenario drawer; the nav bar. Empty-lambda hits in
`ComponentGalleryScreen` are correct — it is a dev-only gallery whose whole point is inert components.

**Dead or missing** — the entire list:

Re-walked **2026-08-25** at the end of phase two; the Closed column is what that walk found.

| # | Surface | State | Item | Closed |
|---|---|---|---|---|
| 1 | Settings → ABOUT: Documentation, Support | `onNavRowClick = {}` — two dead rows | ENV-A9 | **Empty** — both open their settled URL through a view intent |
| 2 | Settings → LEGAL: Terms, Privacy, Open-source licenses | same callback — three dead rows | ENV-A9, ENV-A14 | **Empty** — two open URLs, and Open-source licenses opens the notices screen |
| 3 | Settings → Sign out | `onSignOut = {}` — a dead destructive row | ENV-A9 | **Empty** — clears the session and the saved form details, then returns to Products |
| 4 | Settings → 5 of 7 switches | persisted, rendered, read by nothing | ENV-A7, ENV-A8 | **Empty** — all five reach the SDK, and the device flow proves each by where the run lands |
| 5 | Verifications list → pull-to-refresh | design draws it and a `refreshing` state; not implemented | §10 — stays deferred, new reason | **Dated decision 2026-08-25**, now written into `sample-apps-plan.md` §8.1 rather than only here: `refresh` returns `SessionMismatch` for any row not submitted under the current session, so a list-wide pull would visibly do nothing for most of the list. The shape it needs first is whether a refresh spans sessions at all |
| 6 | `appLocale` | parsed, spec-tested, no consumer | ENV-A11 | **Dated decision 2026-08-25 — cut**, with the reason in §4: it needs a dependency this repo must ask before adding, and there are no strings to localise until §10's extraction lands |
| 7 | Launcher icon | no `android:icon`, no `mipmap/` — the app wears the system default | §10 — excluded, own PR | **Dated decision** — §10, app-identity work |
| 8 | `PlaceholderScreen.kt` | `internal`, **zero references anywhere** — dead code | ENV-A15, delete it | **Empty** — deleted 2026-08-25 |
| 9 | Every sheet | nothing renders behind the scrim (F50) | §10 — ruling asked, not built | **Dated decision 2026-08-24**, now written into `navigation-plan.md` R12 so the ports read a rule: M3's `ModalBottomSheet`, owned by the screen beneath, and the five sheet routes resolve to their parent screen with the sheet open |
| 10 | Scenario drawer presentation | the one `spec/screens.json` open question still **OPEN** | §6.12 — closed: Settings row, debug-only | **Empty** — recorded in `spec/screens.json` as a deliberate addition, which closes the last OPEN question in the spec |
| 11 | Probe surfaces on release | Scenarios row and result card ship to partners today | ENV-A16 | **Empty** — the row is debug-only, the card is behind `probes`, and the release device run passes it |
| 12 | Localisation and RTL | `sample-ui` has **no `strings.xml` at all** — every string is a Kotlin literal | §10 — deferred, post-port | **Dated decision** — §10, after the ports |

**Not gaps, and not to be "fixed":** the result card's `sdkVersion` em dash is instructed by
`spec/result-card.schema.json`'s `blocked` note; the scan reticle being decorative while the analyser
reads the whole frame is a recorded open design question, not a bug.

**The acceptance criterion for ENV-A15**, and the thing to hand the ports: rows 1–4, 8, 10 and 11 are
empty at merge, and rows 5, 6, 7, 9 and 12 each carry a written decision — a dated ruling or an item in
another PR — rather than silence. A port reading this document should be able to tell, for every
affordance in the app, whether it works or whether somebody decided it does not yet. **Met on
2026-08-25**, with one change from the list as written: row 6 moved from empty to dated, because
`appLocale` was cut, and row 10 moved the other way.

---

## 5. Where environment is decided, before and after

| Reader | Today | After |
|---|---|---|
| The SDK builder | `snapshot.sandbox` ← `app.useSandbox` | unchanged — the snapshot's source changes, not the seam |
| A job row | `snapshot.sandbox`, stored per row | unchanged |
| A status refresh | `row.sandbox` | unchanged |
| The chip | `app.environment` | **stops rendering** on Products; the component stays (§6.5) |
| Settings | `app.environment` + `environmentPinned` | gone — both, with the section |
| The result card | — | new (ENV-A5) |

The seam is already right, which is why this is a plan about a decision and a screen rather than a
refactor. `buildSnapshot` reads the clock and the stores once at entry precisely so a run cannot be
moved underneath itself, and `processingJob` comments that it stamps the row *"from the snapshot, not
re-read: by the time a result lands the toggle may have moved on"*. Both invariants are what make
§6.2's answer free rather than merely cheap: the case it worried about cannot arise.

---

## 6. Ask first — the rulings this plan will not make on its own

`AGENTS.md` requires asking before changing anything in `spec/` that four apps implement, and these
change six spec files between them. The rest are here because they are product or brand decisions
wearing engineering clothes.

### 6.1 `api_url` — **answered: two hosts, one helper**

**Owner ruling 2026-08-24: there are only ever two hosts** — `api.smileidentity.com` and
`testapi.smileidentity.com` — so check for them in a helper and be done. That matches the SDK exactly:
`internal object SmileIDUrls` resolves its boolean to those same two strings and nothing else.

```kotlin
/** The token's `api_url` onto an environment. Two hosts is the whole contract — see the SDK's own SmileIDUrls. */
/** The token's `api_url` onto an environment. Host only: a real claim carries a `/v3` path. */
fun environmentFor(apiUrl: String?): UseSmileIDSampleEnvironment? = when (apiUrl?.toHostOrNull()) {
    SANDBOX_HOST -> UseSmileIDSampleEnvironment.Sandbox
    PRODUCTION_HOST -> UseSmileIDSampleEnvironment.Production
    else -> null // absent or unrecognised — the scanner refuses and says which host it saw
}
```

Match on the **parsed host**, case-insensitively — never the whole string, or
`https://api.smileidentity.com` fails for want of the trailing slash the SDK's constant carries, and
that failure presents as "the token has no environment".

`UseSmileIDSampleStatusApi` already holds both host strings for its own `GET /v3/status/{jobId}`
calls, so the helper lives beside them and there is exactly one copy in the app.

**The `null` branch: one answer, because the claim is always present.** Owner ruling 2026-08-24: the
URL is never missing. So absent-claim and unrecognised-host collapse into the same outcome and the
helper stays a plain nullable return.

**Refuse the token, and name the host on screen.** The scanner already has an honest rejection path —
`UseSmileIDSampleTokenDecode.Rejected` names the claim and never a value — and an API host is public,
so showing it leaks nothing. A silent sandbox fallback would submit a production-minted token to the
wrong environment and surface as a 401 that reads like a bad token; loud beats plausible.

The branch should still be written and tested even though it should never fire. It is what tells us
the day the contract changes — and the pre-claim tokens that once argued for a softer fallback are all
long past their 8h ceiling.

### 6.2 Mid-session environment change — **closed: the case stops existing**

**Owner ruling 2026-08-24: under the new flow there are no such cases.** That is right, and the
reasoning is worth recording so nobody reopens it:

- **A run in flight cannot move.** `FlowLaunchSnapshot` is read once at entry (R2), and `processingJob`
  stamps the row from the snapshot, not from live state.
- **A persisted job keeps its own environment for life.** `refresh` reads `row.sandbox`, and
  `SessionMismatch` means a refresh only ever runs under the session that submitted the row — so a row
  and its refresh can never disagree.
- **The resume path is no longer a mismatch, it is the answer.** When an expired run is sent to the
  scanner and resumed, a new snapshot is built from the new token — and since the token *is* the
  environment, the resumed run goes where its token says. There is nothing to reconcile.

No work. The machinery that would have made a wrong ruling dangerous already has the right shape.

### 6.3 The `sandbox` launch argument — **answered: everything switches to the token**

**Owner ruling 2026-08-24: all environment config comes from the token.** So the `sandbox` argument
stops being an environment override, and `spec/launch-args.json` loses it — a four-platform contract
change that ENV-A4 carries.

Three things follow, and the third is what makes it work:

1. **`environmentPinned` disappears entirely**, along with the Settings copy *"Pinned by the sandbox
   launch argument"* and `UseSmileIDSampleAppState.environmentPinned`. `useSandbox` becomes a plain
   read of the session's environment.
2. **A tokenless run is still sandbox — but be precise about why, because the obvious phrasing is
   wrong.** It is tempting to say *the environment is whatever the token in use says, fixture or
   scanned*. The code cannot mean that: `useSandbox` reads `app.session`, and the fixture minted inside
   `applying()` is **not** a session — it never reaches app state. So the real rule is: **environment
   comes from the linked session; no session means sandbox.** Give the fixture an `api_url` naming the
   sandbox host anyway, so the artifact is self-consistent and its decode test passes, but do not
   describe it as the source of truth — a later reader who believes that will go looking for a code
   path that does not exist.
3. **Automation keeps determinism through the same door.** This is the part that would otherwise be a
   regression: `launch-args.yaml` uses `sandbox` today to pin a run. It does not need to — the
   scanner's **Simulate** path already mints a fixture token in-process (`token-session-android.md`
   §7.2 records that automation needs no new argument for exactly this reason). Extend Simulate to
   mint either host, and a flow picks its environment by minting rather than by argument. That is
   strictly better evidence: it exercises the real decode path instead of bypassing it.

`sample_result_environment` (ENV-A5) is what a flow then asserts on, so a run still proves which
environment it got rather than which one it asked for.

### 6.4 Production reachability — **answered: production is always reachable**

Reachable **through a production-minted Portal token**, which is exactly what the real 8h token decoded
on 2026-08-24 was. Removing the Production toggle removes a *local* switch, not the environment.

Two consequences to state plainly rather than discover:

- **The sample can submit real production jobs** the moment someone scans a production token. That is
  intended, and it is why the environment must be visible — `sample_result_environment` on the result
  card (ENV-A5) is the thing that says where a job actually went.
- **Automation stays sandbox-only by construction**, satisfying `AGENTS.md`, because automation mints
  its own fixture tokens (§6.3) and those name the sandbox host. No flow can reach production by
  accident, because no flow has a production token to reach it with.

The one-time DataStore clear in ENV-A2 still lands: a device carrying `production = true` from the old
build would otherwise have a stale key with no UI left to clear it. It is cheap and self-terminating.

### 6.5 Does the environment chip go, or move? — **superseded, see below**

**Answered by the design on 2026-08-24.** Node `5447:1701` keeps the `profile-env` instance in the
frame and sets it **`hidden="true"`** — hidden, not deleted. So the component survives in
`spec/components.json`, the chip stops rendering on Products, and nothing has to be justified as a
deleted design component. `screen_products_production` still goes; `profile_env_chip` follows the
component. Take that answer and drop this question, but read
`products-visual-refresh-android.md` §7.5 first — the same frame also removes the header **avatar
button**, which leaves Products with no profile-switch trigger at all. The recommendation below to
move the chip into the session card is withdrawn.

<details><summary>The original question, kept because its reasoning still applies if the ruling changes</summary>


The Settings row is uncontroversial — it was never in the design and `spec/screens.json` says so.
The chip is different: a designed composite in `spec/components.json` with tokens, metrics, a
variant pair, two recorded owner decisions and Figma nodes, whose removal deletes two screen states
and a component from the spec.

**Recommendation: keep the chip and move it into the session card.** Once environment is a property of
the token, it belongs with the token — the session card already renders the handle and the countdown,
and putting the environment there says *this session submits here*, which is the true statement, where
a header chip says *this app submits here*, which stops being true the moment a token can change it.
That keeps a designed component alive, keeps a human-visible environment indicator at the moment it
matters most, and costs a re-record of the same goldens ENV-A3 already re-records.

If the ruling is removal, the chip's `spec/components.json` entry must record why, in the same style
as the 2026-08-13 decisions already on it. A designed component that disappears with no note is how the
next design-conformance pass reports it as missing.

</details>

### 6.6 The consent switch — **answered: add or omit `consent { }`, and the token always wins**

**Owner ruling 2026-08-24**, and it is simpler and more honest than either option I offered:

| Setting | Token binds consent | Builder |
|---|---|---|
| ON | no | `consent { }` |
| OFF | no | **nothing** — the screen is simply omitted |
| either | **yes** | nothing; the token's binding wins, always |

**No `consentInformation` is fabricated.** My earlier concern — that OFF would put an invented
`granted = true` on the wire — dissolves: OFF just omits the screen. Withdrawn.

**What happens when OFF makes the flow invalid is the point, not a bug.** With no token consent and no
consent screen, `appendConsentRule` raises an ERROR (*"must include either a Consent screen or a
pre-supplied consentInformation"*), and the app shows the SDK's own reason. Per the ruling: **the SDK's
builder validation handles that** — literally, as it turns out. **Corrected 2026-08-25:** this said the
host pre-flight returns `FlowPreflight.Misconfigured`; it cannot, because the rule runs inside the SDK's
own `build()` and no public entry point exposes it (§8). The demonstration arrives as
`onResult(Failure(BuilderValidationException))` instead, so the SDK's message and suggested fix land on
the result card. For a sample whose job is to show partners what the SDK does, a switch that
demonstrates a real validation failure with a real message is a legitimate probe affordance — it just
has to say why, which the result card does.

**Two things this simplifies.** `spec/test-ids.json`'s description for `sample_setting_consent_step`
— *"include/omit `consent()` in the flow"* — is **already correct** and needs no edit, so ENV-A4 gets
smaller. And the token-priority row must be *visible*: a switch reading ON while the token has taken
the decision away is a lie the screen tells, so the row needs the overridden treatment described in
ENV-A8.

### 6.7 SDK ask — **decided: do not file it**

**Owner ruling 2026-08-24: no — the SDK only needs to know whether it is sandbox or not.**

That is the right call and worth recording with its reasoning, because the question will occur to the
next reader too. `partnerConfig { useSandbox }` is the SDK's abstraction boundary: the SDK's job is to
pick a base URL from a boolean, and *deciding* which environment a session belongs to is the host's.
Pushing `api_url` parsing into the SDK would move a Portal-shaped concern into a library that
deliberately knows nothing about how the token was minted.

So §6.1's helper is not a workaround for a missing SDK feature — it is the host doing its own job. The
duplication it creates is one two-entry `when`, per platform, which is a cheaper price than widening
the SDK's contract. **Nothing to file.**

### 6.8 The URLs — **answered**, and the footer is the only thing still owed

**All five destinations settled 2026-08-24 from `smile.id`, each verified to return 200:**

| Row | URL |
|---|---|
| Documentation | `https://docs.usesmileid.com/` |
| Support | `https://smile.id/contact-us` |
| Terms of Service | `https://smile.id/terms-and-conditions` |
| Privacy Policy | `https://smile.id/privacy-policy` |
| Open-source licenses | in-app — see §6.11 |

Two corrections that fall out of it. The design's supporting line reads `docs.usesmileid.com`, which is
right — `docs.smileidentity.com` 307-redirects to it — so `spec/screens.json`'s `copy.aboutDocs` is
legacy and ENV-A4 fixes it. And **`FlowBuilderConfig` hands the SDK's consent screen
`https://usesmileid.com/privacy-policy`**, which resolves but is not the canonical host; point it at
`https://smile.id/privacy-policy` in the same change, so the settings row and the consent screen cannot
show a partner two different policies.

**The version footer — answered: go with the design.** It becomes **`Smile ID Sample App · 1.0.0`**.
`SettingsDestinations.kt`'s `APP_DISPLAY_NAME` and `spec/screens.json` → `copy.footer` both change.

Worth one line in the spec so nobody "fixes" it later: this **does not** change
`spec/app-identity.json`, whose display-name family `UseSmileID Sample` is the **launcher label and
store identity** and was settled against real constraints about ids the SDK repos reserve. The footer
is brand copy; the launcher label is identity. They are allowed to differ, and after this change they
do. `sample-ui` already takes `versionLabel` as a parameter precisely because it names the host and the
module runs under eight of them, so each host keeps passing its own.

**Sign out — answered 2026-08-24: confirmed as proposed.** It clears the local session and the saved
form details, then returns to Products. Real, reversible, and it matches the word — which is the bar a
designed row on a shipped screen has to clear.

### 6.9 Enhanced SmartSelfie™ — the rename renames a four-platform test id

`sample_setting_smile_to_capture` becomes `sample_setting_enhanced_smart_selfie`. Test ids are the
contract device flows key off, so this is a `spec/test-ids.json` change of the kind `AGENTS.md` names
explicitly. Bundled with it, because they are the same decision:

- `spec/components.json` — the `SettingRow` `decision` field and `settingsToSdkMapping` both carry the
  2026-08-13 owner decision that this design supersedes. Rewrite both, marked as superseded by node
  5206:2898 (2026-08-24), and correct the "cannot fight" rationale (§3).
- `spec/screens.json` — `settings.sections` reads `CAPTURE (two rows: Smile to capture, Agent mode)`.
- `spec/test-ids.json` — the id and its description.

**Polarity confirmed 2026-08-24 ("use Figma as truth")**: ON means `enableEnhancedLiveness = true`,
the head-turn challenge, and it is **ON by default** — for every product, not just enrollment, which is
the only one that gets it today. The spec edits above are the work; the decision is made.

### 6.10 Does the ™ go on every SmartSelfie, or only on the product name?

The partner docs mark every occurrence; the Settings frame marks `Enhanced SmartSelfie™`; the products
grid marks none, and that frame is already stale on two other counts.

**Partly answered by the products refresh (2026-08-24).** Node `5447:1701` puts **`SmartSelfie™` in
the card's *subtitle*** while the titles become `Registration` and `Auth` — so the mark attaches to the
product *family*, not to the job-type name. `products-visual-refresh-android.md` §7.4 carries the
label split that follows from it, and **PVR-A3 must land before ENV-A13**, or the mark is added to a
string that is about to stop existing. What remains open is the other surfaces — the verifications row
and the result card still render one full label.

**Resolved for the card by `products-visual-refresh-android.md` §7.4:** the short titles
(`Registration`, `Auth`) are overflow-driven display labels, the full `label` is untouched, and the
mark lives in the new **`cardFamily`** field. So ENV-A13's constant feeds `cardFamily` and the Settings
row, and `spec/scenarios.json`'s `label` keeps the SDK's job-type name in full — the 2026-08-13 ruling
stands.

**The other two surfaces — ruled 2026-08-24: no mark.** The rule, which is what the ports should
inherit rather than the individual verdicts:

> **The mark goes where the product is presented, not where it is recorded.**

So `SmartSelfie™` appears on the products card (`cardFamily`) and on the Settings row
(`Enhanced SmartSelfie™`), and **not** on the verifications row or the result card. Three reasons, in
the order they decide it:

1. **The result card is an assertion surface, not copy.** `AGENTS.md` makes it the evidence channel
   device flows read, and `spec/result-card.schema.json` defines its fields as data. Putting a
   trademark glyph into a value a flow does `assertVisible` on adds brittleness for something that
   carries no information there.
2. **Screen readers announce it.** On the products grid that is two occurrences. On a verifications
   list it is once per row — the seeded fixture set alone is eleven. A mark repeated down a list is
   noise in exactly the channel that can least afford it.
3. **Trademark practice is first or most prominent use, not every use.** Marking the presentation
   surface asserts the claim; marking the log of what already ran adds nothing to it.

`UseSmileIDSampleMarks.SMART_SELFIE` stays the single owner either way, so if the ruling is ever
revisited it is one edit rather than eight. And the partner docs marking every occurrence is not in
tension with this — prose has no assertion surface and no per-row repetition.

Two consequences that belong in the ruling rather than in the implementation: screen readers announce
the mark aloud on every card, so the accessibility label must drop it; and a device flow asserts the
literal text `"SmartSelfie Enrollment"` today, so those assertions move onto ids.

### 6.11 Third-party notices — **in-app, generated**, which reverses my earlier recommendation

**Owner ruling 2026-08-24: do what world-class companies do.** That changes the answer I gave, and the
reason is worth stating because it is not a taste call.

Major apps ship their attribution list **inside the binary**, not as a link: iOS puts it under
Settings → Legal → Acknowledgements, Android apps ship a generated licences screen. They do that
because **Apache-2.0 §4 requires the notice to travel with the distribution** — a URL pointing at a
web page is a weaker discharge of that obligation than shipping the text. Since the SDK's dependency
set is overwhelmingly Apache-2.0 (§below), a link-only answer was the wrong recommendation. Withdrawn.

**The shape, which keeps the docs page as well:**

1. **In-app, primary.** A generated `licenses.json` in `sample-ui`'s assets, rendered by a plain screen
   built from components this app already has — `UseSmileIDSampleSectionSurface`,
   `UseSmileIDSampleSettingRow`, `UseSmileIDSampleTopAppBar`. Row → full licence text.
2. **`docs-v3`, secondary.** The *same* generated file renders the partner-facing page at
   `docs.usesmileid.com`. Partners have to produce this list for their own store listing, so giving
   them a readable copy is a real deliverable — it just is not the thing that discharges the
   obligation.

**No new dependency, deliberately.** The two off-the-shelf options both cost more than they give here:
Google's `oss-licenses-plugin` pulls `play-services-oss-licenses`, and this repo cares about GMS-free
devices; `AboutLibraries` adds a runtime dependency and its own UI, which would be the one screen in
the app not built from the design system. A build-time generator emitting JSON has neither problem and
keeps `AGENTS.md`'s registry-only, ask-before-adding rules intact. **Ask-first item: confirm the
generator is the shape you want before it is written**, since a licences screen is also a new screen
and `spec/screens.json` has none.

**One accuracy point, and it is not a legal question.** The scope is exactly what you said — list the
open-source licences the app carries. The wrinkle is only that **five resolved artifacts are not open
source**; they declare Google's own terms rather than a licence:

| Artifact | Declared licence |
|---|---|
| `com.google.android.play:integrity` | Play Integrity API Terms of Service |
| `play-services-mlkit-face-detection` | ML Kit Terms of Service |
| `com.google.mlkit:object-detection` | ML Kit Terms of Service |
| `com.google.mlkit:barcode-scanning` (this app's own QR dependency) | ML Kit Terms of Service |
| `play-services-camera-low-light-boost` | Android Software Development Kit License |

So a page headed "Open-source licenses" cannot simply list them alongside Apache-2.0 entries. No
editorial wording is needed to fix that — just a second heading. Keep the design's row label, and give
the destination two sections: *Open-source components*, each with its licence text, and *Google
services*, each with its declared terms name and a link. The generator already knows which is which,
because it reads the declaration; nothing has to be written by hand and nothing needs sign-off.

**Generator rules, each one earned from a real artifact in this graph:**

- **Walk parent POMs.** Guava's own POM declares no licence; `guava-parent` declares Apache-2.0.
- **Keep a reviewed override table.** Bouncy Castle declares nothing in any POM — it ships the Bouncy
  Castle Licence inside the jar (`org/bouncycastle/LICENSE.class`).
- **Allow more than one licence per artifact.** `androidx.camera:camera-core` declares Apache-2.0
  **and** BSD-3-Clause.
- **Fail the build on an unrecognised artifact.** Never emit "Unknown" — an unknown that reaches a
  partner is worse than a red build.

**The list as it resolves today**, which is the first fixture:

- **Apache-2.0** — AndroidX (`annotation`, `core-ktx`, `exifinterface`, `activity-compose`, Compose
  `ui` / `material3` / `animation-graphics` / `ui-text-google-fonts`, `lifecycle-viewmodel-compose`,
  `lifecycle-runtime-compose`, CameraX `core` / `compose` / `lifecycle` / `camera2` / `view`,
  `datastore-preferences`, `room-runtime`, `navigation-compose`); Kotlin and kotlinx (`kotlin-stdlib`,
  `kotlinx-serialization-json`, `kotlinx-coroutines-core` / `-guava` / `-play-services`,
  `kotlinx-collections-immutable`); Square (`okhttp`, `logging-interceptor`, `retrofit`,
  `converter-scalars`, `converter-kotlinx-serialization`); Google (`dagger`, `guava` — via parent);
  `com.jakewharton.timber:timber`; `com.airbnb.android:lottie-compose`; `io.coil-kt:coil-compose`;
  `io.github.raamcosta.compose-destinations:core`
- **Apache-2.0 + BSD-3-Clause** — `androidx.camera:camera-core`
- **MIT** — `io.sentry:sentry`, `io.sentry:sentry-android-timber`
- **Bouncy Castle Licence** (MIT-style, in the jar) — `org.bouncycastle:bcprov-jdk18on`
- **Not open source** — the five Google artifacts above

**Scope note for the PR:** this is the *SDK's* transitive set plus the sample's own, because that is
what a partner ships. "The sample app's direct dependencies" would be short, tidy and useless.

**Withdrawn:** I earlier asked who signs off the legal wording. There is no wording to sign off — the
list is mechanical and the second heading is a fact the POMs state. The only ask-first item left here
is the **new screen** (§ENV-A14), because `spec/screens.json` and `spec/routes.json` gain an entry.

### 6.12 The scenario drawer — **the question, restated plainly**

*What the drawer is:* the debug sheet that lets a human pick a flow scenario (`normal`,
`expiredToken`, `offlineRetry`, …) and a theme scenario, so the SDK can be driven into each state by
hand instead of only by launch argument. `AGENTS.md` requires it to ship in the app — it is a probe
affordance, not test scaffolding — and `spec/test-ids.json` already gives it ids.

*Why it is open:* **the design set has no frame for it.** So nobody has said how it should be
presented, or what opens it. It is the only question in the entire `spec/` still marked `OPEN`.

*Where things stand:* the app shipped an answer anyway — a **"Scenarios" row in a DEBUG section at the
bottom of Settings** — with a code comment saying *"The design draws no control for the drawer, so this
placement is ours."* The Settings frame read on 2026-08-24 has no DEBUG section, so the app and the
design still disagree. The spec's own recorded recommendation was *a long-press on the environment
chip*, which is no longer available since the chip is now hidden (§6.5).

**The question: what opens the scenario drawer?**

| Option | Note |
|---|---|
| **Keep the Settings DEBUG row** *(recommended)* | Already built, already has its test id, discoverable, works on a release build. Costs one section the design does not draw |
| A long-press somewhere on Products | The original recommendation; its target no longer exists, and a hidden gesture is undiscoverable to a partner reading the app |
| A deep link only (`usesmileid-sample-android://debug/scenarios`) | Already works and is what the device flows use. But then no human can reach it on a device |

**Recommendation: bless the Settings row**, and record it in `spec/screens.json` as a deliberate
addition — the same way the ENVIRONMENT section was recorded as *"not in the design"* before it was
deleted. That closes the last open question in the spec at the cost of one line.


### 6.13 Debug-only probe surfaces — **ruled, and it collides with a Golden Rule**

**Owner ruling 2026-08-24: the Settings DEBUG section (Scenarios) and the verification-details result
card are visible on debug builds only.** Half of that is free. The other half breaks the release device
suite, so it needs one addition rather than a straight `if (BuildConfig.DEBUG)`.

**The Scenarios row: free, do it as ruled.** Device flows never tap it — they reach the drawer by deep
link (`usesmileid-sample-android://debug/scenarios`, used in `launch-args.yaml`). So hiding the row on
release costs nothing testable, and it also closes §6.12: the row is blessed *and* it stops being
something a partner sees.

**The result card: the same treatment would blind the release lane.** `AGENTS.md` is explicit in two
places that pull against this —

> **Probe affordances are product features here.** The scenario drawer, the on-screen result card and
> the callback counters are how both a human and an automated flow observe what the SDK did. They stay
> in the shipped app; they are honest debug surfaces, not test-only scaffolding.

> **Release builds are first-class.** … Debug-only verification proves very little.

and the numbers back it: **four of the eight flows** — `launch-args`, `deep-links`, `sdk-flow` and
`token-session` — carry **20 assertions** on `sample_result_*`. `verify.sh` documents running the suite
against the release APP_ID as well as debug. Compiling the card out of release means those four flows
can only ever run on debug, on the exact build configuration `AGENTS.md` says proves the least.

**Approved 2026-08-24: reveal it on release behind a launch argument.** Keep the card out of a
partner's way, but let automation ask for it. `spec/launch-args.json` already does exactly this for
`seedJobs`, whose own description reads *"Present in release builds too, deliberately: the device suite
has to pass on the minified, resource-shrunk variant as well as debug, and that run needs the same
precondition."* Same reasoning, same mechanism.

- **Debug build:** card always shown, as today. No argument needed.
- **Release build:** hidden by default; shown when `probes` is passed.
- **Device suite:** the release run passes `probes`, so all eight flows keep working on both variants
  and nothing is scoped down.

Both Golden Rules survive intact: the affordance still ships in the release binary — minified, shrunk
and on the release classpath, which is where consumption defects surface — and a partner opening the
app never sees it.

### 6.14 `probes` — the new launch argument, **approved**

Follows from §6.13 and lands in `spec/launch-args.json`, so the three sibling platforms inherit it.
Proposed entry, written in that file's own register:

```json
{
  "name": "probes",
  "type": "boolean",
  "values": [true, false],
  "default": false,
  "description": "Reveals the on-screen probe affordances — the result card and its callback counters — on a release build. Always on in debug, so the argument is only ever needed by a release run. It exists because the affordances are how a flow observes what the SDK did, and the release variant is the one where consumption defects surface: hiding them from release outright would mean half the device suite could only run on the configuration that proves the least. A partner opening the app sees nothing; the code still ships, minified and shrunk, on the release classpath."
}
```

**The callback counters travel with the card.** `AGENTS.md` names them in the same breath and they are
rendered by the same component, so one flag governs both — splitting them would create a state where a
run can count callbacks but not read the outcome they belong to.

**What it is not.** `probes` does not reveal the Settings DEBUG section: that stays strictly
`BuildConfig.DEBUG`, because no flow needs it (they deep-link to the drawer) and a partner should never
find a scenario picker in Settings on any build.


### 6.15 No pre-submission environment indicator — **closed: the Portal owns that**

Raised by a security pass over the two plans together, 2026-08-24, and **closed the same day** by a
fact the pass did not have. Recorded rather than deleted so it is not re-raised by the next review or
by a port.

**What was raised.** Three approved rulings compose: §6.4 makes production reachable by scanning a
production token, §6.3 deletes the `sandbox` launch argument, and ENV-A3 removes the Settings row and
stops rendering the chip. Verified against the code, `UseSmileIDSampleEnvironment` has exactly two
user-facing consumers — `ProductsScreen`'s chip and `SettingsScreen`'s row — and both go, leaving
`sample_result_environment` on the verification-details screen as the only surface, which is read
*after* a job is submitted.

**Why it is not a problem.** **The Portal's own minting flow distinguishes sandbox from production
with clear UX**, and that is where the choice is actually made. The person scanning is the person who
just minted, and they chose the environment deliberately, upstream, on a screen built to make that
choice obvious. The app is not the first thing to tell them — it is the second. An in-app warning
before a run would restate a decision the operator made moments earlier, which is noise rather than
safety.

**What still carries the app's share of it**, and both stay: `sample_result_environment` on the result
card records where the job actually went, which is a different job from warning beforehand — proving
after the fact is what makes a run auditable. And the session card's handle and countdown bound how
long a linked token can sit unremembered, since the Portal's longest span is 8h.

**No work, and nothing owed.** ENV-A5 was already in the plan and is unchanged; ENV-A3 proceeds as
written.


---

## 7. Blast radius, file by file

Traced, not estimated. `spec/` first because it is the ask-first surface.

**`spec/` (5 files)** — `launch-args.json`, `screens.json`, `components.json`, `test-ids.json`,
`result-card.schema.json`. Covered in ENV-A4.

**Android — `app`**

| File | Why |
|---|---|
| `UseSmileIDSampleAppState.kt` | `useSandbox`, `environmentPinned`, `environment` |
| `flow/FlowLaunchSnapshot.kt` | environment source; five new settings fields |
| `flow/FlowBuilderConfig.kt` | `useSandbox`; `selfie { }`; `journeyFor`'s three step toggles (no `consentInformation` — §6.6) |
| `navigation/SettingsDestinations.kt` | drops the environment fields; wires `onNavRowClick` and `onSignOut` |
| `navigation/TokenDestinations.kt` | the resume gate, per §6.2 |
| `status/UseSmileIDSampleStatusApi.kt` | already holds both host strings — the natural home for the map, so it exists once |
| `UseSmileIDSampleActivity.kt` | `appLocale`, if ENV-A11 rides along |

**Android — `sample-ui`**

| File | Why |
|---|---|
| `state/UseSmileIDSampleSettings.kt` | `production` and `useSandbox` deleted; the agent-mode mutex added |
| `data/UseSmileIDSampleStore.kt` | `PRODUCTION` key and its `key()` branch |
| `state/UseSmileIDSampleTokenSession.kt` / `UseSmileIDSampleTokenDecoder.kt` | the `api_url` claim and the field |
| `screens/SettingsScreen.kt` | the `ENVIRONMENT` section; the mutex and overridden-consent supporting lines |
| `screens/ProductsScreen.kt` | stops rendering the env chip; the component file itself is **unchanged** (§6.5) |
| `UseSmileIDSampleFlowTokens.kt` | fixture tokens gain `api_url`; Simulate mints either host (§6.3) |
| `UseSmileIDSampleTestIds.kt` | `SETTING_PRODUCTION` out, `SETTING_SMILE_TO_CAPTURE` renamed, `ENV_CHIP` per §6.5, `RESULT_ENVIRONMENT` in |
| `model/UseSmileIDSampleProduct.kt` | product labels composed from the mark (ENV-A13) |
| `UseSmileIDSampleMarks.kt` | new — the one owner of `SmartSelfie\u2122` |
| `screens/PlaceholderScreen.kt` | **deleted** — `internal`, zero references |

**Tests and flows** — `android/maestro/launch-args.yaml` (two blocks), `deep-links.yaml` (the literal
`"SmartSelfie Enrollment"` assertion, per ENV-A13), the twelve goldens in §ENV-A3,
`ScreenGoldenTest` / `ScreenCompositeGoldenTest` fixtures, `UseSmileIDSampleTestIdsSpecTest`,
`UseSmileIDSampleLaunchArgsSpecTest`, `UseSmileIDSampleResultSpecTest`,
`UseSmileIDSampleTokenDecoderTest`, `SdkFlowPreflightTest`.

**Outside the Android tree** — `docs-v3` gains the third-party notices page (ENV-A14), which is its own
PR in that repo and the one piece of this plan that does not land here.

`grep` confirms nothing else reads `settings.production`, `useSandbox`, `sample_env_chip` or
`sample_setting_production`, and that `PlaceholderScreen` has no caller in `main`, `test` or the
gallery.

---

## 8. Testing

`android/verify.sh` is the definition of done: tokens, lint, `test`, `verifyRoborazziDebug`,
`assembleRelease`. It needs no change — a new test source file is picked up by `./gradlew test`.

- **Unit, in `sample-ui`.** `api_url` decode: each known host, case and trailing-slash variants, a
  scheme-only difference, an unrecognised host, a malformed URL, and the claim absent — each asserting
  the §6.1 behaviour rather than "does not crash". The agent-mode mutex, driven from
  `UseSmileIDSampleSettings` so both orders of flipping are covered. ~~The DataStore migration.~~
  Dropped with the migration itself (§ENV-A7): there is nothing left to test but that the new key
  reads its default, which the settings tests already assert.
- **Unit, in `app`.** `buildSnapshot` resolves environment from the session, and from the launch
  argument per §6.3. `journeyFor` composes exactly the screens the four toggle combinations imply, and
  the consent triple of §ENV-A8 — the third row (token-bound) is the regression guard for behaviour
  that already exists and is currently untested.
- **Preflight — and this bullet was wrong, corrected 2026-08-25 against 12.0.2.** Every settings
  combination the UI can persist must still reach the SDK as `Ready`, which is testable and tested.
  What is **not** possible is the second half: no host can pre-flight the composed flow.
  `UseSmileIDFlowBuilder.validate()` is `FlowValidator.validateBuilder(screens, mlConfigResult,
  networkConfigResult)` — ML/network configuration failure and an empty `screens` block, nothing else.
  Both rules this plan leans on, `validateSelfie()` (the agent-mode/enhanced-liveness pair) and
  `appendConsentRule`, run inside `FlowValidator.validate(configuration, …)`, which only the SDK's
  `internal fun build()` calls; `FlowConfiguration` is public but its `screens` can come from nowhere
  but the builder's private list. So the pair cannot be asserted as a named `Misconfigured`, and that
  test is deliberately not written. **What guards it instead:** the mutex is unit-tested in
  `UseSmileIDSampleSettings`, both tap orders and all four combinations, and the SDK's own refusal is
  proved on a device — `build()` returns `Invalid`, the SDK calls
  `onResult(Failure(BuilderValidationException))`, and the message lands on
  `sample_result_last_error`. Uniform on both variants, because that path forks on the builder's
  `enableDebugMode`, which defaults false and this app never sets. Ruled 2026-08-25: record it here,
  prove it on the card, file nothing against the SDK.
- **Two behaviours the plan specifies with no test named, both cheap to add.** The five ABOUT/LEGAL
  URLs (ENV-A9) should be asserted against `spec/screens.json` in a unit test rather than eyeballed —
  a wrong URL is invisible until a partner taps it. And the `cardTitle` / `cardFamily` pair
  (`products-visual-refresh-android.md` PVR-A3) needs `UseSmileIDSampleSpecTest` extended, or four
  platforms can abbreviate a product name differently with nothing failing.
- **Spec tests.** The existing three run unchanged and catch the id and launch-argument edits.
  `UseSmileIDSampleTestIdsSpecTest` asserts one way only — app ⊆ spec — so removing an id from the app
  without removing it from the spec passes. Say so in the PR; do not add a two-way assertion here,
  which would fail on every id the other three platforms have not implemented yet.
- **Goldens.** The twelve in §ENV-A3. `profile_env_chip` and its max-font-scale predicate are
  **unaffected** — the component still exists and still renders both variants; only Products stops
  showing it. A re-recorded golden must be **looked at**, not just regenerated: the whole value of the
  products re-records is noticing whether a header that has lost its chip still balances against the
  avatar button beside it.
- **Device, Maestro, on `si_*` and `sample_*` ids only.** `launch-args.yaml` per ENV-A6. A new
  `settings.yaml` (or an extension of `shell-navigation.yaml`) driving each switch and proving it
  reached the SDK — the step switches are provable without a capture, because a run that reaches
  `si_instructions_screen` versus one that skips straight past it is an id assertion, and the
  consent-screen presence assertions already exist in `sdk-flow.yaml`. Assert environment on
  `sample_result_environment`, never on the chip, so the flow survives §6.5 either way.
- **What cannot be tested here.** Nothing proves a *production* submission from this repo, and
  nothing should — `AGENTS.md` forbids production credentials. The production leg of the mapping is
  covered by a decode test and by the card reporting `production`; a real production run is somebody's
  manual check with their own token, recorded in the PR, not a lane.
- **The capture-setting flip needs a device, not a unit test.** Enhanced SmartSelfie™ defaulting ON
  changes what five of the six products actually do on camera. Prove on a device that a default run
  reaches the head-turn challenge and that turning it off reaches passive capture — a builder
  assertion proves the field was set, not that the SDK did the other thing.
- **The mutex, driven from the UI.** Tap Agent mode from the default state and assert Enhanced
  SmartSelfie™ went OFF, then the reverse. This is the one test that stops the app shipping a
  one-tap blocked run.
- **The rename, on a real device with real prior state.** Install the current build, set Smile to
  capture, install the new build over it (`adb install -r`, never a fresh install — a fresh install
  proves nothing because `allowBackup="false"` wipes the store), and assert Enhanced SmartSelfie™ is
  ON while a key the rename does not touch, like Dark mode, keeps its value. **Run 2026-08-25 and it
  passes**, which is what makes the migration unnecessary rather than merely unimportant: the old
  value is not read under the new name whether or not anything deletes it.
- **The notices generator has a test, and it is the failure path.** Feed it Guava (licence only in the
  parent POM), Bouncy Castle (licence in no POM at all) and `camera-core` (two licences) and assert it
  resolves the first, uses the override for the second, keeps both for the third — and **fails** on a
  fabricated artifact with no metadata and no override, rather than emitting "Unknown".
- **Release lane.** `assembleRelease` is in `verify.sh`, and the device suite must be run on the
  minified variant too. Two of these items are the shape that only fails minified — a DataStore
  migration lambda and a URL parse — so a debug-only pass proves less than usual here.

---

## 9. What the other three inherit

**The contract, identical everywhere.** The token's `api_url` decides the environment; the map is
host-based against the SDK's two hosts; an unrecognised host takes §6.1's behaviour; there is no user
control for environment; and the SDK is still handed a boolean, because
`partnerConfig { useSandbox }` is the whole surface on every platform. A port that keeps an
environment toggle, or that maps by whole-string comparison, has diverged. The mapping deserves the
same treatment §9 of `token-session-android.md` gave the decode rules: **the same fixture hosts,
tested on all four**, so a platform cannot quietly disagree about what "production" means.

**The rulings travel with it — all answered, so the ports inherit decisions rather than questions.**
§6.1 through §6.4 and §6.6 are cross-platform contract, not Android
choices — the resume-across-environments rule, whether the launch argument overrides, and what
`consentStep = false` puts on the wire must be answered once. `spec/launch-args.json`,
`spec/test-ids.json` and `spec/result-card.schema.json` carry them; the ports read the spec, not this
document.

**`probes` is a four-platform contract, not an Android convenience.** Every port hides the result card
on its release build and reveals it under the same argument name, and every port's release device run
passes it. A platform that ships the card unconditionally on release leaks a debug surface to partners;
one that compiles it out cannot run half its suite on the configuration that matters. Both failures are
silent, which is why the rule belongs in `spec/launch-args.json` rather than in four heads. The
Scenarios row is simpler and also shared: strictly debug-only everywhere, no argument.

**Per-platform, and fine to differ — but the presentation is not.** Ruled 2026-08-25: the four
external Settings rows open **in-app** on every platform, and the mechanism is each platform's own —
Custom Tabs on Android (`androidx.browser`, the one dependency this phase added), `SFSafariViewController`
on iOS, `url_launcher`'s `inAppBrowserView` on Flutter, `expo-web-browser` on React Native. Not a
WebView on any of them: the page keeps the user's session, autofill and password manager, and this is
code partners copy. Also per-platform: how the locale override is applied. The *effect* must match: no UI can
restore a retired setting. There is no one-time clear to express — see §ENV-A7.

**Three things to fix in the spec before the ports read it.**

1. ~~`spec/test-ids.json` tells all four platforms that Smile to capture and Agent mode "cannot
   fight".~~ **Done in PR #27**: the description now records that they *can* fight, with the SDK's
   error code and the date it was read. The id itself still says `smile_to_capture` — renaming it is
   ENV-A7's, in phase two.
2. ~~`spec/components.json` still carries the superseded 2026-08-13 polarity in two places.~~
   **Done 2026-08-25**: both the `SettingRow` `decision` field and `settingsToSdkMapping` are
   rewritten, each saying it was superseded by node 5206:2898 rather than being silently replaced, and
   the test id is renamed to `sample_setting_enhanced_smart_selfie`.
3. ~~`spec/screens.json` records the legacy documentation domain and a footer string that contradicts
   `spec/app-identity.json`.~~ **Done 2026-08-25**: the footer is the design's
   `Smile ID Sample App · 1.0.0`, `copy.aboutDocs` and the row's URL are `docs.usesmileid.com`, and
   both decisions carry the evidence that superseded them. `spec/app-identity.json` is deliberately
   unchanged — the launcher label and the footer are allowed to differ, and the spec now says so.

**What the ports get for free, and must not re-derive.** The mark is one constant, not eight string
literals (ENV-A13) — the ruling in §6.10 travels with it, and so does the accessibility rule that the
spoken label drops the mark. The third-party notices are **generated once and rendered twice**
(ENV-A14): one `licenses.json`, produced by the build from the release runtime classpath, rendering
both the in-app screen and the `docs-v3` page. Corrected 2026-08-25 — this paragraph previously said
each port would just link one shared URL, which was the recommendation §6.11 reversed: Apache-2.0 §4
asks the notice to travel with the distribution, so every port ships the screen and the generator, and
each port's list is its own because each resolves its own classpath. And §4.1's ledger is the
completeness contract: a port is done when its own ledger has the same shape, not when its screens
look right.

---

## 10. Folded in, and deliberately excluded

**Folded in.** `appLocale` (ENV-A11) — same write-only shape as the five switches, and the two files
it needs are already open. Cut it first if the PR grows. And `PlaceholderScreen.kt`, deleted under
ENV-A15: it is `internal` with zero references, so deleting it is a one-line diff that stops a port
mirroring a file the tree does not use.

**Excluded, with reasons.**

- **Android has no launcher icon.** Confirmed: no `android:icon` in the manifest and no `mipmap`
  directory, so the launcher shows the system default. Real, but it is app-identity and branding work
  belonging with `spec/app-identity.json` and a design asset — nothing to do with environment or with
  Settings. Own PR.
- **`sample-ui` has no `resourcePrefix`.** The convention is already followed by hand
  (`sample_ic_*`), and the library merges into eight application identities where an unprefixed
  collision would silently resolve to the host's resource. Worth adding — and adding it fails the
  build for any resource that does not conform, which is a risk with no business inside an
  environment PR. Own PR, and run `./gradlew :sample-ui:assembleDebug` with the prefix set before
  committing to it.
- **Pull-to-refresh on the verifications list (`sample-apps-plan.md` §8.1).** §8.1 deferred it until
  "the first real API call", and that has landed — `GET /v3/status/{jobId}` through
  `RetrofitJobStatusSource`. **Its trigger has fired and it is still not ready, for a new reason:**
  `UseSmileIDSampleJobStore.refresh` returns `SessionMismatch` for any row not submitted under the
  *current* session, so a list-wide pull would refresh only the current session's rows and return a
  mismatch for the rest — a gesture that visibly does nothing for most of the list. That is a better
  argument for deferring than the original one, and it should be written into §8.1 so the next reader
  does not "unblock" it on the strength of the API call existing. The shape it needs first: whether a
  refresh spans sessions at all, which is a token question, not a list question.

**Localisation and RTL flows — noted now, built after the ports.** Owner instruction 2026-08-24:
mirror what the SDK repos' samples do. Read against `android/sample`, that means shipping `values-fr`
and `values-ar` alongside `values`, with `android:supportsRtl="true"` — which this app **already has**
(`AndroidManifest.xml:20`).

**The prerequisite is bigger than the translations, which is the real reason to defer.** `sample-ui`
has **no `strings.xml` at all** — every user-facing string is a Kotlin literal, and there are dozens
(21 from `text = "…"` in the screens alone, before the components and the parameters). So the work is:
extract every string to resources, *then* translate, *then* test. Extraction alone touches nearly every
file in `sample-ui` and would collide with all sixteen items above.

Two things to get right when it happens, both cheap now and expensive later:

- **`appLocale` is the mechanism, not the device locale.** `spec/launch-args.json` already says why —
  *"changing the device locale is not reliably scriptable on every OEM"* — which is also the argument
  for keeping ENV-A11 rather than cutting it. The SDK sample has no programmatic switch and relies on
  the device; this app should be better, and the spec already says so.
- **RTL is a structural predicate, not a golden.** Arabic goldens need Arabic copy review to mean
  anything; what is checkable without a design reference is that nothing clips, mirrors wrongly or
  loses its chevron direction — the same family as the existing max-font-scale and contrast predicates.
  String extraction is also the moment `sample-ui`'s missing `resourcePrefix` is worth adding, since
  that library merges into eight application identities.

Sequenced after the ports, as instructed. Recorded here rather than in a tracker so the ports know it
is coming and do not hard-code their own strings in the meantime.

**The sheet scrim (§8.2) — ruled 2026-08-24: Material 3 practice.** Checked against the Compose
Destinations v2 docs as instructed, and the two halves of the instruction pull apart, so here is what
the check found:

- **Destinations v2 *can* fix it.** Its `bottom-sheet` artifact wraps the whole `DestinationsNavHost`
  in a `ModalBottomSheetLayout`, so the current destination **stays composed underneath** and the sheet
  is a layer over it — exactly the overlay shape F50 needs, with the sheet still a route.
- **But it costs Material 2.** `io.github.raamcosta.compose-destinations:bottom-sheet:2.3.0` depends on
  `androidx.compose.material:material-navigation:1.9.3`. There is no M3 variant — the published
  artifacts are `core`, `ksp`, `codegen`, `animations-core`, `bottom-sheet`, `wear-core`. Adopting it
  ships two Material libraries in one app and themes the sheets from M2's `MaterialTheme` rather than
  the app's M3 one. `navigation-hardening-android.md` NAV-A6 rejected it on those grounds already.

**So take the M3 practice: `androidx.compose.material3.ModalBottomSheet`, owned by the screen beneath
it.** The screen stays composed by construction, so the scrim covers the right thing, and it needs
**no new dependency** — `material3` is already here.

**The one cost, and how to pay it.** M3's pattern gives up sheet-as-route, and `spec/routes.json`
declares five sheet routes with deep links. Keep the contract by making each sheet route resolve to
*its parent screen with the sheet open* — `/profiles/switch` navigates to Products with the switch
sheet showing — rather than to a destination of its own. The five spec paths keep working, the deep
links keep working, and the sheet becomes state on the screen that owns it. NAV-A5's revisit trigger
does not fire: the sheets still commit to the shared stores, so nothing moves into screen-local state.

The rule belongs in `navigation-plan.md` so the ports read a rule rather than a recommendation, and
iOS, Flutter and React Native already present sheets over the current screen — they should be checked,
not changed.

**Two things this plan does not touch, on purpose.** The result card's `sdkVersion` renders an em dash
by design — `spec/result-card.schema.json` carries the `blocked` note and instructs leaving it null,
verified against 12.0.1 and 12.0.2. And the scan screen's reticle is decorative while the analyser
reads the whole frame; that mismatch with its "line up the code inside the frame" caption is a known
open design question (`token-session-android.md` §8), not a bug to close here.

---

## 11. Landing order

**Owner-set sequence 2026-08-24: token/environment first, then Settings, then the visual refresh.**
`products-visual-refresh-android.md` is therefore the last of the three, not interleaved.

**PR 1 — the environment chain. Shipped: PR #27, merged 2026-08-25.** ENV-A12 first as its own commit
(one paragraph, no code: a superseded fact in `docs/` outranks the code that contradicts it). Then
**ENV-A1 → A2 → A3 → A4 → A5 → A6 as one PR** — they are one behaviour change, and splitting them
leaves `main` with a spec and an app that disagree, or a device suite asserting on a chip that has
gone. Two places where this plan was wrong turned up in the building of it, both recorded where they
were wrong rather than only here: §7 put a helper in a module that could not host it, and ENV-A1's own
snippet specified a nullable session field that §6.1's later ruling made unsafe.

**PR 2 — Settings, and it is one PR, not several. Owner ruling 2026-08-25:** the whole of Settings
lands as a single PR that closes it. The dependency order below is still the order to *build* in — it
just no longer means separate reviews. One PR also means `screen_settings` is re-recorded once at the
end instead of four times, and the spec lands as one coherent contract change instead of four partial
ones.

Build order inside it: ENV-A7 and ENV-A8 first (the capture and step switches, the design rename). Then ENV-A9 with ENV-A16, since both touch the Settings screen and the details
screen once each. Then ENV-A14. ENV-A11 rides along, and is the first thing to cut if the PR grows —
said in the PR, not dropped in silence. ENV-A15 last, as the gate rather than the work — re-walk §4.1
and merge only when every row is either empty or carries a dated decision. The device pass comes after
all of it, once, rather than interleaved: half these items change the same screen and the same flows,
so an early run only has to be redone.

**Done 2026-08-25.** Settings is closed. What landed that this section did not predict: the journey
became a named step list so the composition could be asserted at all (the SDK exposes no built screen
list), `probes` had to be readable off a deep link's query as well as an intent extra (a VIEW intent
carries no extras, and four flows reach the card that way), and the notices generator excludes both
first-party artifacts and BOMs — a partner licenses the SDK from us, and a BOM ships no code.

**PR 3 onward — the visual refresh.** All of `products-visual-refresh-android.md`, in its own §10
order. PVR-A3 still has to precede ENV-A13, so **ENV-A13 moves into this phase** rather than shipping
with the Settings work: the mark lands in `cardFamily`, which PVR-A3 creates.

One PR per repo, single conventional-commit subject lines, no changelog. Every PR: `android/verify.sh`
green or an explicit list of what could not be run, and any claim about environment verified through
`sample_result_environment` on a device — the card is the evidence channel precisely because a screen
that *looks* like sandbox proves nothing about where the job went.
