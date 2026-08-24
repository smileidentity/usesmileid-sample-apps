# Token session — Android, from a scanned QR to a submitted job

**Status:** TOK-A1–A6 and TOK-A9 built on Android — manual entry, Simulate minting, decode, session
model, builder handoff, honest countdown, and the CameraX QR scanner with the bundled ML Kit barcode
model. Both host forms are now skipped when the token already carries what they would collect (§4.2). A9 was planned as its own PR and folded into the same one on the owner's call (2026-08-19), so
the token flow lands complete rather than scannerless. TOK-A7 (Room) is built: jobs persist, carrying the
profile that submitted them and the environment they went to, and the verification-details screen
fetches `GET /v3/status/{jobId}` under a live scanned session. **TOK-A11 and the `holdCamera` consumer
are built (2026-08-24)**, which closes the item list; TOK-A11 was added the same day after a
device run mistook the expiry redirect for a glitch — the gate was right, but it said nothing and
resumed nothing (§TOK-A5). TOK-A8's goldens listed in §8 were already covered by the session card, the
ended banner, and the `nav_bar`/`TokenRings` ring pair, so what remains of A8 is its **device** pass,
not more goldens. The one deliberate scope call: `holdCamera` was to be a separate PR (§7.1) and was
folded in on the owner's instruction that the token work land as one review.

**Device pass 2026-08-24 (Oppo CPH2113, debug):** `token-session.yaml` green end to end, including the
expiry redirect stating its reason, a relink re-entering the interrupted run, and a deliberate scanner
visit explaining nothing. `holdCamera` verified on both lenses — front for SmartSelfie (85 frames in
4s), back for Document Verification (136 frames in 6s), each reporting its last frame tens of
milliseconds before release, so the hold demonstrably lasted rather than being evicted early. One real
finding, which **removed TOK-A10 rather than shipping it**: the ID-form prefill could only ever seed
`country` and `id_type`, and the host already skips the ID form whenever those two are present, so no
journey could reach it. Confirmed on the device, not inferred — Biometric KYC showed no ID form under
a details-binding token. The code and its tests are deleted; §2's "prefilling a name or an ID number
is impossible" was always the ceiling, and it turns out the reachable ceiling is lower still.

**Scan reliability, the last gate, closed the same day.** The dense Portal QR read poorly until the
analyser's resolution was pinned — §8 has the mechanism — and now reads at a comfortable distance.
That was the one item fixtures could never settle.

**Real Portal token, end to end, same day.** A scanned Portal QR ran Enhanced KYC to a real sandbox
submission: `200 OK` / "Job completed", exactly one result callback, no error. Three things only a
real token could confirm. The countdown read **`7:57:13`** on an 8h span, so TOK-A6's hours part is
right against a real `exp - iat` rather than a fixture's. **Both host forms were skipped**, so the
Portal's bindings are honoured in practice and not just in the decode tests — which is also the
regression check on this branch's refactor, since the two skip decisions now delegate to
`liveBindings`. And the verdict badge read **Blocked against a green 200**, which is the intended
split between "the request worked" and "the verification said no" (`RetrofitJobStatusSource` maps
`block`/`error`; the details screen documents the colouring). Enhanced KYC is what made this reachable
without frame injection — it is the one product with `capture = false`.

Android first; the token contract is shared, so §9 records what the other three inherit. Written against the Portal as merged (`portal#3274`, `portal#3274`'s follow-up
`portal#3306`) and the SDK as published (`com.usesmileid:usesmileid:12.0.2`), read rather than assumed.

Companion reading: `navigation-plan.md` §7.3 (the entry gate this extends) and R6 (why a session is an
absolute deadline), and `sample-apps-plan.md` §7 (where this sits against the ports).

**The one-line goal:** scan the QR the Portal mints, start a real flow under that token, show how long
it has left, and keep the resulting jobs after the process dies.

---

## 1. What exists today, verified

| Piece | State |
|---|---|
| `scanToken` route + `/token/scan` deep link | wired, in `spec/routes.json` |
| `ScanTokenScreen` | **a mock.** Static glyph and copy; no camera, no QR decode |
| `onSimulate` | writes a fake session — hard-coded id `9f3a`, `DEFAULT_DURATION` of 5 minutes |
| `onPaste` | `{}` — the manual-entry row exists in the sheet and does nothing |
| `UseSmileIDSampleTokenSession` | `id` + `expiresAtMillis`, an absolute deadline (R6 satisfied) |
| Countdown, ring, ended banner | built and asserted — `sample_session_card`, `sample_session_countdown`, `sample_token_float`, `sample_session_ended_banner` |
| Persistence | DataStore holds six settings and the session's `id` + `expiresAt`. Jobs and profiles are in memory |
| The flow's token | `applying()` mints a per-scenario fixture JWT. Nothing consumes a scanned token |

So the session **UI** is largely done and the session **substance** is absent: there is no token, and
nothing a token could feed.

---

## 2. What the Portal actually mints

`portal#3274` (merged 2026-07-23) added an admin-only "v3 QR" per API key on `/security-settings`:
`POST /api_key/:id/v3_token`, expiry allow-listed to **15m / 1h / 8h**, returned `Cache-Control:
no-store`. **The QR encodes the raw v3 JWT** — not a URL, not a JSON envelope. Its own known-issues
list flags that this payload is denser than the legacy sample-app QR and that scan reliability on a
real device is unconfirmed. That is our problem to close, not theirs (TOK-A9).

`portal#3306` (merged 2026-08-18) made the token carry optional **user details** (`given_names`,
`last_name`, `email`, `phone_number`, `id_number`, `country`, `id_type`) and an optional **consent**
object (`granted` fixed true, `granted_at`, `notice_language`, `notice_privacy_policy_url`). Three
properties of that claim decide most of this plan:

