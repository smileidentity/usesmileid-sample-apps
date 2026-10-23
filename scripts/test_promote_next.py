#!/usr/bin/env python3
"""Tests for the Promote next script. Run: python3 scripts/test_promote_next.py"""
from __future__ import annotations

import json
import os
import subprocess
import sys
import unittest
from unittest import mock

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import promote_next as pn  # noqa: E402

REPO = "smileidentity/usesmileid-sample-apps"


class FakeGitHub:
    """Answers from a scripted repository and records every change the promotion asks for."""

    def __init__(self, trees=("main-tree", "next-tree"), changed=3, pulls=(), branches=None, behind=None):
        self.repo = REPO
        self.trees = {"main": trees[0], "next": trees[1]}
        self.changed_files = changed
        self.pulls = list(pulls)
        self.branches = {"next": "1234567890abcdef", **(branches or {})}
        self.behind_by = behind or {}
        self.changes: list[tuple] = []

    def tree(self, ref):
        return self.trees[ref]

    def changed(self, base, head):
        return self.changed_files

    def behind(self, base, head):
        return self.behind_by.get(base, 0)

    def open_pulls(self):
        return self.pulls

    def tip(self, branch):
        return self.branches.get(branch)

    def create_branch(self, branch, sha):
        self.changes.append(("create", branch, sha))

    def move_branch(self, branch, sha):
        self.changes.append(("move", branch, sha))

    def open_pull(self, branch, title, body):
        self.changes.append(("open", branch, title))
        return 300

    def describe_pull(self, number, body):
        self.changes.append(("describe", number))

    def close_pull(self, number, branch, comment, delete_branch):
        self.changes.append(("close", number, branch, delete_branch))


def promotion(version, number, repo=REPO):
    """An open pull request from a promotion branch, as the REST API lists it."""
    return {"number": number, "head": {"ref": pn.PREFIX + version, "repo": {"full_name": repo}}}


class TestPromote(unittest.TestCase):
    def test_a_version_that_is_not_a_release_is_refused(self):
        for bad in ("v12.4.0", "12.4", "12.4.0\nx"):
            with self.assertRaises(pn.PromoteError):
                pn.promote(FakeGitHub(), bad)

    def test_nothing_is_promoted_when_main_already_holds_next(self):
        for github in (FakeGitHub(trees=("same", "same")), FakeGitHub(changed=0)):
            self.assertIn("nothing to promote", pn.promote(github, "12.4.0"))
            self.assertEqual([], github.changes)

    def test_a_first_promotion_copies_next_and_opens_the_pull_request(self):
        github = FakeGitHub()
        self.assertEqual("opened #300 from sync/next-into-main-12.4.0", pn.promote(github, "12.4.0"))
        self.assertEqual(
            [
                ("create", "sync/next-into-main-12.4.0", "1234567890abcdef"),
                ("open", "sync/next-into-main-12.4.0", "🔀 sync: next into main, now that 12.4.0 has shipped"),
            ],
            github.changes,
        )

    def test_an_older_promotion_is_replaced_only_after_the_new_one_is_open(self):
        github = FakeGitHub(pulls=[promotion("12.4.0", 7)], branches={"sync/next-into-main-12.4.0": "old"})
        pn.promote(github, "12.5.0")
        self.assertEqual(["create", "open", "close"], [change[0] for change in github.changes])
        self.assertEqual(("close", 7, "sync/next-into-main-12.4.0", True), github.changes[-1])

    def test_a_replaced_promotion_with_commits_next_lacks_keeps_its_branch(self):
        github = FakeGitHub(pulls=[promotion("12.4.0", 7)], behind={"sync/next-into-main-12.4.0": 1})
        pn.promote(github, "12.5.0")
        self.assertEqual(("close", 7, "sync/next-into-main-12.4.0", False), github.changes[-1])

    def test_a_newer_open_promotion_stops_the_run_before_anything_changes(self):
        github = FakeGitHub(pulls=[promotion("12.10.0", 9)])
        with self.assertRaisesRegex(pn.PromoteError, "12.10.0 promotion .* is open, which is newer than 12.5.0"):
            pn.promote(github, "12.5.0")
        self.assertEqual([], github.changes)

    def test_a_rerun_for_the_same_version_moves_its_branch_and_refreshes_its_description(self):
        github = FakeGitHub(pulls=[promotion("12.4.0", 7)], branches={"sync/next-into-main-12.4.0": "old"})
        self.assertIn("#7 from sync/next-into-main-12.4.0 was already open", pn.promote(github, "12.4.0"))
        self.assertEqual(
            [("move", "sync/next-into-main-12.4.0", "1234567890abcdef"), ("describe", 7)], github.changes
        )

    def test_a_promotion_branch_with_commits_next_lacks_is_refused_unchanged(self):
        github = FakeGitHub(
            branches={"sync/next-into-main-12.4.0": "old"}, behind={"sync/next-into-main-12.4.0": 2}
        )
        with self.assertRaisesRegex(pn.PromoteError, "merging main into next"):
            pn.promote(github, "12.4.0")
        self.assertEqual([], github.changes)

    def test_a_forks_branch_or_a_hand_made_one_is_never_taken_for_a_promotion(self):
        fork = promotion("12.9.0", 5, repo="someone/usesmileid-sample-apps")
        hand_made = {"number": 6, "head": {"ref": pn.PREFIX + "wip", "repo": {"full_name": REPO}}}
        github = FakeGitHub(pulls=[fork, hand_made])
        pn.promote(github, "12.5.0")
        self.assertEqual(["create", "open"], [change[0] for change in github.changes])

    def test_the_description_names_the_release_and_the_copied_commit(self):
        body = pn.description("12.4.0", "1234567890abcdef")
        self.assertIn("12.4.0 has shipped", body)
        self.assertIn("a copy of `next` at 12345678", body)


class TestGitHub(unittest.TestCase):
    def test_a_missing_branch_reads_as_none_and_any_other_failure_stops_the_run(self):
        def run(error_text):
            def fail(args, **kwargs):
                raise subprocess.CalledProcessError(1, args, stderr=error_text)
            return fail

        github = pn.GitHub(REPO)
        with mock.patch.object(pn.subprocess, "run", run("gh: Not Found (HTTP 404)")):
            self.assertIsNone(github.tip("sync/next-into-main-12.4.0"))
        with mock.patch.object(pn.subprocess, "run", run("gh: Bad credentials (HTTP 401)")):
            with self.assertRaises(subprocess.CalledProcessError):
                github.tip("sync/next-into-main-12.4.0")

    def test_open_pull_requests_are_read_across_every_page(self):
        pages = {1: [{"number": 1}], 2: [{"number": 2}], 3: []}

        def answer(args, **kwargs):
            page = int(args[-1].rsplit("page=", 1)[1])
            return subprocess.CompletedProcess(args, 0, stdout=json.dumps(pages[page]))

        with mock.patch.object(pn.subprocess, "run", answer):
            self.assertEqual([1, 2], [pull["number"] for pull in pn.GitHub(REPO).open_pulls()])


if __name__ == "__main__":
    unittest.main()
