#!/usr/bin/env python3
"""Apply the locked v1.0 metadata schema to all twenty campaign stages."""

from __future__ import annotations

import json
from pathlib import Path


STAGE_DATA = {
    "1-1": (["tutorial", "wall_jump", "melee", "ranged"], ["goblin", "flying_eye"], 1, 185),
    "1-2": (["moving_platform", "electric_sign"], ["goblin", "satyr_archer", "harpy"], 2, 220),
    "1-3": (["vertical", "signal_hazard", "flying_combat"], ["flying_eye", "gargoyle", "satyr_archer"], 2, 230),
    "1-4": (["moving_platform", "breakaway_platform", "dash_challenge"], ["werewolf", "harpy", "skeleton_warrior"], 2, 245),
    "1-5": (["boss", "air_hazard", "projectile_arcs"], ["demon_boss"], 1, 180),
    "2-1": (["conveyor", "steam_vent"], ["stone_golem", "goblin", "pyromancer"], 1, 215),
    "2-2": (["reversible_conveyor", "moving_platform", "drop_hazard"], ["cyclops", "satyr_archer", "imp"], 2, 250),
    "2-3": (["heat_zone", "steam_vent", "laser_grid", "vertical"], ["stone_golem", "pyromancer", "flying_eye"], 2, 265),
    "2-4": (["crusher", "terminal", "security_gate"], ["minotaur", "satyr_archer", "witch"], 2, 275),
    "2-5": (["boss", "conveyor", "shockwave"], ["cyclops"], 1, 200),
    "3-1": (["low_gravity", "long_gap"], ["harpy", "poison_skull", "gargoyle"], 1, 230),
    "3-2": (["terminal", "security_gate", "laser_grid"], ["satyr_archer", "witch", "flying_eye"], 2, 260),
    "3-3": (["turret", "rotating_laser", "vertical", "low_gravity"], ["poison_skull", "gryphon", "skeleton_warrior"], 2, 280),
    "3-4": (["gravity_zone", "terminal", "ambush", "multi_switch"], ["mimic", "medusa", "demon_boss"], 2, 290),
    "3-5": (["boss", "gravity_zone", "laser_sweep"], ["medusa"], 1, 210),
    "4-1": (["corruption_zone", "elite_enemy"], ["death_knight", "werewolf", "demon_boss"], 1, 255),
    "4-2": (["moving_platform", "void_pit", "low_visibility", "dash_challenge"], ["gargoyle", "headless_horseman", "harpy"], 2, 285),
    "4-3": (["corruption_node", "ambush", "security_gate"], ["mimic", "cerberus", "witch"], 2, 300),
    "4-4": (["conveyor", "laser_grid", "gravity_zone", "moving_platform", "elite_enemy"], ["stone_golem", "poison_skull", "death_knight"], 2, 320),
    "4-5": (["boss", "corruption_zone", "laser_sweep", "desperation"], ["cerberus"], 1, 240),
}


def main() -> int:
    root = Path(__file__).resolve().parents[1]
    path = root / "Stages" / "campaign_manifest.json"
    manifest = json.loads(path.read_text(encoding="utf-8"))
    manifest["schema_version"] = 1
    previous_id = ""
    for act in manifest["acts"]:
        act.pop("legacy_prop_roots", None)
        act.pop("legacy_stage_roots", None)
        for stage in act["stages"]:
            stage_id = stage["id"]
            mechanics, roster, checkpoints, par_time = STAGE_DATA[stage_id]
            is_boss = stage_id.endswith("-5")
            act_number, substage = map(int, stage_id.split("-"))
            is_bespoke_short_stage = stage_id in {"1-1", "2-1"}
            stage.update(
                {
                    "display_name": stage["name"],
                    "act": act_number,
                    "substage": substage,
                    "music_id": f"boss_{act_number}" if is_boss else f"act_{act_number}",
                    "mechanics": mechanics,
                    "expected_checkpoints": checkpoints,
                    "expected_boss": ["", "helix_warden", "assembly_colossus", "lunar_oracle", "void_cerberus"][act_number] if is_boss else "",
                    "completion_target": {"type": "boss" if is_boss else "encounters", "count": 1 if is_boss else 2},
                    "camera_bounds": [
                        0,
                        -540 if "vertical" in mechanics else 0,
                        1408 if is_bespoke_short_stage else 4800,
                        540 if is_bespoke_short_stage else 720,
                    ],
                    "par_time": par_time,
                    "collectible_count": 3,
                    "encounter_count": 1 if is_boss else 2,
                    "unlock_dependencies": [previous_id] if previous_id else [],
                    "enemy_roster": roster,
                    "status": "production",
                }
            )
            previous_id = stage_id
    manifest["characters"]["Player"] = {
        "texture_root": "res://assets/runtime/characters/Player",
        "scene": "res://scenes/Player.tscn",
    }
    path.write_text(json.dumps(manifest, indent=2, ensure_ascii=False) + "\n", encoding="utf-8", newline="\n")
    print("CAMPAIGN_MANIFEST_UPGRADE_OK stages=20 schema=1")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
