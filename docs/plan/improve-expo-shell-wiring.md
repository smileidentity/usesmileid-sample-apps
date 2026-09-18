# Improve plan: wire the Expo shell to the library it already ships

> **Executor instructions**: Follow this plan step by step. Run every verification command and
> confirm the expected result before moving to the next step. If anything in the "STOP conditions"
> section occurs, stop and report — do not improvise. When done, update this plan's row in
> `docs/plan/improve-plans-index.md`.
>
> **Drift check (run first)**:
> `git diff --stat 2d9ba17..HEAD -- expo/app expo/sample-ui/src expo/verify.sh`
> If any in-scope file changed since this plan was written, compare the "Current state" excerpts
> against the live code before proceeding; on a mismatch, treat it as a STOP condition.

## Status

- **Priority**: P1
- **Effort**: M
- **Risk**: LOW (steps 1–5), MED (step 6)
- **Depends on**: none
- **Category**: bug
- **Planned at**: commit `2d9ba17`, 2026-09-17

## Why this matters

`expo/sample-ui` implements the job store's remove/undo contract, the fixture seeding, the dark-mode
setting, the notice window and the floating nav bar — all of them unit-tested and all of them
documented in their own doc comments as "reached by" something in the shell. **Nothing in
`expo/app` calls any of them.** The result is an app where hiding a verification is silent and
irreversible, the Dark Mode switch toggles and persists and changes nothing on screen, and
`seedJobs=true` opens an empty list — so every automated flow written against the seeded verifications
story is unrunnable on Expo.

