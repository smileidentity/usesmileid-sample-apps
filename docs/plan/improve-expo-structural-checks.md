# Improve plan: give Expo the two structural checks Flutter has, and fix what they find

> **Executor instructions**: Follow this plan step by step. Run every verification command and
> confirm the expected result before moving to the next step. If anything in the "STOP conditions"
> section occurs, stop and report — do not improvise. When done, update this plan's row in
> `docs/plan/improve-plans-index.md`.
>
> **Drift check (run first)**:
> `git diff --stat 00834b2..HEAD -- expo/sample-ui/src expo/sample-ui/test expo/app`
> If any in-scope file changed since this plan was written, compare the "Current state" excerpts
> against the live code before proceeding; on a mismatch, treat it as a STOP condition.

## Status

- **Priority**: P2
- **Effort**: M
- **Risk**: LOW
- **Depends on**: none
- **Category**: tests (plus one accessibility bug the second check finds)
- **Planned at**: commit `00834b2`, 2026-09-18

## Why this matters

Four sample apps in this repo are held to one contract. Two **structural checks** — checks that
assert a property of the code rather than of a rendered picture — exist on Flutter and on no other
platform:

1. **Every declared accessibility id is actually attached to something.** Flutter's is
   `flutter/app/test/use_smileid_sample_test_id_call_sites_test.dart`, 38 lines; iOS has the same
   check as `TestIdUsageTest`, and Android and Expo have none. It exists because
   a declared id can sit in the spec, pass the spec test, and be set on no widget at all: the spec
   test asserts the *other* direction, and a screenshot cannot see an accessibility id. The first
   thing to find such an id is a device flow keying off the spec, at which point it looks like a
   spec error rather than a missing call site.
2. **A container must not absorb its children's semantics, and traversal order must follow visual
   order.** Flutter's is `flutter/sample_ui/test/state/use_smileid_sample_top_app_bar_semantics_test.dart`.
   It exists because Flutter's app bar collapsed into a single node labelled `Back` then the title,
   flagged as a button — so a screen reader announced the title as part of the back control and
   neither could be reached alone. **The fix moved no pixel and no golden changed**, which is
   exactly why it needs its own test rather than a look.

`docs/plan/port-gaps-backlog.md` §2 and §7 record both checks as owed by **Android and iOS**. They
do not mention Expo, because Flutter wrote them and the Expo tranche had already landed. Expo has
neither.

Running check 1 against Expo by hand while writing this plan found **9 of its 103 declared ids
attached to nothing** in `expo/sample-ui/src` or `expo/app`. Six of the nine are already-recorded or
deliberate absences; three need a ruling. The value is not the nine — it is that Expo has no
mechanism that would ever have told anyone, and the next one will be a live defect rather than a
known absence.

Reading Expo's app bar for check 2 found a live divergence: **Expo's title carries no header role**,
where Flutter's does and Flutter's test asserts it. On a pushed screen a screen-reader user gets no
heading to navigate by.

## Current state

### The files

- `expo/sample-ui/src/use-smile-id-sample-test-ids.ts` — the declarations. 103 constants in
  `UseSmileIDSampleTestIds`, plus 19 helpers in `UseSmileIDSampleSuffixedTestIds`, each of which
  builds `${UseSmileIDSampleTestIds.<BASE>}_${value}`.
- `expo/sample-ui/test/use-smile-id-sample-test-ids-spec.test.ts` — the existing spec test. It
  already asserts the set **both ways** against `spec/test-ids.json` (lines 15–21), so the gap is
  not there. It never asks whether an id is attached to anything.
- `expo/sample-ui/src/components/use-smile-id-sample-top-app-bar.tsx` — the app bar.
- `expo/sample-ui/test/render-in-theme.tsx` — the render helper every component test uses. Exports
  `renderInTheme(element, dark, fontScale)`.
- `expo/sample-ui/test/use-smile-id-sample-composites.test.tsx` — an existing component test,
  the structural pattern to follow.
- `expo/sample-ui/jest.config.js` — `roots: ['<rootDir>/test']`, so a new test file goes in
  `expo/sample-ui/test/`.

### The Flutter checks to port

`flutter/app/test/use_smileid_sample_test_id_call_sites_test.dart`, in full — the mechanism is
three moves: read the declarations, read every source file in **both** packages, assert each
declared name appears somewhere other than its own declaration:

