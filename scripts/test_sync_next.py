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
    """A bare origin with main and next, a seed clone that edits them, and the clone the workflow checks out."""

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
        self.checkout = os.path.join(self.root.name, "checkout")
        self.run_git(self.root.name, "clone", "--quiet", self.origin, self.checkout)

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


if __name__ == "__main__":
    unittest.main()
