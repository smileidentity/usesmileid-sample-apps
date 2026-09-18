#!/usr/bin/env python3
"""Tests for the App Store Connect publisher's submit path.

Run: python3 scripts/test_asc_publish.py

A fake client answers the reads and records the writes, so the order Apple insists on — resolve the
rejected item, then submit — is pinned without a token or a network.
"""

from __future__ import annotations

import argparse
import contextlib
import io
import os
import sys
import unittest

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import asc_publish as asc_module  # noqa: E402

APP = {"id": "app1", "attributes": {"name": "Smile ID", "sku": "sku", "bundleId": "com.example"}}
VERSION = {
    "id": "v1",
    "attributes": {"versionString": "1.0", "appStoreState": "PREPARE_FOR_SUBMISSION", "releaseType": "MANUAL"},
    "relationships": {"build": {"data": {"type": "builds", "id": "b1"}}},
}
SUBMISSION = {"id": "sub1", "attributes": {"state": "UNRESOLVED_ISSUES", "platform": "IOS", "submittedDate": None}}


def item(item_id: str, state: str, version_id: str) -> dict:
    return {
        "id": item_id,
        "attributes": {"state": state},
        "relationships": {"appStoreVersion": {"data": {"type": "appStoreVersions", "id": version_id}}},
    }


class FakeASC(asc_module.ASC):
    """The real client with its network call replaced: reads are canned, writes are recorded."""

    def __init__(self, items: list[dict], refuse: set[str] = frozenset()):
        self.items = items
        self.refuse = refuse
        self.writes: list[tuple[str, str, dict | None]] = []

    def call(self, method, path, body=None, raw=None, headers=None, **query):
        if method == "GET":
            return 200, self.read(path)
        self.writes.append((method, path, body))
        if path in self.refuse:
            return 409, {"errors": [{"title": "STATE_ERROR", "detail": "refused by the fake"}]}
        return (201 if method == "POST" else 200), {"data": {"id": "written"}}

    def read(self, path: str) -> dict:
        if path == "apps":
            return {"data": [APP]}
        if path == "apps/app1/appStoreVersions":
            return {"data": [VERSION]}
        if path == "reviewSubmissions":
            return {"data": [SUBMISSION]}
        if path == "reviewSubmissions/sub1/items":
            return {"data": self.items}
        raise AssertionError(f"unexpected read {path}")

    def patches(self) -> list[tuple[str, dict]]:
        return [(path, body["data"]["attributes"]) for method, path, body in self.writes if method == "PATCH"]


def run_submit(asc: FakeASC, dry_run: bool = False) -> None:
    with contextlib.redirect_stdout(io.StringIO()):
        asc_module.submit(asc, argparse.Namespace(dry_run=dry_run))


class SubmitTests(unittest.TestCase):
    def test_resolves_this_versions_rejected_item_before_submitting(self):
        asc = FakeASC([item("it1", "REJECTED", "v1")])
        run_submit(asc)
        self.assertEqual(asc.patches(), [
            ("reviewSubmissionItems/it1", {"resolved": True}),
            ("reviewSubmissions/sub1", {"submitted": True}),
        ])

    def test_leaves_other_items_alone(self):
        asc = FakeASC([item("it9", "REJECTED", "v9"), item("it1", "READY_FOR_REVIEW", "v1")])
        run_submit(asc)
        self.assertEqual(asc.patches(), [("reviewSubmissions/sub1", {"submitted": True})])

    def test_failed_resolve_stops_before_submit(self):
        asc = FakeASC([item("it1", "REJECTED", "v1")], refuse={"reviewSubmissionItems/it1"})
        with self.assertRaises(SystemExit):
            run_submit(asc)
        self.assertEqual([path for path, _ in asc.patches()], ["reviewSubmissionItems/it1"])

    def test_refused_submit_fails_the_run(self):
        asc = FakeASC([item("it1", "READY_FOR_REVIEW", "v1")], refuse={"reviewSubmissions/sub1"})
        with self.assertRaises(SystemExit):
            run_submit(asc)

    def test_dry_run_writes_nothing(self):
        asc = FakeASC([item("it1", "REJECTED", "v1")])
        run_submit(asc, dry_run=True)
        self.assertEqual(asc.writes, [])


if __name__ == "__main__":
    unittest.main()
