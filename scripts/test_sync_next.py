#!/usr/bin/env python3
"""Tests for the Sync next script. Run: python3 scripts/test_sync_next.py"""
from __future__ import annotations

import os
import subprocess
import sys
import tempfile
import unittest
from unittest import mock

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import sync_next as sn  # noqa: E402

IDENTITY = {"GIT_AUTHOR_NAME": "test", "GIT_AUTHOR_EMAIL": "test@example.com",
            "GIT_COMMITTER_NAME": "test", "GIT_COMMITTER_EMAIL": "test@example.com"}


class SyncNextTest(unittest.TestCase):
    """A bare origin with main and next, a seed clone that edits them, and a partial, sparse clone as the workflow's."""

    def setUp(self):
        self.root = tempfile.TemporaryDirectory()
        self.addCleanup(self.root.cleanup)
        empty = os.path.join(self.root.name, "gitconfig")
        open(empty, "w").close()
        env = mock.patch.dict(os.environ, {**IDENTITY, "GIT_CONFIG_GLOBAL": empty, "GIT_CONFIG_NOSYSTEM": "1"})
        env.start()
        self.addCleanup(env.stop)

        self.origin = os.path.join(self.root.name, "origin.git")
        self.seed = os.path.join(self.root.name, "seed")
        self.run_git(self.root.name, "init", "--quiet", "--bare", "-b", "main", self.origin)
        self.run_git(self.root.name, "clone", "--quiet", self.origin, self.seed)
        with open(os.path.join(self.seed, "README.md"), "w") as handle:
            handle.write("sample apps\n")
        self.run_git(self.seed, "add", "README.md")
        self.run_git(self.seed, "commit", "--quiet", "-m", "start")
        self.run_git(self.seed, "push", "--quiet", "origin", "main", "main:next")
        self.run_git(self.origin, "config", "uploadpack.allowFilter", "true")
        self.run_git(self.origin, "config", "uploadpack.allowAnySHA1InWant", "true")
        self.checkout = os.path.join(self.root.name, "checkout")
        self.run_git(self.root.name, "clone", "--quiet", "--filter=blob:none", "--sparse", f"file://{self.origin}", self.checkout)
        self.run_git(self.checkout, "sparse-checkout", "set", "scripts")

    def run_git(self, repo, *args):
        return subprocess.run(["git", "-C", repo, *args], check=True, capture_output=True, text=True).stdout.strip()

    def commit(self, path, text, branch="main"):
        self.run_git(self.seed, "checkout", "--quiet", "-B", branch, f"origin/{branch}")
        with open(os.path.join(self.seed, path), "w") as handle:
            handle.write(text)
        self.run_git(self.seed, "add", path)
        self.run_git(self.seed, "commit", "--quiet", "-m", f"edit {path} on {branch}")

    def publish(self, branch):
        self.run_git(self.seed, "push", "--quiet", "origin", f"{branch}:{branch}")

    def tip(self, branch):
        return self.run_git(self.origin, "rev-parse", branch)

    def test_does_nothing_when_next_already_holds_main(self):
        self.commit("next-only.txt", "next\n", branch="next")
        self.publish("next")
        before = self.tip("next")
        self.assertEqual(sn.sync(self.checkout, wait=0), "next already holds everything on main")
        self.assertEqual(self.tip("next"), before)

    def test_merges_main_into_next_and_keeps_what_next_holds(self):
        self.commit("next-only.txt", "next\n", branch="next")
        self.publish("next")
        next_before = self.tip("next")
        self.commit("main-only.txt", "main\n")
        self.publish("main")
        self.assertIn("merged main", sn.sync(self.checkout, wait=0))
        merged = self.tip("next")
        self.assertEqual(self.run_git(self.origin, "rev-list", "--parents", "-n", "1", merged).split()[1:],
                         [next_before, self.tip("main")])
        self.assertEqual(self.run_git(self.origin, "log", "-1", "--format=%s", merged),
                         "Merge remote-tracking branch 'origin/main' into next")

    def test_a_conflict_leaves_next_alone_and_names_the_file(self):
        self.commit("README.md", "next's words\n", branch="next")
        self.publish("next")
        before = self.tip("next")
        self.commit("README.md", "main's words\n")
        self.publish("main")
        with self.assertRaisesRegex(sn.SyncError, "conflicts in README.md"):
            sn.sync(self.checkout, wait=0)
        self.assertEqual(self.tip("next"), before)
        self.assertEqual(self.run_git(self.checkout, "status", "--porcelain"), "")

    def test_a_next_that_moves_during_the_run_is_merged_again_not_overwritten(self):
        self.commit("main-only.txt", "main\n")
        self.publish("main")
        real_git, moved = sn.git, []

        def moving_next(repo, *args, check=True):
            if args[0] == "push" and not moved:
                moved.append(True)
                self.commit("late.txt", "late\n", branch="next")
                self.publish("next")
            return real_git(repo, *args, check=check)

        with mock.patch.object(sn, "git", moving_next):
            self.assertIn("merged main", sn.sync(self.checkout, wait=0))
        late = self.run_git(self.origin, "rev-list", "-1", "--grep=edit late.txt", "next")
        self.assertEqual(self.run_git(self.origin, "merge-base", "--is-ancestor", late, "next"), "")
        self.assertEqual(self.run_git(self.origin, "merge-base", "--is-ancestor", self.tip("main"), "next"), "")

    def test_a_next_that_keeps_moving_ends_the_run_without_overwriting_it(self):
        self.commit("main-only.txt", "main\n")
        self.publish("main")
        real_git, late = sn.git, []

        def always_moving_next(repo, *args, check=True):
            if args[0] == "push":
                late.append(f"late-{len(late)}.txt")
                self.commit(late[-1], "late\n", branch="next")
                self.publish("next")
            return real_git(repo, *args, check=check)

        with mock.patch.object(sn, "git", always_moving_next), \
                self.assertRaisesRegex(sn.SyncError, r"next moved while this ran \(gave up after 2 attempts"):
            sn.sync(self.checkout, attempts=2, wait=0)
        self.assertEqual(self.run_git(self.origin, "log", "-1", "--format=%s", "next"), f"edit {late[-1]} on next")

    def test_a_fetch_that_fails_once_is_tried_again(self):
        self.commit("main-only.txt", "main\n")
        self.publish("main")
        real_git, failed = sn.git, []

        def flaky_fetch(repo, *args, check=True):
            if args[0] == "fetch" and not failed:
                failed.append(True)
                return subprocess.CompletedProcess(args, 128, "", "fatal: the remote end hung up unexpectedly\n")
            return real_git(repo, *args, check=check)

        with mock.patch.object(sn, "git", flaky_fetch):
            self.assertIn("merged main", sn.sync(self.checkout, wait=0))
        self.assertEqual(self.run_git(self.origin, "merge-base", "--is-ancestor", self.tip("main"), "next"), "")

    def test_a_conflict_outside_the_sparse_checkout_is_named(self):
        os.makedirs(os.path.join(self.seed, "android"), exist_ok=True)
        self.commit("android/app.txt", "start\n")
        self.publish("main")
        self.run_git(self.seed, "push", "--quiet", "origin", "main:next")
        self.commit("android/app.txt", "next's words\n", branch="next")
        self.publish("next")
        before = self.tip("next")
        self.commit("android/app.txt", "main's words\n")
        self.publish("main")
        with self.assertRaisesRegex(sn.SyncError, "conflicts in android/app.txt"):
            sn.sync(self.checkout, wait=0)
        self.assertEqual(self.tip("next"), before)

    def test_a_merge_that_changes_workflows_is_left_to_a_person(self):
        os.makedirs(os.path.join(self.seed, ".github", "workflows"))
        self.commit(".github/workflows/lane.yml", "name: lane\n")
        self.publish("main")
        before = self.tip("next")
        with self.assertRaisesRegex(sn.SyncError, "main changes .github/workflows/lane.yml, which this run's token"):
            sn.sync(self.checkout, wait=0)
        self.assertEqual(self.tip("next"), before)

    def test_a_checkout_that_keeps_failing_ends_with_its_own_error_and_leaves_next_alone(self):
        self.commit("next-only.txt", "next\n", branch="next")
        self.publish("next")
        self.commit("main-only.txt", "main\n")
        self.publish("main")
        before = self.tip("next")
        real_git = sn.git

        def failing_checkout(repo, *args, check=True):
            if args[0] == "checkout":
                return subprocess.CompletedProcess(args, 128, "", "fatal: could not fetch a missing object\n")
            return real_git(repo, *args, check=check)

        with mock.patch.object(sn, "git", failing_checkout), \
                self.assertRaisesRegex(sn.SyncError, r"^checking out next failed: fatal: could not fetch .*\(gave up after 2"):
            sn.sync(self.checkout, attempts=2, wait=0)
        self.assertEqual(self.tip("next"), before)

    def test_a_merge_that_fails_without_conflicts_says_what_git_said(self):
        self.commit("main-only.txt", "main\n")
        self.publish("main")
        real_git = sn.git

        def failing_merge(repo, *args, check=True):
            if args[:2] == ("merge", "--no-ff"):
                return subprocess.CompletedProcess(args, 128, "", "fatal: unable to write new index file\n")
            return real_git(repo, *args, check=check)

        with mock.patch.object(sn, "git", failing_merge), \
                self.assertRaisesRegex(sn.SyncError, "^merging main into next failed: fatal: unable to write"):
            sn.sync(self.checkout, wait=0)

    def test_an_annotation_keeps_every_line(self):
        self.assertEqual(sn.annotation("To github\n ! [remote rejected] 100%"),
                         "::error::To github%0A ! [remote rejected] 100%25")

    def test_a_refused_push_says_what_git_said_and_leaves_next_alone(self):
        self.commit("main-only.txt", "main\n")
        self.publish("main")
        before = self.tip("next")
        hook = os.path.join(self.origin, "hooks", "pre-receive")
        with open(hook, "w") as handle:
            handle.write("#!/bin/sh\necho 'token expired' >&2\nexit 1\n")
        os.chmod(hook, 0o755)
        with self.assertRaisesRegex(sn.SyncError, "pushing to next failed: .*token expired"):
            sn.sync(self.checkout, wait=0)
        self.assertEqual(self.tip("next"), before)


