# Token session — Android, from a scanned QR to a submitted job

**Status:** TOK-A1–A6 and TOK-A9 built on Android — manual entry, Simulate minting, decode, session
model, builder handoff, honest countdown, and the CameraX QR scanner with the bundled ML Kit barcode
model. Both host forms are now skipped when the token already carries what they would collect (§4.2). A9 was planned as its own PR and folded into the same one on the owner's call (2026-08-19), so
the token flow lands complete rather than scannerless. TOK-A7 (Room) is next as its own PR;
`holdCamera`, TOK-A8's remaining goldens and TOK-A10 follow it.

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
   never relaxes, so the ID form still runs, and TOK-A10's prefill has real data to read.

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

**An SDK defect, found on device and not inferable from the source (2026-08-19, `12.0.2`):** a token
whose `payload.consent` binding is complete makes the flow deliver `UseSmileIDResult.Cancelled`
**immediately, with no user action**, so the host lands back where it started and the run never begins.
The same token with the consent binding removed runs normally through to the consent screen, which is
what isolates the binding as the trigger — bisected on a quiet handset, release build, twice.
`FlowNavigationManager` does filter the Consent screen out of `flowStructure` exactly as §3 describes,
and `navigationPath` seeds from `screens.firstOrNull()`, so a start at instructions is what the code
reads like; the cancellation arrives from `deliverTerminalOnTeardown()`, which fires when the
`FlowNavigationManager` ViewModel is cleared. Root-causing beyond that is the SDK repo's to do, and it
should be filed there with this repro. Two consequences here: the consent-screen drop — the thing §7.2
calls the most valuable client-side behaviour a fixture token can exercise — **cannot be asserted on
device yet**, and `token-session.yaml` therefore covers the unbound path and records why rather than
encoding the defect as expected behaviour.

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
| TOK-A10 | Prefill the ID-details form from the token's plaintext fields | P3 | A2 |

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

**A gap the device suite exposed, and an owed product decision:** an expired session persists (R6) and
the gate turns *every* product run into a trip to the scanner, so a partner who lets a session lapse
cannot start any run until they scan again — and the app offers no way to unlink one. `clearTokenSession()`
exists in the store and nothing calls it. The ended banner's only action is Scan, so adding an unlink
affordance is a design question rather than something to invent here. It also makes device flows
order-dependent: a flow that leaves an expired session behind fails whichever flow runs next, which is
why `token-session.yaml` ends by relinking a live span rather than leaving the ended state on disk.

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

2. **The environment has two sources of truth that can disagree.** The chip reads
   `profiles.active.environment`; `useSandbox` reads the `sandbox` launch argument (default `true`).
   Profile `p-3` is Production, so selecting it displays Production while the builder still submits to
   sandbox. **Owed decision** — the fix is to resolve both from one source and let the launch argument
   override only when present, which makes `sandbox` nullable and needs a `spec/launch-args.json` note.

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
- **`holdCamera` becomes implementable, and is still owed.** It is one of the two launch arguments
  without a consumer, and it cannot be honoured without a host-owned camera — the argument's own note
  in `spec/launch-args.json` warns that a probe which never acquired the camera passes vacuously. Kept
  out of this PR deliberately even though the camera code is now here: it is a launch-argument
  consumer rather than part of the token journey, and it would hand one reviewer a second subject.

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
- **Scan reliability (TOK-A9), on the Oppo:** the densest QR the Portal can mint — 8h with all seven
  user-detail fields and consent — at the readable size the Portal renders, plus the same at 15m with
  no payload. The Portal's own PR flags this as unconfirmed; a sample app that cannot scan the QR is
  the whole feature failing, so this is a gate, not a nice-to-have.

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
