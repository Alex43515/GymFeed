"""Download 20 media items from a public Instagram profile, newest posts first.

One-time prerequisite: an Apify account with credit and APIFY_TOKEN configured.
No Instagram login, browser access, or third-party Python packages are used.
"""

import argparse
import hashlib
from http.client import HTTPException
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import time
from urllib.error import HTTPError, URLError
from urllib.parse import urlencode, urlsplit
from urllib.request import Request, urlopen


API = "https://api.apify.com/v2"
ACTOR = "apify~instagram-scraper"
LIMIT = 20
MAX_BYTES = 512 * 1024 * 1024
TERMINAL = {"SUCCEEDED", "FAILED", "TIMED-OUT", "ABORTED"}


class ApifyHTTPError(RuntimeError):
    def __init__(self, status, message):
        self.status = status
        super().__init__(message)


def profile_url(value):
    parsed = urlsplit(value)
    handle = parsed.path.strip("/").lower()
    if (parsed.scheme not in {"https", "http"}
            or parsed.netloc.lower() not in {"www.instagram.com", "instagram.com"}
            or not re.fullmatch(r"[a-z0-9_][a-z0-9_.]{0,29}", handle)
            or handle.endswith(".") or ".." in handle
            or handle in {"accounts", "explore", "direct", "p", "reel", "reels", "stories", "tv"}
            or re.fullmatch(r"(?:con|prn|aux|nul|com[1-9]|lpt[1-9])(?:\..*)?", handle)):
        raise argparse.ArgumentTypeError("Enter a public profile URL, e.g. https://www.instagram.com/fiit/")
    return f"https://www.instagram.com/{handle}/", handle


def desktop():
    if os.name == "nt":
        import winreg
        with winreg.OpenKey(winreg.HKEY_CURRENT_USER,
                            r"Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders") as key:
            return Path(os.path.expandvars(winreg.QueryValueEx(key, "Desktop")[0]))
    return Path.home() / "Desktop"


def token_from_environment():
    token = os.environ.get("APIFY_TOKEN") or os.environ.get("APIFY_API_TOKEN")
    if not token and os.name == "nt":
        import winreg
        try:
            with winreg.OpenKey(winreg.HKEY_CURRENT_USER, "Environment") as key:
                token = winreg.QueryValueEx(key, "APIFY_TOKEN")[0]
        except OSError:
            pass
    return (token or "").strip()


def write_json(path, data):
    temp = path.with_suffix(path.suffix + ".tmp")
    temp.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    temp.replace(path)


def read_json(path):
    return json.loads(path.read_text(encoding="utf-8"))


def api_request(token, path, body=None, _attempt=0):
    # The bearer token is sent only to Apify, never to a media CDN.
    request = Request(API + path, headers={"Authorization": f"Bearer {token}",
                      "Content-Type": "application/json"},
                      data=None if body is None else json.dumps(body).encode())
    try:
        with urlopen(request, timeout=45) as response:
            return json.load(response)
    except HTTPError as error:
        if body is None and error.code in {408, 429, 500, 502, 503, 504} and _attempt < 2:
            time.sleep(2)
            return api_request(token, path, _attempt=_attempt + 1)
        hints = {401: "Invalid API key.", 402: "Apify credit or a subscription is required.",
                 403: "Apify denied this request.", 429: "Apify rate limit; retry later."}
        raise ApifyHTTPError(error.code, f"Apify HTTP {error.code}. " + hints.get(error.code, "Request failed.")) from None
    except (URLError, TimeoutError, HTTPException, ConnectionError, json.JSONDecodeError):
        if body is None and _attempt < 2:
            time.sleep(2)
            return api_request(token, path, _attempt=_attempt + 1)
        raise RuntimeError("Apify connection failed. No automatic paid-run retry was made.") from None


