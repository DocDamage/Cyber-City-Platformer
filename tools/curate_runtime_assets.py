#!/usr/bin/env python3
"""Copy only licensed production assets into the tracked runtime tree.

This is a maintainer tool for an asset-populated working copy. A clean clone
does not need to run it because its outputs are committed through Git LFS.
"""

from __future__ import annotations

import hashlib
import json
import shutil
from pathlib import Path


TEXT_SUFFIXES = {".gd", ".json", ".tres", ".tscn"}

DYNAMIC_ASSETS = [
    "Characters/Player/SourceArt/Female Fighter/Player 96X96 (1).png",
    *[
        f"Stage Props/CyberCityProps/SourceArt/Cyber City/Coin/coin{index}.png"
        for index in range(1, 9)
    ],
    "Stage Props/LunarProps/SourceArt/Space Props/Space extra (1).png",
    "Music/Library/Rooftops/Cyberpunk Rooftops.ogg",
    "Parallax/SourceArt/Rooftops 2/back.png",
    "Stages/Act1_CyberCity/SourceArt/Cyber City/Cyber City/Backgroud/BACKGROUND (6)/Backgroud (6) 1.png",
    "Stages/Act1_CyberCity/SourceArt/Cyber City/Cyber City/Backgroud/BACKGROUND (5)/Backgroud (5) 1.png",
    "Stages/Act1_CyberCity/SourceArt/Cyber City/Cyber City/Backgroud/BACKGROUND (3)/Backgroud (3) 1.png",
    "Stages/Act1_CyberCity/SourceArt/Cyber City/Cyber City/Backgroud/BACKGROUND (2)/Backgroud (2) 1.png",
    "Stages/Act1_CyberCity/SourceArt/Cyber City/Cyber City/Backgroud/BACKGROUND (1)/Backgroud (1) 1.png",
    "Stages/Act2_RobotFactory/SourceArt/Mega Robot Factory/CENA (!)/BACKGROUD/BACKGROUND (1).png",
]


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def runtime_relative(source_relative: str) -> str:
    mappings = (
        ("Characters/Enemies/SourceArt/", "characters/Enemies/"),
        ("Characters/Player/SourceArt/", "characters/Player/"),
        ("Characters/Bosses/SourceArt/", "characters/Bosses/"),
        ("Music/Library/", "audio/music/"),
        ("SFX/Library/", "audio/sfx/"),
        ("Parallax/SourceArt/", "environments/parallax/"),
        ("VFX/SourceArt/", "vfx/"),
    )
    for prefix, replacement in mappings:
        if source_relative.startswith(prefix):
            return replacement + source_relative.removeprefix(prefix)

    if source_relative.startswith("Stage Props/") and "/SourceArt/" in source_relative:
        head, tail = source_relative.split("/SourceArt/", 1)
        prop_group = head.removeprefix("Stage Props/")
        return f"props/{prop_group}/{tail}"
    if source_relative.startswith("Stages/") and "/SourceArt/" in source_relative:
        head, tail = source_relative.split("/SourceArt/", 1)
        act_group = head.removeprefix("Stages/")
        return f"environments/{act_group}/{tail}"
    return "misc/" + source_relative


def nearest_license(root: Path, source: Path) -> Path:
    music_license = root / "assets" / "Music" / "license.txt"
    if source.is_relative_to(root / "Music") and music_license.exists():
        return music_license
    relative = source.relative_to(root).as_posix()
    licensed_mirror_fallbacks = (
        (
            "Parallax/SourceArt/Rooftops 2/",
            "Stages/Act1_CyberCity/SourceArt/Rooftops/license.txt",
        ),
        (
            "Stage Props/CyberCityProps/SourceArt/Rooftops 2/",
            "Stages/Act1_CyberCity/SourceArt/Rooftops/license.txt",
        ),
        (
            "Stage Props/CyberCityProps/SourceArt/Cyber City/",
            "Stages/Act1_CyberCity/SourceArt/Cyber City/Cyber City/license.txt",
        ),
        (
            "Stage Props/LunarProps/SourceArt/Neon Moon Portal/",
            "Stages/Act3_NeonMoon/SourceArt/Neon Moon Protocol/license.txt",
        ),
        (
            "Stages/Act1_CyberCity/SourceArt/Rooftops 2/",
            "Stages/Act1_CyberCity/SourceArt/Rooftops/license.txt",
        ),
    )
    for prefix, license_relative in licensed_mirror_fallbacks:
        if relative.startswith(prefix):
            license_path = root / license_relative
            if license_path.is_file():
                return license_path
    for parent in (source.parent, *source.parents):
        if parent == root.parent:
            break
        if parent.exists():
            candidates = sorted(
                (path for path in parent.iterdir() if path.is_file() and path.name.lower() in {"license.txt", "licence.txt"}),
                key=lambda path: path.name.casefold(),
            )
            if candidates:
                return candidates[0]
        if parent == root:
            break
    raise FileNotFoundError(f"No license found for {source.relative_to(root)}")