The reason this survived review is structural: `expo/app` has **no tests at all** and
`expo/verify.sh` runs Jest only inside `sample-ui`. The library's green says the library is correct
and says nothing about the app. `docs/plan/port-gaps-backlog.md` §5 records three cases on Flutter
with exactly this shape ("a fixture that no caller uses proves only that the fixture is
self-consistent"); these are the Expo equivalents, and none of them is in that backlog.

Step 1 exists first for that reason: without a test lane on `expo/app`, every fix below is
unverifiable and the next one will regress the same way.

## Current state

### The files

- `expo/app/app/_layout.tsx` — the root layout. Reads launch args, resets the profile store, provides
  the theme. The only place a cold-start argument can be applied before the first screen mounts.
- `expo/app/app/(tabs)/verifications.tsx` — the verifications route. Since `1b199cf` and `67a6b2b`
  on this branch it consumes removals into the transient notice with Undo, so step 3 below is done
  and only its test is owed.
- `expo/app/app/(tabs)/_layout.tsx` — the tab bar. Uses `expo-router`'s stock `<Tabs>` bar.
- `expo/app/app/profiles/index.tsx` — **the working exemplar.** It already does, correctly, the exact
  pattern steps 3 and 4 need: consume a one-shot store signal in an effect, show a transient notice
  with an action, and mount the host.
- `expo/sample-ui/src/data/use-smile-id-sample-job-store.ts` — the store. `seedFixtures` (`:198`),
  `undoRemove` (`:120`), `consumeRemoval` (`:190`), `lastRemoved` (`:55`).
- `expo/sample-ui/src/components/use-smile-id-sample-transient-notice.tsx` — the notice host and its
  window context.
- `expo/sample-ui/src/components/use-smile-id-sample-nav-bar.tsx` — `UseSmileIDSampleNavBar` (`:26`).
- `expo/sample-ui/jest.config.js` — the config to model the new one on.

### The excerpts, as they exist today

`expo/app/app/_layout.tsx:22-38` — one argument of ten is applied, and the theme ignores the setting:

```tsx
export default function RootLayout() {
  const scheme = useColorScheme();
  const dark = scheme === 'dark';
  const colors = dark ? smileDarkColors : smileLightColors;
  const args = useLaunchArgs();
  const resetProfiles = useSmileIDSampleProfileStore((state) => state.reset);

  // The five faces are bundled rather than fetched: a provider would make text depend on the network.
  const [fontsLoaded] = useFonts(smileFontAssets);

  useEffect(() => {
    resetProfiles(smileIDSampleProfilesForLaunch(args));
  }, [args, resetProfiles]);
```

`expo/app/app/(tabs)/verifications.tsx:18-25` as it stood when this plan was surveyed, before the
branch wired the notice. The comment claimed a property the code did not then deliver:

```tsx
    <VerificationsScreen
      state={{ jobs, nowMillis }}
      onJobPress={(job) => router.push(`/verifications/${job.id}`)}
      // The write outlives this screen: a removal must land even if the reader navigates at once.
      onRemove={(ids) => void remove(ids)}
    />
```

`expo/app/app/profiles/index.tsx:23-46` — **the pattern to copy**:

```tsx
  const notice = useSmileIDSampleTransientNotice();
  const { show } = notice;

  // Consumed on sight, so returning to the list cannot re-show it.
  useEffect(() => {
    if (lastCreatedId === null) return;
    const created = profiles.find((profile) => profile.id === lastCreatedId);
    clearLastCreated();
    if (created === undefined) return;
    show({ message: `${created.organisation} created`, actionLabel: 'Make active', onAction: () => setActive(created.id) });
  }, [lastCreatedId, profiles, clearLastCreated, setActive, show]);

  return (
    <View style={styles.host}>
      <ProfilesScreen … />
      <UseSmileIDSampleTransientNoticeHost state={notice} style={styles.notice} />
    </View>
  );
```

`expo/sample-ui/src/components/use-smile-id-sample-transient-notice.tsx:14-19`:

```tsx
/// Long enough to undo, short enough not to outlive its cause.
export const SMILE_ID_SAMPLE_NOTICE_WINDOW_MS = 5_000;

/// The shell overrides this from `noticeWindow`; the default is the product's own behaviour.
const NoticeWindowContext = createContext(SMILE_ID_SAMPLE_NOTICE_WINDOW_MS);

export const UseSmileIDSampleNoticeWindowProvider = NoticeWindowContext.Provider;
```

`expo/sample-ui/jest.config.js` — the config to model the new one on:

```js
process.env.TZ = 'UTC';
process.env.LC_ALL = 'en_US.UTF-8';

module.exports = {
  preset: 'jest-expo',
  testEnvironment: 'node',
  roots: ['<rootDir>/test'],
  moduleNameMapper: { '^@smileid/usesmileid$': '<rootDir>/test/stubs/usesmileid.ts' },
  snapshotResolver: '<rootDir>/test/snapshot-resolver.js',
  setupFiles: ['<rootDir>/test/setup.ts'],
  clearMocks: true,
};
```

`expo/sample-ui/test/setup.ts` — the AsyncStorage mock the new lane also needs:

```ts
jest.mock('@react-native-async-storage/async-storage', () =>
  require('@react-native-async-storage/async-storage/jest/async-storage-mock'),
);
```

### Repo conventions you must match

These come from `AGENTS.md` and `docs/plan/port-patterns.md`. The executor has not read them; they
are quoted here.

- **"The doc comment is the documentation; inline comments are the exception."** Every type, function
  and non-obvious property carries a `///` doc comment of **one line**. Inside a body, prefer no
  comment at all. An inline `//` is earned only by something the code cannot say — a measured
  constraint, a platform trap, an order that looks arbitrary and is not. **No multi-line comments
  anywhere.**
- **"Fixture data is opt-in, per launch."** A store's constructor default is what a partner sees on a
  fresh install, so it carries no example anything. Fixtures are reached only through a
  `spec/launch-args.json` argument.
- **"Mirror structure across the four platforms."** Same screen, same file name adjusted only for
  platform casing, same relative folder.
- **Copy vs API deliberately disagree.** The store methods are `remove`/`undoRemove` and the test ids
  are `sample_selection_remove`/`sample_details_delete`, but **every user-facing label says Hide** —
  "Hide from List", "Hide", "N verifications hidden from App list". Port the copy exactly.
- **Commits**: a single conventional-commit subject line, `type: summary`. No body. Example from
  `git log`: `fix: guard duplicate frame delivery`.

### The exact user-facing strings

Take these verbatim from the three sibling apps — do not reword them:

| Case | String |
|---|---|
| one row hidden | `1 verification hidden from App list` |
| N rows hidden | `N verifications hidden from App list` |
| the action | `Undo` |

Confirm before writing by reading
`flutter/sample_ui/lib/src/screens/use_smileid_sample_verifications_screen.dart:225-227`, which is
the current Flutter wording, and matching it exactly.

## Commands you will need

Run from the repo root. `expo/verify.sh` expects pnpm 9 and will exit 1 on anything else.

| Purpose | Command | Expected on success |
|---|---|---|
| Install | `cd expo && pnpm install --frozen-lockfile` | exit 0 |
| Lint | `cd expo && pnpm exec eslint .` | exit 0, no errors |
| Typecheck (library) | `cd expo && pnpm --filter @smileid/sample-ui exec tsc --noEmit` | exit 0 |
| Typecheck (shell) | `cd expo && pnpm --filter usesmileid-sample-expo exec tsc --noEmit` | exit 0 |
| Library tests | `cd expo && pnpm --filter @smileid/sample-ui exec jest --ci` | all pass |
| Shell tests (new, step 1) | `cd expo && pnpm --filter usesmileid-sample-expo exec jest --ci` | all pass |
| Full gate | `expo/verify.sh` | prints `OK` |

`expo/verify.sh` with no argument runs phase `all` = checks + bundle. Do **not** run
`expo/verify.sh native`; it needs an Android SDK and is out of scope here.

## Scope

**In scope** (the only files you may modify or create):

- `expo/app/jest.config.js` (create)
- `expo/app/test/setup.ts` (create)
- `expo/app/test/use-smile-id-sample-launch.test.ts` (create)
- `expo/app/test/use-smile-id-sample-shell-wiring.test.tsx` (create)
- `expo/app/package.json` (add a `test` script and the jest devDependencies, each with a
  `pinRationale` entry — see step 1)
- `expo/package.json` (the workspace-root `test` script)
- `expo/verify.sh` (one added line)
- `expo/app/app/_layout.tsx`
- `expo/app/app/(tabs)/verifications.tsx`
- `expo/app/app/(tabs)/_layout.tsx` (step 6 only)

**Out of scope** (do NOT touch, even though they look related):

- Anything under `expo/sample-ui/src/`. The library is correct; this plan wires the shell to it. If
  you believe a library change is needed, that is a STOP condition.
- `spec/` — any change there must land with four app-side updates and is a separate decision.
- The SDK flow host, the token session and the scanner. They are deliberately absent from this repo
  today and are planned separately. Do not add, stub or reference them.
- The remaining launch arguments — `scenario`, `theme`, `route`, `autostart`, `probes`, `appLocale`,
  `holdCamera`. They need surfaces that do not exist yet. This plan wires `seedJobs` and
  `noticeWindow` only.
- Any golden baseline under `expo/sample-ui/test/goldens/`. If a step makes one stale, that is a
  STOP condition — report it rather than re-recording.

## Git workflow

- Branch: `improve/expo-shell-wiring`
- One conventional-commit subject line per step. No body, no attribution trailers.
- Do **not** push, open a PR, or run the `create-pr` skill.

## Steps

### Step 1: give `expo/app` a test lane

Create `expo/app/jest.config.js` modelled on `expo/sample-ui/jest.config.js` quoted above. It needs:

- `preset: 'jest-expo'`, `testEnvironment: 'node'`, `roots: ['<rootDir>/test']`, `clearMocks: true`
- `moduleNameMapper` mapping `^@smileid/usesmileid$` to the library's existing stub at
  `../sample-ui/test/stubs/usesmileid.ts`
- `setupFiles: ['<rootDir>/test/setup.ts']`
- the same `process.env.TZ = 'UTC'` and `process.env.LC_ALL = 'en_US.UTF-8'` lines, for the same
  reason (a day-boundary regroup would otherwise pin the machine that ran it)

Create `expo/app/test/setup.ts` containing the same AsyncStorage mock quoted above.

Add to `expo/app/package.json`: a `"test": "jest"` script, and whatever jest devDependencies the
config needs that are not already resolvable (`jest`, `jest-expo`, `@types/jest`,
`react-test-renderer` — check what `expo/sample-ui/package.json` declares and match its versions
exactly). **Every dependency you add must get a one-line entry in that file's `pinRationale` object**
— `docs/plan/port-patterns.md` §4: "deleting them silently unpins".

Add to `expo/package.json`, replacing the existing `test` script:

```json
"test": "pnpm -r --workspace-concurrency=1 exec jest --ci"
```

Add to `expo/verify.sh`, immediately after the existing `sample-ui` jest line (`:100`):

```bash
"$PNPM" --filter usesmileid-sample-expo exec jest --ci
```

Write one first test in `expo/app/test/use-smile-id-sample-launch.test.ts` that exercises
`expo/app/src/use-smile-id-sample-launch.ts` against a mocked `Linking.getInitialURL`, asserting that
a URL carrying `seedJobs=true` produces args with `seedJobs === true` and that a launch with no URL
produces the plain defaults.

**Verify**: `cd expo && pnpm --filter usesmileid-sample-expo exec jest --ci` → exits 0, at least 2
tests pass. Then `cd expo && pnpm exec eslint .` → exit 0.

**Commit**: `test: give the Expo shell its own jest lane`

### Step 2: apply `seedJobs` at cold start

In `expo/app/app/_layout.tsx`, read `seedFixtures` off the job store and call it once when
`args.seedJobs` is true, in the same effect that already resets the profile store. It must run before
the verifications route's first `load()`. `seedFixtures` is idempotent (rows are keyed by job id), so
a second call is harmless — but it must not run when the argument is absent.

Pass the timestamp explicitly: `seedFixtures(Date.now())`.

**Verify**: `cd expo && pnpm --filter usesmileid-sample-expo exec tsc --noEmit` → exit 0. Then a new
test in `expo/app/test/use-smile-id-sample-shell-wiring.test.tsx` that renders `RootLayout` with a
mocked initial URL carrying `seedJobs=true` and asserts the job store's `jobs` is non-empty; and a
second that renders it with no URL and asserts `jobs` is empty. Both pass.

**Commit**: `fix: seed the Expo verification fixtures from seedJobs`

### Step 3: show the removal confirmation and offer Undo

**Done on this branch** (`1b199cf`, `67a6b2b`), except the test under **Verify**, which needs step 1's
lane. Read the rest of this step as the description of what to test, not what to build.

In `expo/app/app/(tabs)/verifications.tsx`, follow the `expo/app/app/profiles/index.tsx` pattern
exactly:

- take `useSmileIDSampleTransientNotice()`
- read `consumeRemoval` and `undoRemove` off the job store
- in an effect keyed on the store's jobs, call `consumeRemoval()`; when it returns a non-null count,
  `show({ message, actionLabel: 'Undo', onAction: () => void undoRemove() })` using the exact strings
  in the table above
- wrap the screen in a `<View style={styles.host}>` and render
  `<UseSmileIDSampleTransientNoticeHost state={notice} style={styles.notice} />` beneath it

The notice's inset is caller-supplied by design ("every screen clears different chrome"). The
verifications route sits inside the tab bar, so its inset is **not** the profiles route's. Start from
the profiles values and say in a one-line inline comment what chrome the number clears, as
`profiles/index.tsx:52` does.

**Verify**: a test in `use-smile-id-sample-shell-wiring.test.tsx` that renders the verifications
route with seeded rows, removes one through `onRemove`, asserts the toast text is present, invokes
the Undo action, and asserts the row is back. `cd expo && pnpm --filter usesmileid-sample-expo exec
jest --ci` → passes.

**Commit**: `fix: confirm and allow undo of a hidden Expo verification`

### Step 4: make the Dark Mode setting drive the theme

In `expo/app/app/_layout.tsx`, read `darkMode` and the load flag off
`useSmileIDSampleSettingsStore`, call the settings store's `load()` once at root, and pass the
provider `dark={darkMode || scheme === 'dark'}`.

That expression is deliberate and matches Flutter: `flutter/app/lib/src/use_smileid_sample_app.dart:42`
is `themeMode: darkMode ? ThemeMode.dark : ThemeMode.system` — the switch **overrides** to dark, and
off means follow the device. Do not implement it as a plain preference that can force light.

Keep `useColorScheme()` as the value used before the store has loaded.

**Verify**: a test that renders `RootLayout` with the settings store holding `darkMode: true` and a
light system scheme, and asserts the resolved theme is the dark one; and its inverse. Both pass.

**Commit**: `fix: let the Expo Dark Mode switch reach the theme`

### Step 5: honour `noticeWindow`

Wrap the tree in `_layout.tsx` with
`<UseSmileIDSampleNoticeWindowProvider value={...}>`, taking the value from `args.noticeWindow` and
falling back to `SMILE_ID_SAMPLE_NOTICE_WINDOW_MS`.

Read `spec/launch-args.json`'s entry for `noticeWindow` to get the unit right (seconds or
milliseconds) and convert if needed. Do not guess.

