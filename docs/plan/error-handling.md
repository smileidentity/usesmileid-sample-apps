# Friendly errors: the screen and its actions

Status: done. The table, the resolver and the banner on verification details are in all four apps. The
actions are not wired as buttons, by decision: see section 3.

## 1. The problem

A run that fails lands on verification details with no job. A release build shows "No verification
here" there, and a debug build adds the result card with the SDK's raw error. A job that ends in
`error` or `block` shows its badge and the server's message as it came. Neither tells the user whether
the problem is theirs to fix.

Partners copy these apps as the reference integration, so they copy that handling too.

## 2. What is done

- `spec/error-handling.json` holds each failure's message, action, delays and limits as data.
- Each app's `sample-ui` resolves an HTTP status, a transport failure or a result `reason` to a row.
- A unit test in each app asserts its table against the spec, row for row and case for case.
- The messages and button labels are in `spec/l10n/app/`, in the four languages.
- Each app maps a failure the SDK hands `onResult` to its row, and keeps the row with the run's
  result: a refused submission by its HTTP status and the server's message, a timeout and a lost
  connection as transport failures, and no row for a failure no submission returned. A new run, or
  one the app refuses to start, clears it. The result card is unchanged.

- Verification details shows the row's message as a banner: in place of "No verification here" for a
  run that failed, and under the badge for a job that ended in `error` or `block`. The result card
  stays, because the error still has to reach the host app. The states, the id, goldens in light and
  dark and the font-scale predicate are in `spec/` and each app.

[Handling errors](../error-handling.md) describes all of it.

## 3. Decided: no buttons

The banner states the failure and offers no action. Running the actions from the app's screen would
start a new capture under a token that lasts 15 minutes, which the products tab already does, and the
SDKs already offer the retry that matters: their processing screen resends the same images with delays
and limits by error code, and asks for a refused token again through `onTokenExpired`. Delays, use
counts and offline dimming in the app are dropped with the buttons.

## 4. Open questions

1. Try again cannot send the same images again. The SDK deletes a run's images when its flow ends, and
   only the SDK's own processing screen can resubmit them, with its Retry button, before the failure
   reaches the app. From the app's screen, Try again has to capture again. Decided: the SDKs own the
   retry of the same images. Their processing screen now offers Retry only for a failure a retry can
   get past, and the delay and the limit by error code follow there. The app offers no Try again of its
   own.
2. `GET /v3/status/{jobId}` returns no `reason`. Until it does, or an app has a backend that passes the
   webhook on, a job that ends in `error` or `block` resolves as the fallback and shows "We couldn't
   verify your identity." The recapture, fix-input and retry rows for a result are tested but
   no app reaches them.
3. Two 403 causes have no documented response text: a refusal by a security rule, and a token rejected
   after the flow began. Which text identifies each?
4. A 408 is not in the table, so it resolves as the fallback and ends in Close. Should it resolve as a
   timeout?
5. "We couldn't start this verification. Please try again, or contact the app's support." takes the error
   tone. Should the message drop "Please try again"?