def referenced_asset_files(root: Path) -> set[str]:
    inventory_path = root / "docs" / "assets" / "runtime_asset_inventory.json"
    inventory = json.loads(inventory_path.read_text(encoding="utf-8"))
    paths = set(DYNAMIC_ASSETS)
    for record in inventory["dependencies"]:
        if record["requirement"] == "Editor-only" or record["tracked"]:
            continue
        relative = str(record["path"]).removeprefix("res://")
        if (root / relative).is_file():
            paths.add(relative)
    return paths


def replace_resource_paths(root: Path, replacements: dict[str, str]) -> int:
    changed = 0
    for path in sorted(root.rglob("*")):
        if not path.is_file() or ".git" in path.parts or ".godot" in path.parts:
            continue
        relative = path.relative_to(root)
        if relative.parts[0] in {"assets", "docs"}:
            continue
        if path.name != "project.godot" and path.suffix.lower() not in TEXT_SUFFIXES:
            continue
        text = path.read_text(encoding="utf-8-sig")
        updated = text
        for old_path, new_path in replacements.items():
            updated = updated.replace(old_path, new_path)
        if updated != text:
            path.write_text(updated, encoding="utf-8", newline="\n")
            changed += 1
    return changed


def main() -> int:
    root = Path(__file__).resolve().parents[1]
    runtime_root = root / "assets" / "runtime"
    license_root = runtime_root / "licenses"
    license_root.mkdir(parents=True, exist_ok=True)

    source_paths = referenced_asset_files(root)
    replacements: dict[str, str] = {}
    records: list[dict[str, object]] = []
    licenses: dict[str, str] = {}

    for source_relative in sorted(source_paths, key=str.casefold):
        source = root / source_relative
        if not source.is_file():
            raise FileNotFoundError(f"Required source asset is missing: {source_relative}")
        destination_relative = "assets/runtime/" + runtime_relative(source_relative)
        destination = root / destination_relative
        destination.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(source, destination)

        license_source = nearest_license(root, source)
        license_hash = sha256(license_source)
        license_name = f"LICENSE-{license_hash[:12]}.txt"
        license_destination = license_root / license_name
        if not license_destination.exists():
            shutil.copy2(license_source, license_destination)
        licenses[license_name] = license_source.relative_to(root).as_posix()

        old_resource_path = "res://" + source_relative
        new_resource_path = "res://" + destination_relative
        replacements[old_resource_path] = new_resource_path
        records.append(
            {
                "runtime_path": new_resource_path,
                "source_path": old_resource_path,
                "sha256": sha256(destination),
                "bytes": destination.stat().st_size,
                "license": f"res://assets/runtime/licenses/{license_name}",
            }
        )

    changed_sources = replace_resource_paths(root, replacements)
    manifest = {
        "schema_version": 1,
        "strategy": "Curated runtime files tracked with Git LFS; bulk source packs remain ignored.",
        "assets": records,
        "license_sources": licenses,
    }
    (runtime_root / "asset_license_manifest.json").write_text(
        json.dumps(manifest, indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8",
        newline="\n",
    )

    total_bytes = sum(int(record["bytes"]) for record in records)
    lines = [
        "# Curated runtime assets",
        "",
        "Only assets referenced by the production game are stored here. Binary files are tracked with Git LFS; the original bulk source packs remain ignored.",
        "",
        f"- Runtime files: {len(records)}",
        f"- Runtime bytes: {total_bytes}",
        f"- Unique license texts: {len(licenses)}",
        "",
        "`asset_license_manifest.json` maps every shipped binary to its source path, SHA-256 digest, size, and included license text.",
        "",
        "To recurate from an asset-populated maintainer checkout, run `python tools/curate_runtime_assets.py`, then rerun `python tools/inventory_runtime_assets.py --check`.",
        "",
    ]
    (runtime_root / "README.md").write_text("\n".join(lines), encoding="utf-8", newline="\n")
    print(
        "RUNTIME_ASSET_CURATION_OK "
        f"assets={len(records)} bytes={total_bytes} source_files_rewritten={changed_sources}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
