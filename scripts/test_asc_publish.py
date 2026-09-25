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


class PagedBuilds(asc_module.ASC):
    """Canned build pages and processing states, for the read-only helpers."""

    def __init__(self, pages: list[list[str]], states: list[str] = ()):
        self.pages = pages
        self.states = list(states)

    def call(self, method, path, body=None, raw=None, headers=None, **query):
        if path == "apps":
            return 200, {"data": [APP]}
        if path == "builds" and "filter[version]" in query:
            state = self.states.pop(0) if len(self.states) > 1 else self.states[0]
            return 200, {"data": [{"id": "b1", "attributes": {"version": query["filter[version]"], "processingState": state}}] if state else []}
        if path.startswith("builds/") and path.endswith("/preReleaseVersion"):
            return 200, {"data": {"attributes": {"version": "20260925.1211.138"}}}
        index = 0 if path == "builds" else int(path.rsplit("=", 1)[1])
        more = {"next": f"builds?page={index + 1}"} if index + 1 < len(self.pages) else {}
        return 200, {"data": [{"attributes": {"version": v}} for v in self.pages[index]], "links": more}


def printed(fn, asc, **args) -> str:
    out = io.StringIO()
    with contextlib.redirect_stdout(out):
        fn(asc, argparse.Namespace(**args))
    return out.getvalue()


class BuildNumberTests(unittest.TestCase):
    def test_next_build_is_one_above_the_highest_across_pages(self):
        asc = PagedBuilds([["103", "9"], ["137", "1.0.2"]])
        self.assertEqual(printed(asc_module.next_build, asc).strip(), "138")

    def test_next_build_on_an_app_with_no_builds_is_one(self):
        self.assertEqual(printed(asc_module.next_build, PagedBuilds([[]])).strip(), "1")

    def test_wait_returns_once_the_build_is_valid(self):
        asc = PagedBuilds([[]], states=[None, "PROCESSING", "VALID"])
        self.assertIn("VALID", printed(asc_module.wait, asc, build="138", timeout=60, interval=0))

    def test_wait_fails_on_an_invalid_build(self):
        with self.assertRaises(SystemExit):
            printed(asc_module.wait, PagedBuilds([[]], states=["INVALID"]), build="138", timeout=60, interval=0)


class Certificates(asc_module.ASC):
    """Canned development certificates; deletes are recorded."""

    def __init__(self, certs: list[tuple[str, str]], refuse: bool = False):
        self.certs = certs
        self.refuse = refuse
        self.deleted: list[str] = []

    def call(self, method, path, body=None, raw=None, headers=None, **query):
        if method == "DELETE":
            self.deleted.append(path.rsplit("/", 1)[1])
            return (409, {"errors": [{"title": "refused", "detail": "by the fake"}]}) if self.refuse else (204, {})
        return 200, {"data": [{"id": i, "attributes": {"certificateType": "DEVELOPMENT", "displayName": n}} for i, n in self.certs]}


class CertificateTests(unittest.TestCase):
    def revoke(self, asc, before: list[str]):
        import tempfile
        with tempfile.NamedTemporaryFile("w", suffix=".txt", delete=False) as f:
            f.write("\n".join(before))
        printed(asc_module.revoke_new_dev_certs, asc, before=f.name)

    def test_revokes_only_what_the_run_minted(self):
        asc = Certificates([("old", "Created via API"), ("new", "Created via API"), ("person", "Juma Allan")])
        self.revoke(asc, ["old", "person"])
        self.assertEqual(asc.deleted, ["new"])

    def test_never_revokes_a_persons_certificate_even_if_new(self):
        asc = Certificates([("person", "Juma Allan")])
        self.revoke(asc, [])
        self.assertEqual(asc.deleted, [])

    def test_a_refused_revoke_fails_the_run(self):
        with self.assertRaises(SystemExit):
            self.revoke(Certificates([("new", "Created via API")], refuse=True), [])


if __name__ == "__main__":
    unittest.main()
