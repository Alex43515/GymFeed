#!/usr/bin/env python3
"""Build-number discovery and Google Play internal-track publishing.

The script uses a short-lived Google Play edit. It never logs credentials and
deletes an uncommitted edit if any upload or track update fails.
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path
from typing import Any
from urllib.parse import quote

from google.auth.transport.requests import AuthorizedSession
from google.oauth2 import service_account


ANDROID_PUBLISHER_SCOPE = "https://www.googleapis.com/auth/androidpublisher"
API_ROOT = "https://androidpublisher.googleapis.com/androidpublisher/v3"
UPLOAD_ROOT = "https://androidpublisher.googleapis.com/upload/androidpublisher/v3"


class PlayApiError(RuntimeError):
    pass


def _session(credentials_file: Path) -> AuthorizedSession:
    credentials = service_account.Credentials.from_service_account_file(
        str(credentials_file), scopes=[ANDROID_PUBLISHER_SCOPE]
    )
    return AuthorizedSession(credentials)


def _json(response: Any, action: str) -> dict[str, Any]:
    try:
        payload = response.json()
    except ValueError:
        payload = {}
    if not response.ok:
        error = payload.get("error", {}) if isinstance(payload, dict) else {}
        message = error.get("message") or response.text[:500]
        raise PlayApiError(f"Google Play {action} failed ({response.status_code}): {message}")
    return payload


def _create_edit(session: AuthorizedSession, package_name: str) -> str:
    package = quote(package_name, safe="")
    response = session.post(f"{API_ROOT}/applications/{package}/edits", json={}, timeout=60)
    payload = _json(response, "edit creation")
    edit_id = payload.get("id")
    if not edit_id:
        raise PlayApiError("Google Play did not return an edit id")
    return str(edit_id)


def _delete_edit(session: AuthorizedSession, package_name: str, edit_id: str) -> None:
    package = quote(package_name, safe="")
    session.delete(f"{API_ROOT}/applications/{package}/edits/{edit_id}", timeout=60)


def next_version_code(credentials_file: Path, package_name: str, minimum: int) -> int:
    session = _session(credentials_file)
    edit_id = _create_edit(session, package_name)
    try:
        package = quote(package_name, safe="")
        response = session.get(
            f"{API_ROOT}/applications/{package}/edits/{edit_id}/bundles", timeout=60
        )
        payload = _json(response, "bundle listing")
        existing = [int(bundle["versionCode"]) for bundle in payload.get("bundles", [])]
        return max([minimum - 1, *existing]) + 1
    finally:
        _delete_edit(session, package_name, edit_id)


def publish_bundle(
    credentials_file: Path,
    package_name: str,
    bundle_file: Path,
    track: str,
    release_name: str,
) -> int:
    if not bundle_file.is_file():
        raise PlayApiError(f"App Bundle not found: {bundle_file}")

    session = _session(credentials_file)
    edit_id = _create_edit(session, package_name)
    committed = False
    package = quote(package_name, safe="")
    try:
        with bundle_file.open("rb") as bundle:
            response = session.post(
                f"{UPLOAD_ROOT}/applications/{package}/edits/{edit_id}/bundles",
                params={"uploadType": "media"},
                headers={"Content-Type": "application/octet-stream"},
                data=bundle,
                timeout=600,
            )
        upload_payload = _json(response, "bundle upload")
        version_code = int(upload_payload["versionCode"])

        track_payload = {
            "track": track,
            "releases": [
                {
                    "name": release_name,
                    "versionCodes": [str(version_code)],
                    "status": "completed",
                }
            ],
        }
        response = session.put(
            f"{API_ROOT}/applications/{package}/edits/{edit_id}/tracks/{quote(track, safe='')}",
            json=track_payload,
            timeout=60,
        )
        _json(response, "track update")

        response = session.post(
            f"{API_ROOT}/applications/{package}/edits/{edit_id}:commit", timeout=60
        )
        _json(response, "edit commit")
        committed = True
        return version_code
    finally:
        if not committed:
            _delete_edit(session, package_name, edit_id)


def _parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser()
    parser.add_argument("--credentials", required=True, type=Path)
    parser.add_argument("--package", required=True)
    subparsers = parser.add_subparsers(dest="command", required=True)

    next_parser = subparsers.add_parser("next-version-code")
    next_parser.add_argument("--minimum", type=int, default=1)

    upload_parser = subparsers.add_parser("publish")
    upload_parser.add_argument("--bundle", required=True, type=Path)
    upload_parser.add_argument("--track", default="internal")
    upload_parser.add_argument("--release-name", required=True)
    return parser


def main() -> int:
    args = _parser().parse_args()
    try:
        if args.command == "next-version-code":
            print(next_version_code(args.credentials, args.package, args.minimum))
        else:
            version_code = publish_bundle(
                args.credentials,
                args.package,
                args.bundle,
                args.track,
                args.release_name,
            )
            print(json.dumps({"track": args.track, "versionCode": version_code}))
        return 0
    except (KeyError, ValueError, PlayApiError) as error:
        print(str(error), file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
