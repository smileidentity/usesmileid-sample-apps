# Flutter and Expo port: review findings

A multi-perspective review was run over each port's merged diff (`016932c..main`) after the fact,
because the review step was skipped on several of the twelve port PRs. Flutter: 37 findings, 31 after
deduplication. Expo: 30 findings, 25 after deduplication. One critical, sixteen major, none discarded.

**How to read the status column.** `verified` means the claim was checked against the code or
reproduced, by someone other than the reviewer that raised it. `asserted` means it is the reviewer's
finding and plausible, but nobody has re-checked it — treat the effort estimate as soft. Both reviews
ran three same-model passes, so agreement between passes is weaker evidence than it looks; neither
dispatched a cross-model pass, because that would have sent this repo's source to a third-party vendor.

## 1. Already fixed

| # | Finding | Status |
|---|---|---|
| 1 | Back threw `GoError: There is nothing to pop` on the consent form, the ID form and the profiles list. All four handlers now navigate explicitly, matching the nested routes' existing pattern | verified, reproduced on all three routes, regression test proved to red |
| 2 | Removal copy lived in the Expo shell, so four shells could word it differently | verified, moved to `sample-ui` |
| 3 | The consume-once contract behind the removal confirmation had no test | verified, four tests added |

## 2. Verified and open — highest value first

| # | Finding | Where | Why it matters |
|---|---|---|---|
| 4 | Row test ids are indexed against the **unfiltered** list, so under any filter they name different rows than Android and iOS, which index the visible list | `expo/sample-ui/src/screens/verifications-screen.tsx:170` | Breaks the shared id contract device automation asserts on. Android states the contract in a comment at `VerificationsScreen.kt:132` |
| 5 | Sign out is a no-op; the previous person's name, email and phone stay in the forms store and seed the next consent form | `expo/app/app/(tabs)/settings.tsx:54` | A spec'd destructive affordance that does nothing. The only `.clear()` in production code is `inFlight.clear()`, unrelated |
| 6 | The dark mode setting is written to storage, drawn as a switch, and never read — the theme comes entirely from `useColorScheme()` | `expo/app/app/_layout.tsx:24` | A user-visible control that does nothing. Invisible to tests because `render-in-theme.tsx` passes `dark` straight into the provider |
| 7 | `seedJobs` and `seedFixtures` reach nothing, and `noticeWindow`'s provider is mounted nowhere | `expo/sample-ui/src/data/use-smile-id-sample-job-store.ts:198` | With no flow host either, the Expo verifications list **can never hold a row on a device**, so its filters, select mode and removal have nothing to act on |
| 8 | The **truncation** half of the text-scale predicate cannot fail. `didExceedMaxLines && maxLines != 1` excludes exactly the paragraphs able to report, because every `maxLines` in the app is `1` or `null` | `flutter/sample_ui/test/golden/golden_harness.dart:220` | A different half of the function repaired earlier — that repair covered `split`, not `truncated`. A sheet header truncating at 2x is live and undetectable |
| 9 | The app bar's back control and title **merge into one semantics node** inside a screen's `Semantics(identifier:)` wrapper | `flutter/sample_ui/lib/src/screens/use_smileid_sample_profiles_screen.dart:57` | The component-level fix works in isolation; in situ the screen wrapper absorbs it again. Found while writing finding 1's test, reported by neither reviewer |
| 10 | The Expo shell ships the stock tab bar and never mounts the designed floating nav bar, which exists in `sample-ui` with zero call sites | `expo/app/app/(tabs)/_layout.tsx:9` | Flutter mounts its floating bar; Expo mounts it zero times. The file's comment stages this for "U2", so it was a decision — but it is now an undocumented divergence between the two new apps |
| 11 | 74 multi-paragraph doc comments break the one-line rule, across 57 files | repo-wide | A retrospective trim missed them: its pattern required `///` plus content, and a bare `///` separator line broke the run |
| 12 | The clearance test added yesterday sweeps five text scales against **one** tab root | `flutter/sample_ui/test/use_smileid_sample_nav_bar_clearance_test.dart` | The bar's height depends on the selected tab's label, which is the term the fix was about. My own test, and the reviewer caught it |

## 3. Asserted, not yet re-checked

