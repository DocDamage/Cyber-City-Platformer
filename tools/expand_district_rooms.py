#!/usr/bin/env python3
"""Expand the connected world to the production district room budget.

The source blueprints are intentionally separate from the generated room JSON so
design intent remains reviewable. The transform preserves every existing room and
district pacing total, inserts four critical traversal rooms into each compact
district, raises every district to two optional rooms, and assigns a stable snake
layout plus a canonical critical-path index.
"""

from __future__ import annotations

import argparse
import copy
import json
import math
from collections import defaultdict
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[1]
MANIFEST_PATH = ROOT / "data/world/world_manifest.json"
BLUEPRINT_PATH = ROOT / "tools/data/district_expansion_blueprints.json"
LAYOUT_BLUEPRINT_PATH = ROOT / "tools/data/district_layout_blueprints.json"
EXPANSION_VERSION = 2
ROLE_WEIGHTS = [0.10, 0.105, 0.13, 0.115, 0.14, 0.12, 0.12, 0.17]
REGION_ROWS = {
    "cyber_city": (0, 1),
    "robot_factory": (4, -1),
    "neon_moon": (8, 1),
    "abyssal_night": (12, -1),
}
OPTIONAL_ROW_OFFSETS = {
    "cyber_city": -1,
    "robot_factory": 1,
    "neon_moon": -1,
    "abyssal_night": 1,
}


def load_json(path: Path) -> dict[str, Any]:
    with path.open("r", encoding="utf-8") as stream:
        value = json.load(stream)
    if not isinstance(value, dict):
        raise ValueError(f"{path} must contain a JSON object")
    return value


