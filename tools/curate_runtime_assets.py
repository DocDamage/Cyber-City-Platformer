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
    "Stages/Act3_NeonMoon/SourceArt/Neon Moon Protocol/Backgroud/backgroud (1).png",
    "Stages/Act3_NeonMoon/SourceArt/Neon Moon Protocol/Backgroud/backgroud (2).png",
    "Stages/Act3_NeonMoon/SourceArt/Neon Moon Protocol/Backgroud/backgroud (3).png",
    "Stages/Act3_NeonMoon/SourceArt/Neon Moon Protocol/Backgroud/backgroud (4).png",
]

PROJECT_GENERATED_ASSETS = {
    "environments/Act1_CyberCity/Generated/communication_spire_panorama_v1.png": "communication-spire",
    "environments/Act1_CyberCity/Generated/executive_helipad_panorama_v1.png": "executive-helipad",
    "environments/Act1_CyberCity/Generated/skybridge_junction_panorama_v1.png": "skybridge-junction",
    "environments/Act2_RobotFactory/Generated/assembly_engine_panorama_v1.png": "assembly-engine",
    "environments/Act2_RobotFactory/Generated/mega_robot_factory_panorama_v1.png": "mega-robot-factory",
    "environments/Act2_RobotFactory/Generated/robotic_maintenance_panorama_v1.png": "robotic-maintenance",
    "environments/Act2_RobotFactory/Generated/smelting_core_panorama_v1.png": "smelting-core",
    "environments/Act3_NeonMoon/Generated/bio_tech_labs_panorama_v1.png": "bio-tech-labs",
    "environments/Act3_NeonMoon/Generated/lunar_surface_arrival_panorama_v1.png": "lunar-surface-arrival",
    "environments/Act3_NeonMoon/Generated/orbital_command_panorama_v1.png": "orbital-command",
    "environments/Act3_NeonMoon/Generated/research_cleanrooms_panorama_v1.png": "research-cleanrooms",
    "environments/Act3_NeonMoon/Generated/security_grid_shaft_panorama_v1.png": "security-grid-shaft",
    "environments/Act4_AbyssalNight/Generated/abyssal_sanctuary_panorama_v1.png": "abyssal-sanctuary",
    "environments/Act4_AbyssalNight/Generated/bio_mechanical_nest_panorama_v1.png": "bio-mechanical-nest",
    "environments/Act4_AbyssalNight/Generated/corrupted_outpost_panorama_v1.png": "corrupted-outpost",
    "environments/Act4_AbyssalNight/Generated/heart_of_the_void_panorama_v1.png": "heart-of-the-void",
    "environments/Act4_AbyssalNight/Generated/the_dark_chasm_panorama_v1.png": "the-dark-chasm",
    "props/TraversalKits/Generated/cyber_antenna_perch_v1.png": "cyber-antenna-perch",
    "props/TraversalKits/Generated/cyber_antenna_shaft_v1.png": "cyber-antenna-shaft",
    "props/TraversalKits/Generated/cyber_billboard_gantry_v1.png": "cyber-billboard-gantry",
    "props/TraversalKits/Generated/cyber_elevator_cage_v1.png": "cyber-elevator-cage",
    "props/TraversalKits/Generated/cyber_rooftop_catwalk_v1.png": "cyber-rooftop-catwalk",
    "props/TraversalKits/Generated/cyber_skybridge_truss_v1.png": "cyber-skybridge-truss",
    "props/TraversalKits/Generated/factory_cargo_lift_v1.png": "factory-cargo-lift",
    "props/TraversalKits/Generated/factory_conveyor_v1.png": "factory-conveyor",
    "props/TraversalKits/Generated/factory_crane_runway_v1.png": "factory-crane-runway",
    "props/TraversalKits/Generated/factory_crusher_bay_v1.png": "factory-crusher-bay",
    "props/TraversalKits/Generated/factory_furnace_catwalk_v1.png": "factory-furnace-catwalk",
    "props/TraversalKits/Generated/factory_maintenance_gantry_v1.png": "factory-maintenance-gantry",
}
PROJECT_GENERATED_LICENSE = "LICENSE-0ddffeed82b7.txt"


