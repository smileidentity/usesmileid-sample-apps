# A token before every run

**Status:** in progress. Three pull requests, in order: the entry gate (§3), the profile inputs (§4), then
the partner's own product configuration (§5). This file is deleted by the last of them.

## 1. The problem

- **A run can start with no token.** The gate before the SDK only asks for a new token when a session has
  *expired*. With no session at all it passes, and the flow builder falls back to the synthetic fixture
  token the refresh scenarios use. The server rejects that token, so the run fails late.
- **The token is asked for too late.** The gate runs just before the SDK mounts, after the person has
  filled the forms. The Enhanced Document Verification form needs a token earlier: the countries it can
  offer depend on the partner (§5), and only a token says who the partner is.
- **Simulate fires on its own.** "Simulate a successful scan" sits under the nav bar's Token button. Tap
  Token twice and the second tap lands on Simulate while the scanner is still sliding in (reproduced on
  Android, 2026-09-30).
- **Profile inputs.** Email and phone fields use the default keyboard, and an email that is not an email
  is accepted, then fails the job.

## 2. Decisions

- **D1. Every product needs a live session before its first step.** A product tap with no live session
  opens the scanner. Simulate still reaches every screen without a real partner, so nothing becomes
  unreachable.
- **D2. The resume goes to the product's first step, not the SDK.** Bindings decide which forms show, and
  a new token can bind different fields, so the first step is worked out again after the scan.
- **D3. The expiry gate stays.** A token can run out while someone fills the forms; the SDK-entry gate
  keeps sending that run to the scanner.
- **D4. The fixture token is for scenarios only.** The refresh scenarios (`expiredToken`, `badRefresh`)
  keep using it, because a scanned token has no refresh journey. No other run reaches the builder without
  a session.
- **D5. The scan sheet ignores taps until its entry transition ends.** On Android that is the back-stack
  entry reaching `RESUMED`; the other platforms use their own transition-end signal.
- **D6. The portal link is a phrase, not a URL.** A raw URL breaks mid-word on the narrowest phone at the
  largest type. The caption gains one line, "Get a v3 token from the Smile ID Portal, under Security
  settings.", with "Smile ID Portal" opening `https://portal.usesmileid.com/security-settings` in the
  system browser, which holds the Portal sign-in. The link is the same for sandbox and production.

## 3. Pull request 1: the entry gate

- A product tap with no live session records the run and opens the scanner (D1).
- A scan that links a session resumes at the product's first step (D2).
- The SDK-entry gate treats "no session" as it treats "expired" (D3, D4).
- The scan sheet's tap guard (D5) and the portal line (D6).
- Device flows that tap a product with no session link one first.
- `docs/token-session.md` describes the new gate.

## 4. Pull request 2: profile inputs

- Email and phone fields in the new-profile sheet and the user-details form set the platform's email and
  phone keyboards.
- An email must be `local@domain.tld` shaped before Continue enables; the field says why.
- Phone gets a basic shape check (`+`, then 7 to 15 digits). The per-country pattern arrives in §5.

## 5. Pull request 3: the partner's product configuration

`GET /v3/services/config`, authenticated with the session's token, lists the ID types the partner has
enabled per product and country, and the input rules per ID type (`field_type`, `regex`).

- The Enhanced Document Verification country and document lists come from
  `products.enhanced_document_verification`, fetched once per session in the token's environment. A
  scan from the form's own token button refetches them for the new session.
- A 401 or 403 names the reason on the form instead of showing an empty list.
- Once a country and ID type are picked, the user-details form applies that ID type's phone and email
  rules.