def issue(number, title, author=sn.BOT, **extra):
    """An open issue as the REST API lists it."""
    return {"number": number, "title": title, "user": {"login": author}, **extra}


class ScriptedIssues(sn.Issues):
    """Answers from a list of open issues and records every change the sync asks for."""

    def __init__(self, open_issues=()):
        super().__init__("smileidentity/usesmileid-sample-apps", "https://example.com/run/1")
        self.open_issues = list(open_issues)
        self.changes: list[tuple] = []
        self.refuse = False

    def _api(self, path, method="GET", fields=None):
        if method == "GET":
            page = int(path.rsplit("page=", 1)[1])
            return self.open_issues[(page - 1) * 2:page * 2]
        if self.refuse:
            raise subprocess.CalledProcessError(1, ["gh", "api"], stderr="HTTP 502")
        self.changes.append((method, path, (fields or {}).get("title") or (fields or {}).get("state")))
        return None


class BlockedSyncIssueTest(unittest.TestCase):
    """The run keeps one issue open while a sync waits on a person, and closes it when one goes through."""

    def blocked(self):
        raise sn.SyncError("main changes .github/workflows/lane.yml, which this run's token can't push")

    def test_a_blocked_sync_opens_the_issue_and_writes_the_summary(self):
        issues = ScriptedIssues([issue(5, "Something else"), issue(6, sn.BLOCKED, pull_request={}),
                                 issue(8, sn.BLOCKED, author="someone")])
        with tempfile.NamedTemporaryFile("r", suffix=".md") as summary, \
                mock.patch.dict(os.environ, {"GITHUB_STEP_SUMMARY": summary.name}), mock.patch("builtins.print"):
            self.assertEqual(sn.run(issues, self.blocked), 1)
            self.assertIn("lane.yml", summary.read())
        self.assertEqual(issues.changes, [("POST", "issues", sn.BLOCKED)])

    def test_a_still_blocked_sync_comments_on_the_open_issue(self):
        issues = ScriptedIssues([issue(1, "One"), issue(2, "Two"), issue(7, sn.BLOCKED)])
        with mock.patch.dict(os.environ, {}, clear=False), mock.patch("builtins.print"):
            os.environ.pop("GITHUB_STEP_SUMMARY", None)
            self.assertEqual(sn.run(issues, self.blocked), 1)
        self.assertEqual(issues.changes, [("POST", "issues/7/comments", None)])

    def test_a_clean_sync_closes_the_open_issue(self):
        issues = ScriptedIssues([issue(7, sn.BLOCKED)])
        with mock.patch("builtins.print"):
            self.assertEqual(sn.run(issues, lambda: "merged main (abc) into next"), 0)
        self.assertEqual(issues.changes, [("POST", "issues/7/comments", None), ("PATCH", "issues/7", "closed")])

    def test_a_refused_issue_update_is_a_warning_and_the_sync_result_stands(self):
        issues = ScriptedIssues([issue(7, sn.BLOCKED)])
        issues.refuse = True
        with mock.patch("builtins.print") as printed:
            self.assertEqual(sn.run(issues, lambda: "merged main (abc) into next"), 0)
            self.assertEqual(sn.run(issues, self.blocked), 1)
        warnings = [call.args[0] for call in printed.call_args_list if call.args[0].startswith("::warning::")]
        self.assertEqual(len(warnings), 2)

    def test_a_clean_sync_with_no_open_issue_changes_nothing(self):
        issues = ScriptedIssues()
        with mock.patch("builtins.print"):
            self.assertEqual(sn.run(issues, lambda: "next already holds everything on main"), 0)
        self.assertEqual(issues.changes, [])


if __name__ == "__main__":
    unittest.main()