def external_renamed_assets() -> dict[str, str]:
    """Map normalized runtime names to files in the sibling source library."""
    result: dict[str, str] = {}
    creator = "Characters/Character Creator"
    for index in range(1, 7):
        result[f"characters/player_creator/skin/skin_{index:02d}.png"] = (
            f"{creator}/skin/skin_c{index}.png"
        )
    for index in range(1, 8):
        result[f"characters/player_creator/face/face_{index:02d}.png"] = (
            f"{creator}/face/face_c{index}.png"
        )
    for hair_id in ("f1", "f2", "m1"):
        for layer in ("bot", "top"):
            result[f"characters/player_creator/hair/hair_{hair_id}_{layer}.png"] = (
                f"{creator}/hair/{hair_id}/{hair_id}_{layer}/{hair_id}_c1_{layer}.png"
            )
    for index in range(1, 4):
        for layer in ("bot", "top"):
            result[f"characters/player_creator/clothing/cloth_{index}_{layer}.png"] = (
                f"{creator}/cloth/cloth{index}/cloth{index}_{layer}/cloth{index}_c1_{layer}.png"
            )
    for index in range(1, 6):
        for layer in ("bot", "top"):
            source_name = f"weapon{index}_c1_{layer}.png" if index == 5 else f"weapon{index}_{layer}.png"
            result[f"characters/player_creator/weapons/weapon_{index}_{layer}.png"] = (
                f"{creator}/weapon/weapon{index}/weapon{index}_{layer}/{source_name}"
            )

    result["weapons/sword/sword_effects.png"] = (
        "Stage Props/Animated Weapons/Ultimate Weapon Pack – 2D Pixel Art/PNG/Armas (1).png"
    )
    icon_root = "Stage Props/Icons"
    for icon_name, source_index in (
        ("sword", 173),
        ("dagger", 164),
        ("spear", 197),
        ("heavy", 185),
        ("bow", 169),
        ("staff", 190),
    ):
        result[f"ui/icons/weapons/{icon_name}.png"] = (
            f"{icon_root}/Icon ({source_index}).png"
        )
    result["ui/icons/unknown.png"] = f"{icon_root}/Icon (1103).png"

    district_props = {
        "communication_spire/relay_core.png": "Cargo, Tech & Laboratory Loot/Loot(117).png",
        "communication_spire/service_console.png": "Cargo, Tech & Laboratory Loot/Loot(134).png",
        "skybridge_junction/suspension_arm.png": "Cargo, Tech & Laboratory Loot/Loot(176).png",
        "skybridge_junction/signal_flare.png": "Cargo, Tech & Laboratory Loot/Loot(199).png",
        "executive_helipad/shuttle.png": "Space Props/space extra (247).png",
        "executive_helipad/landing_obelisk.png": "Space Props/space extra (252).png",
        "sub_level_intake/coolant_filter.png": "Cargo, Tech & Laboratory Loot/Loot(190).png",
        "sub_level_intake/intake_canister.png": "Cargo, Tech & Laboratory Loot/Loot(137).png",
        "conveyor_assembly/sorter_crates.png": "Cargo, Tech & Laboratory Loot/Loot(195).png",
        "conveyor_assembly/conveyor_rack.png": "Cargo, Tech & Laboratory Loot/Loot(325).png",
        "smelting_core/slag_drum.png": "Cargo, Tech & Laboratory Loot/Loot(403).png",
        "smelting_core/furnace_canister.png": "Cargo, Tech & Laboratory Loot/Loot(513).png",
        "robotic_maintenance/service_bench.png": "Cargo, Tech & Laboratory Loot/Loot(511).png",
        "robotic_maintenance/repair_drones.png": "Cargo, Tech & Laboratory Loot/Loot(597).png",
        "assembly_engine/cable_core.png": "Cargo, Tech & Laboratory Loot/Loot(269).png",
        "assembly_engine/control_chip.png": "Cargo, Tech & Laboratory Loot/Loot(494).png",
        "lunar_surface_arrival/landing_pod.png": "Space Props/space extra (148).png",
        "lunar_surface_arrival/lunar_crystal.png": "Space Props/space extra (61).png",
        "research_cleanrooms/specimen_rack.png": "Cargo, Tech & Laboratory Loot/Loot(448).png",
        "research_cleanrooms/assay_console.png": "Cargo, Tech & Laboratory Loot/Loot(449).png",
        "security_grid_shaft/security_pod.png": "Space Props/space extra (315).png",
        "security_grid_shaft/grid_terminal.png": "Space Props/space extra (318).png",
        "bio_tech_labs/egg_cluster.png": "Space Props/space extra (382).png",
        "bio_tech_labs/culture_crystal.png": "Cargo, Tech & Laboratory Loot/Loot(451).png",
        "orbital_command/command_console.png": "Space Props/space extra (308).png",
        "orbital_command/telemetry_ring.png": "Cargo, Tech & Laboratory Loot/Loot(280).png",
        "corrupted_outpost/corruption_capsule.png": "Space Props/space extra (388).png",
        "corrupted_outpost/purifier_crystal.png": "Space Props/space extra (390).png",
        "the_dark_chasm/debris_field.png": "Space Props/space extra (295).png",
        "the_dark_chasm/fossil_claw.png": "Space Props/space extra (296).png",
        "bio_mechanical_nest/brood_cluster.png": "Space Props/space extra (377).png",
        "bio_mechanical_nest/neural_mass.png": "Space Props/space extra (384).png",
        "abyssal_sanctuary/phase_reliquary.png": "Space Props/space extra (381).png",
        "abyssal_sanctuary/sentinel_idol.png": "Space Props/space extra (396).png",
        "heart_of_the_void/void_orb.png": "Space Props/space extra (283).png",
        "heart_of_the_void/core_portal.png": "Space Props/space extra (587).png",
    }
    for destination_name, source_name in district_props.items():
        result[f"props/districts/{destination_name}"] = f"Stage Props/{source_name}"
    voice_root = "SFX/Super Dialogue Audio Pack v1/Step 2 - Audio Files"
    profiles = (
        ("voice_01", "Female", "Karen Cenon", "karen"),
        ("voice_02", "Female", "Meghan Christian", "meghan"),
        ("voice_03", "Male", "Alex Brodie", "alex"),
        ("voice_04", "Male", "Ian Lampert", "ian"),
        ("voice_05", "Male", "Sean Lenhart", "sean"),
    )
    categories = (
        ("confirmation", "2 - Confirmation"),
        ("greeting", "3 - Greeting"),
        ("damage", "7 - Damage"),
        ("grunting", "9 - Grunting"),
    )
    for profile_id, gender, performer, slug in profiles:
        for category, folder in categories:
            result[f"audio/voices/{profile_id}/{category}_01.wav"] = (
                f"{voice_root}/{folder}/{gender}/{performer}/{category}_1_{slug}.wav"
            )
    return result