Grouped by the pattern they share, because the patterns matter more than the individual items.

**Tests that cannot fail, or assert something other than their name.** The settings-footer spec test
asserts the spec against a literal copy of itself; the test-id spec test asserts the set in one
direction so it cannot fail on an omission (true on Android too); the URL-scheme test never asserts its
"and only that one" clause; the 23-hour-day test passes with the buggy implementation it forbids; the
test named for the cold-start link exercises a parser the cold start never calls; the filter-fallback
test, the go-pill test, and a licence test that never opens a row; and a golden-pairs theme test that
compares two palette constants rather than the provider.

**Built, then never wired.** Four Settings rows are dead — any nav row carrying a URL does nothing;
the Flutter sign-out row is inert with its `clear()` uncalled; copy buttons on the Expo detail page are
wired to a no-op; nine scenario description strings are unread and have already drifted from the spec;
two token-ring exports have no consumers; `UseSmileIDSampleStatus.role` is read by no production code.

**Cold start and deep link.** A cold deep link to a stored verification paints the empty state on the
first frame (Flutter) and never loads the store at all (Expo); the profile store is reset a second time
when the cold-start URL resolves; the settings store's `loaded` flag is never read, so a write during
the load window is silently undone.

**Duplication that will drift.** Two sources of truth for the same four field labels, with the two
screens already disagreeing; eleven call sites rebuilding radii inline; `FontWeight.values[...]`
open-coded in four places; the controller-sync block copy-pasted into three widgets, comment included;
the avatar hue formula reimplemented beside the helper that owns it; the trademark re-typed rather than
taken from the constant that holds it.

**Parity divergence with the two originals.** Both Flutter pickers are presented as partial sheets
though the spec declares them `fullSheet`; the Expo empty-state copy diverges from all three siblings;
the DEBUG section ships in release builds on Flutter only; four Expo weight overrides bypass `atWeight`
and render the wrong face.

**Correctness and robustness.** `spec/screens.json:456` contradicts its own owner ruling recorded at
line 683 of the same file; `continueEnabled` ignores the test id it is given and reads whichever button
is last; a `WidgetRef` is used across an await after the caller has navigated away; AsyncStorage
failures are unhandled and a failed load strands the list; the refresh notice is never withdrawn so its
toast covers the page permanently; Settings reserves nav-bar clearance twice and the second does not
scale; the wrapped profile-row layout drops the selected check the Row layout draws; `isComplete` is a
second, contradicting completeness rule only a test exercises; the memory store breaks the `read()`
ordering contract the real store honours; the verifications list builds every row eagerly and scans the
job list five times per build; the licences screen mounts all 74 rows and their SVGs at once.

## 4. Rejected, with the reasoning

Kept so nobody re-opens them.

- **`consumeRemoval` read-write race.** The claim was that two consumers in one tick double-consume,
  latent until the function gained a caller. The function is fully synchronous — no await between the
  read and the write, no async middleware on that path — and JavaScript does not preempt synchronous
  code, so the second call always observes the first's write. The fix was written and reverted before
  shipping; a comment asserting a race that cannot happen is worse than no comment.
- **The notice overlay's missing `left`/`right`.** The host component already sets `width: '100%'`, and
  the identical pattern is merged in `profiles/index.tsx`. Fixing one call site would diverge from its
  sibling; if explicit insets are wanted they belong in the host, not duplicated at two call sites.

## 5. What the five patterns say about the next port

The individual findings are cheap to fix. The patterns are what to change:

1. **A test's green says nothing until you know what it exercises.** Twelve of these are tests that
   cannot fail. Three separate mechanisms produced them: a predicate narrowed until every case is
   exempt, a one-directional set assertion, and a fixture asserted against a copy of itself.
2. **A component's test passing says nothing about the component in its caller.** Three instances:
   the app bar's semantics, the products fixture, and the clearance test's single tab root.
3. **Wiring is the step that gets skipped.** Eleven affordances exist, are spec'd, are tested, and
   reach nothing. Every one was found by looking for callers, not by reading the code.
4. **Cold start and deep link are where state management fails**, and neither is on the default path a
   widget test takes.
5. **Copy and constants drift within days**, not months — the two ports already disagree with each
   other and with the originals in five places.
