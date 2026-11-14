"""Download 20 media files per profile from a text list of Instagram/ig.me URLs."""

import argparse
from concurrent.futures import ThreadPoolExecutor, as_completed
from datetime import datetime, timezone
import json
from pathlib import Path
import subprocess
import sys
from urllib.parse import urlsplit

import download_instagram as downloader


def load_profiles(path):
    profiles = []
    seen = set()
    for line in path.read_text(encoding="utf-8-sig").splitlines():
        value = line.strip()
        if not value or value.startswith("#"):
            continue
        parsed = urlsplit(value)
        if parsed.netloc.lower() == "ig.me" and parsed.path.startswith("/m/"):
            value = "https://www.instagram.com/" + parsed.path[3:].strip("/") + "/"
        url, handle = downloader.profile_url(value)
        if handle not in seen:
            profiles.append((url, handle))
            seen.add(handle)
    return profiles


def run_profile(profile, root, logs):
    url, handle = profile
    output = root / handle
    log_path = logs / (handle + ".log")
    command = [sys.executable, str(Path(__file__).with_name("download_instagram.py")),
               url, "--output", str(output)]
    print(f"START {handle}", flush=True)
    with log_path.open("a", encoding="utf-8") as log:
        log.write(f"\nBatch attempt {datetime.now(timezone.utc).isoformat()}\n")
        log.flush()
        result = subprocess.run(command, stdout=log, stderr=subprocess.STDOUT, check=False)
    manifest_path = output / "manifest.json"
    manifest = downloader.read_json(manifest_path) if manifest_path.exists() else {}
    saved = [item for item in manifest.get("items", []) if item.get("status") == "saved"]
    text = log_path.read_text(encoding="utf-8", errors="replace")
    error_lines = [line for line in text.splitlines() if "Download stopped:" in line or "] Failed " in line]
    record = {"handle": handle, "url": url, "folder": str(output), "exit_code": result.returncode,
              "saved": len(saved), "photos": sum(i["type"] == "photo" for i in saved),
              "videos": sum(i["type"] == "video" for i in saved),
              "bytes": sum(i.get("bytes", 0) for i in saved),
              "status": "complete" if result.returncode == 0 and len(saved) == 20 else "partial" if saved else "failed",
              "errors": error_lines[-20:], "log": str(log_path)}
    print(f"DONE {handle}: {record['saved']}/20 ({record['photos']} photos, {record['videos']} videos); {record['status']}", flush=True)
    return record


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("list", type=Path)
    parser.add_argument("--output-root", type=Path, default=downloader.desktop())
    parser.add_argument("--workers", type=int, choices=range(1, 5), default=4)
    args = parser.parse_args()
    profiles = load_profiles(args.list)
    if not profiles:
        parser.error("No profile URLs found.")
    if not downloader.token_from_environment():
        parser.error("APIFY_TOKEN is not configured.")
    root = args.output_root.resolve()
    root.mkdir(parents=True, exist_ok=True)
    logs = args.list.resolve().parent / "logs"
    logs.mkdir(parents=True, exist_ok=True)
    report_path = args.list.resolve().parent / "report.json"
    records = {}
    report = {"started_at": datetime.now(timezone.utc).isoformat(), "requested_profiles": len(profiles),
              "requested_media_per_profile": 20, "output_root": str(root), "profiles": []}
    downloader.write_json(report_path, report)
    print(f"Profiles: {len(profiles)}. Maximum combined new-run charge: ${len(profiles) * 0.1:.2f}. Destination: {root}", flush=True)
    with ThreadPoolExecutor(max_workers=args.workers) as pool:
        tasks = {pool.submit(run_profile, p, root, logs): p for p in profiles}
        for future in as_completed(tasks):
            url, handle = tasks[future]
            try:
                records[handle] = future.result()
            except Exception as error:
                records[handle] = {"handle": handle, "url": url, "status": "failed", "saved": 0,
                                   "photos": 0, "videos": 0, "errors": [str(error)]}
                print(f"FAILED {handle}: {error}", flush=True)
            report["profiles"] = [records[h] for _, h in profiles if h in records]
            report["finished_profiles"] = len(records)
            report["saved_total"] = sum(r["saved"] for r in records.values())
            downloader.write_json(report_path, report)
    report["finished_at"] = datetime.now(timezone.utc).isoformat()
    downloader.write_json(report_path, report)
    print(f"Batch finished: {report['saved_total']} media files. Report: {report_path}", flush=True)
    return int(any(r["status"] != "complete" for r in records.values()))


if __name__ == "__main__":
    sys.exit(main())