```dart
/// Every id `sample_ui` declares is actually rendered by something.
void main() {
  test('every declared id is referenced by a screen, component or host', () {
    final File declarations = File('../sample_ui/lib/src/use_smileid_sample_test_ids.dart');
    final Iterable<String> names = RegExp(r'static (?:const String|String) (\w+)')
        .allMatches(declarations.readAsStringSync())
        .map((RegExpMatch it) => it.group(1)!);
    expect(names, isNotEmpty, reason: 'the declarations could not be read');

    final String callers = <Directory>[Directory('lib'), Directory('../sample_ui/lib')]
        .expand((Directory it) => it.listSync(recursive: true))
        .whereType<File>()
        .where((File it) => it.path.endsWith('.dart') &&
            !it.path.endsWith('use_smileid_sample_test_ids.dart'))
        .map((File it) => it.readAsStringSync())
        .join('\n');

    expect(
      names.where((String name) =>
          name != 'all' && !callers.contains('UseSmileIDSampleTestIds.$name')),
      isEmpty,
      reason: 'declared, specified, and attached to nothing',
    );
  });
}
```

**Why it spans both packages** (`docs/plan/port-gaps-backlog.md` §2): a sheet's id is supplied by
whichever host *presents* the sheet, and only a host sees both halves — scoped to the shared UI
package alone it reports four false positives. On Expo the two packages are `expo/sample-ui/src` and
`expo/app`.

