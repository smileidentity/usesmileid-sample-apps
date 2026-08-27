# Token bindings → what the host collects, and what it declares to the SDK

**Status:** §8's three questions are **all answered** (Q2 in code on 2026-08-25, Q1 and Q3 by owner
ruling on 2026-08-27), and answering Q2 falsified one row of §6. The decision tables in §3–§7 stand as
written; read §8 for what changed and why.

Scope: Android. The token contract is shared, so §9 records what the other three inherit.

## 1. Why this document exists

A token can carry the end user's details, their consent, and their ID parameters. Each of those
changes what the sample must collect *and* what it must declare to the SDK. Get the first half wrong
and a partner re-types data the token already holds. Get the second half wrong and the run does not
start at all.

That second failure already happened, twice, and both times the diagnosis went to the wrong place:

- `journeyFor` declared `consent { }` for every token. A token carrying complete consent lifts the
  SDK's requirement for that screen — so declaring one anyway declares a screen the SDK then filters
  back out, and for Enhanced KYC, whose validator permits only consent and processing, that left
  nothing to start on. The run was cancelled ~30 ms after entry with no error. This was written up as
  an SDK defect for a day. It was ours.
- The correction to that write-up was *also* wrong: it claimed the defect was structural to the two
  non-capture job types, reasoning from a partial read of `FlowNavigationManager` while the answer sat
  one function above code already open in the same file.

Both mistakes share a shape: **the host inferred what the SDK wanted instead of reading the rule that
decides it.** So this document starts from the SDK's own validators, quotes them, and derives the
host's behaviour from them — rather than the other way round.

## 2. The authority: what the SDK actually decides

All references are `android` @ `12.0.2` / `main`, verified by reading them on 2026-08-20. Anything in
§3 onwards that contradicts this section is a bug in this document.

### 2.1 Consent — `JobTypeValidator.appendConsentRule`

```kotlin
val tokenConsent = tokenPayload?.consent
if (tokenConsent != null) {
    val missing = tokenConsent.missingSubfields
    if (missing.isNotEmpty()) { add(...incomplete binding, naming the subfields...) }
    return                       // <-- the local-consent requirement never runs
}
if (!configuration.hasConsentScreen && !configuration.hasConsentInformation) {
    add(...must include either a Consent screen or a pre-supplied consentInformation...)
}
```

Three consequences, in order of how easy they are to get wrong:

1. **A token carrying consent lifts the requirement.** The early `return` means the host is not asked
   for a consent screen *or* a `consentInformation` preset. The SDK's own `suggestedFix` states the
   intent: *"Bind all four consent fields when minting the token at /v3/token, or bind none and
   collect consent in the app."* Bind-none-and-collect, or bind-all-and-don't — not both.
2. **Declaring one anyway is not harmless.** `FlowNavigationManager.flowStructure` filters
   `ScreenType.Consent` out of the flow it runs when `resolvedTokenPayload?.consent?.isComplete`,
   and `navigationPath` seeds from `flowStructure.screens.firstOrNull()`. The declaration survives
   validation and is then removed from the thing that runs.
3. **A partial binding is a build error, not a partial relaxation.** One to three of the four
   subfields fails the build naming what is missing. There is no host workaround; the token is wrong.

### 2.2 User details — `appendUserDetailsRequiredRule` and `FlowValidator.missingUserDetailsFieldIssues`

```kotlin
if (configuration.userDetails != null) return          // (a)
if (tokenPayload.bindsRequiredUserDetails) return      // (b)
if (tokenPayload == null) { add(...legacy blanket error...); return }
addAll(FlowValidator.missingUserDetailsFieldIssues(userDetails = null, tokenPayload = tokenPayload))
```

with `bindsRequiredUserDetails = hasGivenNames && hasLastName && (hasEmail || hasPhoneNumber)`.

- **(b) is the relaxation:** names plus one contact field, bound by the token, and the host may omit
  `userDetails` entirely.
- **(a) is a trap.** A *non-null* `userDetails` short-circuits the rule before any field is examined,
  so `UserDetails(givenNames = "", lastName = "", email = null, phoneNumber = null)` — blanks standing
  in for token-bound fields — silences the SDK's per-field gap reporting completely. The sample was
  doing exactly this. It happened to be safe (the token really did bind those fields) but it means the
  host, not the SDK, was the only thing checking. **Rule: never pass a blank standing in for a bound
  field.** Pass `null` when the token satisfies (b); otherwise pass only what the host collected.
- Per-field errors are only reachable with `userDetails == null`, and they name the gap precisely:
  `"not bound by the token and not supplied on the builder"`.

### 2.3 ID parameters — out of scope for the SDK's relaxation

