#!/usr/bin/env python3
"""Push the App Store listing in ios/store/ to App Store Connect, and submit it on request.

The listing lives in the repository — copy, screenshots, review notes — and this is what carries it
to the store, so a reviewer reads the same files Apple does. Dependency-free on purpose: the token is
signed with the openssl every Mac and runner already has, so nothing is installed to publish.

    scripts/asc_publish.py plan                 # read-only: what would change, against what is live
    scripts/asc_publish.py apply --build 103    # write the listing and attach that build
    scripts/asc_publish.py submit               # create or reuse the review submission, clear a rejected item, submit
    scripts/asc_publish.py status               # where the version is in review

Environment: APP_STORE_CONNECT_KEY_ID, APP_STORE_CONNECT_ISSUER_ID, and the .p8 at
~/.appstoreconnect/private_keys/AuthKey_<id>.p8 (or APP_STORE_CONNECT_KEY_PATH). The review
contact comes from ASC_REVIEW_NAME, ASC_REVIEW_PHONE and ASC_REVIEW_EMAIL.
"""
from __future__ import annotations

import argparse
import base64
import hashlib
import json
import os
import struct
import subprocess
import sys
import tempfile
import time
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
STORE = ROOT / "ios" / "store"
API = "https://api.appstoreconnect.apple.com/v1/"

LOCALE = "en-US"
# App Store Connect's own limits; check_store_listing.py enforces them before this runs.
COPY = {
    "description": ("description.txt", 4000),
    "keywords": ("keywords.txt", 100),
    "promotionalText": ("promotional-text.txt", 170),
    "whatsNew": ("whats-new.txt", 4000),
}
SUBTITLE_FILE = "subtitle.txt"
REVIEW_NOTES_FILE = "review-notes.txt"
SUPPORT_URL = "https://docs.smileidentity.com"
MARKETING_URL = "https://smile.id"
PRIVACY_POLICY_URL = "https://smile.id/privacy-policy"
PRIMARY_CATEGORY, SECONDARY_CATEGORY = "DEVELOPER_TOOLS", "BUSINESS"
# The seller name as the App Store shows it; the year is the release's, so it follows the calendar.
COPYRIGHT = f"{time.gmtime().tm_year} Smile Identity, Inc."
# 1320 × 2868 is the 6.9" iPhone; App Store Connect files it under the 6.7" display set.
SCREENSHOT_DISPLAY_TYPE = "APP_IPHONE_67"
PANELS = ["products", "token_session", "verifications", "verification_details", "settings"]
BASE_TERRITORY = "USA"

# Every content descriptor at its lowest level: the app shows a partner's own verification flows.
AGE_RATING = {
    "alcoholTobaccoOrDrugUseOrReferences": "NONE",
    "contests": "NONE",
    "gamblingSimulated": "NONE",
    "horrorOrFearThemes": "NONE",
    "matureOrSuggestiveThemes": "NONE",
    "medicalOrTreatmentInformation": "NONE",
    "profanityOrCrudeHumor": "NONE",
    "sexualContentGraphicAndNudity": "NONE",
    "sexualContentOrNudity": "NONE",
    "violenceCartoonOrFantasy": "NONE",
    "violenceRealistic": "NONE",
    "violenceRealisticProlongedGraphicOrSadistic": "NONE",
    "gambling": False,
    "lootBox": False,
    "unrestrictedWebAccess": False,
}


# ---- the token, signed without a dependency -------------------------------------------------------

def b64url(data: bytes) -> str:
    return base64.urlsafe_b64encode(data).rstrip(b"=").decode()


def der_to_raw(der: bytes) -> bytes:
    """ECDSA DER (SEQUENCE of two INTEGERs) to the 64-byte r||s a JWT wants."""
    assert der[0] == 0x30
    i = 2 if der[1] < 0x80 else 3
    out = b""
    for _ in range(2):
        assert der[i] == 0x02
        length = der[i + 1]
        value = der[i + 2:i + 2 + length].lstrip(b"\x00")
        out += value.rjust(32, b"\x00")
        i += 2 + length
    return out


