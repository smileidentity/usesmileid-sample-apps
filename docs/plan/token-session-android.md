# Token session — Android, from a scanned QR to a submitted job

**Status:** proposed, not started. Android first; the token contract is shared, so §9 records what the
other three inherit. Written against the Portal as merged (`portal#3274`, `portal#3274`'s follow-up
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

## 3. What the SDK does with it

Read from `TokenPayload`, `FlowValidator`, `JobTypeValidator` and `FlowNavigationManager` at 12.0.2:

- The SDK decodes the token at `build()` and exposes **presence flags only** — `hasGivenNames`,
  `hasLastName`, `hasEmail`, `hasPhoneNumber` — plus `consent`, whose four subfields *are* readable.
- A token-bound user-detail field **relaxes** the matching `userDetails` requirement per field and is
  stripped from the `user_details` part; the server injects the real value.
- **A complete consent binding drops the consent screen at runtime** (`FlowNavigationManager`: the
  screen is removed from the flow the navigation runs). An *incomplete* binding is a build error that
  names the missing subfields.
- **Offline mode skips decoding entirely**, so an offline run keeps the strict legacy rules and loses
  every relaxation above. That matters the moment we save jobs offline (§6).
- **ID params are not relaxed by the token.** `validateBiometricKYCParams` and friends take no token
  payload, so `country` / `idType` / `idNumber` must still be supplied locally even when the token
  binds them. `TokenPayload` does not even model `id_number`, `country` or `id_type`.

Three consequences worth stating plainly, because each one is a place a reasonable design goes wrong:

- The Consent Details Form cannot be skipped just because a token exists. It can be **relaxed**, and
  only for the four fields the SDK models.
- The ID-details form can be **prefilled** from the token's plaintext `country` / `id_type` if we
  decode them ourselves, but never skipped, and `id_number` can never be prefilled.
- A token-bound run **has no consent screen**, so every device flow that asserts `si_consent_screen`
  is asserting the no-token path. Token-bound coverage starts at `si_instructions_screen` (TOK-A8).

**An SDK gap to file, not work around:** `UseSmileIDJwtDecoder` and `DecodedToken` are public, but
`DecodedToken.tokenPayload` is `internal`, so a host cannot reach the parsed payload through the
SDK's own decoder — and `bindsRequiredUserDetails` is internal too. We therefore decode the claim
ourselves (TOK-A2) and replicate two rules the SDK owns. Ask the SDK to widen the accessor; until
then our copy is a documented duplicate, and the unit test in TOK-A2 pins it to the SDK's semantics.

---

## 4. The work items

| Id | What | Priority | Depends on |
|---|---|---|---|
| TOK-A1 | Manual token entry: paste/typed token → a real session | **P1** | — |
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

## 5. Where each piece of state belongs

The rule this table applies: **Room when it is many rows that get queried, DataStore when it is one
small value read as a stream, in-memory when it must not outlive the run.** Nothing goes in two
places.

| State | Home | Why |
|---|---|---|
| Submitted jobs | **Room** | Many rows, filtered by status, counted per filter, grouped by date, removed with undo. That is a query surface, and re-deriving it from a serialised blob on every read is the thing Room exists to avoid |
| Per-job token binding (what the token supplied) | **Room**, column on the job | Belongs to the row it describes; the evidence for "the server injected these" is per submission |
| Settings (6 booleans) | **DataStore** — already | Small, single-valued, read as a Flow |
| Token session: token, `iat`, `exp`, `id`, bindings | **DataStore** | One record, replaced wholesale, read as a Flow. Not relational, and a table of one row is a table for no reason |
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
2. **`spec/launch-args.json` gains `token`.** Automation cannot type a JWT reliably, and this is the
   canonical way the four apps take input. Four platforms then owe it.
3. **`spec/test-ids.json` gains the ids for manual entry, the decoded-binding summary and the expiry
   state.** Same ripple.
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
  SDK resolves as a finding rather than something Gradle quietly reconciles upward.
- **ML Kit barcode: take the bundled `com.google.mlkit:barcode-scanning`**, not the Play-services
  variant. The bundled model works with no Play services, which keeps the reference sample usable on
  the GMS-free devices this org already ships an ML variant for. It costs APK size; the
  consumer-measured size lane is what should quantify that rather than a guess in this document.
- **`CAMERA` permission moves into the host manifest**, and the scan screen must request it. The SDK
  asks for its own between consent and instructions; two requesters in one app is realistic partner
  behaviour and is now something this sample demonstrates.
- **Releasing the camera becomes a host invariant.** The scan screen must unbind its use cases when
  it leaves composition, because navigating scan → flow otherwise hands the SDK a camera the host
  still holds. `sample-apps-plan.md` §1 lists "a camera not released after navigating away" as a
  host-interaction defect class this repo exists to catch, and this decision is what finally creates
  it here. A device check that runs scan → flow back to back is therefore part of TOK-A9, not a
  nice-to-have.
- **`holdCamera` becomes implementable.** It is one of the two launch arguments still without a
  consumer, and it cannot be honoured without a host-owned camera — the argument's own note in
  `spec/launch-args.json` warns that a probe which never acquired the camera passes vacuously. Worth
  folding in while the camera code is fresh, as its own item rather than inside TOK-A9.

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
