# Friendly errors: the screen and its actions

Status: the table and the resolver are in all four apps. The screen that uses them is not built.

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

[Handling errors](../error-handling.md) describes all of it.

## 3. What is left

Each item is one pull request on all four apps, in this order.

1. Keep what the resolver needs from a failed run. The shell records the failure's HTTP status, or
   that it was a timeout or a lost connection, beside the text the result card already shows.
2. Show the message and the action on verification details: in place of "No verification here" for a
   run that failed, and under the badge for a job that ended in `error` or `block`. The result card
   stays, because the error still has to reach the host app.
3. Run the actions:
   - Try again and Retake photo start the product's flow again with the same details.
   - Edit ID number opens the ID form, and Continue there starts the flow.
   - Start again opens the scan sheet for a new token, then starts the flow.
   - Close leaves the screen.
4. Dim the button for the row's delay, with the seconds left in the label and in what a screen reader
   announces, and enable it when the delay ends. Count uses, and replace the button with Close at the
   limit.
5. Add the states to `spec/screens.json`, the ids to `spec/test-ids.json`, goldens in light and dark,
   and the font-scale predicate for the longest message.

## 4. Open questions

1. Try again cannot send the same images again. The SDK deletes a run's images when its flow ends, and
   only the SDK's own processing screen can resubmit them, with its Retry button, before the failure
   reaches the app. From the app's screen, Try again has to capture again. Is that acceptable, or should
   the delay and the limit move into the SDK's screen?
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
