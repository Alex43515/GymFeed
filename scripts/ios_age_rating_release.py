#!/usr/bin/env python3
"""Complete GymFeed's App Store age rating answers for an existing app.

The App Store Connect key is supplied by the protected GitHub environment.
Only the app's current editable age rating declaration is updated.
"""

from __future__ import annotations

import argparse
import json
import os
import sys
import time
from urllib.error import HTTPError
from urllib.request import Request, urlopen

import jwt


API_ROOT = "https://api.appstoreconnect.apple.com/v1"


def _boolean(value: str) -> bool:
    if value.lower() not in {"true", "false"}:
        raise ValueError("Expected true or false")
    return value.lower() == "true"


def _request(token: str, method: str, path: str, body: dict | None = None) -> dict:
    payload = None if body is None else json.dumps(body).encode("utf-8")
    request = Request(
        f"{API_ROOT}{path}",
        data=payload,
        method=method,
        headers={
            "Authorization": f"Bearer {token}",
            "Accept": "application/json",
            "Content-Type": "application/json",
        },
    )
    try:
        with urlopen(request, timeout=60) as response:
            return json.load(response)
    except HTTPError as error:
        detail = error.read().decode("utf-8", errors="replace")[:2000]
        raise RuntimeError(f"App Store Connect {method} {path} failed ({error.code}): {detail}") from error


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--app-id", required=True)
    parser.add_argument("--advertising", default="false")
    parser.add_argument("--age-assurance", default="false")
    args = parser.parse_args()

    now = int(time.time())
    private_key = os.environ["APP_STORE_CONNECT_PRIVATE_KEY"]
    if private_key.startswith("@file:"):
        with open(private_key[6:], encoding="utf-8") as key_file:
            private_key = key_file.read()
    token = jwt.encode(
        {"iss": os.environ["APP_STORE_CONNECT_ISSUER_ID"],
         "iat": now, "exp": now + 600, "aud": "appstoreconnect-v1"},
        private_key,
        algorithm="ES256",
        headers={"kid": os.environ["APP_STORE_CONNECT_KEY_IDENTIFIER"]},
    )
    infos = _request(token, "GET", f"/apps/{args.app_id}/appInfos")['data']
    editable = [info for info in infos if info.get('attributes', {}).get('state') == 'PREPARE_FOR_SUBMISSION']
    if len(editable) == 1:
        info = editable[0]
    elif len(infos) == 1:
        info = infos[0]
    else:
        states = [(info['id'], info.get('attributes', {}).get('state')) for info in infos]
        raise RuntimeError(f"Cannot identify current app info: {states}")
    path = f"/appInfos/{info['id']}/ageRatingDeclaration"
    declaration = _request(token, "GET", path)["data"]
    declaration_id = declaration["id"]
    current = declaration.get("attributes") or {}

    # These capabilities are present in GymFeed's fitness, feed and chat UI.
    required = {
        "healthOrWellnessTopics": True,
        "userGeneratedContent": True,
        "messagingAndChat": True,
        "socialMedia": True,
        "advertising": _boolean(args.advertising),
        "ageAssurance": _boolean(args.age_assurance),
    }
    # Preserve already answered content questions; fill only missing values.
    missing_defaults = {
        "gunsOrOtherWeapons": "NONE",
        "lootBox": False,
        "parentalControls": False,
        "socialMediaAgeRestricted": False,
    }
    changes = {key: value for key, value in required.items()
               if current.get(key) != value}
    changes.update({key: value for key, value in missing_defaults.items()
                    if current.get(key) is None})

    if changes:
        _request(token, "PATCH", f"/ageRatingDeclarations/{declaration_id}", {
            "data": {
                "type": "ageRatingDeclarations",
                "id": declaration_id,
                "attributes": changes,
            }
        })
    verified = _request(token, "GET", path)["data"]["attributes"]
    for key, value in changes.items():
        if verified.get(key) != value:
            raise RuntimeError(f"Age rating declaration did not retain {key}")
    print(f"Age rating declaration {declaration_id} updated: {json.dumps(changes, sort_keys=True)}")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (KeyError, ValueError, RuntimeError) as error:
        print(str(error), file=sys.stderr)
        raise SystemExit(1) from error