1. **The PII values are not readable.** Every PII field is swapped for an opaque vault token before
   signing; only `country` and `id_type` are plaintext. The app can learn *that* a field is bound and
   never *what* it is. Any design that prefills a name or an ID number from the token is impossible.
2. **Blank means absent.** A field left empty is omitted from the claim entirely, because an empty
   string is rejected downstream. Presence is therefore a real signal.
3. **Consent is all-or-nothing.** The object is optional, but a partial one is a validation failure
   rather than a partial relaxation.

### 2.1 What a real Portal token actually contains, read off two of them

Decoded from two tokens minted from the Portal and scanned on device (2026-08-19) — an 8h and a 1h —
with values withheld throughout. Both had **identical claim sets**:

| Where | Claims |
|---|---|
| top level | `aud`, `exp`, `iat`, `iss`, `key_id`, `nbf`, `partner_id`, `payload` |
| `payload` | `country`, `email`, `given_names`, `id_number`, `id_type`, `last_name`, `phone_number` |

Six things follow, each of which had been a guess until now:

1. **There is no environment claim.** Nothing named `env`, `is_sandbox`, `environment`, `mode`, or
   anything else matching an environment word; no claim *value* mentioning sandbox or production; no
   booleans anywhere. `aud` and `iss` are the constants `smileid-api` and `smileid-auth`, identical in
   both tokens, so they do not encode it either. The environment is implied by the API key that minted
   the token (`key_id`) and resolved server-side. **Owner decision 2026-08-19 was "the token wins and
   drives `useSandbox`" — which cannot be built until the Portal adds the claim.** Until then the
   active profile is the only source of environment, and a mismatch surfaces as an auth failure on the
   result card. **Portal ask: add an environment claim.** One decode rule and its tests land the moment
   it exists.
2. **No `jti`.** So TOK-A3's fallback is the normal path, not the exception: the session handle a
   partner sees is the short digest, and the `jti` branch is exercised by unit test only.
3. **`iat` is present**, which is what makes TOK-A6's `exp - iat` span honest. Requiring it was a real
   risk — a Portal that minted only `exp` would have had every token rejected — and it is now settled.
4. **`nbf` is present and equals `iat`.** The decoder ignores it, so a not-yet-valid token would link.
   Latent rather than broken; if it is ever checked it needs clock-skew leeway, because a strict
   comparison against a slow device clock rejects good tokens. **Owed decision.**
5. **Neither token binds consent.** So the §3 consent-drop defect is not reproducible from the Portal
   as it mints today — reproducing it needs consent bound server-side. The fixture path in
   `UseSmileIDSampleFlowTokens` remains the only way to exercise it.
6. **Both bind the required user details** (`given_names`, `last_name`, `email`), so
   `bindsRequiredUserDetails` is true for a real token and the host's details form is skipped in
   practice, not just in theory. They also bind `id_number`, `country` and `id_type` — which the SDK
   never relaxes — though the *host* skips its own ID form once all three are bound, which is why the
   prefill this once implied was removed on 2026-08-24 as unreachable.

Every PII value was exactly 30 characters across name, email and ID number, which is what opaque vault
references look like and confirms §2's "presence, never content" empirically.

## 3. What the SDK does with it

Read from `TokenPayload`, `FlowValidator`, `JobTypeValidator` and `FlowNavigationManager` at 12.0.2:

- The SDK decodes the token at `build()` and exposes **presence flags only** — `hasGivenNames`,
  `hasLastName`, `hasEmail`, `hasPhoneNumber` — plus `consent`, whose four subfields *are* readable.
- A token-bound user-detail field **relaxes** the matching `userDetails` requirement per field and is
  stripped from the `user_details` part; the server injects the real value.
- **A complete consent binding drops the consent screen at runtime** (`FlowNavigationManager`: the
  screen is removed from the flow the navigation runs). An *incomplete* binding is a build error that
  names the missing subfields. **This is what the source says and it is not what the device does —
  see the defect below.**
- **Offline mode skips decoding entirely**, so an offline run keeps the strict legacy rules and loses
  every relaxation above. That matters the moment we save jobs offline (§6).
- **ID params are not relaxed by the token.** `validateBiometricKYCParams` and friends take no token
  payload, so `country` / `idType` / `idNumber` must still be supplied locally even when the token
  binds them. `TokenPayload` does not even model `id_number`, `country` or `id_type`.

Three consequences worth stating plainly, because each one is a place a reasonable design goes wrong:

- The Consent Details Form cannot be skipped just because a token exists. It can be **relaxed**, and
  only for the four fields the SDK models.
- The ID-details form **can be skipped outright**, which is a correction to what this section said
  first. The reasoning that ruled it out was that `id_number` had no local value to supply — but the
  token carries one: the vault reference. The SDK's validators ask only that these three be non-blank,
  and the server overwrites all three from the token's own claims before the job is created, so passing
  the reference through is the honest value and not a placeholder. See §4.2.
- A token-bound run **has no consent screen**, so every device flow that asserts `si_consent_screen`
  is asserting the no-token path. Token-bound coverage starts at `si_instructions_screen` (TOK-A8).

**Verified against the published artifact, not the source (2026-08-19):** `FlowValidator` exposes
`validateUserDetails(userDetails, tokenPayload)` — a real per-field union — and `TokenPayload` has a
public constructor, so a host could hand the SDK its own decode and let the SDK do the deciding. **Not
at 12.0.2:** in `usesmileid-12.0.2.aar` `FlowValidator` is minified to `a.class` and `TokenPayload` is
absent from `com/usesmileid/data/model/`, so neither is reachable. That API is on the SDK's `main`, and
this is the trap this repo exists to catch — reading the sibling checkout is not reading what partners
consume. Until it ships, the union is mirrored host-side (§4.3) and `InvalidFieldValueException`, which
*is* public at 12.0.2, carries the issues so the messages still name fields the SDK's way.

