"""Download up to 20 photos and videos from an Instagram profile, post, or reel."""

import argparse
import re
import subprocess
import sys
from importlib.util import find_spec
from pathlib import Path
from urllib.parse import urlsplit


MEDIA_EXTENSIONS = ("jpg", "jpeg", "png", "webp", "mp4", "mov")


def instagram_target(value):
    try:
        url = urlsplit(value)
    except ValueError as error:
        raise argparse.ArgumentTypeError("Use a full Instagram URL.") from error
    if (
        url.scheme not in ("http", "https")
        or url.netloc.lower() not in ("instagram.com", "www.instagram.com")
    ):
        raise argparse.ArgumentTypeError("Use a URL on https://www.instagram.com/.")
    parts = url.path.strip("/").split("/")
    # Instagram also links reels as /username/reel/SHORTCODE/.
    if len(parts) == 3 and re.fullmatch(r"[A-Za-z0-9_.]{1,30}", parts[0]):
        parts = parts[1:]
    if (
        len(parts) == 2
        and parts[0] in {"p", "reel", "reels", "tv"}
        and re.fullmatch(r"[A-Za-z0-9_-]+", parts[1])
    ):
        kind = "reel" if parts[0] == "reels" else parts[0]
        return f"https://www.instagram.com/{kind}/{parts[1]}/", parts[1]
    handle = parts[0]
    if (
        len(parts) != 1
        or not re.fullmatch(r"[A-Za-z0-9_.]{1,30}", handle)
        or not handle.strip(".")
        or handle.lower() in {"accounts", "direct", "explore", "p", "reel", "reels", "stories", "tv"}
    ):
        raise argparse.ArgumentTypeError("Use a profile, post, or reel URL.")
    handle = handle.lower()
    return f"https://www.instagram.com/{handle}/posts/", handle


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("url", type=instagram_target, help="Instagram profile, post, or reel URL")
    parser.add_argument("--output", type=Path, help="Empty destination folder")
    parser.add_argument("--captions", action="store_true", help="Save original captions in JSON sidecars")
    authentication = parser.add_mutually_exclusive_group()
    authentication.add_argument(
        "--browser",
        choices=("chrome", "edge", "firefox"),
        help="Use your existing Instagram login in this browser if anonymous access is limited",
    )
    authentication.add_argument(
        "--cookies", type=Path,
        help="Use a local Netscape cookies.txt export of your Instagram session",
    )
    args = parser.parse_args()
    target_url, folder = args.url
    if args.cookies and not args.cookies.is_file():
        parser.error("--cookies must point to an existing file.")
    if find_spec("gallery_dl") is None:
        parser.exit(1, 'Install the downloader first: python -m pip install "gallery-dl==1.32.19"\n')

    output = (args.output or Path("outputs/instagram") / folder).resolve()
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
        if args.cookies:
            command.extend(("--cookies", str(args.cookies.resolve())))
        command.append(target_url)
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
            "Instagram did not return downloadable media for this URL. "
            "If it opens while logged in, retry in an empty folder with --browser "
            "or a local Instagram --cookies export.",
            file=sys.stderr,
        )
        return result.returncode or 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