**Verify**: a test that renders the verifications route under a provider value of 50 ms, triggers a
removal, advances jest fake timers past 50 ms, and asserts the toast is gone. Passes.

**Commit**: `fix: honour the Expo noticeWindow launch argument`

### Step 6: mount the floating nav bar

`expo/sample-ui/src/components/use-smile-id-sample-nav-bar.tsx:26` exports
`UseSmileIDSampleNavBar`, which the other three apps mount and Expo does not. `expo/app/app/(tabs)/_layout.tsx:4`
carries a comment saying "The design's floating pill replaces this bar in U2", and U2 has landed.

Pass `tabBar={(props) => <UseSmileIDSampleNavBar … />}` to `<Tabs>`, driving `selectedId`/`onSelect`
from `props.state`, and drive the three labels from `smileIDSampleNavItems`
(`expo/sample-ui/src/model/use-smile-id-sample-nav-item.ts:17,23,29`) rather than the three string
literals currently in `options.title` at `:23`, `:29`, `:34` — those are a second copy of copy the
library already owns. Leave the two `href: null` rows at `:37-38` exactly as they are.

Read the component's props before writing the call — do not assume the signature.

**Clearance**: reserve the bar's *measured* height, never a computed one. Flutter now takes it from
the laid-out bar (`flutter/app/lib/src/use_smileid_sample_shell.dart`: the bar sits in Scaffold's
bottom slot under `extendBody`, which publishes its height to the body as bottom padding in the same
frame), matching Android's `onSizeChanged` and iOS's `.safeAreaInset`. A formula over the token's
`minHeight` cannot see the label wrap and left the last row under the bar at 320dp.