**An SDK gap this leaves with the host:** because `TokenPayload` models none of `country`, `id_type` or
`id_number`, every relaxation for them is the host's to implement — the SDK will keep asking its
validators for values it could have read from the token it already decoded. Worth filing alongside the
accessor ask below: a `TokenPayload` that modelled these three would let the SDK relax them itself, and
every host would stop reimplementing this.

**A host bug this document previously blamed on the SDK — corrected 2026-08-20.** A token whose
`payload.consent` binding is complete made the flow deliver `UseSmileIDResult.Cancelled` immediately,
with no user action, and this was written up here as an SDK defect awaiting a fix. It is not. The SDK
is consistent: `JobTypeValidator.appendConsentRule` returns early when the token carries consent, so
the requirement to declare a consent screen is **lifted** — its own `suggestedFix` says to bind all
four fields at mint time *or* bind none and collect consent in the app. A host that declares
`consent { }` anyway is declaring a screen the token has already satisfied, and
`FlowNavigationManager` filters it back out of the flow it runs; for Enhanced KYC, whose validator
permits only consent and processing, that leaves nothing to start on.
`journeyFor` declared it unconditionally, which is what stranded the run.
**Fixed:** the binding decides whether the screen is declared at all. Verified on device with a
consent-bound fixture token — Enhanced KYC now reaches `si_processing_screen` and submits (HTTP 401,
which is what a locally minted token deserves). The consent-screen drop is therefore assertable on
device after all, and `token-session.yaml` no longer has to avoid it.

The wrong conclusion held for a day because the bisect established the right fact — the binding is the
trigger — and then reached for the wrong owner. Nothing in the SDK source was read as far as
`appendConsentRule`, whose early return is the whole story.

**An SDK gap the host currently papers over (found 2026-08-20, `12.0.2`):** the flow does not follow the
host's dark mode. `UseSmileIDTheme` takes `darkMode: Boolean = isSystemInDarkTheme()` and is public, but
the flow-hosting path — `UseSmileIDBuilder` → `RenderFlow` — calls it as
`UseSmileIDTheme(themeConfig = ...)` and never passes `darkMode`, so a hosted flow always resolves the
mode from the OS. Any app whose appearance is its own setting rather than the system's therefore shows a
light SDK inside a dark host, which is what this sample did: system light, app dark, SDK light.
Verified both ways on device after the workaround — app dark gives an SDK background of `#1A1C23`, app
light gives `#F9FAFB`, with the system in light mode throughout.
**Worked around** in `SdkFlowScreen` by providing the flow subtree a copy of `LocalConfiguration` with
only `UI_MODE_NIGHT_*` rewritten, which is what `isSystemInDarkTheme()` reads. It touches no SDK
internals, but it is a host reaching around a missing parameter. **The ask:** expose `darkMode` on the
flow DSL's `theme { }` block, or forward it from `UseSmileIDBuilder`; then the override goes away. Worth
filing with the accessor asks below, since it is the same shape of gap — a value the SDK already models
that a host cannot reach.

**An SDK gap to file, not work around:** `UseSmileIDJwtDecoder` and `DecodedToken` are public, but
`DecodedToken.tokenPayload` is `internal`, so a host cannot reach the parsed payload through the
SDK's own decoder — and `bindsRequiredUserDetails` is internal too. We therefore decode the claim
ourselves (TOK-A2) and replicate two rules the SDK owns. Ask the SDK to widen the accessor; until
then our copy is a documented duplicate, and the unit test in TOK-A2 pins it to the SDK's semantics.

---

## 4. The work items

| Id | What | Priority | Depends on |
|---|---|---|---|
| TOK-A1 | Manual entry, plus Simulate minting a fixture token (duration + bindings) | **P1** | — |
| TOK-A2 | Token decode: `exp`, `iat`, binding flags, plaintext `country`/`id_type` | **P1** | — |
| TOK-A3 | Session model carries the token, its issue time and its bindings | **P1** | A2 |
| TOK-A4 | Feed the token to the builder; session beats scenario fixture | **P1** | A3 |
| TOK-A5 | Gate the flow on a live session; expiry is a first-class outcome | **P1** | A3, A4 |
| TOK-A6 | Timeout UI honest for 15m/1h/8h, not just five minutes | **P1** | A3 |
| TOK-A7 | Room for jobs; a submitted job survives the process | P2 | A4 |
| TOK-A8 | Device + unit coverage, including the no-consent-screen path | P2 | A4–A7 |
| TOK-A9 | QR scanning for real (CameraX + bundled ML Kit barcode), release-on-leave, scan reliability | P2 | A1–A3 |
| TOK-A12 | `holdCamera` gets its consumer, proven by frames rather than by a bind returning | P3 | A9 |
| TOK-A11 | Say why the expiry gate redirected, and let a fresh scan resume the run it interrupted | P2 | A5, A9 |

**Landing order, and why A9 is not first.** The camera is the only part of this that needs a new
dependency and an owner decision (§7), and everything else is testable without it. Manual entry is a
first-class affordance in its own right — the sheet already offers it, and `spec/launch-args.json`
already says credentials are seeded as arguments rather than typed, "because keyboard input drops
characters from long API keys", which a pasted 900-character JWT confirms. So A1–A6 land first and
make the feature real; A9 replaces the entry mechanism afterwards without touching anything below it.

### TOK-A1 — manual entry

Wire the sheet's existing manual-entry row to a text field, and `onPaste` to the clipboard. Accept
the raw JWT only; reject anything that is not three base64url segments, with the reason on screen.
A launch argument (`token`) is the automation path and needs `spec/launch-args.json` — an ask-first
change (§7), so until it lands automation uses the paste path with `adb shell input text` avoided in
favour of the clipboard (`adb shell am broadcast` cannot set it; use a `--es` extra read once at
launch, which is the same mechanism the other arguments already use).