def token() -> str:
    key_id = os.environ.get("APP_STORE_CONNECT_KEY_ID") or sys.exit("APP_STORE_CONNECT_KEY_ID is not set")
    issuer = os.environ.get("APP_STORE_CONNECT_ISSUER_ID") or sys.exit("APP_STORE_CONNECT_ISSUER_ID is not set")
    key_path = os.environ.get("APP_STORE_CONNECT_KEY_PATH") or os.path.expanduser(
        f"~/.appstoreconnect/private_keys/AuthKey_{key_id}.p8"
    )
    if not os.path.exists(key_path):
        sys.exit(f"no App Store Connect key at {key_path}")
    now = int(time.time())
    header = b64url(json.dumps({"alg": "ES256", "kid": key_id, "typ": "JWT"}).encode())
    payload = b64url(json.dumps({"iss": issuer, "iat": now, "exp": now + 900, "aud": "appstoreconnect-v1"}).encode())
    signing_input = f"{header}.{payload}".encode()
    with tempfile.NamedTemporaryFile(delete=False) as f:
        f.write(signing_input)
        f.flush()
        der = subprocess.run(["openssl", "dgst", "-sha256", "-sign", key_path, f.name], check=True, capture_output=True).stdout
    os.unlink(f.name)
    return f"{header}.{payload}.{b64url(der_to_raw(der))}"


class ASC:
    def __init__(self):
        self.auth = {"Authorization": f"Bearer {token()}"}

    def call(self, method: str, path: str, body: dict | None = None, raw: bytes | None = None, headers: dict | None = None, **query):
        url = path if path.startswith("http") else API + path + ("?" + urllib.parse.urlencode(query) if query else "")
        data = raw if raw is not None else (json.dumps(body).encode() if body is not None else None)
        h = dict(self.auth)
        h.update(headers or ({"Content-Type": "application/json"} if body is not None else {}))
        req = urllib.request.Request(url, method=method, data=data, headers=h)
        try:
            with urllib.request.urlopen(req, timeout=60) as r:
                return r.status, (json.load(r) if r.status not in (204,) and r.length != 0 else {})
        except urllib.error.HTTPError as e:
            return e.code, json.loads(e.read() or b"{}")

    def get(self, path, **q):
        status, body = self.call("GET", path, **q)
        if status != 200:
            sys.exit(f"GET {path} → {status}: {errors(body)}")
        return body

    def write(self, method, path, body, label):
        status, out = self.call(method, path, body)
        ok = status in (200, 201, 204)
        print(f"  {'ok ' if ok else 'ERR'} {label} ({status}{'' if ok else ': ' + errors(out)})")
        return out if ok else None


def errors(body: dict) -> str:
    parts = []
    for e in body.get("errors", []):
        parts.append(f"{e.get('title', '')}: {e.get('detail', '')}")
        for errs in ((e.get("meta") or {}).get("associatedErrors") or {}).values():
            parts.extend(f"→ {ae.get('title', '')}: {ae.get('detail', '')}" for ae in errs)
    return "; ".join(parts) or json.dumps(body)[:300]


# ---- what the repository says the listing is ---------------------------------------------------

def read(name: str) -> str:
    return (STORE / name).read_text(encoding="utf-8").strip("\n")


def png_size(path: Path):
    head = path.read_bytes()[:24]
    return struct.unpack(">II", head[16:24])


def bundle_id() -> str:
    spec = json.loads((ROOT / "spec" / "app-identity.json").read_text())
    return next(a["bundleIdentifier"] for a in spec["apps"] if a["platform"] == "ios")


# ---- the record as it stands ------------------------------------------------------------------------

def app(asc: ASC) -> dict:
    data = asc.get("apps", **{"filter[bundleId]": bundle_id(), "fields[apps]": "name,sku,bundleId"})["data"]
    if not data:
        sys.exit(f"no app record for {bundle_id()} — create it in App Store Connect first")
    return data[0]


def has_live_version(asc: ASC, app_id: str) -> bool:
    return bool(asc.get(f"apps/{app_id}/appStoreVersions", **{"filter[appStoreState]": "READY_FOR_SALE,PENDING_DEVELOPER_RELEASE,PROCESSING_FOR_APP_STORE", "limit": "1"})["data"])


