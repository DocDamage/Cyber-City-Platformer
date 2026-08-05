#!/usr/bin/env python3
"""Validate and assemble the Cyber City Platformer Windows release archive."""

from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
import re
import subprocess
import sys
import zipfile


ROOT = Path(__file__).resolve().parents[1]
BUILD_DIR = ROOT / "build" / "windows"
RELEASE_DIR = ROOT / "build" / "release"
REQUIRED_DOCUMENTS = (
    "README.md",
    "CONTROLS.md",
    "LICENSES.md",
    "CHANGELOG.md",
    "KNOWN_ISSUES.md",
    "VERSION",
)
FORBIDDEN_PCK_MARKERS = (
    b"res://tests/",
    b"res://tools/",
    b"res://scripts/tools/",
    b"SourceArt/",
    b"addons/AsepriteWizard",
    b"FULL_COMPLETION_PLAN",
    b"GoalSmokeTest",
    b"SystemsSmokeTest",
)
ABSOLUTE_WINDOWS_PATH = re.compile(r"(?i)(?:^|[\s`'\"])[a-z]:\\")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--allow-dirty",
        action="store_true",
        help="Permit packaging an uncommitted candidate (never use for a release tag)",
    )
    return parser.parse_args()


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def git(*arguments: str) -> str:
    return subprocess.run(
        ["git", *arguments],
        cwd=ROOT,
        check=True,
        capture_output=True,
        text=True,
        encoding="utf-8",
    ).stdout.strip()


def validate_documents() -> list[Path]:
    paths: list[Path] = []
    for relative in REQUIRED_DOCUMENTS:
        path = ROOT / relative
        if not path.is_file():
            raise FileNotFoundError(f"Required release document is missing: {relative}")
        if ABSOLUTE_WINDOWS_PATH.search(path.read_text(encoding="utf-8")):
            raise ValueError(f"Absolute developer path found in release document: {relative}")
        paths.append(path)
    return paths


def validate_pck(path: Path) -> None:
    payload = path.read_bytes()
    found = [marker.decode("utf-8") for marker in FORBIDDEN_PCK_MARKERS if marker in payload]
    if found:
        raise ValueError(f"Development content markers found in PCK: {', '.join(found)}")


def main() -> int:
    args = parse_args()
    executable = BUILD_DIR / "CyberCityPlatformer.exe"
    pck = BUILD_DIR / "CyberCityPlatformer.pck"
    for path in (executable, pck):
        if not path.is_file() or path.stat().st_size == 0:
            print(f"PACKAGE_ERROR: missing build output: {path.relative_to(ROOT)}", file=sys.stderr)
            return 2
    try:
        documents = validate_documents()
        validate_pck(pck)
        dirty = bool(git("status", "--porcelain"))
        if dirty and not args.allow_dirty:
            raise ValueError("Git worktree is dirty; commit and rerun or use --allow-dirty for a non-release candidate.")
        source_sha = git("rev-parse", "HEAD")
    except (FileNotFoundError, ValueError, subprocess.CalledProcessError) as exc:
        print(f"PACKAGE_ERROR: {exc}", file=sys.stderr)
        return 3

    version = (ROOT / "VERSION").read_text(encoding="utf-8").strip()
    archive_root = f"CyberCityPlatformer-{version}-windows-x86_64"
    RELEASE_DIR.mkdir(parents=True, exist_ok=True)
    archive = RELEASE_DIR / f"{archive_root}.zip"
    if archive.exists():
        archive.unlink()

    asset_manifest = ROOT / "assets" / "runtime" / "asset_license_manifest.json"
    license_files = sorted((ROOT / "assets" / "runtime" / "licenses").glob("*.txt"))
    build_info = {
        "version": version,
        "source_sha": source_sha,
        "dirty": dirty,
        "engine": "4.7.1.stable.official.a13da4feb",
        "artifacts": {
            executable.name: sha256(executable),
            pck.name: sha256(pck),
        },
    }

    with zipfile.ZipFile(archive, "w", compression=zipfile.ZIP_DEFLATED, compresslevel=9) as bundle:
        for path in (executable, pck, *documents):
            bundle.write(path, f"{archive_root}/{path.name}")
        bundle.write(asset_manifest, f"{archive_root}/ASSET_LICENSE_MANIFEST.json")
        for license_path in license_files:
            bundle.write(license_path, f"{archive_root}/licenses/{license_path.name}")
        bundle.writestr(
            f"{archive_root}/BUILD_INFO.json",
            json.dumps(build_info, indent=2, ensure_ascii=False) + "\n",
        )

    if not zipfile.is_zipfile(archive):
        print("PACKAGE_ERROR: output archive failed ZIP validation", file=sys.stderr)
        return 4
    print(
        "RELEASE_PACKAGE_OK "
        f"version={version} sha={source_sha[:12]} bytes={archive.stat().st_size} "
        f"archive={archive.relative_to(ROOT)}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