PR #336 states it: *"out of scope: id information (country, id_type, id_number) and callback_url."*
The token may carry `country` and `id_type` in plaintext and the ID number as a **vault reference**,
but no validator reads them. The host must lift them out of the token and pass them as builder params
itself, or the SDK will keep asking. `applyIdParams` already does this, per field, token first.

### 2.4 Screen sets per job type — `NonCaptureJobTypeValidator`

Enhanced KYC and BVN permit **only** Consent and Processing; anything else is
`InvalidJobTypeScreenConfigException`. So with consent bound, the entire legal flow is
`screens { processing { } }`. That is the narrowest flow the sample can produce and it must stay
covered by a test, because it is the one that broke.

## 3. The decision table

`B` = the token's bindings. Read left to right; every column is derived from §2, never guessed.

| # | Token carries | Host user-details form | Host ID form | `screens { consent }` | builder `userDetails` |
|---|---|---|---|---|---|
| 1 | consent + all user details | **skip** | per §2.3 | **omit** | `null` |
| 2 | consent only | **show** (all rows) | per §2.3 | **omit** | collected values |
| 3 | user details only | **skip** | per §2.3 | **declare** | `null` |
| 4 | nothing | **show** (all rows) | per §2.3 | **declare** | collected values |
| 5 | consent + *some* user details | **show** (the gap only) | per §2.3 | **omit** | collected values |
| 6 | *some* user details only | **show** (the gap only) | per §2.3 | **declare** | collected values |
| 7 | partial consent (1–3 of 4) | n/a — build fails | n/a | **omit** | n/a |

Cases 1–4 are the four the owner named. 5 and 6 are the partial-binding rows that fall out of §2.2 and
must not be treated as case 2/4: asking for a name the token already bound is the original complaint.
7 is not a UX case at all — it is a malformed token, and the only correct behaviour is to report it.

**The ID column is independent of consent and user details**, which is why it is not expanded into
more rows. Per §2.3 the rule is: show the ID form when `product.needsIdDetails && !B.bindsIdDetails(product)`.
`bindsIdDetails` is deliberately stricter than Document Verification's own validator, which accepts a
null `idType` — the form is where the document type is chosen.

## 4. One pure function, because branching in four places is how this went wrong

Today the decision is spread across `firstStepFor`, `stepAfterUserDetails`, `journeyFor`,
`applyIdParams` and `applying`. Five call sites, each re-deriving part of the same question. The fix
is one function with no Android dependency, exhaustively unit-testable:

```kotlin
/** Everything the bindings decide, resolved once at flow entry (R2). */
data class UseSmileIDSampleFlowPlan(
    /** Which user-details rows the host must still collect; empty means skip the form. */
    val userDetailsGap: UseSmileIDSampleUserDetailsRequirement,
    val showIdDetailsForm: Boolean,
    val declareConsentScreen: Boolean,
    /** False ⇒ pass null, never blanks (§2.2 (a)). */
    val passUserDetails: Boolean,
)

fun flowPlan(
    bindings: UseSmileIDSampleTokenBindings?,
    product: UseSmileIDSampleProduct,
): UseSmileIDSampleFlowPlan
```

Derivation, one line per field, each traceable to §2:

- `userDetailsGap = bindings.userDetailsRequirement()` — §2.2 (b)
- `showIdDetailsForm = product.needsIdDetails && bindings?.bindsIdDetails(product) != true` — §2.3
- `declareConsentScreen = bindings?.consent == null` — §2.1
- `passUserDetails = bindings?.bindsRequiredUserDetails != true` — §2.2 (a)

Every existing call site then reads the plan instead of re-deciding. `journeyFor` gets the one line it
needed all along, and the routing functions stop being the place the rule lives.

## 5. What each case looks like to the person holding the phone

The sample already renders bound rows as **`Provided by token`** rather than prefilling them, because
the values are vault references and the host genuinely does not have them. That stays, and it is the
main affordance that makes these cases legible instead of mysterious.

- **Case 1** — tap a product, land on the SDK. No host forms at all. For Enhanced KYC that means
  landing directly on the SDK's processing screen, which looks abrupt and is correct: there is nothing
  left to ask.
- **Case 2** — the form appears with all four rows live, the sentence under it says consent came from
  the token, and the SDK never shows its consent screen.
- **Case 3** — no form; the SDK's consent screen is the first thing seen.
- **Case 4** — today's unbound baseline, unchanged.
- **Cases 5/6** — the form appears with bound rows reading `Provided by token` and only the gap
  editable. Continue stays disabled until the gap is filled, per the existing requirement model.
- **Case 7** — the run never starts and the result card names the missing consent subfields. This is
  what `recordBlocked` exists for; without it the screen just returns to the product list.