def fetch_posts(token, url, output, max_cost):
    state_path = output / ".apify-run.json"
    state = read_json(state_path) if state_path.exists() else {"profile_url": url}
    if state.get("profile_url") != url:
        raise RuntimeError("This folder belongs to a different profile.")
    if state.get("start_pending") and not state.get("id"):
        raise RuntimeError("A previous run-start response was lost. Check Apify Console before removing .apify-run.json; a charged run may already exist.")
    if state.get("id"):
        run = api_request(token, f"/actor-runs/{state['id']}")["data"]
    else:
        state["start_pending"] = True
        write_json(state_path, state)
        params = urlencode({"timeout": 600, "maxTotalChargeUsd": max_cost})
        print(f"Starting Apify run (maximum charge ${max_cost:.2f})...", flush=True)
        try:
            result = api_request(token, f"/actors/{ACTOR}/runs?{params}",
                                 {"directUrls": [url], "resultsType": "posts", "resultsLimit": LIMIT})
        except ApifyHTTPError as error:
            if error.status in {400, 401, 402, 403, 404, 422, 429}:
                state["start_pending"] = False
                write_json(state_path, state)
            raise
        run = result["data"]
        state.update(id=run["id"], start_pending=False)
        write_json(state_path, state)
    deadline = time.monotonic() + 660
    while run["status"] not in TERMINAL:
        if time.monotonic() > deadline:
            raise RuntimeError("Run still pending. Rerun this command to reconnect to the same run.")
        print(f"Apify: {run['status']} (run {run['id']})", flush=True)
        # Bounded server-side wait; Ctrl+C leaves the run ID available for resumption.
        run = api_request(token, f"/actor-runs/{run['id']}?waitForFinish=10")["data"]
    if run["status"] != "SUCCEEDED":
        raise RuntimeError(f"Apify run {run['id']} ended with {run['status']}. Check the run in Apify Console.")
    dataset = run["defaultDatasetId"]
    posts = api_request(token, f"/datasets/{dataset}/items?format=json&clean=true&limit={LIMIT}")
    if isinstance(posts, list):
        unavailable = [{key: post.get(key) for key in ("shortCode", "url", "error", "errorDescription")}
                       for post in posts if post.get("error")]
        if unavailable:
            write_json(output / "provider-warnings.json", unavailable)
            print(f"Skipped {len(unavailable)} unavailable post(s); details in provider-warnings.json.", flush=True)
        posts = [post for post in posts if not post.get("error")]
    if not isinstance(posts, list) or not posts:
        raise RuntimeError("Apify returned no usable posts. Check profile availability and the run in Apify Console.")
    return posts


def select_media(posts):
    selected, seen = [], set()
    # Dataset insertion order can reflect completion time, not profile order.
    for post in sorted(posts, key=lambda item: item.get("timestamp") or "", reverse=True):
        code = str(post.get("shortCode") or post.get("id") or "")
        if not re.fullmatch(r"[A-Za-z0-9_-]+", code):
            raise RuntimeError("Post is missing a valid ID.")
        children = post.get("childPosts") or []
        if post.get("type") == "Sidecar" and not children:
            raise RuntimeError(f"Carousel {code} is missing its children; refusing to save only its cover.")
        for index, child in enumerate(children or [post], 1):
            item_id = f"{code}_{index:02}"
            if item_id in seen:
                continue
            seen.add(item_id)
            video = bool(child.get("videoUrl")) or child.get("type") == "Video"
            media_url = child.get("videoUrl") if video else child.get("displayUrl")
            selected.append({"id": item_id, "type": "video" if video else "photo",
                             "media_url": media_url, "audio_url": child.get("audioUrl"),
                             "caption": post.get("caption") or "", "timestamp": post.get("timestamp"),
                             "source_url": post.get("url") or f"https://www.instagram.com/p/{code}/"})
            if len(selected) == LIMIT:
                return selected
    return selected


def media_request(url, destination, _attempt=0):
    parsed = urlsplit(url or "")
    if parsed.scheme != "https" or not parsed.hostname or parsed.username or parsed.password:
        raise RuntimeError("Missing or invalid HTTPS media URL.")
    request = Request(url, headers={"User-Agent": "GymfeedMediaDownloader/1.0"})
    try:
        with urlopen(request, timeout=45) as response, destination.open("wb") as target:
            total = 0
            while chunk := response.read(1024 * 1024):
                total += len(chunk)
                if total > MAX_BYTES:
                    raise RuntimeError("Media exceeds the 512 MB file limit.")
                target.write(chunk)
            if not total:
                raise RuntimeError("Empty media response.")
            expected = response.headers.get("Content-Length")
            if expected and total != int(expected):
                raise RuntimeError("Incomplete media download.")
    except HTTPError as error:
        if error.code in {408, 429, 500, 502, 503, 504} and _attempt < 2:
            time.sleep(2)
            return media_request(url, destination, _attempt + 1)
        raise RuntimeError(f"Media HTTP {error.code}; the media link may have expired.") from None
    except (URLError, TimeoutError, HTTPException, ConnectionError):
        if _attempt < 2:
            time.sleep(2)
            return media_request(url, destination, _attempt + 1)
        raise RuntimeError("Media connection failed.") from None


def media_extension(path, kind):
    with path.open("rb") as source:
        header = source.read(32)
    if kind == "video" and header[4:8] == b"ftyp":
        return ".mp4"
    if kind == "photo":
        if header.startswith(b"\xff\xd8\xff"):
            return ".jpg"
        if header.startswith(b"\x89PNG\r\n\x1a\n"):
            return ".png"
        if header.startswith(b"RIFF") and header[8:12] == b"WEBP":
            return ".webp"
    raise RuntimeError("Response is not a supported media file (possibly an HTML error page).")


def ffmpeg_path():
    installed = shutil.which("ffmpeg")
    bundled = Path(__file__).resolve().parents[1] / "marketing/node_modules/ffmpeg-static/ffmpeg.exe"
    return installed or (str(bundled) if bundled.is_file() else None)


def inspect_video(path, executable):
    if not executable:
        return {"validation": "header_only", "has_audio": None}
    result = subprocess.run([executable, "-hide_banner", "-i", str(path), "-f", "null", "-"],
                            capture_output=True, text=True, errors="replace", timeout=180)
    if result.returncode or "Video:" not in result.stderr:
        raise RuntimeError("Video failed the FFmpeg decode check.")
    return {"validation": "decoded", "has_audio": "Audio:" in result.stderr}


