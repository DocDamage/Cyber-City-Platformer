# Campaign stages

The four act folders contain five named `Stage.tscn` scenes each. `campaign_manifest.json` is the source for titles, design goals, status, the shared enemy library, and scene paths.

Stage 1-1 wraps the playable rooftop level and stage 2-1 wraps the existing factory prototype. The remaining 18 scenes are editable prototypes based on `PrototypeStage.tscn`; they are deliberately labeled `prototype`, not complete levels.

Each prototype contains:

- Three configured parallax layers and an OGG music assignment.
- A `Terrain` TileMapLayer with the act's paint-ready atlas palette from `Stages/TileSets`.
- Playable blockout ground and platforms with collision.
- Named `Props`, `Hazards`, `Enemies`, `VFX`, `Lighting`, and `Markers` folders.
- Player and HUD instances for immediate playtesting.
- One or more supplied enemy scenes. Across the 18 prototypes, all 22 packs are represented.

The TileSet palettes expose the supplied grids for painting but intentionally leave gameplay collision and terrain rules for the level designer. The blockout geometry provides safe collision until the final terrain is authored.

After editing `campaign_manifest.json` or the shared template, run `godot --headless --path . --script res://scripts/tools/CampaignPrototypeBuilder.gd` to regenerate the prototype set.