def dump_json(path: Path, value: dict[str, Any]) -> None:
    path.write_text(
        json.dumps(value, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
        newline="\n",
    )


def resource_path(value: str) -> Path:
    prefix = "res://"
    if not value.startswith(prefix):
        raise ValueError(f"Expected a res:// path, got {value!r}")
    return ROOT / value.removeprefix(prefix)


def current_route(rooms: dict[str, dict[str, Any]], start_id: str) -> list[str]:
    """Follow the pre-expansion authored route used by the production test."""
    result: list[str] = []
    visited: set[str] = set()
    room_id = start_id
    vertical_spire = {"cyber_spire_entry", "cyber_spire_lift", "cyber_spire_signal"}
    while room_id in rooms and room_id not in visited:
        visited.add(room_id)
        result.append(room_id)
        if room_id == "void_heart_exit":
            break
        connection_id = "north" if room_id in vertical_spire else "east"
        connection = next(
            (
                entry
                for entry in rooms[room_id].get("connections", [])
                if entry.get("id") == connection_id
            ),
            None,
        )
        if connection is None:
            raise ValueError(f"Critical route stops at {room_id}: missing {connection_id}")
        room_id = str(connection.get("target_room", ""))
    return result


def distribute(total: int, weights: list[float]) -> list[int]:
    raw = [total * weight for weight in weights]
    values = [math.floor(value) for value in raw]
    remainder = total - sum(values)
    order = sorted(range(len(raw)), key=lambda index: (raw[index] - values[index], -index), reverse=True)
    for index in order[:remainder]:
        values[index] += 1
    return values


def connection_rect(connection_id: str) -> list[int]:
    return {
        "west": [0, 385, 16, 115],
        "east": [944, 385, 16, 115],
        "north": [430, 0, 100, 18],
        "south": [430, 522, 100, 18],
    }.get(connection_id, [0, 210, 16, 90])


def spawn_point(connection_id: str) -> list[int]:
    return {
        "west": [70, 446],
        "east": [875, 446],
        "north": [480, 70],
        "south": [480, 446],
    }.get(connection_id, [70, 270])


def authored_platforms(profile: dict[str, Any], role: str) -> list[list[int]]:
    """Shape one room from a district-authored spatial rhythm.

    Profiles define the recognizable anchor silhouette for a district. Role
    transforms preserve that identity while changing safety, gaps, and vertical
    pressure between teach/test/twist/recovery and optional rooms.
    """
    anchors = profile.get("anchors", [])
    if len(anchors) != 4 or any(not isinstance(anchor, list) or len(anchor) != 3 for anchor in anchors):
        raise ValueError("Layout profile must contain four [x, y, width] anchors")
    transforms = {
        "teach": ([0, 0, 0, 0], [10, 8, 6, 4], [20, 20, 15, 15]),
        "test": ([-10, 15, -5, 10], [0, -15, 5, -20], [-10, -5, -10, -5]),
        "twist": ([20, -20, 25, -15], [-35, 10, -30, 15], [-20, -15, -20, -10]),
        "recovery": ([0, 5, -5, 0], [25, 25, 30, 30], [35, 35, 30, 35]),
        "optional_lore": ([15, -10, 10, -20], [-10, 15, -5, 20], [10, 15, 10, 15]),
        "optional_mastery": ([-20, 20, -15, 15], [-30, -5, -35, 0], [-15, -10, -15, -10]),
    }
    if role not in transforms:
        raise ValueError(f"Unsupported authored room role {role}")
    x_bias, y_bias, width_bias = transforms[role]
    result: list[list[int]] = []
    if role in {"test", "twist", "optional_mastery"}:
        gap_width = 280 if role == "test" else (320 if role == "twist" else 240)
        gap_center = int(profile.get("gap_center", 480)) + (20 if role == "twist" else 0)
        gap_start = max(190, gap_center - gap_width // 2)
        gap_end = min(770, gap_center + gap_width // 2)
        result.extend([[0, 500, gap_start, 40], [gap_end, 500, 960 - gap_end, 40]])
    else:
        result.append([0, 500, 960, 40])
    for index, anchor in enumerate(anchors):
        x = max(20, min(900, int(anchor[0]) + x_bias[index]))
        y = max(120, min(470, int(anchor[1]) + y_bias[index]))
        width = max(90, min(210, int(anchor[2]) + width_bias[index]))
        if x + width > 940:
            x = 940 - width
        result.append([x, y, width, 18])
    return result


def apply_authored_layout(
    room: dict[str, Any],
    profile: dict[str, Any],
    role: str,
    slug: str,
) -> None:
    room["layout_id"] = f"{room['district_id']}_{role}_{slug}"
    room["layout_source"] = "district_layout_blueprint_v1"
    room["spatial_rhythm"] = str(profile["spatial_rhythm"])
    room["landmark"] = str(profile["landmark"])
    room["platforms"] = authored_platforms(profile, role)


def apply_mechanic(room: dict[str, Any], mechanic: str, role_index: int) -> None:
    if mechanic == "moving_horizontal":
        room["moving_platforms"] = [{"position": [480, 410], "size": [116, 18], "path": [[-190, 0], [190, 0]], "speed": 92 + role_index * 8, "wait": 0.35}]
    elif mechanic == "moving_vertical":
        room["moving_platforms"] = [{"position": [480, 440], "size": [116, 18], "path": [[0, 0], [0, -270]], "speed": 88 + role_index * 8, "wait": 0.35}]
    elif mechanic == "breakaway":
        room["breakaway_platforms"] = [
            {"position": [335, 370], "size": [105, 18], "collapse_delay": 0.75},
            {"position": [630, 325], "size": [105, 18], "collapse_delay": 0.65},
        ]
    elif mechanic in {"conveyor", "conveyor_reverse"}:
        room["conveyors"] = [
            {
                "id": f"{room['id']}_belt_a",
                "position": [275, 480],
                "size": [310, 22],
                "speed": 105,
                "reversible": mechanic == "conveyor_reverse",
                "reverse_interval": 3.2,
            },
            {
                "id": f"{room['id']}_belt_b",
                "position": [700, 480],
                "size": [260, 22],
                "speed": -115,
                "reversible": mechanic == "conveyor_reverse",
                "reverse_interval": 3.2,
            },
        ]
    elif mechanic == "rotating_laser":
        room["hazards"] = [{"type": "rotating_laser", "position": [480, 300], "radius": 175, "speed": 0.62 + role_index * 0.06, "clockwise": role_index % 2 == 0}]
    elif mechanic == "gravity_zone":
        room["hazards"] = [{"type": "gravity_zone", "position": [480, 290], "size": [560, 300], "gravity": 0.42 + role_index * 0.04}]
    elif mechanic == "crusher":
        room["hazards"] = [
            {"type": "crusher", "position": [350, 185], "distance": 245, "phase": 0.0},
            {"type": "crusher", "position": [650, 185], "distance": 245, "phase": 1.2},
        ]
    else:
        sizes = {
            "electrical_floor": [220, 24],
            "laser_grid": [28, 285],
            "steam_vent": [120, 26],
            "toxic_pool": [250, 38],
            "void_pit": [270, 44],
            "corruption_zone": [300, 110],
        }
        position = [480, 475]
        if mechanic == "laser_grid":
            position = [480, 305]
        elif mechanic == "corruption_zone":
            position = [480, 405]
        room["hazards"] = [
            {
                "type": mechanic,
                "position": position,
                "size": sizes.get(mechanic, [180, 28]),
                "active": 0.85 + role_index * 0.05,
                "inactive": 1.55 - role_index * 0.08,
                "damage": 0 if mechanic == "corruption_zone" else 1,
            }
        ]


def critical_room(
    district_id: str,
    region_id: str,
    district_name: str,
    brief: dict[str, Any],
    role_index: int,
    layout_profile: dict[str, Any],
) -> dict[str, Any]:
    room_id = f"{district_id}_exp_{brief['slug']}"
    room: dict[str, Any] = {
        "id": room_id,
        "region_id": region_id,
        "district_id": district_id,
        "display_name": f"{district_name} — {brief['title']}",
        "bounds": [0, 0, 960, 540],
        "pacing": {"first_pass_seconds": 1, "expert_seconds": 1},
        "room_role": brief["role"],
        "design_intent": brief["intent"],
        "mechanic_contract": brief["mechanic"],
        "authored_expansion": True,
        "spawns": {},
        "connections": [],
    }
    apply_authored_layout(room, layout_profile, str(brief["role"]), str(brief["slug"]))
    apply_mechanic(room, str(brief["mechanic"]), role_index)
    return room


def find_connection(room: dict[str, Any], target_id: str) -> dict[str, Any]:
    matches = [entry for entry in room.get("connections", []) if entry.get("target_room") == target_id]
    if len(matches) != 1:
        raise ValueError(f"Expected one connection from {room['id']} to {target_id}, found {len(matches)}")
    return matches[0]


def splice_edge(
    rooms: dict[str, dict[str, Any]],
    source_id: str,
    target_id: str,
    insert_ids: list[str],
) -> None:
    source_connection = find_connection(rooms[source_id], target_id)
    target_connection = find_connection(rooms[target_id], source_id)
    forward_id = str(source_connection["id"])
    reverse_id = str(source_connection["target_connection"])
    if target_connection.get("id") != reverse_id:
        raise ValueError(f"Reciprocal id mismatch for {source_id} -> {target_id}")

    source_connection["target_room"] = insert_ids[0]
    source_connection["target_connection"] = reverse_id
    target_connection["target_room"] = insert_ids[-1]
    target_connection["target_connection"] = forward_id
    chain = [source_id, *insert_ids, target_id]
    for index, room_id in enumerate(insert_ids, start=1):
        room = rooms[room_id]
        room["spawns"] = {
            reverse_id: spawn_point(reverse_id),
            forward_id: spawn_point(forward_id),
        }
        room["connections"] = [
            {
                "id": reverse_id,
                "rect": connection_rect(reverse_id),
                "target_room": chain[index - 1],
                "target_connection": forward_id,
            },
            {
                "id": forward_id,
                "rect": connection_rect(forward_id),
                "target_room": chain[index + 1],
                "target_connection": reverse_id,
            },
        ]


def optional_room(
    district_id: str,
    region_id: str,
    district_name: str,
    brief: dict[str, Any],
    optional_index: int,
    cache_amount: int,
    layout_profile: dict[str, Any],
) -> dict[str, Any]:
    room_id = f"{district_id}_opt_{brief['slug']}"
    hazard_by_region = {
        "cyber_city": "electrical_floor",
        "robot_factory": "steam_vent",
        "neon_moon": "gravity_zone",
        "abyssal_night": "corruption_zone",
    }
    room: dict[str, Any] = {
        "id": room_id,
        "region_id": region_id,
        "district_id": district_id,
        "display_name": f"{district_name} — {brief['title']}",
        "bounds": [0, 0, 960, 540],
        "pacing": {"first_pass_seconds": 95 + optional_index * 15, "expert_seconds": 27 + optional_index * 4, "optional": True},
        "room_role": "optional_lore" if optional_index == 0 else "optional_mastery",
        "design_intent": f"Optional discovery route: {brief['lore']}",
        "authored_expansion": True,
        "spawns": {"return": [875, 270]},
        "terminals": [
            {
                "id": f"lore_{district_id}_{brief['slug']}",
                "kind": "lore",
                "persistence": "save",
                "position": [710, 430],
                "text": brief["lore"],
                "targets": [],
            }
        ],
        "cache": {
            "id": f"cache_{district_id}_{brief['slug']}",
            "amount": cache_amount,
            "position": [480, 255],
        },
        "connections": [],
    }
    apply_authored_layout(room, layout_profile, str(room["room_role"]), str(brief["slug"]))
    if optional_index == 1:
        apply_mechanic(room, hazard_by_region[region_id], optional_index)
    return room


def attach_optional(
    rooms: dict[str, dict[str, Any]],
    anchor_id: str,
    optional_id: str,
    branch_number: int,
) -> None:
    anchor = rooms[anchor_id]
    connection_id = f"annex_{branch_number}"
    existing_ids = {entry.get("id") for entry in anchor.get("connections", [])}
    while connection_id in existing_ids:
        branch_number += 1
        connection_id = f"annex_{branch_number}"
    anchor.setdefault("spawns", {})[connection_id] = [70, 270]
    anchor.setdefault("connections", []).append(
        {
            "id": connection_id,
            "rect": [0, 210, 16, 90],
            "target_room": optional_id,
            "target_connection": "return",
        }
    )
    rooms[optional_id]["connections"] = [
        {
            "id": "return",
            "rect": [944, 210, 16, 90],
            "target_room": anchor_id,
            "target_connection": connection_id,
        }
    ]


def mark_hidden_pair(rooms: dict[str, dict[str, Any]], left_id: str, right_id: str) -> None:
    for source_id, target_id in ((left_id, right_id), (right_id, left_id)):
        for connection in rooms[source_id].get("connections", []):
            if connection.get("target_room") == target_id:
                connection["map_hidden"] = True


def relayout(
    rooms: dict[str, dict[str, Any]],
    critical_route: list[str],
    districts: list[dict[str, Any]],
) -> None:
    by_region: dict[str, list[str]] = defaultdict(list)
    for room_id in critical_route:
        by_region[str(rooms[room_id]["region_id"])].append(room_id)

    current_x = 0
    critical_cells: dict[str, tuple[int, int]] = {}
    for region_id in REGION_ROWS:
        row, direction = REGION_ROWS[region_id]
        region_rooms = by_region[region_id]
        for offset, room_id in enumerate(region_rooms):
            x = current_x + direction * offset
            rooms[room_id]["map_cell"] = [x, row]
            critical_cells[room_id] = (x, row)
        current_x += direction * (len(region_rooms) - 1)

    district_region = {str(entry["id"]): str(entry["region_id"]) for entry in districts}
    occupied = set(critical_cells.values())
    for district in districts:
        district_id = str(district["id"])
        region_id = district_region[district_id]
        main_row, _ = REGION_ROWS[region_id]
        optional_row = main_row + OPTIONAL_ROW_OFFSETS[region_id]
        optional_ids = sorted(
            room_id
            for room_id, room in rooms.items()
            if room.get("district_id") == district_id and room.get("pacing", {}).get("optional", False)
        )
        for optional_id in optional_ids:
            neighbors = [
                str(entry.get("target_room", ""))
                for entry in rooms[optional_id].get("connections", [])
                if str(entry.get("target_room", "")) in critical_cells
            ]
            if neighbors:
                candidate_x = round(sum(critical_cells[target][0] for target in neighbors) / len(neighbors))
            else:
                district_critical = [
                    room_id
                    for room_id in critical_route
                    if rooms[room_id].get("district_id") == district_id
                ]
                candidate_x = critical_cells[district_critical[len(district_critical) // 2]][0]
            step = 1
            while (candidate_x, optional_row) in occupied:
                candidate_x += step
                step = -step if step > 0 else -step + 1
            rooms[optional_id]["map_cell"] = [candidate_x, optional_row]
            occupied.add((candidate_x, optional_row))

    for room_id, room in rooms.items():
        source = tuple(int(value) for value in room["map_cell"])
        for connection in room.get("connections", []):
            target_id = str(connection.get("target_room", ""))
            if target_id not in rooms or room_id >= target_id:
                continue
            target = tuple(int(value) for value in rooms[target_id]["map_cell"])
            dx, dy = target[0] - source[0], target[1] - source[1]
            steps = math.gcd(abs(dx), abs(dy))
            crosses_room = False
            if steps > 1:
                step_x, step_y = dx // steps, dy // steps
                crosses_room = any(
                    (source[0] + step_x * index, source[1] + step_y * index) in occupied
                    for index in range(1, steps)
                )
            both_critical = room_id in critical_cells and target_id in critical_cells
            nonadjacent_critical = both_critical and abs(dx) + abs(dy) > 1
            if connection.get("map_hidden", False) or crosses_room or nonadjacent_critical:
                mark_hidden_pair(rooms, room_id, target_id)


def verify_expanded(
    rooms: dict[str, dict[str, Any]],
    manifest: dict[str, Any],
    blueprints: dict[str, Any],
    layout_blueprints: dict[str, Any],
) -> None:
    errors: list[str] = []
    indices: dict[int, str] = {}
    layout_ids: dict[str, str] = {}
    platform_signatures: dict[str, str] = {}
    for room_id, room in rooms.items():
        pacing = room.get("pacing", {})
        if not pacing.get("optional", False):
            index = room.get("critical_path_index")
            if not isinstance(index, int):
                errors.append(f"{room_id} lacks critical_path_index")
            elif index in indices:
                errors.append(f"critical index {index} is shared by {indices[index]} and {room_id}")
            else:
                indices[index] = room_id
        if room.get("authored_expansion", False):
            layout_id = str(room.get("layout_id", ""))
            if not layout_id or layout_id in layout_ids:
                errors.append(f"{room_id} has missing or duplicate layout id {layout_id}")
            else:
                layout_ids[layout_id] = room_id
            if room.get("layout_source") != "district_layout_blueprint_v1":
                errors.append(f"{room_id} has no authored layout source")
            if not str(room.get("spatial_rhythm", "")) or not str(room.get("landmark", "")):
                errors.append(f"{room_id} lacks spatial rhythm or landmark metadata")
            platforms = room.get("platforms", [])
            if not isinstance(platforms, list) or len(platforms) < 5:
                errors.append(f"{room_id} has insufficient authored platform geometry")
            signature = json.dumps(platforms, sort_keys=True, separators=(",", ":"))
            if signature in platform_signatures:
                errors.append(f"{room_id} duplicates platform geometry from {platform_signatures[signature]}")
            else:
                platform_signatures[signature] = room_id
    if sorted(indices) != list(range(len(indices))):
        errors.append("critical path indices are not contiguous")

    district_ids = [str(entry["id"]) for entry in manifest["districts"]]
    profiles = layout_blueprints.get("profiles", {})
    if set(profiles) != set(district_ids):
        errors.append("layout blueprint district coverage does not match the world manifest")
    for district_id in district_ids:
        district_rooms = [room for room in rooms.values() if room.get("district_id") == district_id]
        critical = [room for room in district_rooms if not room.get("pacing", {}).get("optional", False)]
        optional = [room for room in district_rooms if room.get("pacing", {}).get("optional", False)]
        if not 8 <= len(critical) <= 14:
            errors.append(f"{district_id} has {len(critical)} critical rooms")
        if not 2 <= len(optional) <= 5:
            errors.append(f"{district_id} has {len(optional)} optional rooms")
        total = sum(int(room["pacing"]["first_pass_seconds"]) for room in critical)
        if not 900 <= total <= 1200:
            errors.append(f"{district_id} first-pass total is {total}")
        if district_id != "rooftop_alley":
            roles = {
                str(room.get("room_role", ""))
                for room in critical
                if room.get("authored_expansion", False)
            }
            expected_roles = set(blueprints["design_contract"]["roles"])
            if roles != expected_roles:
                errors.append(f"{district_id} expansion roles are {sorted(roles)}")
        if not any("cache" in room for room in optional):
            errors.append(f"{district_id} has no optional currency cache")

    authored_count = sum(bool(room.get("authored_expansion", False)) for room in rooms.values())
    if authored_count != 103 or len(layout_ids) != authored_count or len(platform_signatures) != authored_count:
        errors.append(
            f"authored layout coverage is rooms={authored_count} ids={len(layout_ids)} geometry={len(platform_signatures)}"
        )

    route_ids = [indices[index] for index in sorted(indices)]
    if not route_ids or route_ids[0] != manifest["start_room_id"] or route_ids[-1] != "void_heart_exit":
        errors.append("critical route endpoints are invalid")
    for left_id, right_id in zip(route_ids, route_ids[1:]):
        if not any(entry.get("target_room") == right_id for entry in rooms[left_id].get("connections", [])):
            errors.append(f"critical route is disconnected at {left_id} -> {right_id}")
    if errors:
        raise ValueError("Expansion verification failed:\n- " + "\n- ".join(errors))


def upgrade_layouts(
    rooms: dict[str, dict[str, Any]],
    layout_blueprints: dict[str, Any],
) -> None:
    profiles = layout_blueprints.get("profiles", {})
    for room in rooms.values():
        if not room.get("authored_expansion", False):
            continue
        room_id = str(room["id"])
        district_id = str(room["district_id"])
        role = str(room.get("room_role", ""))
        marker = "_exp_" if "_exp_" in room_id else "_opt_"
        if marker not in room_id:
            raise ValueError(f"Cannot derive authored layout slug from {room_id}")
        slug = room_id.split(marker, 1)[1]
        if district_id not in profiles:
            raise ValueError(f"No authored layout profile for {district_id}")
        apply_authored_layout(room, profiles[district_id], role, slug)


def expand() -> tuple[dict[Path, dict[str, Any]], dict[str, dict[str, Any]], dict[str, Any], dict[str, Any]]:
    manifest = load_json(MANIFEST_PATH)
    blueprints = load_json(BLUEPRINT_PATH)
    layout_blueprints = load_json(LAYOUT_BLUEPRINT_PATH)
    layout_profiles = layout_blueprints.get("profiles", {})
    if not isinstance(layout_profiles, dict):
        raise ValueError("District layout blueprints must contain a profiles object")
    payloads: dict[Path, dict[str, Any]] = {}
    room_sources: dict[str, Path] = {}
    rooms: dict[str, dict[str, Any]] = {}
    for value in manifest["room_files"]:
        path = resource_path(str(value))
        payload = load_json(path)
        payloads[path] = payload
        for room in payload["rooms"]:
            room_id = str(room["id"])
            if room_id in rooms:
                raise ValueError(f"Duplicate room id {room_id}")
            rooms[room_id] = room
            room_sources[room_id] = path

    versions = {payload.get("district_expansion_version") for payload in payloads.values()}
    if versions == {EXPANSION_VERSION}:
        verify_expanded(rooms, manifest, blueprints, layout_blueprints)
        return payloads, rooms, manifest, blueprints
    if versions == {1}:
        upgrade_layouts(rooms, layout_blueprints)
        for payload in payloads.values():
            payload["district_expansion_version"] = EXPANSION_VERSION
        verify_expanded(rooms, manifest, blueprints, layout_blueprints)
        return payloads, rooms, manifest, blueprints
    if versions != {None}:
        raise ValueError(f"World files have an unsupported or partial expansion state: {sorted(versions, key=str)}")

    original_route = current_route(rooms, str(manifest["start_room_id"]))
    if len(original_route) != 86:
        raise ValueError(f"Expected the 86-room pre-expansion critical route, got {len(original_route)}")
    original_by_district: dict[str, list[str]] = defaultdict(list)
    for room_id in original_route:
        original_by_district[str(rooms[room_id]["district_id"])].append(room_id)

    district_meta = {str(entry["id"]): entry for entry in manifest["districts"]}
    district_chains: dict[str, list[str]] = {"rooftop_alley": original_by_district["rooftop_alley"]}
    new_rooms_by_source: dict[Path, list[dict[str, Any]]] = defaultdict(list)
    for district_id, blueprint in blueprints["districts"].items():
        if district_id == "rooftop_alley":
            continue
        anchors = original_by_district[district_id]
        if len(anchors) != 4:
            raise ValueError(f"{district_id} must have four pre-expansion critical anchors, got {len(anchors)}")
        briefs = blueprint.get("critical", [])
        if len(briefs) != 4:
            raise ValueError(f"{district_id} must author four critical expansion briefs")
        region_id = str(district_meta[district_id]["region_id"])
        district_name = str(district_meta[district_id]["display_name"])
        layout_profile = layout_profiles[district_id]
        additions = [critical_room(district_id, region_id, district_name, brief, index, layout_profile) for index, brief in enumerate(briefs)]
        source_path = room_sources[anchors[0]]
        for room in additions:
            if room["id"] in rooms:
                raise ValueError(f"Generated room id collides: {room['id']}")
            rooms[room["id"]] = room
            room_sources[room["id"]] = source_path
            new_rooms_by_source[source_path].append(room)
        new_ids = [str(room["id"]) for room in additions]
        splice_edge(rooms, anchors[0], anchors[1], [new_ids[0]])
        splice_edge(rooms, anchors[1], anchors[2], [new_ids[1]])
        splice_edge(rooms, anchors[2], anchors[3], [new_ids[2], new_ids[3]])
        chain = [anchors[0], new_ids[0], anchors[1], new_ids[1], anchors[2], new_ids[2], new_ids[3], anchors[3]]
        district_chains[district_id] = chain
        first_pass_total = sum(int(rooms[room_id]["pacing"]["first_pass_seconds"]) for room_id in anchors)
        expert_total = sum(int(rooms[room_id]["pacing"]["expert_seconds"]) for room_id in anchors)
        for room_id, first_pass, expert in zip(chain, distribute(first_pass_total, ROLE_WEIGHTS), distribute(expert_total, ROLE_WEIGHTS)):
            rooms[room_id]["pacing"] = {"first_pass_seconds": first_pass, "expert_seconds": expert}

    region_rank = {region_id: index for index, region_id in enumerate(REGION_ROWS)}
    for district_id, blueprint in blueprints["districts"].items():
        current_optional = [
            room_id
            for room_id, room in rooms.items()
            if room.get("district_id") == district_id and room.get("pacing", {}).get("optional", False)
        ]
        needed = 2 - len(current_optional)
        if needed <= 0:
            continue
        optional_briefs = blueprint.get("optional", [])
        if len(optional_briefs) < needed:
            raise ValueError(f"{district_id} needs {needed} optional briefs")
        region_id = str(district_meta[district_id]["region_id"])
        district_name = str(district_meta[district_id]["display_name"])
        if district_id == "rooftop_alley":
            anchors = ["cyber_rooftop_signworks"]
        else:
            expansion_ids = [room_id for room_id in district_chains[district_id] if rooms[room_id].get("authored_expansion", False)]
            anchors = [expansion_ids[-1]] if needed == 1 else [expansion_ids[0], expansion_ids[-1]]
        source_path = room_sources[anchors[0]]
        for index in range(needed):
            cache_amount = 25 + region_rank[region_id] * 15 + index * 10
            layout_profile = layout_profiles[district_id]
            room = optional_room(district_id, region_id, district_name, optional_briefs[index], index, cache_amount, layout_profile)
            room_id = str(room["id"])
            if room_id in rooms:
                raise ValueError(f"Generated room id collides: {room_id}")
            rooms[room_id] = room
            room_sources[room_id] = source_path
            new_rooms_by_source[source_path].append(room)
            attach_optional(rooms, anchors[index], room_id, index + 1)

    critical_route: list[str] = []
    for district in manifest["districts"]:
        critical_route.extend(district_chains[str(district["id"])])
    for index, room_id in enumerate(critical_route):
        rooms[room_id]["critical_path_index"] = index
    relayout(rooms, critical_route, manifest["districts"])

    for path, additions in new_rooms_by_source.items():
        payloads[path]["rooms"].extend(additions)
    for payload in payloads.values():
        payload["schema_version"] = max(int(payload.get("schema_version", 1)), 2)
        payload["district_expansion_version"] = EXPANSION_VERSION
    verify_expanded(rooms, manifest, blueprints, layout_blueprints)
    return payloads, rooms, manifest, blueprints


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    mode = parser.add_mutually_exclusive_group(required=True)
    mode.add_argument("--apply", action="store_true", help="write the expanded room files")
    mode.add_argument("--check", action="store_true", help="verify the checked-in expansion without writing")
    args = parser.parse_args()

    manifest_snapshot = load_json(MANIFEST_PATH)
    versions = [
        load_json(resource_path(str(value))).get("district_expansion_version")
        for value in manifest_snapshot["room_files"]
    ]
    if len(set(versions)) != 1:
        raise ValueError(f"World files have a partial expansion state: {versions}")
    if args.check and versions[0] != EXPANSION_VERSION:
        raise ValueError("World files are not expanded; run with --apply")

    payloads, rooms, manifest, blueprints = expand()
    if args.apply:
        for path, payload in payloads.items():
            dump_json(path, payload)
    else:
        verify_expanded(rooms, manifest, blueprints, load_json(LAYOUT_BLUEPRINT_PATH))
    critical_count = sum(not room.get("pacing", {}).get("optional", False) for room in rooms.values())
    optional_count = len(rooms) - critical_count
    print(
        "DISTRICT_EXPANSION_OK "
        f"rooms={len(rooms)} critical={critical_count} optional={optional_count} "
        f"districts={len(manifest['districts'])} version={EXPANSION_VERSION}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
