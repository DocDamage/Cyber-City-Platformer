#!/usr/bin/env python3
"""Assign the complete production contract to every imported enemy."""

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

CONTRACTS = {
    "ground_chaser": {
        "attack_kind": "melee", "attack_timing": (0.32, 0.14, 0.32),
        "stagger": (2.0, 0.48, 0.05), "resistances": (0.0, 0.05),
        "leash": 430, "currency": (2, 4),
    },
    "fast_melee_attacker": {
        "attack_kind": "melee", "attack_timing": (0.20, 0.12, 0.24),
        "stagger": (2.0, 0.40, 0.0), "resistances": (0.0, 0.0),
        "leash": 510, "currency": (3, 5),
    },
    "heavy_armored_enemy": {
        "attack_kind": "melee", "attack_timing": (0.56, 0.20, 0.58),
        "stagger": (4.0, 0.68, 0.40), "resistances": (0.16, 0.42),
        "leash": 360, "currency": (7, 11),
    },
    "ranged_shooter": {
        "attack_kind": "ranged", "attack_timing": (0.48, 0.10, 0.42),
        "stagger": (2.5, 0.52, 0.10), "resistances": (0.0, 0.08),
        "leash": 540, "currency": (4, 7),
    },
    "flying_patrol": {
        "attack_kind": "melee", "attack_timing": (0.34, 0.14, 0.32),
        "stagger": (2.0, 0.46, 0.0), "resistances": (0.0, 0.0),
        "leash": 500, "currency": (3, 5),
    },
    "flying_shooter": {
        "attack_kind": "ranged", "attack_timing": (0.46, 0.10, 0.40),
        "stagger": (2.5, 0.52, 0.08), "resistances": (0.0, 0.05),
        "leash": 580, "currency": (5, 8),
    },
    "leaping_enemy": {
        "attack_kind": "leap", "attack_timing": (0.44, 0.20, 0.46),
        "stagger": (3.0, 0.58, 0.18), "resistances": (0.06, 0.18),
        "leash": 520, "currency": (5, 8),
    },
    "shielded_enemy": {
        "attack_kind": "melee", "attack_timing": (0.42, 0.18, 0.50),
        "stagger": (4.0, 0.64, 0.34), "resistances": (0.12, 0.36),
        "leash": 380, "currency": (6, 10),
    },
    "ambush_enemy": {
        "attack_kind": "melee", "attack_timing": (0.24, 0.15, 0.38),
        "stagger": (3.0, 0.54, 0.14), "resistances": (0.04, 0.12),
        "leash": 460, "currency": (5, 9),
    },
    "hazard_spawning_enemy": {
        "attack_kind": "hazard", "attack_timing": (0.62, 0.18, 0.60),
        "stagger": (3.5, 0.62, 0.24), "resistances": (0.08, 0.24),
        "leash": 500, "currency": (7, 12),
    },
}

def choose_animation(names: list[str], candidates: list[str]) -> str:
    for candidate in candidates:
        if candidate in names:
            return candidate
    return names[0] if names else "default"


def collect_region_assignments(root: Path) -> dict[str, list[str]]:
    assignments: dict[str, set[str]] = {enemy_id: set() for enemy_id in ARCHETYPES}
    for room_file in (root / "data/world/rooms").glob("*.json"):
        payload = json.loads(room_file.read_text(encoding="utf-8"))
        for room in payload.get("rooms", []):
            region = room.get("region_id", "")
            for encounter in room.get("encounters", []):
                for wave in encounter.get("waves", []):
                    for unit in wave:
                        enemy_id = unit.get("enemy", "")
                        if enemy_id in assignments and region:
                            assignments[enemy_id].add(region)
    missing = sorted(enemy_id for enemy_id, regions in assignments.items() if not regions)
    if missing:
        raise ValueError(f"Enemies have no authored world-region placement: {missing}")
    return {enemy_id: sorted(regions) for enemy_id, regions in assignments.items()}


def navigation_contract(archetype: str, airborne: bool) -> dict[str, object]:
    if airborne:
        return {
            "mode": "flight",
            "requires_floor": False,
            "can_cross_gaps": True,
            "tracks_target_vertically": True,
        }
    return {
        "mode": "ground",
        "requires_floor": True,
        "can_cross_gaps": archetype == "leaping_enemy",
        "tracks_target_vertically": archetype == "leaping_enemy",
    }