### TOK-A2 — decode

One small pure function in `sample-ui`, no Android dependency: split on `.`, base64url-decode the
middle segment, read `exp` and `iat` as epoch seconds, then read the `payload` claim for presence of
`given_names` / `last_name` / `email` / `phone_number` (non-empty string ⇒ bound), the four consent
subfields, and the plaintext `country` / `id_type`. Never log the token, any segment of it, or any
claim value. Unit-test against fixtures that mirror the SDK's rules exactly — `granted: false` is not
a binding, a non-string is not a binding, an empty consent object is no consent — because those are
the rules `TokenPayload` applies and we are duplicating them.

Decoding is not verification: we do not hold the signing key and must not pretend to. A malformed or
unparseable token is a *rejection at entry*, never a silently degraded session.

### TOK-A3 — the session model

`UseSmileIDSampleTokenSession` grows to carry `token`, `issuedAtMillis`, `expiresAtMillis`, and the
decoded `UseSmileIDSampleTokenBindings`. `id` stops being a fabricated `9f3a`: use the token's `jti`
when present, otherwise a short non-reversible digest of the token — a display handle, never a
prefix of the credential itself.

### TOK-A4 — into the builder

`FlowLaunchSnapshot` gains the session, and `applying()` uses it:

- **A live session wins over the scenario fixture.** The fixtures exist because there was no real
  token; with one, they are the fallback, not the default.
- `userDetails` still ships what the form holds. The SDK strips token-bound fields itself, so the
  host must not try to second-guess which to send.
- The `consent { }` screen stays in the screens block. With a complete binding the SDK drops it; with
  none, it is the local consent the validator demands. Nothing to branch on host-side — a deliberate
  non-decision, and the reason the flow assembly does not fork per token.
- `onTokenExpired` cannot mint a replacement: the Portal mints by hand and there is no endpoint the
  sample may call. It therefore returns the token unchanged, and the resulting auth failure surfaces
  as `Failure` on the result card. That is the honest behaviour of a partner whose refresh is not
  wired, and the counters make it observable. The alternative — inventing a fixture mid-run — would
  make the sample lie about the very thing it exists to demonstrate.

Interaction to document, not resolve in code: `expiredToken` and `badRefresh` describe a *refresh*
journey the scanned-token path cannot have. With a session active those two scenarios keep using the
fixture path so they still mean something; the card reports the scenario, and the session card's
presence is what tells a reader which source a run used.

### TOK-A5 — the gate

Extend the §7.3 gate: a session that has expired, or a token that fails to decode, is
`NeedsSession` — a third outcome beside `NeedsDetails` and `Misconfigured` — routing to
`scanToken` rather than the forms, because no form fixes it. A run started with no session at all
keeps working on the fixture path, so the no-token journey is unaffected.

**Built with one case, not two:** a session is constructible only from a token that decodes, so an
undecodable one is rejected at entry (TOK-A2's own rule) and cannot reach the gate. `NeedsSession` is
checked ahead of the payload validators, because a form cannot fix a token.

One SDK asymmetry the gate has to know about, found the same way as the accessor gap in §3:
`validateUserDetails` is host-facing but takes **no** token payload, while `build()` applies a
per-field union of "the token binds it or the builder supplies it". A host running the pre-flight
under a binding would therefore redirect to a form the SDK does not need, so the gate skips that one
check when the session's bindings satisfy the SDK's own `bindsRequiredUserDetails` rule.

**Settled 2026-08-24 — the token is deleted at its deadline, the fact of the session is not.** The
original gap was that an expired session persisted whole (R6): the gate turned *every* product run
into a trip to the scanner, the app offered no way to unlink one, and `clearTokenSession()` sat in the
store with no callers. The owner's ruling was to delete expired tokens outright, since the deadline is
already known. Taken literally that would also have deleted the ended banner, this gate, and TOK-A11's
redirect and resume — all of which key off "a session expired" — and worse, a run started after expiry
would have fallen through to the no-token path and submitted **untokenised** without saying so.

So the split is asymmetric: `retireTokenSession` removes the credential and writes a marker holding
only the session's **handle and deadline**, neither of which is a credential (the handle is the `jti`
or a digest, never a prefix of the token). Everything that needs to know a session ended still does;
nothing holds a dead bearer token. That is a straight improvement on §6's stored-unencrypted trade,
which only ever justified holding a *live* token. Retirement fires from the countdown effect the
moment the deadline passes, and a cold start after expiry takes the same path because that effect's
loop exits immediately. `clearTokenSession()` is gone: retirement is the only way a token leaves.

An unlink affordance is still not built, and is still a design question — the ended banner's only
action is Scan and the design file draws no second one. What has changed is that it is no longer the
*only* escape: TOK-A11 means a lapse now explains itself and a relink resumes the interrupted run.

One consequence for device flows remains: a flow that leaves an ended marker behind sends whichever
flow runs next to the scanner, which is why `token-session.yaml` ends by relinking a live span.

**What the redirect leaves behind, and the recommendation (TOK-A11).** Two halves, and only the
second needs design. The redirect is *silent*: `NeedsSession` navigates and returns, while
`Misconfigured` three lines below deliberately records a reason first, on the argument that a silent
exit "is indistinguishable from a dead tap". Landing on a scanner nobody asked for earns the same
courtesy, and per R10 the message belongs to the screen the redirect arrives at rather than the one
it fired from. Nothing typed is lost when it happens — `forms` is shell-level saveable state, which
is R6 — so the cost is orientation, not data.