**Verify**: `cd expo && pnpm exec eslint . && pnpm --filter usesmileid-sample-expo exec tsc --noEmit`
→ both exit 0. Then `cd expo && pnpm --filter @smileid/sample-ui exec jest --ci` → all pass with **no
new obsolete or written snapshots**. If any golden changes, STOP (see STOP conditions).

**Commit**: `feat: mount the floating nav bar in the Expo shell`

## Test plan

New tests, all under `expo/app/test/`:

| File | Cases |
|---|---|
| `use-smile-id-sample-launch.test.ts` | `seedJobs=true` parsed from the initial URL; no URL yields plain defaults |
| `use-smile-id-sample-shell-wiring.test.tsx` | seeding on with rows; seeding off with none; remove shows the exact toast string; Undo restores the row; `darkMode: true` resolves the dark theme with a light system scheme; `darkMode: false` follows the system; a 50 ms notice window dismisses |

Model the structure on `expo/sample-ui/test/use-smile-id-sample-job-store.test.ts` (store setup and
`beforeEach` reset discipline) and on
`flutter/app/test/use_smileid_sample_verification_actions_test.dart` for what an end-to-end removal
assertion should cover.

**Every test must drive the app's own start-up path.** `docs/plan/port-gaps-backlog.md` §5 records
why: three Flutter tests passed while the feature was broken, because each test arranged its own
world — overriding the provider the app was failing to feed, or passing an explicit initial location
a real deep link never takes. A test that calls `seedFixtures` itself proves the fixture is
self-consistent and nothing more. Render `RootLayout` and the route; mock only the platform edge
(`Linking.getInitialURL`, AsyncStorage).

