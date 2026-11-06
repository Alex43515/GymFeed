"""Download up to 20 photos and videos from an Instagram profile's post grid."""

import argparse
import re
import subprocess
import sys
from importlib.util import find_spec
from pathlib import Path
from urllib.parse import urlsplit


MEDIA_EXTENSIONS = ("jpg", "jpeg", "png", "webp", "mp4", "mov")


def profile_handle(value):
    try:
        url = urlsplit(value)
    except ValueError as error:
        raise argparse.ArgumentTypeError("Use a full Instagram profile URL.") from error
    handle = url.path.strip("/")
    if (
        url.scheme not in ("http", "https")
        or url.netloc.lower() not in ("instagram.com", "www.instagram.com")
        or not re.fullmatch(r"[A-Za-z0-9_.]{1,30}", handle)
        or not handle.strip(".")
        or handle.lower() in {"accounts", "direct", "explore", "p", "reel", "reels", "stories", "tv"}
    ):
        raise argparse.ArgumentTypeError("Use https://www.instagram.com/username/.")
    return handle.lower()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("url", type=profile_handle, help="Instagram profile URL")
    parser.add_argument("--output", type=Path, help="Empty destination folder")
    parser.add_argument("--captions", action="store_true", help="Save original captions in JSON sidecars")
    parser.add_argument(
        "--browser",
        choices=("chrome", "edge", "firefox"),
        help="Use your existing Instagram login in this browser if anonymous access is limited",
    )
    args = parser.parse_args()
    if find_spec("gallery_dl") is None:
        parser.exit(1, 'Install the downloader first: python -m pip install "gallery-dl==1.32.19"\n')

    output = (args.output or Path("outputs/instagram") / args.url).resolve()
    try:
        output.mkdir(parents=True, exist_ok=True)
        if any(output.iterdir()):
            parser.exit(1, f"Choose an empty output folder. Existing files: {output}\n")
        command = [
            sys.executable, "-m", "gallery_dl",
            "--config-ignore", "--no-input",
            "--retries", "0", "--http-timeout", "20",
            "--directory", str(output),
            "--range", "1-20",
            "--filter", f"extension.lower() in {MEDIA_EXTENSIONS!r}",
            "--filename", "{date:%Y%m%d-%H%M%S}_{post_shortcode}_{num:02}.{extension}",
            "-o", "extractor.instagram.videos=merged",
        ]
        if args.captions:
            command.append("--write-metadata")
        if args.browser:
            command.extend(("--cookies-from-browser", f"{args.browser}/instagram.com"))
        command.append(f"https://www.instagram.com/{args.url}/posts/")
        result = subprocess.run(command, check=False)
        count = sum(
            path.is_file() and path.suffix.lower().lstrip(".") in MEDIA_EXTENSIONS
            for path in output.iterdir()
        )
    except OSError as error:
        parser.exit(1, f"Download failed: {error}\n")

    print(f"Saved {count} media files to {output}")
    if result.returncode or not count:
        print(
            "Instagram may be limiting access, or the profile has no downloadable public posts. "
            "If you can view the posts while logged in, retry in an empty folder with --browser.",
            file=sys.stderr,
        )
        return result.returncode or 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