def external_license_path(source_relative: str) -> str:
    if source_relative.startswith("Characters/Character Creator/"):
        return "Characters/Character Creator/license.txt"
    if source_relative.startswith("Stage Props/Animated Weapons/"):
        return "Stage Props/Animated Weapons/Ultimate Weapon Pack – 2D Pixel Art/license.txt"
    if source_relative.startswith("Stage Props/Icons/"):
        return "Stage Props/Icons/license.txt"
    if source_relative.startswith("Stage Props/Cargo, Tech & Laboratory Loot/"):
        return "Stage Props/Cargo, Tech & Laboratory Loot/license.txt"
    if source_relative.startswith("Stage Props/Space Props/"):
        return "Stage Props/Space Props/license.txt"
    if source_relative.startswith("SFX/Super Dialogue Audio Pack v1/"):
        return "SFX/Super Dialogue Audio Pack v1/Step 2 - Audio Files/license.txt"
    raise FileNotFoundError(f"No external license mapping for {source_relative}")


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
    existing_manifest_path = root / "assets" / "runtime" / "asset_license_manifest.json"
    if existing_manifest_path.is_file():
        existing_manifest = json.loads(existing_manifest_path.read_text(encoding="utf-8"))
        for record in existing_manifest.get("assets", []):
            source_path = str(record.get("source_path", ""))
            if source_path.startswith("res://"):
                paths.add(source_path.removeprefix("res://"))
    for record in inventory["dependencies"]:
        if record["requirement"] == "Editor-only" or record["tracked"]:
            continue
        relative = str(record["path"]).removeprefix("res://")
        if relative.replace("\\", "/").startswith("assets/runtime/"):
            continue
        # The inventory also reports new runtime code/scenes in a dirty
        # worktree. Those are distribution dependencies, not raw licensed
        # binaries to copy into assets/runtime.
        if (root / relative).is_file() and Path(relative).suffix.lower() not in TEXT_SUFFIXES:
            paths.add(relative)
    return paths


