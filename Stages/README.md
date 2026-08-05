# Campaign stages

The four act folders contain five production `Stage.tscn` scenes each. `campaign_manifest.json` is the source for titles, progression, asset families, camera bounds, and scene paths. Exact gameplay content is authored per stage in `scripts/campaign/content/Act1Content.gd` through `Act4Content.gd`; no campaign content is regenerated from an editor template.

Every production stage combines its serialized environment shell with an explicit content blueprint containing:

- Three configured parallax layers and an OGG music assignment.
- A serialized, multi-screen `Terrain` TileMapLayer painted with the act's atlas palette from `Stages/TileSets`.
- Ground, jump platforms, gap bridges, and a physics layer on every terrain tile.
- Seven themed Sprite2D props sourced from the matching `Stage Props` act folder.
- Two animated checkpoint terminals and a death-zone respawn loop.
- A `StageExit` linked to the next scene, with a persistent fade-to-black transition.
- Named `Props`, `Hazards`, `Enemies`, `VFX`, `Lighting`, and `Markers` folders.
- Player and HUD instances for immediate playtesting.
- At least two named traversal sections and two named combat encounters in every standard stage.
- Exact encounter activation bounds, enemy positions, elite variants, and reinforcement waves.
- Exact stage-mechanic placements, variants, timing, and terminal/gate links.
- An optional collectible route with stable pickup identifiers.
- A three-phase `BossBase` encounter in every X-5 arena. The stage exit is locked until the boss defeat signal fires.

The TileSet palettes expose the supplied grids for continued hand painting and assign physics polygons to the `World` collision layer. `StageController` installs the authored blueprint without searching the scene tree for critical nodes; each scene exposes typed node paths through `StageBase`.

After changing campaign data, run `python tools/run_headless_suite.py`. Use `scripts/tools/StageTileSetBuilder.gd` only when intentionally rebuilding the collision palettes.