def editable_version(asc: ASC, app_id: str) -> dict | None:
    versions = asc.get(f"apps/{app_id}/appStoreVersions", **{
        "filter[appStoreState]": "PREPARE_FOR_SUBMISSION,READY_FOR_REVIEW,DEVELOPER_REJECTED,REJECTED,METADATA_REJECTED,WAITING_FOR_REVIEW",
        "fields[appStoreVersions]": "versionString,appStoreState,releaseType,build", "include": "build", "fields[builds]": "version",
    })
    return versions["data"][0] if versions["data"] else None


def plan(asc: ASC, args):
    a = app(asc)
    print(f"app {a['attributes']['name']} · {a['attributes']['bundleId']} · sku {a['attributes']['sku']} · id {a['id']}")
    v = editable_version(asc, a["id"])
    if v:
        build = (v.get("relationships", {}).get("build", {}).get("data") or {}).get("id")
        print(f"editable version: {v['attributes']['versionString']} ({v['attributes']['appStoreState']}, release {v['attributes']['releaseType']}, build {'attached' if build else 'none'})")
    else:
        print("editable version: none — apply would create one")
    if args.build:
        b = build_by_number(asc, a["id"], args.build)
        print(f"build {args.build}: {b['attributes']['processingState']}, marketing version {b['attributes']['version_string']}" if b else f"build {args.build}: NOT FOUND")

    print("\nlisting from ios/store/:")
    print(f"  subtitle           {read(SUBTITLE_FILE)!r} ({len(read(SUBTITLE_FILE))}/30)")
    for field, (name, limit) in COPY.items():
        text = read(name)
        print(f"  {field:<18} {len(text):>4}/{limit}  {text.splitlines()[0][:70]!r}…")
    print(f"  supportUrl         {SUPPORT_URL}\n  marketingUrl       {MARKETING_URL}\n  privacyPolicyUrl   {PRIVACY_POLICY_URL}")
    print(f"  categories         {PRIMARY_CATEGORY} / {SECONDARY_CATEGORY}\n  content rights     does not use third-party content")
    print(f"  age rating         every descriptor NONE → 4+\n  price              Free, base territory {BASE_TERRITORY}, all territories")
    print(f"  release            {args.release}\n  copyright          {COPYRIGHT}")
    notes = read(REVIEW_NOTES_FILE)
    print(f"  review notes       {len(notes)}/4000  {notes.splitlines()[0][:70]!r}…")
    name, phone, email = review_contact(required=False)
    print(f"  review contact     {name or '<ASC_REVIEW_NAME missing>'} · {phone or '<ASC_REVIEW_PHONE missing>'} · {email}")
    print(f"  screenshots ({SCREENSHOT_DISPLAY_TYPE}):")
    for panel in PANELS:
        p = STORE / "screenshots" / f"{panel}.png"
        w, h = png_size(p)
        print(f"    {panel:<22} {w}x{h}  {p.stat().st_size // 1024} KB")


def review_contact(required: bool):
    name, phone = os.environ.get("ASC_REVIEW_NAME"), os.environ.get("ASC_REVIEW_PHONE")
    email = os.environ.get("ASC_REVIEW_EMAIL", "harun@smileidentity.com")
    if required and not (name and phone):
        sys.exit("ASC_REVIEW_NAME and ASC_REVIEW_PHONE are required to apply review details")
    return name, phone, email


def build_by_number(asc: ASC, app_id: str, number: str) -> dict | None:
    for b in asc.get("builds", **{"filter[app]": app_id, "filter[version]": number, "fields[builds]": "version,processingState",
                                   "include": "preReleaseVersion", "fields[preReleaseVersions]": "version"}).get("data", []):
        pre = asc.get(f"builds/{b['id']}/preReleaseVersion")["data"]["attributes"]["version"]
        b["attributes"]["version_string"] = pre
        return b
    return None


# ---- apply ---------------------------------------------------------------------------------------------