def replace_resource_paths(root: Path, replacements: dict[str, str]) -> int:
    changed = 0
    for path in sorted(root.rglob("*")):
        if not path.is_file() or ".git" in path.parts or ".godot" in path.parts:
            continue
        relative = path.relative_to(root)
        # Curated assets, evidence documents, and generated package/extraction
        # output are not production source and must never be rewritten.
        if relative.parts[0] in {"assets", "build", "docs"}:
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
    source_library_root = root.parent
    runtime_root = root / "assets" / "runtime"
    license_root = runtime_root / "licenses"
    license_root.mkdir(parents=True, exist_ok=True)

    source_paths = referenced_asset_files(root)
    replacements: dict[str, str] = {
        "res://Characters/Enemies/SourceArt/": "res://assets/runtime/characters/Enemies/",
    }
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
        licenses.setdefault(license_name, license_source.relative_to(root).as_posix())

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

    for destination_runtime, source_relative in sorted(external_renamed_assets().items()):
        source = source_library_root / source_relative
        if not source.is_file():
            raise FileNotFoundError(f"Required external source asset is missing: {source_relative}")
        destination_relative = "assets/runtime/" + destination_runtime
        destination = root / destination_relative
        destination.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(source, destination)

        license_relative = external_license_path(source_relative)
        license_source = source_library_root / license_relative
        license_hash = sha256(license_source)
        license_name = f"LICENSE-{license_hash[:12]}.txt"
        license_destination = license_root / license_name
        if not license_destination.exists():
            shutil.copy2(license_source, license_destination)
        licenses.setdefault(license_name, f"source-library://{license_relative}")
        records.append(
            {
                "runtime_path": "res://" + destination_relative,
                "source_path": f"source-library://{source_relative}",
                "sha256": sha256(destination),
                "bytes": destination.stat().st_size,
                "license": f"res://assets/runtime/licenses/{license_name}",
            }
        )

    for destination_runtime, provenance_id in sorted(PROJECT_GENERATED_ASSETS.items()):
        destination = runtime_root / destination_runtime
        if not destination.is_file():
            raise FileNotFoundError(f"Required project-generated asset is missing: {destination_runtime}")
        license_destination = license_root / PROJECT_GENERATED_LICENSE
        if not license_destination.is_file():
            raise FileNotFoundError(f"Generated-derivative license is missing: {PROJECT_GENERATED_LICENSE}")
        records.append(
            {
                "runtime_path": "res://assets/runtime/" + destination_runtime,
                "source_path": f"generated://openai-imagegen/2026-08-05/{provenance_id}",
                "sha256": sha256(destination),
                "bytes": destination.stat().st_size,
                "license": f"res://assets/runtime/licenses/{PROJECT_GENERATED_LICENSE}",
            }
        )

    changed_sources = replace_resource_paths(root, replacements)
    records.sort(key=lambda record: str(record["runtime_path"]).casefold())
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
    resource_index = {
        "schema_version": 1,
        "generator": "tools/curate_runtime_assets.py",
        "paths": [str(record["runtime_path"]) for record in records],
    }
    (runtime_root / "resource_index.json").write_text(
        json.dumps(resource_index, indent=2, ensure_ascii=False) + "\n",
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
        "`asset_license_manifest.json` maps every shipped binary to its source path, SHA-256 digest, size, and included license text. `resource_index.json` is the source-free runtime lookup index included in exports.",
        "",
        "The prompt specifications, canonical references, output paths, and hashes for the generated Act 1/2 and Act 3/4 panoramas plus traversal kits are recorded in `docs/assets/ACT1_ACT2_GENERATED_PANORAMAS.md`, `docs/assets/ACT3_ACT4_GENERATED_PANORAMAS.md`, and `docs/assets/ACT1_ACT2_GENERATED_TRAVERSAL_KITS.md`.",
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
