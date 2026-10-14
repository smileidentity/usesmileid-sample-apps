#!/usr/bin/env python3
"""Publishes the Android sample's AppGallery build through the AppGallery Connect Publishing API.

    AGC_CLIENT_ID=... AGC_CLIENT_SECRET=... scripts/appgallery_publish.py highest-version-code
    AGC_CLIENT_ID=... AGC_CLIENT_SECRET=... scripts/appgallery_publish.py publish --apk <path> --notes <file>
    scripts/appgallery_publish.py check-notes android/appgallery/whatsnew-en-US
"""
from __future__ import annotations

import argparse
import json
import os
import sys
import time
import urllib.parse
import urllib.request
import uuid

PACKAGE = "com.usesmileid.sample.android"
API = "https://connect-api.cloud.huawei.com/api"
SOFTWARE_PACKAGE = 5
NOTES_LANG = "en-US"
NOTES_LIMIT = 500
# AGC parses an uploaded package asynchronously and refuses a submit until it has, about two minutes.
PARSE_WAIT_S = 150


class AgcError(RuntimeError):
    pass


def checked(body: dict) -> dict:
    """AGC reports failures in `ret.code` with an HTTP 200, so a call is only good when that is 0."""
    ret = body.get("ret") or {}
    if ret.get("code", 0) != 0:
        raise AgcError(f"AppGallery Connect error {ret.get('code')}: {ret.get('msg', '')}")
    return body


def call(method: str, url: str, headers: dict, body: dict | None = None) -> dict:
    data = json.dumps(body).encode() if body is not None else None
    req = urllib.request.Request(url, data=data, method=method, headers={**headers, "Content-Type": "application/json"})
    with urllib.request.urlopen(req, timeout=120) as response:
        raw = response.read()
    return checked(json.loads(raw) if raw else {})


def auth_headers(client_id: str, client_secret: str) -> dict:
    token = call("POST", f"{API}/oauth2/v1/token", {}, {
        "grant_type": "client_credentials", "client_id": client_id, "client_secret": client_secret,
    })["access_token"]
    return {"client_id": client_id, "Authorization": f"Bearer {token}"}


def app_id(headers: dict) -> str:
    query = urllib.parse.urlencode({"packageName": PACKAGE})
    ids = call("GET", f"{API}/publish/v2/appid-list?{query}", headers).get("appids", [])
    if not ids:
        raise AgcError(f"AppGallery Connect has no app for {PACKAGE}; create it in the console first")
    return ids[0]["value"]


def highest_version_code(app_info: dict) -> int:
    """The higher of the draft's code and the live one's: a draft can sit above what is on the shelf."""
    info = app_info.get("appInfo", {})
    return max(int(info.get("versionCode") or 0), int(info.get("onShelfVersionCode") or 0))


def release_notes(path: str) -> str:
    text = open(path, encoding="utf-8").read().strip()
    if not text:
        raise AgcError(f"{path} is empty; stale or missing notes would ship silently")
    if len(text) > NOTES_LIMIT:
        raise AgcError(f"{path} is {len(text)} characters; AppGallery takes at most {NOTES_LIMIT}")
    return text


def multipart(fields: dict, file_name: str, content: bytes) -> tuple[bytes, str]:
    boundary = uuid.uuid4().hex
    parts = [f'--{boundary}\r\nContent-Disposition: form-data; name="{k}"\r\n\r\n{v}\r\n'.encode() for k, v in fields.items()]
    parts.append(
        f'--{boundary}\r\nContent-Disposition: form-data; name="file"; filename="{file_name}"\r\n'
        "Content-Type: application/octet-stream\r\n\r\n".encode() + content + b"\r\n"
    )
    parts.append(f"--{boundary}--\r\n".encode())
    return b"".join(parts), f"multipart/form-data; boundary={boundary}"


def destination(upload_response: dict) -> str:
    """Where AGC stored the file. Its own field is spelt `fileDestUlr`; both spellings are read."""
    result = upload_response.get("result", {})
    if str(result.get("resultCode", "0")) != "0":
        raise AgcError(f"upload refused: {upload_response}")
    rsp = result.get("UploadFileRsp", {})
    for info in rsp.get("fileInfoList") or [rsp]:
        url = info.get("fileDestUlr") or info.get("fileDestUrl")
        if url:
            return url
    raise AgcError(f"upload reported no destination: {upload_response}")


def upload(headers: dict, app: str, apk: str) -> str:
    query = urllib.parse.urlencode({"appId": app, "suffix": "apk"})
    target = call("GET", f"{API}/publish/v2/upload-url?{query}", headers)
    with open(apk, "rb") as package:
        body, content_type = multipart({"authCode": target["authCode"], "fileCount": "1"}, os.path.basename(apk), package.read())
    req = urllib.request.Request(target["uploadUrl"], data=body, method="POST", headers={"Content-Type": content_type})
    with urllib.request.urlopen(req, timeout=900) as response:
        return destination(json.loads(response.read()))


def publish(headers: dict, apk: str, notes: str) -> None:
    app = app_id(headers)
    query = urllib.parse.urlencode({"appId": app})
    call("PUT", f"{API}/publish/v2/app-language-info?{query}", headers, {"lang": NOTES_LANG, "newFeatures": notes})
    dest = upload(headers, app, apk)
    call("PUT", f"{API}/publish/v2/app-file-info?{query}", headers, {
        "fileType": SOFTWARE_PACKAGE, "files": [{"fileName": os.path.basename(apk), "fileDestUrl": dest}],
    })
    time.sleep(PARSE_WAIT_S)
    call("POST", f"{API}/publish/v2/app-submit?{query}", headers)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    sub = parser.add_subparsers(dest="command", required=True)
    sub.add_parser("highest-version-code")
    pub = sub.add_parser("publish")
    pub.add_argument("--apk", required=True)
    pub.add_argument("--notes", required=True)
    sub.add_parser("check-notes").add_argument("notes")
    args = parser.parse_args()
    if args.command == "check-notes":
        release_notes(args.notes)
        return 0
    if args.command == "publish":
        notes = release_notes(args.notes)
    headers = auth_headers(os.environ["AGC_CLIENT_ID"], os.environ["AGC_CLIENT_SECRET"])
    if args.command == "highest-version-code":
        query = urllib.parse.urlencode({"appId": app_id(headers)})
        print(highest_version_code(call("GET", f"{API}/publish/v2/app-info?{query}", headers)))
    else:
        publish(headers, args.apk, notes)
        print(f"Submitted {os.path.basename(args.apk)} for AppGallery review")
    return 0


if __name__ == "__main__":
    sys.exit(main())