The redirect also does not resume. `NeedsDetails` gets resumption for free because the form it lands
on *is* a wizard step, so §8's cold-link corollary carries the journey forward down the Continue
chain with no continuation state in the route table. The scanner is a `RootGraph` route rather than a
step in that chain, and the bounce has already popped `FlowGraph` inclusive, so linking a fresh
session strands the partner on the product list with the run they asked for forgotten. Recommend
closing both halves together: the notice, and a pending-run intent the scanner's link consumes so a
successful scan re-enters the flow it was sent away from. Keep that intent on app state, never as a
route argument — the corollary's "no return-to token in any route's arguments" is what keeps the
four-platform route table small, and this must not be the exception that reopens it. **Open
decision:** backing out of the scanner without linking should drop the pending run rather than
remember it, so a later unrelated scan cannot resurrect a forgotten flow — cheap to reverse if the
owner prefers otherwise. Neither half adds an affordance, so neither waits on the unlink ruling
above; the design file's expired state (`5206-3752`, read 2026-08-24) confirms only a Scan action is
drawn, so unlink stays a design question and these two do not.

Mid-flow expiry is deliberately *not* interrupted. The SDK owns the flow once it starts (R2), and
tearing it down from the host would both violate that and destroy the failure we want a partner to
see. The countdown is the warning; the auth failure is the outcome.

### TOK-A6 — the timeout, told honestly

Today `progress()` divides the remaining time by a hard-coded five minutes, so a 1h Portal token
would show a full ring for 55 minutes and then a cliff. Progress becomes
`remaining / (expiresAt - issuedAt)`, and `DEFAULT_DURATION` survives only as the simulator's span.
`toCountdown()` is `m:ss` and overflows past an hour — an 8h token must read `7:59:12`, so the
format grows an hours part when the span needs one. Both are asserted by unit test at 15m, 1h and 8h,
which is cheaper and more certain than watching a device for eight hours.

---

## 4.1 Three things a real token exposed that the fixtures could not

Found while driving Enhanced KYC on device against Portal-minted tokens (2026-08-19). None is caused by
the token session; all three are the sample's own, and each one makes a real run fail in a way that
reads as a defect in the SDK.

1. **The partner id was the sample's fixture, not the token's.** `applying()` sent
   `partnerConfig { partnerId = profiles.active.id }` — literally `"p-1"` — alongside a real signed
   token whose own `partner_id` claim is the true one. The server answered **HTTP 401** and the SDK
   showed its "Submission Failed" screen, which is easily mistaken for a crash. **Fixed:** a live
   session's `partner_id` now wins over the local profile, on the same principle as the environment
   decision — the token is the authority for its own identity. The claim is decoded but never logged;
   a partner id is on this repo's never-commit list.

2. **The environment had two sources of truth that could disagree.** The chip read
   `profiles.active.environment`; `useSandbox` read the `sandbox` launch argument (default `true`), so
   selecting the Production profile displayed Production while the builder still submitted to sandbox.
   **Fixed:** one resolution on the app state, `launchArgs.sandbox ?: settings.useSandbox`, feeding both
   the chip and the builder. A Settings row owns the choice, `sandbox` is nullable so an argument
   overrides only where it was passed, and the profile no longer carries an environment at all.

3. **Sandbox only accepts predefined test identities, and this repo documents none.** The ID-details
   form accepts any value, so a run typed with an arbitrary ID number cannot succeed whatever the
   credentials — and neither can a device flow. **Owed, as its own PR** (owner call 2026-08-19): seed
   the form with a valid sandbox identity and use it in `token-session.yaml`, or document the list.
   Until then no automated sandbox run can reach a successful submission, which is worth knowing
   before reading a red flow as a regression.

**A fourth thing, and the reason the other three were findable:** the sample now sets
`config { logging { enabled = BuildConfig.DEBUG; level = HEADERS } }`, and the SDK's own logging is
what turned "it crashes" into an exact answer. It reaches logcat under the tag `OkHttp`, and its
redaction holds — `smileid-token`, `smileid-partner-id` and `smileid-device-nonce` all print as `██`,
with no raw JWT anywhere in the output. `HEADERS` rather than `BODY` deliberately: a logged body
carries the `user_details` this repo forbids in logs, and one word raises it locally when a response
body is what you need. Debug builds only, so a release never logs traffic.

It also settles the environment question empirically: the request goes to `testapi.smileidentity.com`,
so `useSandbox = true` really is in effect regardless of which profile the chip shows.

### 4.2 Why the ID form is skipped, and where the skip stops

Decided 2026-08-19 on the owner's call, after a real Portal token reached the KYC form with three empty
fields it already had the answers to.

The rule is per field, and it is the server's rule: **the token beats the form.** `injectTokenPayload`
overwrites `country`, `id_type` and `id_number` from the token's claims, so a form the user fills and
the server then discards is worse than no form — it invites someone to believe they chose something.
`applyIdParams` therefore reads the token first and the form only as a fallback, and the navigation
gate skips the form entirely when the token covers everything that form would collect.

