"""Offline regression tests. These do not validate access to live Instagram."""

import base64
import io
from http.client import IncompleteRead
import json
from pathlib import Path
import subprocess
import tempfile
import unittest
from unittest.mock import patch
from urllib.parse import parse_qs, urlsplit

import download_instagram as downloader


PNG = base64.b64decode("iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+a3ioAAAAASUVORK5CYII=")
PROFILE = "https://www.instagram.com/fiit/"


class Response(io.BytesIO):
    def __init__(self, data):
        super().__init__(data)
        self.headers = {"Content-Length": str(len(data))}


def post(code, kind="Image"):
    return {"shortCode": code, "type": kind, "caption": "Original caption\nTrening 💪 ñ",
            "displayUrl": f"https://cdn.example/{code}.png",
            **({"videoUrl": f"https://cdn.example/{code}.mp4"} if kind == "Video" else {})}


class DownloaderTests(unittest.TestCase):
    def test_interrupted_get_retries_but_paid_post_does_not(self):
        with patch.object(downloader.time, "sleep"):
            with patch.object(downloader, "urlopen", side_effect=[IncompleteRead(b""), Response(b'{"ok": true}')]) as request:
                self.assertEqual(downloader.api_request("test-key", "/actor-runs/test"), {"ok": True})
                self.assertEqual(request.call_count, 2)
            with patch.object(downloader, "urlopen", side_effect=IncompleteRead(b"")) as request:
                with self.assertRaises(RuntimeError):
                    downloader.api_request("test-key", "/actors/test/runs", {"test": True})
                self.assertEqual(request.call_count, 1)

    def test_unavailable_post_does_not_discard_public_posts(self):
        with tempfile.TemporaryDirectory() as directory:
            folder = Path(directory)
            downloader.write_json(folder / ".apify-run.json", {"profile_url": PROFILE, "id": "run1"})
            responses = [{"data": {"id": "run1", "status": "SUCCEEDED", "defaultDatasetId": "data1"}},
                         [post("PUBLIC"), {"shortCode": "PRIVATE", "error": "restricted_page"}]]
            with patch.object(downloader, "api_request", side_effect=responses):
                posts = downloader.fetch_posts("test-key", PROFILE, folder, 0.1)
            self.assertEqual([p["shortCode"] for p in posts], ["PUBLIC"])
            self.assertEqual(downloader.read_json(folder / "provider-warnings.json")[0]["error"], "restricted_page")

    def test_posts_sorted_newest_before_applying_media_limit(self):
        posts = [{**post(f"P{i}"), "timestamp": f"2026-10-{i + 1:02}T12:00:00.000Z"} for i in range(23)]
        items = downloader.select_media(posts)
        self.assertEqual(len(items), 20)
        self.assertEqual(items[0]["id"], "P22_01")
        self.assertEqual(items[-1]["id"], "P3_01")

    def test_profile_validation(self):
        self.assertEqual(downloader.profile_url(PROFILE + "?igsh=abc"), (PROFILE, "fiit"))
        for url in ("https://evil.example/fiit/", "https://instagram.com/p/ABC/",
                    "https://instagram.com/../", "https://instagram.com/con/",
                    "https://instagram.com/fiit./", "https://instagram.com@evil.example/fiit/"):
            with self.assertRaises(downloader.argparse.ArgumentTypeError):
                downloader.profile_url(url)

    def test_carousel_count_order_duplicates_and_video_thumbnail(self):
        carousel = {**post("CAR"), "type": "Sidecar",
                    "childPosts": [post("CHILD1"), post("CHILD2", "Video")]}
        items = downloader.select_media([carousel, carousel] + [post(f"P{i}") for i in range(25)])
        self.assertEqual(len(items), 20)
        self.assertEqual([item["id"] for item in items[:3]], ["CAR_01", "CAR_02", "P0_01"])
        self.assertEqual(items[1]["media_url"], "https://cdn.example/CHILD2.mp4")
        self.assertEqual(items[1]["caption"], carousel["caption"])
        with self.assertRaises(RuntimeError):
            downloader.select_media([{**post("CAR"), "type": "Sidecar"}])

    def test_full_flow_and_resume_uses_one_run(self):
        with tempfile.TemporaryDirectory() as directory:
            folder = Path(directory)
            calls = []
            posts = [post(f"P{i}") for i in range(23)]

            def respond(request, timeout):
                calls.append(request)
                url = request.full_url
                if "/actors/" in url:
                    params = parse_qs(urlsplit(url).query)
                    self.assertEqual(params["maxTotalChargeUsd"], ["0.1"])
                    self.assertEqual(json.loads(request.data),
                                     {"directUrls": [PROFILE], "resultsType": "posts", "resultsLimit": 20})
                    value = {"data": {"id": "run1", "status": "RUNNING", "defaultDatasetId": "data1"}}
                elif "/actor-runs/" in url:
                    value = {"data": {"id": "run1", "status": "SUCCEEDED", "defaultDatasetId": "data1"}}
                elif "/datasets/" in url:
                    value = posts
                else:
                    self.assertIsNone(request.get_header("Authorization"))
                    return Response(PNG)
                self.assertEqual(request.get_header("Authorization"), "Bearer test-key")
                return Response(json.dumps(value).encode())

            with patch.object(downloader, "urlopen", side_effect=respond):
                with patch.object(downloader, "token_from_environment", return_value="test-key"):
                    self.assertEqual(downloader.main([PROFILE, "--output", str(folder)]), 0)
                    self.assertEqual(downloader.main([PROFILE, "--output", str(folder)]), 0)
            self.assertEqual(sum("/actors/" in call.full_url for call in calls), 1)
            self.assertEqual(sum("cdn.example" in call.full_url for call in calls), 20)
            self.assertEqual(len(list(folder.glob("*.png"))), 20)
            manifest = downloader.read_json(folder / "manifest.json")
            self.assertEqual(manifest["saved"], 20)
            self.assertEqual(manifest["status"], "complete")
            self.assertEqual(manifest["items"][0]["caption"], posts[0]["caption"])
            self.assertNotIn("test-key", (folder / ".apify-run.json").read_text())

    def test_html_and_missing_video_are_failures_not_photos(self):
        items = downloader.select_media([post("HTML"), {**post("VIDEO"), "type": "Video"}])
        with tempfile.TemporaryDirectory() as directory:
            folder = Path(directory)
            with patch.object(downloader, "urlopen", return_value=Response(b"<html>Login</html>")):
                self.assertEqual(downloader.download_selected(items, folder, PROFILE, None), 2)
            manifest = downloader.read_json(folder / "manifest.json")
            self.assertEqual(manifest["saved"], 0)
            self.assertTrue(all(item["status"] == "failed" for item in manifest["items"]))
            self.assertEqual(list(folder.glob("*.part")), [])

    def test_missing_token_does_not_contact_any_service(self):
        with tempfile.TemporaryDirectory() as directory:
            with patch.object(downloader, "token_from_environment", return_value=""):
                with patch.object(downloader, "urlopen") as network:
                    self.assertEqual(downloader.main([PROFILE, "--output", directory]), 1)
                    network.assert_not_called()

    def test_lost_start_response_does_not_repeat_charge(self):
        with tempfile.TemporaryDirectory() as directory:
            folder = Path(directory)
            with patch.object(downloader, "api_request", side_effect=RuntimeError("lost response")) as api:
                with self.assertRaises(RuntimeError):
                    downloader.fetch_posts("test-key", PROFILE, folder, 0.1)
                with self.assertRaisesRegex(RuntimeError, "previous run-start response was lost"):
                    downloader.fetch_posts("test-key", PROFILE, folder, 0.1)
                self.assertEqual(api.call_count, 1)

    def test_invalid_token_can_be_fixed_without_resetting_run_file(self):
        with tempfile.TemporaryDirectory() as directory:
            folder = Path(directory)
            with patch.object(downloader, "api_request", side_effect=downloader.ApifyHTTPError(401, "Invalid key")):
                with self.assertRaises(downloader.ApifyHTTPError):
                    downloader.fetch_posts("bad-key", PROFILE, folder, 0.1)
            self.assertFalse(downloader.read_json(folder / ".apify-run.json")["start_pending"])

    def test_real_mp4_audio_decode(self):
        ffmpeg = downloader.ffmpeg_path()
        if not ffmpeg:
            self.skipTest("FFmpeg not available")
        with tempfile.TemporaryDirectory() as directory:
            folder = Path(directory)
            fixture = folder / "fixture.mp4"
            subprocess.run([ffmpeg, "-nostdin", "-y", "-f", "lavfi", "-i", "color=c=blue:s=64x64:r=10",
                            "-f", "lavfi", "-i", "sine=frequency=440:sample_rate=44100",
                            "-t", "0.3", "-c:v", "libx264", "-pix_fmt", "yuv420p", "-c:a", "aac", str(fixture)],
                           check=True, capture_output=True, timeout=30)
            result_folder = folder / "result"
            result_folder.mkdir()
            with patch.object(downloader, "urlopen", return_value=Response(fixture.read_bytes())):
                result = downloader.download_selected(downloader.select_media([post("VID", "Video")]),
                                                      result_folder, PROFILE, ffmpeg)
            self.assertEqual(result, 2)  # One item is honestly reported as fewer than 20.
            item = downloader.read_json(result_folder / "manifest.json")["items"][0]
            self.assertEqual(item["validation"], "decoded")
            self.assertTrue(item["has_audio"])
            self.assertEqual(item["status"], "saved")


if __name__ == "__main__":
    unittest.main()
