#!/usr/bin/env python3
"""Promote campaign layouts by removing editor-only guide residue."""

from __future__ import annotations

import json
import re
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
MANIFEST = ROOT / "Stages" / "campaign_manifest.json"
OLD_SCRIPTS = (
    "res://scripts/PrototypeStage.gd",
    "res://tools/stage_builder/PrototypeStage.gd",
)
NEW_SCRIPT = "res://scripts/campaign/CampaignStage.gd"


def remove_resource_block(text: str, resource_id: str) -> str:
    pattern = rf'\n\[sub_resource type="StyleBoxFlat" id="{resource_id}"\]\n.*?(?=\n\[)'
    return re.sub(pattern, "", text, flags=re.DOTALL)


def promote(path: Path) -> bool:
    text = path.read_text(encoding="utf-8")
    original = text
    for script in OLD_SCRIPTS:
        text = text.replace(script, NEW_SCRIPT)
    text = text.replace("Gradient_prototype_light", "Gradient_ambient_light")
    text = text.replace(
        "GradientTexture2D_prototype_light", "GradientTexture2D_ambient_light"
    )
    text = text.replace("GradientTexture_prototype_light", "GradientTexture_ambient_light")
    text = text.replace('name="PrototypeLight"', 'name="AmbientKeyLight"')
    text = re.sub(r'\ndesign_notes = ".*?"\n', "\n", text, flags=re.DOTALL)
    text = remove_resource_block(text, "StyleBox_guide")
    text = remove_resource_block(text, "StyleBox_tag")
    text = re.sub(r'\n\[node name="DesignGuide".*\Z', "\n", text, flags=re.DOTALL)
    if text == original:
        return False
    path.write_text(text, encoding="utf-8", newline="\n")
    return True


def main() -> int:
    manifest = json.loads(MANIFEST.read_text(encoding="utf-8"))
    changed = 0
    for act in manifest["acts"]:
        for stage in act["stages"]:
            scene_path = str(stage["scene"])
            if scene_path.startswith("res://"):
                path = ROOT / scene_path.removeprefix("res://")
                changed += int(promote(path))
    print(f"PROMOTE_CAMPAIGN_STAGES_OK changed={changed}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