`flutter/sample_ui/test/state/use_smileid_sample_top_app_bar_semantics_test.dart` asserts three
things (`docs/plan/port-gaps-backlog.md` §7 — "Assert all three. A platform can carry one failure
mode without the other"):

1. **With no trailing action**, back and title are two separate nodes, in that order — the first a
   button, the second a header and *not* a button.
2. **With a trailing action**, all three are separately reachable and in visual order.
3. **No node's label contains a newline.** That is the collapse's signature: merged labels arrive as
   `'Back\nTitle'` on one node, so it catches the shape without naming the strings.

### The Expo app bar as it exists today

`expo/sample-ui/src/components/use-smile-id-sample-top-app-bar.tsx:80-115` — the back control has
`accessibilityRole="button"` and a label (set inside `UseSmileIDSampleTopAppBarButton`, lines
38–40), and **the title `<Text>` has no accessibility role at all**:

```tsx
      <View style={[styles.row, { minHeight: rowHeight, columnGap: theme.dimens.spacing.xs }]}>
        <UseSmileIDSampleTopAppBarButton
          accessibilityLabel={backAccessibilityLabel}
          onPress={onBack}
          emphasis="Filled"
          glyph={(tint) => <UseSmileIDSampleIcon name="arrowBack" tint={tint} />}
        />
        <Text
          // Wraps rather than caps: ellipsising a title is the clipping the predicate forbids.
          style={[
            theme.type.textStyleTitle,
            styles.title,
            { fontSize: TITLE_SIZE, color: theme.colors.textTitle },
          ]}
        >
          {title}
        </Text>
        {/* Holds the action's width even with no action, so the title sits identically either way. */}
        {action ?? <View style={{ width: theme.dimens.space[40] }} />}
      </View>
```

### What check 1 finds on Expo today, and what each one is

Run by hand at commit `00834b2`. Nine declared constants are reached by nothing in
`expo/sample-ui/src` or `expo/app`, counting a base id as reached when a suffixed helper that builds
from it is used:

| Constant | Value | What it is |
|---|---|---|
| `HOME_START_FULLSCREEN` | `sample_home_start_fullscreen` | one of the two shell ids `docs/plan/port-gaps-backlog.md` §3 records as implemented by **no app** — owed feature or owed deletion, undecided |
| `HOME_START_SHELL` | `sample_home_start_shell` | the other of that pair |
| `SCAN_TOKEN_SCREEN` | `sample_scan_token_screen` | the QR scanner, deliberately absent from this repo |
| `TOKEN_ENVIRONMENT` | `sample_token_environment` | the token session, deliberately absent |
| `RESULT_CARD` | `sample_result_card` | shown after an SDK flow, which no app in this repo runs yet |
| `LICENSE_LINK` | `sample_license_link` | `docs/plan/port-gaps-backlog.md` §3: the second licences section exists only where the platform graph produces one, which Expo's does not |
| `SCENARIO_ITEM` | `sample_scenario_item` | the scenario drawer, which Expo does not mount |
| `THEME_ITEM` | `sample_theme_item` | the same drawer |
| `ENV_CHIP` | `sample_env_chip` | **implemented by no app at all** — a repo-wide grep finds it only in `spec/test-ids.json` and the four declaration files. A third entry of the kind §3 records two of |

None of these nine is a defect you should fix. They are the reason the check needs an **allowlist
with a written reason per entry** rather than a pass/fail on the raw set — which is also what keeps
the check non-vacuous, because anything not on the list fails.

### Repo conventions you must match

Quoted here because the executor has not read `AGENTS.md`.

- **"The doc comment is the documentation; inline comments are the exception."** Every type,
  function and non-obvious property carries a `///` doc comment of **one line**. An inline `//` is
  earned only by something the code cannot say. **No multi-line comments anywhere.**
- **TypeScript style**: this package uses `const` arrow functions for components and helpers,
  `readonly` on shared types, and named exports — see any file under `expo/sample-ui/src/components/`.
- **Test style**: `describe` / `it` with sentence-shaped names that say what is true, not what is
  called — see `expo/sample-ui/test/use-smile-id-sample-test-ids-spec.test.ts`.
- **Commits**: a single conventional-commit subject line, `type: summary`. No body, no attribution
  trailers. Example from `git log`: `fix: guard duplicate frame delivery`.

## Commands you will need

`expo/verify.sh` expects pnpm 9 and will exit 1 on anything else.

| Purpose | Command | Expected on success |
|---|---|---|
| Install | `cd expo && pnpm install --frozen-lockfile` | exit 0 |
| Lint | `cd expo && pnpm exec eslint .` | exit 0 |
| Typecheck (library) | `cd expo && pnpm --filter @smileid/sample-ui exec tsc --noEmit` | exit 0 |
| Typecheck (shell) | `cd expo && pnpm --filter usesmileid-sample-expo exec tsc --noEmit` | exit 0 |
| Library tests | `cd expo && pnpm --filter @smileid/sample-ui exec jest --ci` | all pass |
| One file | `cd expo && pnpm --filter @smileid/sample-ui exec jest --ci <name>` | that file passes |
| Full gate | `expo/verify.sh` | prints `OK` |

Do **not** run `expo/verify.sh native`; it needs an Android SDK and is out of scope.

## Scope

**In scope** (the only files you may modify or create):

- `expo/sample-ui/test/use-smile-id-sample-test-id-call-sites.test.ts` (create)
- `expo/sample-ui/test/use-smile-id-sample-top-app-bar-semantics.test.tsx` (create)
- `expo/sample-ui/src/components/use-smile-id-sample-top-app-bar.tsx` (step 3 only)

**Out of scope** (do NOT touch, even though they look related):

- **Every one of the nine ids in the table above.** Attaching any of them is a product decision, not
  this plan's work. They go on the allowlist with their reason. If you find yourself adding a
  `testID` to a component to make the check pass, stop — that is the wrong direction.
- **`spec/`.** `sample_env_chip` being implemented by no app is worth recording, but a spec change
  must land with four app-side updates and is a separate decision. Report it; do not make it.
- **`flutter/`, `android/`, `ios/`.** This plan brings Expo to Flutter's checks. Android and iOS owe
  the same two checks (`docs/plan/port-gaps-backlog.md` §2, §7) and are tracked there, not here.
- **Any golden baseline under `expo/sample-ui/test/goldens/`.** Step 3 adds an accessibility role,
  which does not change a style. If any snapshot changes, is written, or is reported obsolete, that
  is a STOP condition — a changed baseline means the change altered rendering and a human must read
  every changed mark.
- **The tab bar and the floating nav bar.** Whether Expo mounts the designed floating bar is
  `docs/plan/improve-expo-shell-wiring.md`'s step 6, not this plan.

## Git workflow

- Branch: `improve/expo-structural-checks`
- One conventional-commit subject line per step. No body, no attribution trailers.
- Do **not** push, open a PR, or run the `create-pr` skill.

## Steps

### Step 1: assert every declared id is attached to something

Create `expo/sample-ui/test/use-smile-id-sample-test-id-call-sites.test.ts`. It must:

- read `expo/sample-ui/src/use-smile-id-sample-test-ids.ts` from disk with `node:fs` and extract
  both the constant names in `UseSmileIDSampleTestIds` and the helper names in
  `UseSmileIDSampleSuffixedTestIds`, together with the base constant each helper builds from
- assert the extracted list is non-empty, with a reason saying the declarations could not be read —
  a regex that stops matching must fail the test, not silently pass it
- walk **both** `expo/sample-ui/src` and `expo/app`, recursively, collecting every `.ts`/`.tsx`
  file, excluding the declarations file itself and anything under `node_modules`, `.expo` or a
  `goldens` directory
- treat a constant as reached when the joined text contains `UseSmileIDSampleTestIds.<NAME>`, **or**
  when a suffixed helper whose base is that constant is itself reached as
  `UseSmileIDSampleSuffixedTestIds.<helper>`
- fail on any constant that is reached by neither and is not on an allowlist
- also fail on any suffixed **helper** reached by nothing and not on the allowlist

The allowlist is a `const` in the test file: an object mapping each of the nine constant names —
and the four unreached helpers `tokenEnvironment`, `licenseLink`, `scenarioItem`, `themeItem` — to a
one-line reason. Take the reasons from the table in "Current state" above. Add a second assertion
that **every allowlist entry is still unreached**, so an id that later gains a call site has to be
taken off the list rather than lingering as a permanent exemption.

Read `expo/sample-ui/test/use-smile-id-sample-test-ids-spec.test.ts` first — it shows how this
package reads a file from disk in a test and how its `describe`/`it` names are phrased.

**Verify**: `cd expo && pnpm --filter @smileid/sample-ui exec jest --ci call-sites` → passes.
Then prove it can fail: temporarily delete one entry from the allowlist, re-run, confirm it **reds**
naming that id; restore it. Then temporarily remove one *used* id's call site in a component,
re-run, confirm it reds; restore. (`docs/plan/port-gaps-backlog.md` §5: "delete the line it defends
and confirm the test notices".)

**Commit**: `test: assert every declared Expo test id is attached to something`

### Step 2: assert the app bar's controls stay separable

Create `expo/sample-ui/test/use-smile-id-sample-top-app-bar-semantics.test.tsx`, modelled on
`expo/sample-ui/test/use-smile-id-sample-composites.test.tsx` for its render idiom. Use
`renderInTheme` from `expo/sample-ui/test/render-in-theme.tsx`.

React Native's analogue of Flutter's semantics tree is the set of nodes carrying
`accessibilityLabel` / `accessibilityRole`, reachable from `@testing-library/react-native`'s
`toJSON()` tree or via `getAllByRole`. Walk the rendered tree and collect, for every node carrying
an `accessibilityLabel` **or** rendering text, a record of `{ label, role }`. Assert the three
properties:

1. **With no `action` prop**: exactly two accessible entries, in order — the back control labelled
   `Back` with role `button`, then the title `Verification details` with role `header` and **not**
   `button`.
2. **With an `action`**: three entries, in visual order — `Back`, `Verification details`, then the
   action's label.
3. **No entry's label contains a newline**, in both configurations. This catches a container that
   has absorbed its children without naming the strings; in React Native the cause would be
   `accessible={true}` on a wrapping `View`, which merges its descendants into one node.

Assert all three. A platform can carry one failure mode without the other — Flutter had the full
collapse only with no trailing action, and with one it still inverted traversal order, so a test
written against the with-action case alone would have passed while the common configuration was
broken.

Write the test **before** step 3 and confirm property 1 fails on the missing `header` role. If it
passes as written, the app bar already carries the role and step 3 is unnecessary — that is a STOP
condition, because this plan's premise would be wrong.

**Verify**: `cd expo && pnpm --filter @smileid/sample-ui exec jest --ci top-app-bar-semantics` →
**fails**, on the title's role.

**Commit**: `test: pin the Expo app bar's separable controls, currently red`

### Step 3: give the title its header role

In `expo/sample-ui/src/components/use-smile-id-sample-top-app-bar.tsx`, add
`accessibilityRole="header"` to the title `<Text>`. Nothing else changes — no wrapping `View`, no
`accessible` prop, no style.

The flag belongs on the **title**, not on the row. Flutter's defect was exactly the opposite
placement: `Semantics(header: true)` on the row's container absorbed its children
(`docs/plan/port-gaps-backlog.md` §7). Adding `accessible={true}` to the row here would reproduce
that defect on Expo, and property 3 of step 2's test is what would catch it.

**Verify**: `cd expo && pnpm --filter @smileid/sample-ui exec jest --ci` → **all** pass, including
step 2's file, with **no written or obsolete snapshots**. Then
`cd expo && pnpm exec eslint . && pnpm --filter @smileid/sample-ui exec tsc --noEmit` → both exit 0.

**Commit**: `fix: announce the Expo app bar title as a header`

### Step 4: run the gate

**Verify**: `expo/verify.sh` → prints `OK`.

No commit — this step only confirms.

## Test plan

| File | Cases |
|---|---|
| `expo/sample-ui/test/use-smile-id-sample-test-id-call-sites.test.ts` (create) | every declared constant is reached or allowlisted; every suffixed helper is reached or allowlisted; every allowlist entry is still unreached; the declarations parsed to a non-empty list |
| `expo/sample-ui/test/use-smile-id-sample-top-app-bar-semantics.test.tsx` (create) | no action: two entries, `Back` a button then the title a header and not a button; with an action: three entries in visual order; no label contains a newline, in both configurations |

Both falsification runs in step 1, and step 2's deliberate red before step 3, are part of the test
plan rather than optional. A green says nothing until you know what it exercises — twelve of the
findings in `docs/plan/port-review-findings.md` were tests that could not fail.

## Done criteria

All must hold:

- [ ] `expo/verify.sh` prints `OK`
- [ ] `cd expo && pnpm --filter @smileid/sample-ui exec jest --ci` passes with 2 new test files
- [ ] `grep -c "accessibilityRole=\"header\"" expo/sample-ui/src/components/use-smile-id-sample-top-app-bar.tsx` returns `1`
- [ ] the allowlist in the call-site test has exactly 13 entries (9 constants + 4 helpers), each
      with a one-line reason
- [ ] `git status --porcelain expo/sample-ui/test/goldens` is empty (no baseline re-recorded)
- [ ] `git status --porcelain` lists no file outside the In-scope list — in particular nothing under
      `spec/`, `flutter/`, `android/` or `ios/`
- [ ] this plan's row in `docs/plan/improve-plans-index.md` is updated

## STOP conditions

Stop and report — do not improvise — if:

- The code at any "Current state" excerpt does not match what you find.
- Step 2's test **passes** before step 3. The app bar would then already carry the header role and
  this plan's premise is wrong.
- The set of unreached ids you find differs from the nine in the table. A different set means the
  code moved since this plan was written, and each difference needs a ruling rather than an
  allowlist entry you invented.
- Making either check pass appears to require attaching a `testID` to a component, changing `spec/`,
  or touching `flutter/`, `android/` or `ios/`.
- Any snapshot under `expo/sample-ui/test/goldens/` changes, is written, or is reported obsolete.
- Any verification fails twice after a reasonable fix attempt.

## Maintenance notes

- **What a reviewer should scrutinise**: the allowlist. It is the part that decays. Every entry is a
  claim that an id is legitimately unattached *today*; the "still unreached" assertion is what stops
  it becoming a permanent exemption, and it is the easiest thing to drop under time pressure.
- **What lands on top of this**: when the SDK flow host lands, `RESULT_CARD` gains a call site; when
  the token session and scanner land, `SCAN_TOKEN_SCREEN` and `TOKEN_ENVIRONMENT` do; when a
  scenario drawer is mounted, `SCENARIO_ITEM` and `THEME_ITEM` do. Each must come off the allowlist
  as it does, and the "still unreached" assertion is what forces that.
- **`sample_env_chip` is implemented by no app.** `docs/plan/port-gaps-backlog.md` §3 records two
  shell ids in that state; this is a third. It belongs in that list, as an owed feature or an owed
  deletion — a ruling, not a code change.
- **Android and iOS owe both of these checks too**, per `docs/plan/port-gaps-backlog.md` §2 and §7.
  This plan deliberately does not reach into them; §7 already writes out the portable predicate and
  what is Flutter-specific about the recipe.
