---
description: How the sample apps turn a failed verification into one short message and one action — the two kinds of failure, the table in spec/, what the resolver returns, and what an app cannot tell apart.
---

# Handling errors

A verification can fail when it is submitted, or after Smile ID has accepted it. The sample apps resolve
either failure to one short message and one action, from a table held as data in
[`spec/error-handling.json`](../spec/error-handling.json).

This page covers the table, the resolver each app builds from it, and the banner that shows the message
and runs the action. [The plan](plan/error-handling.md) has what is left.

## Prerequisites

- Any of the four apps, built from this repository.
- A flow that hands its result to `onResult`, as each app's shell does.

## 1. The rules the table follows

- Show your own text, never the server's. A server message is written for developers and can name a
  provider. The apps use it only to tell two rows apart, and never show it.
- Explain only what the user can fix: photo quality, a mistyped ID number, the connection, an expired
  session, an out-of-date app.
- Give every security, fraud and compliance outcome the same message, "We couldn't verify your identity."
  A different message for each tells a bad actor which check they failed.
- Offer one action. Do not offer a retry that fails the same way: show the message and Close.
- Never retry for the user. A retry is a button the user presses.

## 2. Two kinds of failure

| Failure | Where it arrives | What it carries |
|---|---|---|
| Refused at submission | `onResult`, as a failure | The HTTP status and the server's message, on the SDK's `NetworkServerException` |
| No answer | `onResult`, as a failure | A timeout or a connection failure, as the SDK's exception type |
| Failed after acceptance | The webhook your backend receives, which it passes to the app | A `status` of `error` or `block`, a `reason` and a message |

`GET /v3/status/{jobId}`, the one request the sample apps make themselves, returns the status without the
`reason`. An app that has no backend to pass the webhook on cannot pick a row for a failed job, and
resolves it as the fallback.

## 3. The table

| Section | Holds |
|---|---|
| `actions` | The six actions, each with its button's string key and, where it has one, a limit |
| `submission` | One row for each failure at submission, matched on `status` or `transport` |
| `result` | One row for each failure after acceptance, matched on `reasons` |
| `fallback` | The row a status or reason the table does not name resolves as |
| `notDistinguished` | The causes an app cannot tell from another row, and the row each resolves as |
| `cases` | Failures with the row each must resolve as, which every app's test runs |

Rows are tried in order and the first match wins. Several causes share one status or reason, and the
API's error body has no code to tell them apart, only a message. A row with `serverMessageContains` also
needs that message to contain one of its entries, ignoring case, so it sits above the plain row for the
same status or reason.

Every `message` and `button` is a key in `spec/l10n/app/`, so each has a string in every language the
apps ship.

### Actions and limits

| Action | Button | What it does | Limit |
|---|---|---|---|
| `retry` | Try again | Runs the verification again as a new job | The row's `maxUses` |
| `retryLater` | Try again | The same, with a longer delay and a single use | The row's `maxUses` |
| `recapture` | Retake photo | Restarts capture, then submits a new job | Three in a session |
| `fixInput` | Edit ID number | Returns to the ID form | None |
| `newSession` | Start again | Takes a new token and restarts the flow | One for each error |
| `exit` | Close | Ends the flow | None |

A row's `backoffSeconds` is how long the button stays dimmed before each use, in order: a server error
waits 5 seconds before the first use, 15 before the second and 30 before the third. A use past the
last entry waits the last entry again, so a timeout, which has one entry and no limit, waits 5 seconds
before every use. `waitsFor: connection` keeps the button dimmed while the device is offline. When a
limit is reached, Close replaces the button.

## 4. The resolver

Each app holds the table in code and resolves a failure with three lookups. A unit test reads
`spec/error-handling.json` and fails when a row, a case, an action or a string differs.

| Platform | Types, in `sample-ui` | Table and lookups, in `sample-ui` |
|---|---|---|
| Android | `model/UseSmileIDSampleErrorResolution.kt` | `state/UseSmileIDSampleErrorHandling.kt`: `forStatus`, `forTransport`, `forReason` |
| iOS | `Model/UseSmileIDSampleErrorResolution.swift` | `State/UseSmileIDSampleErrorHandling.swift`: `forStatus`, `forTransport`, `forReason` |
| Flutter | `model/use_smileid_sample_error_resolution.dart` | `state/use_smileid_sample_error_handling.dart`: `forStatus`, `forTransport`, `forReason` |
| Expo | `model/use-smile-id-sample-error-resolution.ts` | `state/use-smile-id-sample-error-handling.ts`: `smileIDSampleErrorForStatus`, `smileIDSampleErrorForTransport`, `smileIDSampleErrorForReason` |

A lookup returns a resolution:

| Field | Holds |
|---|---|
| `id` | The row's id in the table |
| `message` | The message to show, by its string key |
| `action` | The one action to offer |
| `backoffSeconds` | How long the button stays dimmed before each use |
| `maxUses` | How many times the action is offered; the row's limit, or its action's, or none |
| `waitsForConnection` | Whether the button also stays dimmed while the device is offline |

## 5. The banner

Verification details shows a failure as a banner: the design system's banner on the card surface, with
an accent bar and glyph, the message, and the row's action under it.

| Visit | What it shows |
|---|---|
| A run that failed with no job | The product's name, then the banner in place of "No verification here" |
| A stored job that ended in `error` or `block` | The banner under the status badge |
| Any other visit | No banner |

- The tone is warning, with a filled button, while the action can get past the failure. A row whose only
  action is Close takes the error tone, and Close is a text action.
- On a stored job the banner has no Close: the app bar's back already leaves the page.
- A run that failed before any submission explained it, such as a camera that could not start, shows the
  submission fallback: the message for a request the table does not name, and Close.
- The result card stays under the banner in debug builds, so the SDK's own error is still on screen.

Each action reuses the run the app already knows how to start:

| Action | Goes to |
|---|---|
| Try again, Retake photo | The product's flow, past the forms, as a new job |
| Edit ID number | The ID form, whose Continue starts the flow |
| Start again | The scanner for a new token, then the flow |
| Close | The products tab |

The shell records the product each run starts, so an action knows what to run again. The mapping is
`UseSmileIDSampleErrorMove` in each shell, and `sample_error_banner` and `sample_error_action` are the ids
a flow asserts on.

## 6. What an app cannot tell apart

- Two causes of a 403, a refusal by a security rule and a token rejected after the flow began, have no
  documented response text. Both resolve as the plain 403 row, which ends in Close.
- A status or a reason the table does not name resolves as the fallback: a message that names nothing,
  and Close.

## 7. Automatic retry

The SDK does not retry a request by itself. Its `retry` block's `strategy` is none unless an app sets
it, on all four platforms, and no sample app sets it. So the banner's Try again is the only retry.

## Related

- [Token sessions](token-session.md) for where a new session comes from.
- [Localisation](localisation.md) for how the messages are translated.
- [`spec/README.md`](../spec/README.md) for the other files in the contract.