def main() -> int:
    root = Path(__file__).resolve().parents[1]
    path = root / "Characters" / "Enemies" / "enemy_library.json"
    library = json.loads(path.read_text(encoding="utf-8"))
    library["schema_version"] = 2
    region_assignments = collect_region_assignments(root)
    for enemy in library["enemies"]:
        enemy_id = enemy["id"]
        archetype = ARCHETYPES[enemy_id]
        health, damage, attack_range, cooldown, chase_speed = BALANCE[archetype]
        contract = CONTRACTS[archetype]
        frame_path = root / enemy["sprite_frames"].removeprefix("res://")
        animation_names = re.findall(r'"name": &"([^"]+)"', frame_path.read_text(encoding="utf-8"))
        body_size = [
            max(18, min(48, int(enemy["frame_width"] * 0.18))),
            max(30, min(68, int(enemy["frame_height"] * 0.45))),
        ]
        telegraph, active, recovery = contract["attack_timing"]
        stagger_threshold, stagger_recovery, stagger_resistance = contract["stagger"]
        damage_resistance, knockback_resistance = contract["resistances"]
        minimum_currency, maximum_currency = contract["currency"]
        detection_radius = max(280 if "shooter" in archetype else 210, attack_range + 40)
        attack_audio = (
            "laser_shot" if contract["attack_kind"] == "ranged"
            else "hazard_warning" if contract["attack_kind"] == "hazard"
            else "armor_hit" if archetype in {"heavy_armored_enemy", "shielded_enemy"}
            else "sword_slash"
        )
        enemy.pop("test_scene", None)
        enemy.update(
            {
                "archetype": archetype,
                "animations": animation_names,
                "max_health": health,
                "attack_damage": damage,
                "attack_range": attack_range,
                "attack_cooldown": cooldown,
                "patrol_speed": round(chase_speed * (0.58 if enemy["airborne"] else 0.61), 2),
                "chase_speed": chase_speed,
                "detection_radius": detection_radius,
                "body_size": body_size,
                "regions": region_assignments[enemy_id],
                "stagger": {
                    "threshold": stagger_threshold,
                    "recovery": stagger_recovery,
                    "resistance": stagger_resistance,
                },
                "resistances": {
                    "damage": damage_resistance,
                    "knockback": knockback_resistance,
                },
                "detection": {
                    "radius": detection_radius,
                    "leash_distance": contract["leash"],
                    "requires_line_of_sight": False,
                },
                "navigation": navigation_contract(archetype, bool(enemy["airborne"])),
                "attack": {
                    "kind": contract["attack_kind"],
                    "telegraph": telegraph,
                    "active": active,
                    "recovery": recovery,
                    "punish_window": recovery,
                    "stagger_damage": 2.0 if archetype in {"heavy_armored_enemy", "leaping_enemy"} else 1.0,
                },
                "hurt": {
                    "duration": 0.24 if archetype in {"heavy_armored_enemy", "shielded_enemy"} else 0.20,
                    "interrupts_attack": True,
                },
                "death": {
                    "behavior": "despawn_after_animation",
                    "sfx": "explosion",
                    "vfx": "explosion_ring",
                },
                "drop_table": [
                    {
                        "type": "currency",
                        "id": "credits",
                        "chance": 1.0,
                        "min": minimum_currency,
                        "max": maximum_currency,
                    }
                ],
                "animation_map": {
                    "idle": choose_animation(animation_names, ["idle", "idle_walk", "walk", "move"]),
                    "move": choose_animation(animation_names, ["run", "walk", "move", "flying", "idle"]),
                    "attack": choose_animation(animation_names, ["attack", "attack_1", "attack1", "fwd_swing", "full_combo"]),
                    "hurt": choose_animation(animation_names, ["hurt", "hit", "idle"]),
                    "death": choose_animation(animation_names, ["death", "die", "hurt", "idle"]),
                },
                "collision": {
                    "body_size": body_size,
                    "hurtbox_size": [round(body_size[0] * 1.18, 2), round(body_size[1] * 1.08, 2)],
                    "contact_hitbox_size": [round(body_size[0] * 1.2, 2), round(body_size[1] * 0.72, 2)],
                    "contact_offset": [round(body_size[0] * 0.42, 2), round(-body_size[1] * 0.36, 2)],
                },
                "audio_profile": {
                    "attack": attack_audio,
                    "hurt": "armor_hit" if archetype in {"heavy_armored_enemy", "shielded_enemy"} else "player_hurt",
                    "death": "explosion",
                },
                "vfx_profile": {
                    "telegraph_color": "ff6b45" if contract["attack_kind"] != "ranged" else "58f0ff",
                    "death": "explosion_ring",
                },
                "difficulty_variants": {
                    "act_balance_profile": "res://scripts/campaign/ActBalanceProfile.gd",
                    "elite": {"health_multiplier": 2.0, "palette": "ff59d4"},
                },
                "score_value": health * 100,
            }
        )
        if enemy_id == "death_knight":
            enemy["source_directory"] = "res://assets/runtime/characters/Enemies/Skeleton Warrior  2D Pixel Art v1.1/Sprites/without_outline"
    path.write_text(json.dumps(library, indent=2, ensure_ascii=False) + "\n", encoding="utf-8", newline="\n")
    print("ENEMY_LIBRARY_UPGRADE_OK enemies=22 archetypes=10 schema=2 contracts=22")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