## Done criteria

All must hold:

- [ ] `expo/verify.sh` prints `OK`
- [ ] `cd expo && pnpm --filter usesmileid-sample-expo exec jest --ci` exits 0 with at least 9 tests
- [ ] `grep -rn "seedFixtures\|undoRemove\|consumeRemoval" expo/app/app` returns at least one hit for
      each of the three
- [ ] `grep -rn "'Products'\|'Verifications'\|'Settings'" "expo/app/app/(tabs)/_layout.tsx"` returns
      nothing (the labels come from `smileIDSampleNavItems`)
- [ ] `git status --porcelain` lists no file outside the In-scope list
- [ ] `git status --porcelain expo/sample-ui/test/goldens` is empty (no baseline re-recorded)
- [ ] every dependency added to `expo/app/package.json` has a `pinRationale` entry
- [ ] this plan's row in `docs/plan/improve-plans-index.md` is updated

## STOP conditions

Stop and report — do not improvise — if:

- The code at any "Current state" excerpt does not match what you find.
- Any golden snapshot under `expo/sample-ui/test/goldens/` changes, is written, or is reported
  obsolete. Re-recording baselines is explicitly out of scope: a changed picture means the wiring
  altered rendering and a human must read every changed mark, which
  `docs/plan/port-patterns.md` §6.11 requires and you cannot do.