def sha256(path):
    with path.open("rb") as source:
        return hashlib.file_digest(source, "sha256").hexdigest()


def download_selected(items, output, url, executable):
    manifest_path = output / "manifest.json"
    previous = read_json(manifest_path) if manifest_path.exists() else {}
    if previous and previous.get("profile_url") != url:
        raise RuntimeError("The manifest belongs to a different profile.")
    old_items = {item["id"]: item for item in previous.get("items", [])}
    manifest = {"profile_url": url, "requested": LIMIT, "order": "newest posts first; carousel children count individually",
                "selected": len(items), "saved": 0, "status": "in_progress",
                "items": [dict(old_items.get(item["id"], item)) for item in items]}
    write_json(manifest_path, manifest)
    for number, item in enumerate(items, 1):
        entry = dict(item)
        stem = f"{number:02}_{item['id']}"
        partial = output / (stem + ".part")
        audio = output / (stem + ".audio.part")
        merged = output / (stem + ".merged.mp4")
        try:
            old = old_items.get(item["id"], {})
            old_name = old.get("file", "")
            old_file = output / old_name
            if (old.get("status") == "saved" and Path(old_name).name == old_name
                    and old_file.is_file() and old.get("sha256") == sha256(old_file)):
                entry.update({key: old[key] for key in ("file", "sha256", "bytes", "validation", "has_audio") if key in old})
            else:
                media_request(item["media_url"], partial)
                extension = media_extension(partial, item["type"])
                verification = {"validation": "header_checked"}
                if item["type"] == "video":
                    verification = inspect_video(partial, executable)
                    if item.get("audio_url") and verification.get("has_audio") is not True:
                        if not executable:
                            raise RuntimeError("FFmpeg is needed to combine the separate video and audio tracks.")
                        media_request(item["audio_url"], audio)
                        result = subprocess.run([executable, "-nostdin", "-y", "-i", str(partial), "-i", str(audio),
                                                 "-map", "0:v:0", "-map", "1:a:0", "-c", "copy",
                                                 "-movflags", "+faststart", str(merged)], capture_output=True, timeout=180)
                        if result.returncode:
                            raise RuntimeError("Could not combine the audio and video tracks.")
                        verification = inspect_video(merged, executable)
                        merged.replace(partial)
                filename = stem + extension
                destination = output / filename
                if destination.exists():
                    raise RuntimeError(f"Existing unverified file will not be overwritten: {filename}")
                partial.replace(destination)
                entry.update(file=filename, sha256=sha256(destination), bytes=destination.stat().st_size, **verification)
            entry["status"] = "saved"
            manifest["saved"] += 1
            print(f"[{number}/{len(items)}] Saved {entry['file']}", flush=True)
        except (RuntimeError, OSError, ValueError, subprocess.TimeoutExpired) as error:
            entry.update(status="failed", error=str(error))
            print(f"[{number}/{len(items)}] Failed {item['id']}: {error}", file=sys.stderr, flush=True)
        finally:
            for temporary in (partial, audio, merged):
                temporary.unlink(missing_ok=True)
        manifest["items"][number - 1] = entry
        write_json(manifest_path, manifest)
    manifest["status"] = "complete" if manifest["saved"] == LIMIT else "partial"
    write_json(manifest_path, manifest)
    print(f"Saved {manifest['saved']}/{LIMIT} media files to {output}")
    return 0 if manifest["status"] == "complete" else 2


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("url", type=profile_url)
    parser.add_argument("--output", type=Path, help="Default: Desktop/<profile name>")
    parser.add_argument("--max-cost-usd", type=float, default=0.10, help="Maximum Apify run charge (default: 0.10)")
    args = parser.parse_args(argv)
    if not 0 < args.max_cost_usd <= 10:
        parser.error("--max-cost-usd must be between 0 and 10.")
    url, handle = args.url
    output = (args.output or desktop() / handle).resolve()
    output.mkdir(parents=True, exist_ok=True)
    token = token_from_environment()
    if not token:
        print("No APIFY_TOKEN configured. Create an Apify account, then run scripts/setup_instagram.ps1 once. "
              f"No media downloaded. Destination: {output}", file=sys.stderr)
        return 1
    try:
        manifest_path = output / "manifest.json"
        if manifest_path.exists() and read_json(manifest_path).get("profile_url") != url:
            raise RuntimeError("The destination manifest belongs to a different profile.")
        posts = fetch_posts(token, url, output, args.max_cost_usd)
        items = select_media(posts)
        if not items:
            raise RuntimeError("No media items returned.")
        return download_selected(items, output, url, ffmpeg_path())
    except (RuntimeError, OSError, ValueError, KeyError) as error:
        print(f"Download stopped: {error}", file=sys.stderr)
        return 1
    except KeyboardInterrupt:
        print("Interrupted. Rerun the same command to resume the saved run.", file=sys.stderr)
        return 130


if __name__ == "__main__":
    sys.exit(main())