def apply(asc: ASC, args):
    a = app(asc)
    app_id = a["id"]
    build = build_by_number(asc, app_id, args.build) if args.build else None
    if args.build and not build:
        sys.exit(f"build {args.build} is not on the app")
    if build and build["attributes"]["processingState"] != "VALID":
        sys.exit(f"build {args.build} is {build['attributes']['processingState']}, not VALID")
    version_string = build["attributes"]["version_string"] if build else None

    print("version")
    v = editable_version(asc, app_id)
    release = "MANUAL" if args.release == "manual" else "AFTER_APPROVAL"
    if v:
        attrs = {"releaseType": release, "copyright": COPYRIGHT}
        if version_string and v["attributes"]["versionString"] != version_string:
            attrs["versionString"] = version_string
        asc.write("PATCH", f"appStoreVersions/{v['id']}", {"data": {"type": "appStoreVersions", "id": v["id"], "attributes": attrs}},
                  f"version {v['attributes']['versionString']} → {version_string or v['attributes']['versionString']}, release {release}")
    else:
        v = asc.write("POST", "appStoreVersions", {"data": {"type": "appStoreVersions",
            "attributes": {"platform": "IOS", "versionString": version_string, "releaseType": release, "copyright": COPYRIGHT},
            "relationships": {"app": {"data": {"type": "apps", "id": app_id}}}}}, f"create version {version_string}")["data"]
    vid = v["id"]

    print("version localisation")
    locs = asc.get(f"appStoreVersions/{vid}/appStoreVersionLocalizations", **{"fields[appStoreVersionLocalizations]": "locale"})["data"]
    attrs = {field: read(name) for field, (name, _) in COPY.items()}
    attrs.update({"supportUrl": SUPPORT_URL, "marketingUrl": MARKETING_URL})
    # A first version has nothing to be new against, and App Store Connect refuses the field (409).
    if not has_live_version(asc, app_id):
        attrs.pop("whatsNew", None)
    loc = next((l for l in locs if l["attributes"]["locale"] == LOCALE), None)
    if loc:
        asc.write("PATCH", f"appStoreVersionLocalizations/{loc['id']}", {"data": {"type": "appStoreVersionLocalizations", "id": loc["id"], "attributes": attrs}}, f"{LOCALE} copy")
    else:
        loc = asc.write("POST", "appStoreVersionLocalizations", {"data": {"type": "appStoreVersionLocalizations", "attributes": {"locale": LOCALE, **attrs},
                        "relationships": {"appStoreVersion": {"data": {"type": "appStoreVersions", "id": vid}}}}}, f"{LOCALE} copy")["data"]

    print("app information")
    infos = asc.get(f"apps/{app_id}/appInfos", **{"fields[appInfos]": "appStoreState"})["data"]
    info = infos[0]
    asc.write("PATCH", f"appInfos/{info['id']}", {"data": {"type": "appInfos", "id": info["id"],
        "relationships": {"primaryCategory": {"data": {"type": "appCategories", "id": PRIMARY_CATEGORY}},
                          "secondaryCategory": {"data": {"type": "appCategories", "id": SECONDARY_CATEGORY}}}}},
        f"categories {PRIMARY_CATEGORY}/{SECONDARY_CATEGORY}")
    asc.write("PATCH", f"apps/{app_id}", {"data": {"type": "apps", "id": app_id,
        "attributes": {"contentRightsDeclaration": "DOES_NOT_USE_THIRD_PARTY_CONTENT"}}}, "no third-party content")
    ilocs = asc.get(f"appInfos/{info['id']}/appInfoLocalizations", **{"fields[appInfoLocalizations]": "locale"})["data"]
    iloc = next((l for l in ilocs if l["attributes"]["locale"] == LOCALE), None)
    iattrs = {"subtitle": read(SUBTITLE_FILE), "privacyPolicyUrl": PRIVACY_POLICY_URL}
    if iloc:
        asc.write("PATCH", f"appInfoLocalizations/{iloc['id']}", {"data": {"type": "appInfoLocalizations", "id": iloc["id"], "attributes": iattrs}}, "subtitle + privacy policy url")
    else:
        asc.write("POST", "appInfoLocalizations", {"data": {"type": "appInfoLocalizations", "attributes": {"locale": LOCALE, **iattrs},
                  "relationships": {"appInfo": {"data": {"type": "appInfos", "id": info["id"]}}}}}, "subtitle + privacy policy url")
    rating = asc.get(f"appInfos/{info['id']}/ageRatingDeclaration")["data"]
    asc.write("PATCH", f"ageRatingDeclarations/{rating['id']}", {"data": {"type": "ageRatingDeclarations", "id": rating["id"], "attributes": AGE_RATING}}, "age rating: all NONE")

    print("price")
    points = asc.get(f"apps/{app_id}/appPricePoints", **{"filter[territory]": BASE_TERRITORY, "fields[appPricePoints]": "customerPrice", "limit": "200"})["data"]
    free = next((p for p in points if float(p["attributes"]["customerPrice"]) == 0.0), None)
    if free:
        asc.write("POST", "appPriceSchedules", {"data": {"type": "appPriceSchedules",
            "relationships": {"app": {"data": {"type": "apps", "id": app_id}},
                              "baseTerritory": {"data": {"type": "territories", "id": BASE_TERRITORY}},
                              "manualPrices": {"data": [{"type": "appPrices", "id": "${free}"}]}}},
            "included": [{"type": "appPrices", "id": "${free}", "attributes": {"startDate": None},
                          "relationships": {"appPricePoint": {"data": {"type": "appPricePoints", "id": free["id"]}}}}]},
            "Free, base USA")
    else:
        print("  ERR no free price point found for the base territory — set Free in Pricing and Availability")
    territories = [t["id"] for t in asc.get("territories", limit="200")["data"]]
    code, out = asc.call("POST", "https://api.appstoreconnect.apple.com/v2/appAvailabilities", {
        "data": {"type": "appAvailabilities",
                 "attributes": {"availableInNewTerritories": True},
                 "relationships": {"app": {"data": {"type": "apps", "id": app_id}},
                                   "territoryAvailabilities": {"data": [{"type": "territoryAvailabilities", "id": "${" + t + "}"} for t in territories]}}},
        "included": [{"type": "territoryAvailabilities", "id": "${" + t + "}", "attributes": {"available": True},
                      "relationships": {"territory": {"data": {"type": "territories", "id": t}}}} for t in territories]})
    print(f"  {'ok ' if code in (200, 201) else 'ERR'} availability: all {len(territories)} territories ({code}{'' if code in (200, 201) else ': ' + errors(out) + ' — set it under Pricing and Availability if this stays red'})")

    print("review details")
    name, phone, email = review_contact(required=True)
    rattrs = {"contactFirstName": name.split()[0], "contactLastName": " ".join(name.split()[1:]) or name.split()[0],
              "contactPhone": phone, "contactEmail": email, "demoAccountRequired": False, "notes": read(REVIEW_NOTES_FILE)}
    code, existing = asc.call("GET", f"appStoreVersions/{vid}/appStoreReviewDetail")
    if code == 200 and existing.get("data"):
        asc.write("PATCH", f"appStoreReviewDetails/{existing['data']['id']}", {"data": {"type": "appStoreReviewDetails", "id": existing["data"]["id"], "attributes": rattrs}}, "contact + notes")
    else:
        asc.write("POST", "appStoreReviewDetails", {"data": {"type": "appStoreReviewDetails", "attributes": rattrs,
                  "relationships": {"appStoreVersion": {"data": {"type": "appStoreVersions", "id": vid}}}}}, "contact + notes")

    print("screenshots")
    sets = asc.get(f"appStoreVersionLocalizations/{loc['id']}/appScreenshotSets", **{"fields[appScreenshotSets]": "screenshotDisplayType", "include": "appScreenshots", "fields[appScreenshots]": "fileName,assetDeliveryState,sourceFileChecksum"})
    sset = next((s for s in sets["data"] if s["attributes"]["screenshotDisplayType"] == SCREENSHOT_DISPLAY_TYPE), None)
    have = {}
    if sset:
        have = {i["attributes"]["fileName"]: i for i in sets.get("included", []) if i["type"] == "appScreenshots"}
    else:
        sset = asc.write("POST", "appScreenshotSets", {"data": {"type": "appScreenshotSets", "attributes": {"screenshotDisplayType": SCREENSHOT_DISPLAY_TYPE},
                         "relationships": {"appStoreVersionLocalization": {"data": {"type": "appStoreVersionLocalizations", "id": loc["id"]}}}}}, f"set {SCREENSHOT_DISPLAY_TYPE}")["data"]
    for panel in PANELS:
        path = STORE / "screenshots" / f"{panel}.png"
        data = path.read_bytes()
        digest = hashlib.md5(data).hexdigest()
        current = have.get(path.name)
        if current and current["attributes"].get("sourceFileChecksum") == digest and current["attributes"]["assetDeliveryState"]["state"] in ("COMPLETE", "UPLOAD_COMPLETE"):
            print(f"  ok  {panel} unchanged")
            continue
        if current:
            asc.call("DELETE", f"appScreenshots/{current['id']}")
        shot = asc.write("POST", "appScreenshots", {"data": {"type": "appScreenshots", "attributes": {"fileName": path.name, "fileSize": len(data)},
                         "relationships": {"appScreenshotSet": {"data": {"type": "appScreenshotSets", "id": sset["id"]}}}}}, f"{panel} reserve")
        if not shot:
            continue
        for op in shot["data"]["attributes"]["uploadOperations"]:
            chunk = data[op["offset"]:op["offset"] + op["length"]]
            headers = {h["name"]: h["value"] for h in op["requestHeaders"]}
            req = urllib.request.Request(op["url"], method=op["method"], data=chunk, headers=headers)
            urllib.request.urlopen(req, timeout=120).read()
        asc.write("PATCH", f"appScreenshots/{shot['data']['id']}", {"data": {"type": "appScreenshots", "id": shot["data"]["id"],
                  "attributes": {"uploaded": True, "sourceFileChecksum": digest}}}, f"{panel} commit")
    # Apple's order is the set's order; ours is the render script's.
    ids = []
    for panel in PANELS:
        refreshed = asc.get(f"appScreenshotSets/{sset['id']}/appScreenshots", **{"fields[appScreenshots]": "fileName"})["data"]
        ids = [s["id"] for panel in PANELS for s in refreshed if s["attributes"]["fileName"] == f"{panel}.png"]
        break
    if len(ids) == len(PANELS):
        asc.write("PATCH", f"appScreenshotSets/{sset['id']}/relationships/appScreenshots", {"data": [{"type": "appScreenshots", "id": i} for i in ids]}, "order")

    if build:
        print("build")
        asc.write("PATCH", f"appStoreVersions/{vid}/relationships/build", {"data": {"type": "builds", "id": build["id"]}}, f"attach build {args.build} ({version_string})")

    print("\nre-read:")
    status(asc, args)