- Step 6's nav bar needs a prop the component does not expose, or needs a change inside
  `expo/sample-ui/`.
- `spec/launch-args.json` does not state `noticeWindow`'s unit clearly enough to convert without
  guessing.
- Wiring `darkMode` requires changing `expo/sample-ui/src/theme/use-smile-id-sample-theme.tsx`.
- Any verification fails twice after a reasonable fix attempt.

## Maintenance notes

- **What a reviewer should scrutinise**: that every new test renders `RootLayout` or a real route
  rather than calling a store method directly — that is the whole point of the plan, and it is the
  easiest thing to lose under time pressure.
- The seven launch arguments left unwired (`scenario`, `theme`, `route`, `autostart`, `probes`,
  `appLocale`, `holdCamera`) are deferred deliberately: each needs a surface that does not exist yet.
  Record them in `docs/plan/port-gaps-backlog.md` §5 next to the Flutter entry, which today names
  only Flutter's shortfall.
- When the scenario drawer lands on Expo, `settings-screen.tsx:267` already gates the Debug section on
  an `onOpenScenarioDrawer` prop that the settings tab does not pass. Wiring it is one line there.
- Step 6 changes the tab bar's height and inset. The notice insets chosen in step 3 depend on it —
  if step 6 is dropped or deferred, re-check step 3's inset against the stock bar.