`id_number` is the field that makes this work. A token session never has the number — it has the vault
reference standing in for it, which is non-blank (so the SDK's validator passes) and identical to what
the server substitutes anyway (so nothing is lost). It is held as `idNumberReference` precisely so no
one renders it as a number.

Three boundaries, each deliberate:

- **All or nothing per product.** A partial binding still shows the form, and the bound fields are
  overridden afterwards. Splitting a form into some-fields-asked and some-not is a bigger UI change
  than this earns, and the Portal mints identity fields together.
- **Document Verification is treated more strictly than the SDK treats it.** Its validator accepts a
  null `idType`, so a token binding country alone would build — but the form is where the document type
  is chosen, and skipping on a partial binding would quietly submit without one instead of failing. So
  both must be bound.
- **A skipped form has to be visible as a skip.** The session card names the field groups the token
  covers — `Supplies name, contact, ID` — in field names and never values, because device flows dump
  that screen's hierarchy on failure. A form that vanishes with no explanation is indistinguishable
  from a form the app lost.

### 4.3 Partial bindings, which the Portal does not prevent

The QR generator does not validate which user-detail fields it embeds, so a token may bind some and not
others. The SDK's rule is both names plus one contact, applied per field — so three cases exist and all
three were wrong before this:

- **Both names, no contact.** The form's own rule was "first and last name", so it called itself
  complete, enabled Continue, and the SDK then refused the build for a missing contact. A loop with no
  exit, and it was reachable without a token at all — the form labelled both contact rows optional while
  the SDK required one of them.
- **Some names bound.** The form asked for the bound ones again, and what the user typed was discarded:
  the server overwrites them from the token.
- **Contact bound only.** Both names still needed, which the form got right by accident.

One model now answers all three: `userDetailsRequirement()` subtracts the bindings from the SDK's rule,
and everything reads from it — which rows render as `Provided by token` (never prefilled: the value is
vaulted and the host does not have it), whether a contact row still claims to be optional, the sentence
under the form, whether Continue is enabled, and whether the gate routes here at all. The contact rule
stays "one of two", so a bound email does not grey out the phone row — only the requirement lifts.

---

## 5. Where each piece of state belongs

The rule this table applies: **Room when it is many rows that get queried, DataStore when it is one
small value read as a stream, in-memory when it must not outlive the run.** Nothing goes in two
places.

| State | Home | Why |
|---|---|---|
| Submitted jobs | **Room** | Many rows, filtered by status, counted per filter, grouped by date, removed with undo. That is a query surface, and re-deriving it from a serialised blob on every read is the thing Room exists to avoid |
| Per-job token binding (what the token supplied) | **Room**, column on the job | Belongs to the row it describes; the evidence for "the server injected these" is per submission |
| Which profile submitted a job | **nowhere — owner decision 2026-08-20** | The list is every job this device did. The job id is the handle for looking anything else up afterwards, so the row does not need to carry who ran it. Columns were added and then removed; a status refresh needs the session, not the partner |
| Settings (6 booleans) | **DataStore** — already | Small, single-valued, read as a Flow |
| Token session: the raw token | **DataStore** | One record, replaced wholesale, read as a Flow. Not relational, and a table of one row is a table for no reason. **Built: the token is the whole record** — `id`, `iat`, `exp` and the bindings all decode from it, so storing them beside it would only create copies that can disagree with it |
| Jobs-seeded flag | **DataStore** | One boolean. Prevents the eleven fixtures being re-seeded over a partner's real rows every launch |
| Active profile id | **DataStore** | A scalar |
| Profiles themselves | **in memory for now** | Room-shaped, but not needed by "jobs offline" and it would widen this PR. Named here so the next person does not have to re-derive it |
| Active scenario / theme | **stays `rememberSaveable`** | Deliberately *not* persisted — see below |
| Flow result: status, counters, jobId, lastError | **in memory (`rememberSaveable`)** | Must reset per run; persisting it would carry one run's counters into the next and break the exactly-once claim |
| Form values | **`rememberSaveable`** — already | Survives recreation, and must not outlive the app: it is PII |

**Why scenario and theme must not become persisted state.** They are launch arguments with their own
contract, and `spec/launch-args.json` says they are "read from the launching intent only, and applied
once". Persisting them makes a launch argument sticky: a run that passed `scenario=expiredToken` once
would keep that scenario on every later launch that passed nothing, and the drawer and the argument
would disagree with no way to tell which won. The card reports what the run actually got precisely
because this class of bug is easy to introduce and invisible on screen.

**Room specifics to settle in the PR, not later.** One entity mirroring `UseSmileIDSampleJob` keyed
by job id, which is what makes a repeated result idempotent at the storage layer as well as in the
list. Undo is a re-insert of the rows removed, not a soft-delete column, because the list already
holds what it removed and a `deleted` flag would leak into every query. `fallbackToDestructiveMigration`
is correct for a sample and must be stated out loud rather than left as a default nobody chose. The
DAO returns `Flow`, so the verifications list keeps its current shape.

**The offline-mode trap.** `allowOfflineMode` makes the SDK skip token decoding, which silently
withdraws every token relaxation and re-imposes the strict rules. Saving jobs locally is *not* the
SDK's offline mode and must not be conflated with it: TOK-A7 persists what a run produced, and does
not touch `config { allowOfflineMode }`. If offline submission is ever wanted, it is a separate item
with its own owner decision.

---

## 6. Security

The token is a live bearer credential minted against a real API key, sandbox or not.

- **Never logged**, never in a crash report, never in an error message, never in a test artifact.
  Maestro captures the view hierarchy on failure, so it must never reach a `testTag`ged node either.
- **Not on the result card.** The card is a shipped debug surface that automation dumps; it may show
  the session handle and the remaining time, never the token or a prefix of it.
- **Never committed.** A real token in a fixture, a flow file or a doc is on the never-commit list in
  `AGENTS.md`, and this repo's history goes public. Fixtures stay synthetic and unsigned.
- Stored in DataStore unencrypted, which is the deliberate trade: it is short-lived, sandbox-scoped,
  and the alternative — losing the session on every process death the camera can cause — would make
  the feature unusable. Worth revisiting if a production token ever becomes scannable.
- The redaction rule the Portal itself follows is worth copying: field names and types in messages,
  never values.

---

## 7. Ask first — three of these block a PR

`AGENTS.md` requires asking before a new dependency or a `spec/` change, so these are gathered rather
than assumed:

1. ~~A QR-scanning dependency (TOK-A9).~~ **Settled 2026-08-19: CameraX plus ML Kit barcode, in
   the app's own scan screen.** The owner's reasoning is the deciding one and worth recording: the
   sample is ours, so the dependency cost is acceptable, and a host that owns a camera is a surface
   we *want* — it is how CameraX failures and camera conflicts with the SDK become testable here
   rather than in a partner's app. The Play services code scanner was the cheaper option and is
   rejected: it would have put a Google-provided sheet over a screen the design owns, needed Play
   services on a device (the `huawei-face` variant says GMS-free devices matter to this org), and
   tested nothing about camera contention. See §7.1 for what the decision commits us to.
2. **`spec/launch-args.json` gains `token`** — **deliberately left owed until Android lands**
   (settled 2026-08-19). A four-platform contract is cheaper to get right after one implementation
   than before it, and §7.2 turns out to remove the urgency entirely: automation does not need this
   argument to drive the feature.
3. **`spec/test-ids.json` gains the ids for manual entry, the decoded-binding summary and the expiry
   state.** Same deferral, same reason — the Android build is what will say which of these are real
   affordances worth four implementations and which were guesses. **What it says:** none of the three
   were needed. The four existing ids carried the whole feature — `sample_token_manual_entry` moved
   from the row to the field it always described, `sample_token_paste` and `sample_token_simulate`
   stayed put, and the expiry state was already `sample_session_ended_banner`. The two genuinely new
   affordances are the simulated scan's duration and binding chips and the manual-entry `Link token`
   button, which the device flow drives by their labels; the decoded-binding summary was a guess and
   no screen needed it. So the owed spec change is smaller than it looked: ids for those three
   controls if the other platforms want them, and nothing else.
4. Room itself is a new dependency; it is the user's stated direction, so it is recorded here as
   settled rather than open.

### 7.1 What the CameraX decision commits us to

Measured against the published artifact rather than assumed: `com.usesmileid:usesmileid:12.0.2`
already brings **CameraX 1.6.1** — `camera-core`, `camera-compose`, `camera-lifecycle`,
`camera-camera2`, `camera-view` — at *runtime* scope. So the artifacts are on the app's runtime
classpath today and the real cost is putting them on the **compile** classpath: declare CameraX at
the version the SDK already resolves, not a version of our own choosing. That is smaller than
"four or five new dependencies" and it turns a future SDK CameraX bump into a visible conflict here,
which is the signal the decision is for.

- **Pin to 1.6.1 through the catalog**, and treat a divergence between what we declare and what the
  SDK resolves as a finding rather than something Gradle quietly reconciles upward. **Built and
  verified:** the release runtime graph resolves `camera-core`, `camera-camera2`, `camera-compose`,
  `camera-lifecycle`, `camera-view` and `viewfinder-compose` all at 1.6.1, so the catalog pin matches
  what the SDK already brings. The compile-classpath cost really is the whole cost.
- **ML Kit barcode: take the bundled `com.google.mlkit:barcode-scanning`**, not the Play-services
  variant. The bundled model works with no Play services, which keeps the reference sample usable on
  the GMS-free devices this org already ships an ML variant for. It costs APK size; the
  consumer-measured size lane is what should quantify that rather than a guess in this document.

  **Now measured, because this document asked for a measurement:** the minified, resource-shrunk
  release APK goes from **51.6 MB to 72.9 MB — plus 21.3 MB, a 41% increase**. The bundled model ships
  as a native library per ABI and this app packages four (`arm64-v8a`, `armeabi-v7a`, `x86`, `x86_64`),
  so barcode entries alone account for 44.4 MB uncompressed and the two x86 slices no phone will run
  are about half the native payload. That is a real cost on a sample partners are asked to read, and it
  deserves an owner ruling rather than silent acceptance. Three levers, none taken here because each
  trades against something already settled: ABI splits or an app bundle (packaging only, no behaviour
  change, would recover most of it); the play-services barcode variant (downloads the model, but
  reintroduces the GMS dependency this choice exists to avoid); or accept it, on the grounds that a
  reference sample's fidelity matters more than its size.
  **One correction to that reasoning, read off the graph:** this app consumes `mlkit-face`, which
  pulls `com.google.android.gms:play-services-mlkit-face-detection`, so *this* app already requires
  Play services regardless. The GMS-free argument therefore justifies the variant choice for a
  partner building against `huawei-face` — it does not describe this sample as configured, and the
  document should not imply it does.
- **`CAMERA` permission moves into the host manifest**, and the scan screen must request it. The SDK
  asks for its own between consent and instructions; two requesters in one app is realistic partner
  behaviour and is now something this sample demonstrates.
- **Releasing the camera becomes a host invariant.** The scan screen must unbind its use cases when
  it leaves composition, because navigating scan → flow otherwise hands the SDK a camera the host
  still holds. `sample-apps-plan.md` §1 lists "a camera not released after navigating away" as a
  host-interaction defect class this repo exists to catch, and this decision is what finally creates
  it here. A device check that runs scan → flow back to back is therefore part of TOK-A9, not a
  nice-to-have. **Built, with a coverage limit worth stating:** `token-session.yaml` binds the camera
  on the scan screen, leaves it, and drives the SDK past instructions into capture — which proves the
  host handed the camera back. It cannot prove the preview *renders*: the SDK's capture screen carries
  no `si_*` id and this repo's flows may not assert on pixels, so "the preview is right" stays
  hand-verified. That is the same lane gap the RN preview work hit, and the check plausibly belongs in
  the SDK repos, which can render their own screens.
- **`holdCamera` is built (2026-08-24).** It was one of the two launch arguments without a consumer,
  and it could not be honoured without a host-owned camera — the argument's own note in
  `spec/launch-args.json` warns that a probe which never acquired the camera passes vacuously. It now
  binds an `ImageAnalysis` use case alongside the starting run and **counts delivered frames**, since
  a bind returning is not evidence the camera opened; it unbinds only its own use case, because
  `unbindAll` would take the camera off the SDK it is supposed to be contending with. It holds **the
  lens the product will use** — review caught that a hard-coded back camera contends with nothing on a
  selfie flow while still logging a successful acquisition, which is the vacuous pass again wearing
  the evidence's clothes. Every camera call is guarded, because an unguarded `bindToLifecycle` throw
  inside a `LaunchedEffect` kills the process, and a probe that crashes the run it observes gets
  reported as an SDK defect. The release line names the lens and how long before release the last
  frame arrived, so a hold evicted early by someone else's `unbindAll` cannot read as one that lasted.
  Two limits worth knowing: a missing camera permission is reported rather than requested, because a
  permission dialog over a starting flow changes the hand-off being measured; and the report goes to **logcat**
  under one tag, which is the weak part — a `sample_*` node would be assertable, but adding one is a
  four-platform `spec/test-ids.json` change and this argument is the only thing that would want it.
  That id is the obvious follow-up if the argument earns a device lane. This was originally deferred
  to its own PR to keep one reviewer to one subject; folded in on the owner's instruction.

### 7.2 Automation needs no new argument, because Simulate can mint the token

Deferring the `token` launch argument raised the obvious question — how does a device flow get a
900-character JWT into a text field, when `spec/launch-args.json` itself says credentials are seeded
as arguments "because keyboard input drops characters from long API keys"? The answer was already in
the design: the scan sheet has a **Simulate** affordance and `spec/test-ids.json` already carries
`sample_token_simulate`. Today it fabricates a session with a hard-coded id and no token. It should
instead **mint a fixture token locally** — the same unsigned, structurally valid JWT the scenarios
already rely on (`UseSmileIDSampleFlowTokens`), with a chosen duration and a chosen set of bindings.

That makes the whole feature automatable with **no spec change at all**, and it is not a test-only
branch in shipped code: Simulate is an existing, shipped probe affordance, in the same family as the
scenario drawer and the result card.

What a fixture token can exercise, because the SDK **decodes but never verifies** a token
client-side: the decode rules, the binding flags, the countdown and the ring at any duration, the
expiry gate, the builder handoff — and, most valuably, **the consent-screen drop**. Mint a token
carrying a complete consent binding and the SDK removes its consent screen, so the journey that §8
described as hand-driven becomes a deterministic device assertion.

**Correction from the build:** every one of those holds on device *except* the consent-screen drop,
which cannot be asserted at all on `12.0.2` — a complete consent binding cancels the run outright (§3).
Minting it is still worth doing, because it is what produced the repro; asserting the resulting journey
waits on the SDK.

What it cannot exercise, and what still needs a real Portal token by hand: a server actually
accepting the token, and the QR itself. That boundary is worth stating in the PR rather than letting
a green suite imply more than it proves.

Two consequences for the work list: TOK-A1 grows the Simulate minting (duration + bindings) alongside
manual entry, and TOK-A8's device coverage no longer waits on anything owed.

---

## 8. Testing

- **Unit, in `sample-ui`:** decode (every binding rule, plus malformed, unsigned, missing `exp`),
  progress and countdown at 15m/1h/8h, and the session's expiry boundary. Room DAO tests for the
  filters, the counts, insert-idempotence by job id, and undo.
- **Spec tests:** the new ids and launch argument, once §7 is answered.
- **Goldens:** the session card, the ended banner and the nav-bar ring at a long span, light and dark.
- **Device flows.** A token-bound run is a *different journey*: with consent bound, the SDK starts at
  instructions, so `sdk-flow.yaml`'s `si_consent_screen` assertions describe the no-token path only.
  Add a `token-session.yaml` covering entry by paste, the countdown appearing, a run that starts under
  the token and reaches `si_instructions_screen` **without** a consent screen, an expired session
  routing to `scanToken` instead of the SDK, and jobs surviving `stopApp`. Assert on `si_*` and
  `sample_*` ids only, and never on the token.
- **Scan reliability (TOK-A9), on the Oppo — GATE PASSED 2026-08-24, after a fix.** The densest QR the
  Portal mints (8h, all seven user-detail fields, consent) at the size the Portal renders. The Portal's
  own PR flagged this as unconfirmed and it turned out to be a real defect, in this app rather than in
  the QR: `ImageAnalysis` was built with no `ResolutionSelector`, so CameraX applied its **640x480**
  default, and a v3 token QR is far too dense to survive that downscale. It decoded only when held
  close enough for the code to *overflow* the reticle — the opposite of what the screen's own caption
  asks for. Pinned to **1920x1080** 16:9 and confirmed in the camera's negotiated stream spec; the
  owner then read the same QR "way smoother and quicker even at a distance".

  Two things this leaves. The analyser reads the **whole frame** while the screen draws a reticle at
  72% of width and says "line up the code inside the frame", so the glyph still implies a targeting
  behaviour nothing implements — either crop the analysis to the reticle or reword the caption, and
  that is a design call. And there is no automated check: proving this needs a real dense QR in front
  of a real camera. The cheap approximation, if it is ever worth it, is to assert the negotiated
  analysis resolution rather than the decode, since the resolution is what regressed.

---

## 9. What the other three inherit

The token contract is the SDK's, so it is identical everywhere: presence-only user details, readable
consent, a complete binding dropping the consent screen, no relaxation of ID params, and offline mode
withdrawing all of it. Three things are per-platform and must not drift: where the raw token is
stored (Keychain on iOS is the obvious better home than its Android counterpart, and that asymmetry
is fine and worth recording), how the QR is scanned, and the persistence library. The decode rules
must be unit-tested against the same fixtures on all four so a platform cannot quietly disagree about
what "bound" means.

The form-skipping rule in §4.2 is part of that contract, not an Android choice: token beats form per
field, both host forms are skipped only when the token covers everything they would collect, the ID
number travels as its vault reference, Document Verification requires country *and* ID type before its
form is skipped, and the session surface names the field groups the token supplies. A port that skips on
a partial binding, or that renders the reference as a number, has diverged.