def status(asc: ASC, args=None):
    a = app(asc)
    for v in asc.get(f"apps/{a['id']}/appStoreVersions", **{"fields[appStoreVersions]": "versionString,appStoreState,releaseType,build", "include": "build", "fields[builds]": "version", "limit": "3"})["data"]:
        b = (v.get("relationships", {}).get("build", {}).get("data") or {}).get("id")
        print(f"  {v['attributes']['versionString']:<24} {v['attributes']['appStoreState']:<28} release {v['attributes']['releaseType']:<15} build {'attached' if b else 'none'}")
    subs = asc.get("reviewSubmissions", **{"filter[app]": a["id"], "fields[reviewSubmissions]": "state,submittedDate,platform"})["data"]
    for s in subs:
        print(f"  review submission {s['attributes']['state']} {s['attributes'].get('submittedDate') or ''}")


def item_version(item: dict) -> str | None:
    """The app store version a review-submission item points at, when the response carried the relationship."""
    return (item.get("relationships", {}).get("appStoreVersion", {}).get("data") or {}).get("id")


def submit(asc: ASC, args):
    """A draft submission first: Apple validates completeness when the version is added; a rejected item is resolved before the resubmit."""
    a = app(asc)
    v = editable_version(asc, a["id"])
    if not v:
        sys.exit("no editable version to submit")
    if not (v.get("relationships", {}).get("build", {}).get("data")):
        sys.exit("the version has no build attached — run apply --build first")
    drafts = [x for x in asc.get("reviewSubmissions", **{"filter[app]": a["id"], "filter[state]": "READY_FOR_REVIEW,UNRESOLVED_ISSUES", "fields[reviewSubmissions]": "state,platform"})["data"]]
    if drafts:
        sub = drafts[0]
        print(f"reusing draft submission {sub['id']} ({sub['attributes']['state']})")
    else:
        created = asc.write("POST", "reviewSubmissions", {"data": {"type": "reviewSubmissions", "attributes": {"platform": "IOS"},
                            "relationships": {"app": {"data": {"type": "apps", "id": a["id"]}}}}}, "create draft submission")
        if not created:
            sys.exit(1)
        sub = created["data"]
    # The relationship has to be named in the sparse field set, or it is absent from the response.
    item_fields = {"fields[reviewSubmissionItems]": "state,appStoreVersion", "include": "appStoreVersion"}
    items = asc.get(f"reviewSubmissions/{sub['id']}/items", **item_fields)["data"]
    if not any(item_version(i) == v["id"] for i in items):
        code, out = asc.call("POST", "reviewSubmissionItems", {"data": {"type": "reviewSubmissionItems",
                             "relationships": {"reviewSubmission": {"data": {"type": "reviewSubmissions", "id": sub["id"]}},
                                               "appStoreVersion": {"data": {"type": "appStoreVersions", "id": v["id"]}}}}})
        already = code == 409 and "already added" in errors(out)
        print(f"  {'ok ' if code == 201 or already else 'ERR'} add version {v['attributes']['versionString']} to the draft ({code}{' — already in it' if already else ('' if code == 201 else ': ' + errors(out))})")
        if code != 201 and not already:
            sys.exit("Apple refused the version as an item — the message above says what is missing")
        items = asc.get(f"reviewSubmissions/{sub['id']}/items", **item_fields)["data"]
    print("  items: " + ", ".join(i["attributes"]["state"] for i in items))
    if args.dry_run:
        print("dry run: the draft is complete as far as Apple validates at this step; nothing was submitted")
        return
    # Apple answers a timing-sounding 409 until the rejected item is resolved — docs/plan/app-store-release-ios.md §7.2.
    for i in items:
        if i["attributes"]["state"] != "REJECTED":
            continue
        if item_version(i) != v["id"]:
            print(f"  left alone: rejected item {i['id']} belongs to another version")
            continue
        body = {"data": {"type": "reviewSubmissionItems", "id": i["id"], "attributes": {"resolved": True}}}
        if asc.write("PATCH", f"reviewSubmissionItems/{i['id']}", body, "resolve rejected item") is None:
            sys.exit("Apple refused to mark the rejected item resolved — the message above says why")
    body = {"data": {"type": "reviewSubmissions", "id": sub["id"], "attributes": {"submitted": True}}}
    if asc.write("PATCH", f"reviewSubmissions/{sub['id']}", body, "submit for review") is None:
        sys.exit("Apple refused the submission — the message above says why")
    status(asc)


def main(argv=None) -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = parser.add_subparsers(dest="command", required=True)
    p = sub.add_parser("plan"); p.add_argument("--build"); p.add_argument("--release", choices=["manual", "after-approval"], default="manual")
    p = sub.add_parser("apply"); p.add_argument("--build", required=True); p.add_argument("--release", choices=["manual", "after-approval"], default="manual")
    p = sub.add_parser("submit"); p.add_argument("--dry-run", action="store_true", help="create the draft and add the version, but do not submit")
    sub.add_parser("status")
    args = parser.parse_args(argv)
    asc = ASC()
    {"plan": plan, "apply": apply, "submit": submit, "status": lambda a, _: status(a)}[args.command](asc, args)
    return 0


if __name__ == "__main__":
    sys.exit(main())
