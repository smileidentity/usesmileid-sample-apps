# After the ports: what is next, and how to sequence it

## The ports are not finished, and it is worth being exact about that

Every screen, both navigation hosts, persistence, the verifications list with its actions and detail
page, profiles, the two pre-flow forms and the golden coverage landed for Flutter and Expo in one day
across twelve pull requests. That is the whole **user interface**.

It is not the whole app. Neither new app has ever invoked the SDK:

- `flutter/app` and `expo/app` contain **zero** SDK flow calls.
- Neither has a route for `/flow/:productId/run`. Flutter's two flow routes are `details` and
  `id-details` — both forms. Expo has the same forms and no `run`.
- Android, by contrast, has a flow layer of its own: `SdkFlowScreen`, `SdkFlowViewModel`,
  `FlowBuilderConfig`, `FlowJourney`, `FlowPreflight`, `FlowLaunchSnapshot`.

So both journeys walk a user to the door and stop. A sample app exists to demonstrate a verification,
and on these two you cannot yet run one. **Phase 4 below is the remaining half of the port, not
follow-on work** — the phases before it are debt and rulings that happen to be cheaper.

The same gap explains two things that look like omissions elsewhere: there is no token session or
scanner, which is why the session card, the countdown ring and four product states have goldens and no
way to be reached; and the verification detail page has no status refresh, because a refresh is a call
under a scanned session and no session exists.

`port-gaps-backlog.md` holds the detail of every item referenced here. `stacked-pr-sequencing.md` holds
the measured cost of the branching friction this session hit. Neither is repeated here.

## Phase 0 — two settings, before any of the work below

Both are minutes, and both remove a recurring tax rather than a one-off problem.

1. **Allow merge commits** on this repo. Squash-only merging is why every stacked pull request lost its
   ancestry *and* its approval when the one below it merged: twelve PRs cost roughly six re-approvals,
   several rebases and one collapse that closed seven PRs unmerged. A merge commit preserves ancestry
   and the branch above stays mergeable and approved. Everything in `stacked-pr-sequencing.md` below
   option A is a workaround for this setting being off.
2. **Create the `DESIGN_SYSTEM_TOKEN` secret.** The design-token drift check has never run in CI — it
   reports itself skipped, which reads as a pass. Until it exists, no run has ever compared the emitted
   tokens against the real set.

## Phase 1 — the rulings, because they gate work rather than follow it

Each is a product call, none is an engineering question, and each is cheap to implement once settled.
They are listed in `port-gaps-backlog.md` §3 and §4.

- Should a profile's stored defaults seed the job form, and should the "remember these details" switch
  remember anything? It persists nothing today.
- An edit to the **already-active** profile cannot be saved on any platform: the page's only write both
  saves and activates, so on the active profile the button is disabled and the edit is silently
  discarded. Either the screen grows an always-enabled Save, or the CTA changes meaning when active.
- Button height 48 against 52, and the card glyph at 21 against 20 — the spec and the design disagree.
- The two shell ids `spec/test-ids.json` declares that no app implements: owed feature, or owed deletion.
- Whether `expo/app` may declare `expo-router/testing-library`, a test-only dependency, so a cold deep
  link's navigation state can be asserted.

## Phase 2 — the debt the ports surfaced, which Android and iOS owe

Independent of each other and of everything else, so these can run in parallel and in any order. Each is
small. All are in `port-gaps-backlog.md` §2.

| Item | Platform | Size |
|---|---|---|
| App-bar semantics: a container absorbing its children's nodes | Android, iOS | test + one-line fix |
| `Tap \`Hide from List\` to confirm` renders its backticks literally | Android, iOS | one word, baselines move |
| Job row's secondary line should take the board's caption | Android | row height moves |
| `UseSmileIDSampleStatusBadge` doc comment is stale | Android | one line |
| Id spec test asserts only one direction, so it cannot fail on an omission | Android | one test |
| Ink chosen by perceptual grey rather than WCAG luminance; 12 of 51 colours differ | iOS | one function |

**Take the app-bar one first.** It is the only one a user can be harmed by, it moves no pixel so no
baseline can catch it, and the portable predicate is written out in `port-gaps-backlog.md` §7. The id
spec test is second: a one-directional set assertion is why the missing-id gap survived at all.

## Phase 3 — the device passes, once the handset is unlocked

Twelve behaviours across three Flutter branches have widget tests only, listed per branch in their PR
bodies. They were blocked by a keyguard demanding authentication, which no adb command bypasses.

Worth doing as one pass rather than three, and worth doing before the flow host lands, because the
notices screen is the only way to see the licence registry populated — it is empty under `flutter test`
by design, so no test can stand in for it.

## Phase 4 — the rest of the port: the flow host, then the token session

This is the larger half of the remaining work and the only phase that makes the apps do what they
exist to do. Both journeys stop at `/flow/:productId/run`, a route neither app claims. Neither port
invented a placeholder, deliberately — a page that is not in the design and says "not yet" gets
mistaken for real UI.

Order within the phase: the flow host first, since it is what a product tap has been walking toward
since the forms landed; then the token session and scanner, which unblock the session card, the
countdown ring and the four product states that currently have goldens and no way to be reached, and
which the detail page's status refresh also waits on.

Do Flutter and Expo as siblings again, one tranche at a time. The parity contract held well: where the
two disagreed this session it was because one had a defect, and the other's implementation was the test.

Two things make this phase unlike the four before it, and both argue for starting it differently:

- **It is where the platforms genuinely differ.** Everything so far was UI the design specifies, so a
  divergence was almost always a defect. The flow host is each SDK's own surface — Android needed six
  files for it — so expect real divergence and document it rather than treating it as a parity failure.
- **It cannot be verified without a device.** A flow means camera capture, so no golden and no widget
  test proves it works. The twelve behaviours already owed a device pass are cosmetic beside this: a
  flow host with no device run proves nothing at all. **Unlock the handset before this phase starts**,
  not after it lands.

## How to sequence it, given what this session cost

1. **One pull request in review at a time, per app.** The agent can keep building on its own unmerged
   tip; what matters is that nothing is waiting on a review underneath another review. This alone
   removes the dismissal problem, whether or not merge commits get enabled.
2. **A branch with no pull request is invisible.** One finished tranche sat unnoticed for hours because
   every check anyone ran was scoped to PRs. Open the PR the moment its dependency merges, and before
   deleting any branch, diff it against `main` rather than trusting the PR list.
3. **Keep a tranche reviewable in one sitting.** The pressure to collapse came from stacks six deep; it
   would not have arisen at three.
4. **Do not approve a stacked PR before it has been rebased.** An approval given earlier is dismissed by
   the rebase push. This rule saved the most rework once adopted.
5. **Group at review time, not build time.** Eight branches became three reviewable PRs at no cost and
   saved five approvals.
6. **Run the review skill on every PR.** Every bot finding raised this session that was checked against
   the code turned out real, and the four on the last PR were found only because the bot reviews on open
   regardless of how the PR was created.
7. **Trim comments as you write.** The one-line rule in `AGENTS.md` was applied as a retrospective pass
   over 67 blocks in 38 files; doing it inline costs nothing.
8. **Never hand-edit generated output.** Trimming a generated file's header broke its staleness check.
   If generated text should change, change the generator.
9. **Use the toolchain's own tools.** `dart format` from Homebrew and from Flutter's bundle disagree, and
   CI uses Flutter's. The same applies to any tool with two installations on a machine.
