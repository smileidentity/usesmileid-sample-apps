# Friendly errors: the screen and its actions

Status: the table, the resolver and the banner on verification details are in all four apps. The
button's delays and limits are not.

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
- Verification details shows the row as a banner, for a run that failed with no job and under the badge
  of a job that ended in `error` or `block`, and its action runs: Try again and Retake photo start the
  product's flow again, Edit ID number opens the ID form, Start again opens the scanner, Close leaves.
  A run that failed before any submission explained it shows the submission fallback. The states, ids and
  goldens are in `spec/` and each app.

[Handling errors](../error-handling.md) describes all of it.

## 3. What is left

Dim the button for the row's delay, with the seconds left in the label and in what a screen reader
announces, and enable it when the delay ends. Count uses, and replace the button with Close at the limit.
One pull request on all four apps.

## 4. Open questions

1. Try again cannot send the same images again. The SDK deletes a run's images when its flow ends, and
   only the SDK's own processing screen can resubmit them, with its Retry button, before the failure
   reaches the app. From the app's screen, Try again has to capture again. Decided: the SDKs own the
   retry of the same images. Their processing screen now offers Retry only for a failure a retry can
   get past, and the delay and the limit by error code follow there. The app's Try again starts a new
   capture.
2. `GET /v3/status/{jobId}` returns no `reason`. Until it does, or an app has a backend that passes the
   webhook on, a job that ends in `error` or `block` resolves as the fallback and shows "We couldn't
   verify your identity." with Close. The recapture, fix-input and retry rows for a result are tested but
   no app reaches them.
3. Two 403 causes have no documented response text: a refusal by a security rule, and a token rejected
   after the flow began. Which text identifies each?
4. "Dimmed while offline" needs the app to know when the device is back online. Android and iOS can ask
   the system. Flutter and Expo each need a new dependency for it. Without one, the button stays enabled
   and a press while offline fails with the same message.
5. A 408 is not in the table, so it resolves as the fallback and ends in Close. Should it resolve as a
   timeout?
6. "We couldn't start this verification. Please try again, or contact the app's support." is shown with
   Close and no retry. Should the message drop "Please try again", or the row offer one?
7. A timeout and a lost connection have no limit, so Try again is offered for as long as they keep
   failing. Should each have one, as a server error has three?
