"""Stage only the approved media from a creator's ZIP export or folder."""

import argparse
import hashlib
import json
from contextlib import ExitStack
from pathlib import Path, PurePosixPath
from tempfile import TemporaryDirectory
from zipfile import BadZipFile, ZipFile


IMAGE_EXTENSIONS = {".jpg", ".jpeg", ".png", ".webp"}
VIDEO_EXTENSIONS = {".mp4", ".mov"}
EXTENSIONS = {
    "avatar": IMAGE_EXTENSIONS,
    "photo": IMAGE_EXTENSIONS,
    "video": VIDEO_EXTENSIONS,
    "reel": VIDEO_EXTENSIONS,
    "workout": VIDEO_EXTENSIONS,
}
MAX_FILE_BYTES = 250 * 1024 * 1024


def stage(args):
    manifest = json.loads(args.manifest.read_text(encoding="utf-8-sig"))
    handle = manifest["handle"]
    consent = manifest["consent_ref"].strip()
    if not handle.strip() or not consent:
        raise ValueError("Provide a handle and a reference to written approval.")
    if not manifest["assets"]:
        raise ValueError("List at least one approved file in assets.")
    if args.output.exists():
        raise ValueError("Output already exists. Choose a new directory.")

    source = args.source.resolve(strict=True)
    with ExitStack() as stack:
        archive = None if source.is_dir() else stack.enter_context(ZipFile(source))
        files = []
        seen = set()
        for index, asset in enumerate(manifest["assets"], start=1):
            name = asset["file"]
            path = PurePosixPath(name)
            if (
                not name
                or path.is_absolute()
                or ".." in path.parts
                or any(char in name for char in ("\\", ":", "\x00"))
                or name != path.as_posix()
            ):
                raise ValueError(f"Use a relative path with forward slashes: {name!r}")
            if name in seen:
                raise ValueError(f"Duplicate file in the manifest: {name}")
            seen.add(name)

            kind = asset["kind"]
            suffix = path.suffix.lower()
            if suffix not in EXTENSIONS.get(kind, set()):
                raise ValueError(f"Unsupported kind or extension: {kind} / {name}")

            if archive is not None:
                member = archive.getinfo(name)
                size = member.file_size
            else:
                member = (source / Path(*path.parts)).resolve(strict=True)
                if not member.is_relative_to(source) or not member.is_file():
                    raise ValueError(f"Expected a file inside the source directory: {name}")
                size = member.stat().st_size
            if not 0 < size <= MAX_FILE_BYTES:
                raise ValueError(f"File is empty or exceeds 250 MiB: {name}")

            entry = {
                "file": f"{index:03d}-{kind}{suffix}",
                "kind": kind,
                "original_file": name,
                "bytes": size,
            }
            for field in ("source_url", "caption"):
                if field in asset:
                    entry[field] = asset[field]
            files.append((member, entry))

        print(f"{handle}: {len(files)} approved files, {sum(row['bytes'] for _, row in files):,} bytes.")
        if not args.apply:
            for _, row in files:
                print(f"  {row['kind']}: {row['original_file']}")
            return

        output = args.output.absolute()
        output.parent.mkdir(parents=True, exist_ok=True)
        with TemporaryDirectory(dir=output.parent) as temp:
            batch = Path(temp) / "batch"
            batch.mkdir()
            for member, row in files:
                stream = archive.open(member) if archive is not None else member.open("rb")
                digest = hashlib.sha256()
                remaining = row["bytes"]
                with stream, (batch / row["file"]).open("xb") as target:
                    while chunk := stream.read(1024 * 1024):
                        remaining -= len(chunk)
                        if remaining < 0:
                            raise ValueError(f"Source size changed: {row['original_file']}")
                        digest.update(chunk)
                        target.write(chunk)
                if remaining:
                    raise ValueError(f"Source size changed: {row['original_file']}")
                row["sha256"] = digest.hexdigest()
            receipt = {"handle": handle, "consent_ref": consent, "assets": [row for _, row in files]}
            (batch / "manifest.json").write_text(
                json.dumps(receipt, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
            )
            batch.rename(output)
        print(f"Staged at {output}")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("manifest", type=Path, help="JSON allowlist with written approval reference")
    parser.add_argument("source", type=Path, help="Creator-provided ZIP or folder")
    parser.add_argument("output", type=Path, help="New directory for the staged batch")
    parser.add_argument("--apply", action="store_true", help="Copy files. Default: dry run.")
    args = parser.parse_args()
    try:
        stage(args)
    except (OSError, ValueError, TypeError, AttributeError, KeyError, BadZipFile, RuntimeError) as error:
        parser.exit(1, f"Intake failed: {error}\n")


if __name__ == "__main__":
    main()