## 6. Edge cases, and what each one must do

| Id | Case | Required behaviour | Why it bites |
|---|---|---|---|
| E1 | Partial consent binding | Report the SDK's own message, naming the missing subfields | Silent return to products is indistinguishable from a dead tap |
| E2 | Blank `userDetails` for bound fields | Never; pass `null` | Silences the SDK's per-field errors (§2.2 (a)) |
| E3 | Enhanced KYC + bound consent | `screens { processing { } }` alone must run | Narrowest legal flow; the one that broke |
| E4 | Session expires between form and SDK entry | Existing gate: route to the scanner, not a form | No form holds a token |
| E5 | 401 refresh drops a binding | Out of the host's control; document it | Body was reduced against the *original* token, so the retry submits a gap and the server 400s |
| E6 | Settings "Consent screen" off, token unbound | Omit the screen; supply nothing. **Corrected 2026-08-25** — the premise below was wrong | Omitting both builds and runs. §2.1 requires one or the other only when the screen is declared |
| E7 | ID number is a vault reference | Passes the non-blank check; never display or log it as an ID number | It is credential-adjacent |
| E8 | Token minted for another partner | `partnerId` from the token wins over the active profile | Already fixed; a mismatched id 401s |
| E9 | SmartSelfie products | No ID form ever; `bindsIdDetails` returns true | `needsIdDetails` is false |
| E10 | Offline mode | Treat every binding as absent | SDK skips token decoding, keeping strict legacy validation |
| E11 | Consent bound *and* a local consent screen wanted | Not supported; do not bind consent | PR #336: token data always wins |

## 7. Tests

**Unit — the truth table, and this is the load-bearing one.** `flowPlan` is pure, so enumerate rather
than sample: {consent absent, complete, partial} × {user details: none, names only, contact only,
names+contact} × all six products, asserting all four plan fields. That is the test that would have
caught the original bug in seconds, on a laptop, with no token and no device.

**Unit — pinned to the SDK, not to our reading of it.** The existing pattern already asserts our
mirror rules against the SDK's public `validateUserDetails`. Extend it to consent: for each row of the
table, build the real `UseSmileIDFlowBuilder` from the plan and assert `validate()` returns `Valid`.
This is the check that fails if the SDK's rules move under us — which is exactly what happened when
#336 landed and the sample did not notice.

**Golden.** The user-details form at each distinct gap: all four rows editable, names-only editable,
contact-only editable, and the fully-bound state where the form is not shown at all. Light and dark.

**Device (Maestro).** The mint controls already toggle `Binds consent` and `Binds details`, so all
four owner-named cases are drivable without a Portal token. One block each, asserting on which screens
appear — `sample_user_details_screen` present or absent, `si_consent_screen` present or absent. The
consent-bound journey was previously avoided here as an "SDK defect"; that constraint is gone.

**What none of these prove.** A locally minted token is not server-issued, so every device case ends at
a 401 rather than a verdict. Confirming a real submission still needs a Portal token and a manual run.

## 8. The three questions, answered

Raised with the owner on 2026-08-20 and deliberately deferred: a four-platform contract is cheaper to
get right after one implementation than before it. All three are now closed, and deferring them was
the right call — one of the answers came from the code rather than from a decision, and it corrected
this document.

| Q | Question | Answer |
|---|---|---|
| Q1 | **Case 1 lands straight on the SDK's processing screen for Enhanced KYC.** Host confirmation step, or is abrupt the honest depiction of a fully-bound token? | **Ship abrupt** (owner, 2026-08-27). That is how Enhanced KYC works and it is documented; the builder already composes it. No host screen is added, on any platform |
| Q2 | **When "Consent screen" is off and the token is unbound, where does `consentInformation` come from?** | **Nowhere — it is omitted** (settled in code, 2026-08-25). Consent is include-or-omit and a token binding wins over both; the Settings row says so when the token has taken the decision away. No fixture content was invented and the toggle stays enabled |
| Q3 | **Should the sample warn on E11** — a token binding consent while the partner also shows their own consent UI? | **No warning** (owner, 2026-08-27). Partners are guided on how to configure these cases, so the sample does not build a diagnostic for something the SDK considers legal. Documented in §6 and left there |

**Q2's answer falsified E6.** This document claimed §2.1 required either the consent screen or
`consentInformation`, so omitting both would fail the build. It does not: the requirement only binds
once the screen is declared. E6 is corrected above, and the "five dead Settings toggles" it was said
to block all shipped.

## 9. Parity

The bindings contract is identical in all four SDKs, so the decision table is too. The pure function
should land with the same name and the same four fields in each host, and the truth table should be the
same enumeration — that is what keeps a fix in one from being re-derived from scratch in the others.
