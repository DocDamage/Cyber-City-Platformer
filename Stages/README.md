# Campaign stages

The four act folders contain five named `Stage.tscn` scenes each. `campaign_manifest.json` is the source for titles, design goals, status, the shared enemy library, and scene paths.

Stage 1-1 wraps the bespoke rooftop level and stage 2-1 wraps the bespoke factory intake. The remaining 18 scenes are editable layout passes based on `PrototypeStage.tscn`. All 20 scenes are connected in campaign order.

Each generated layout contains:

- Three configured parallax layers and an OGG music assignment.
- A serialized, multi-screen `Terrain` TileMapLayer painted with the act's atlas palette from `Stages/TileSets`.
- Ground, jump platforms, gap bridges, and a physics layer on every terrain tile.
- Seven themed Sprite2D props sourced from the matching `Stage Props` act folder.
- Two animated checkpoint terminals and a death-zone respawn loop.
- A `StageExit` linked to the next scene, with a persistent fade-to-black transition.
- Named `Props`, `Hazards`, `Enemies`, `VFX`, `Lighting`, and `Markers` folders.
- Player and HUD instances for immediate playtesting.
- One or more supplied enemy scenes. Across the 18 generated layouts, all 22 packs are represented.
- A three-phase `BossBase` encounter in every X-5 arena. The stage exit is locked until the boss defeat signal fires.

The TileSet palettes expose the supplied grids for continued hand painting and assign their physics polygons to the `World` collision layer. Generated layouts are playable construction passes intended for encounter, hazard, and art-direction polish.

After editing `campaign_manifest.json` or the shared template, run `godot --headless --path . --script res://scripts/tools/StageTileSetBuilder.gd`, then `godot --headless --path . --script res://scripts/tools/CampaignPrototypeBuilder.gd` to regenerate the collision palettes and 18 generated layouts.
