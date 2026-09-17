# Stacked pull requests in a squash-only repo: what the Flutter and Expo ports cost

Written after landing both ports as two stacks of six. Everything below was measured on this repo, not
reasoned about. The point is to choose a sequencing for the next port deliberately rather than
rediscovering this.

## The mechanism

This repo allows **squash merges only** — `allow_merge_commit` and `allow_rebase_merge` are both off —
and deletes branches on merge. Squashing replaces a branch's commits with one new commit, so after the
bottom PR merges, `main` is **not an ancestor** of the branch above it. Three things follow, every time,
on every merge up a stack:

1. **The next PR's diff inflates.** It re-shows the merged PR's content, because the merge base is now
   the commit before the whole stack. Measured: one PR went from its true 50 files to 111 files and
   +51k lines; another from 54 to 76.
2. **It reports conflicts that are not real disagreements.** Both sides changed the same files from a
   common ancestor that predates the squash.
3. **Its approval is dismissed.** The base branch is deleted, GitHub retargets the PR to `main`, and the
   retarget dismisses the review — with no push to the head at all.

Point 3 is the expensive one: **re-approval per PR is unavoidable here**, whatever else is done. The
only lever is how many PRs need approving.

## What works, and what does not

**Use `git rebase --onto <main> <merged-tip> <branch>`.** It drops the commits that are now in `main`
and replays only the branch's own. Measured: 26 commits replayed with **zero** conflicts, and separately
a chain of 8 branches rebased in sequence with **zero** conflicts.

**Never merge `main` into a stacked branch to "catch it up".** The same branch that rebased with zero
conflicts reported **19 conflicting files** when `main` was merged into it. Resolving those by hand
risks silently reverting work that was never in disagreement.

**Verify a rebased branch by content, not by commit.** Every SHA changes, so `merge-base --is-ancestor`
and subject-matching both lie. Diff the rebased tip against its own pre-rebase tree and expect exactly
the changes you know about.

**Pushing a fix to one branch does not propagate up the stack.** Fixes pushed to three branches left the
five above them without those fixes; it took a full chain-rebase to carry them up. Check the tips, not
the intent.

## The four sequencings, with their real costs

| | Approvals | CI cycles | Conflict work | Cost |
|---|---|---|---|---|
| **A. Allow merge commits** | 1 per PR, once | 1 per PR | none | a repo setting |
| **B. Land each tranche before starting the next** | 1 per PR | 1 per PR | none | serialises the work |
| **C. Collapse the stack into its top PR** | 1 total | 1 | one rebase | intermediate PRs close unmerged |
| **D. Merge bottom-up, rebasing between each** | 1 per PR | 1 per PR, **re-run after every merge** | one rebase each | ~15 min of dead time per step |

**A is the actual fix.** A merge commit preserves ancestry, so the branch above stays mergeable, keeps
its approval, and needs no rebase. It is one checkbox, and it removes the whole class of problem rather
than working around it.

**C is what the ports used** for the already-reviewed tranches: 7 PRs closed as superseded, their content
landing through 2. It spent 2 approvals instead of 9. The cost is that those 7 never show as *merged* —
a metrics cost, not a code one, and worth naming to whoever cares about merged-PR counts before choosing
it. Nothing is lost: the branches survive and every file was verified present in `main` afterwards.

**D is what the remaining three used**, because they had never been reviewed and collapsing unreviewed
work into one PR defeats the review.

## Recommendation for the next port

1. **Ask for merge commits to be enabled first.** Everything below is a workaround for its absence.
2. If they stay off, prefer **B** — land each tranche before the next begins. The agent can keep building
   on its own unmerged tip; what matters is that only one PR is ever waiting on review, so no approval is
   ever dismissed by a merge underneath it.
3. **Keep tranches small enough to review in one sitting.** The pressure to collapse came from having six
   deep stacks; it would not have arisen with three.
4. **Do not approve a stacked PR until the one below it has merged and it has been rebased.** An approval
   given earlier is dismissed by the rebase push. This single rule saved the most rework once adopted.
5. **Group at review time, not at build time.** The agent should build one tranche per feature; whoever
   opens the PRs decides how many tranches each covers. Grouping eight branches into three reviewable
   PRs cost nothing and saved five approvals.
