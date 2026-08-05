#!/usr/bin/env python3
"""Assign production archetypes and balance data to the enemy library."""

from __future__ import annotations

import json
import re
from pathlib import Path


ARCHETYPES = {
    "centaur": "leaping_enemy",
    "cerberus": "hazard_spawning_enemy",
    "cyclops": "heavy_armored_enemy",
    "death_knight": "shielded_enemy",
    "demon_boss": "flying_shooter",
    "flying_eye": "flying_patrol",
    "gargoyle": "flying_patrol",
    "goblin": "ground_chaser",
    "gryphon": "flying_shooter",
    "harpy": "flying_patrol",
    "headless_horseman": "hazard_spawning_enemy",
    "imp": "fast_melee_attacker",
    "medusa": "ambush_enemy",
    "mimic": "ambush_enemy",
    "minotaur": "heavy_armored_enemy",
    "poison_skull": "flying_shooter",
    "pyromancer": "ranged_shooter",
    "satyr_archer": "ranged_shooter",
    "skeleton_warrior": "shielded_enemy",
    "stone_golem": "heavy_armored_enemy",
    "werewolf": "fast_melee_attacker",
    "witch": "ranged_shooter",
}

BALANCE = {
    "ground_chaser": (3, 1, 48, 1.05, 115),
    "fast_melee_attacker": (3, 1, 54, 0.7, 155),
    "heavy_armored_enemy": (7, 2, 64, 1.5, 70),
    "ranged_shooter": (4, 1, 260, 1.35, 80),
    "flying_patrol": (3, 1, 70, 1.0, 105),
    "flying_shooter": (4, 1, 280, 1.5, 95),
    "leaping_enemy": (4, 2, 110, 1.25, 120),
    "shielded_enemy": (6, 1, 58, 1.4, 75),
    "ambush_enemy": (4, 2, 72, 1.5, 100),
    "hazard_spawning_enemy": (5, 1, 230, 1.8, 85),
}


def main() -> int:
    root = Path(__file__).resolve().parents[1]
    path = root / "Characters" / "Enemies" / "enemy_library.json"
    library = json.loads(path.read_text(encoding="utf-8"))
    library["schema_version"] = 1
    for enemy in library["enemies"]:
        enemy_id = enemy["id"]
        archetype = ARCHETYPES[enemy_id]
        health, damage, attack_range, cooldown, chase_speed = BALANCE[archetype]
        frame_path = root / enemy["sprite_frames"].removeprefix("res://")
        animation_names = re.findall(r'"name": &"([^"]+)"', frame_path.read_text(encoding="utf-8"))
        enemy.update(
            {
                "archetype": archetype,
                "animations": animation_names,
                "max_health": health,
                "attack_damage": damage,
                "attack_range": attack_range,
                "attack_cooldown": cooldown,
                "chase_speed": chase_speed,
                "detection_radius": 280 if "shooter" in archetype else 210,
                "body_size": [max(18, min(48, int(enemy["frame_width"] * 0.18))), max(30, min(68, int(enemy["frame_height"] * 0.45)))],
            }
        )
        if enemy_id == "death_knight":
            enemy["source_directory"] = "res://assets/runtime/characters/Enemies/Skeleton Warrior  2D Pixel Art v1.1/Sprites/without_outline"
    path.write_text(json.dumps(library, indent=2, ensure_ascii=False) + "\n", encoding="utf-8", newline="\n")
    print("ENEMY_LIBRARY_UPGRADE_OK enemies=22 archetypes=10")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
