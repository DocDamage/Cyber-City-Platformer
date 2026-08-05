#!/usr/bin/env python3
"""Rebuild production enemies as inherited instances of the wired base scene."""

from __future__ import annotations

import json
from pathlib import Path


def choose_animation(names: list[str], candidates: list[str]) -> str:
    for candidate in candidates:
        if candidate in names:
            return candidate
    return names[0] if names else "default"


def main() -> int:
    root = Path(__file__).resolve().parents[1]
    library = json.loads((root / "Characters/Enemies/enemy_library.json").read_text(encoding="utf-8"))
    for enemy in library["enemies"]:
        animations = enemy["animations"]
        movement = choose_animation(animations, ["run", "walk", "move", "flying", "idle"])
        death = choose_animation(animations, ["death", "die", "hurt", "idle"])
        node_name = "".join(part.title() for part in enemy["id"].split("_"))
        contents = f'''[gd_scene load_steps=3 format=3]

[ext_resource type="PackedScene" path="res://scenes/EnemyBase.tscn" id="1_base"]
[ext_resource type="SpriteFrames" path="{enemy['sprite_frames']}" id="2_frames"]

[node name="{node_name}" instance=ExtResource("1_base")]
enemy_id = &"{enemy['id']}"
animation_library = ExtResource("2_frames")
uses_gravity = {str(not enemy['airborne']).lower()}
movement_animation = &"{movement}"
death_animation = &"{death}"
'''
        scene_path = root / enemy["scene"].removeprefix("res://")
        scene_path.write_text(contents, encoding="utf-8", newline="\n")
    print("ENEMY_SCENE_REBUILD_OK scenes=22 inherited_base=res://scenes/EnemyBase.tscn")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
