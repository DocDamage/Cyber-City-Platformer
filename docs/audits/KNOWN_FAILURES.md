# Known failures at baseline

All items below were reproduced at commit `380d88d5e181924aa0cf42fdde550af1a0e8479a` with Godot 4.7.1.

| Severity | Area | Exact location | Reproduction | Observed result |
|---|---|---|---|---|
| Critical | Audio autoload | `scripts/AudioManager.gd` | Import or launch a clean clone | Absent `Music/Library` and `SFX/Library` preloads cause parse failure; autoload cannot be created. |
| Critical | VFX/autoload | `scenes/vfx/SparkBurst.tscn`, `scripts/VFXSpawner.gd`, `scripts/Bullet.gd` | Launch a clean clone | Missing `VFX/SourceArt/.../Effect (1)-Sheet.png` breaks scene and script preloads. |
| Critical | Main scene | `scenes/Level.tscn` | Launch a clean clone | Missing tileset and prop resources prevent valid level loading. |
| Critical | Campaign art | `Characters/Enemies/SpriteFrames/*.tres` | Instantiate production enemies in a clean clone | Animation strips are ignored, so `SpriteFrames` resources fail to load. |
| Critical | Terrain | `scenes/RooftopTileSet.tres`, `Stages/Act1_CyberCity/CyberCityTileSet.tres` | Import a clean clone | Missing terrain texture creates invalid atlas tiles and collision data. |
| High | Reproducibility | `.gitignore` canonical asset exclusions | Compare local and clean import | Runtime-critical resources exist only as ignored local files. |
| High | Tests | `scripts/AssetRegistrySmokeTest.gd` | Run in clean clone | Test times out amid missing assets and recursive fallback searches. |
| High | Tests | Existing smoke-test suite | Run in clean clone | Resource/autoload failures prevent intended system assertions from being meaningful. |
| High | Camera | `scripts/DynamicCamera.gd`, generated stages | Traverse a generated 4,800px-wide stage | Shared fixed camera limit cannot represent each stage's authored bounds. |
| High | Enemies | production enemy scenes | Enter nominal player detection range | Production scene wiring and behavior variety are incomplete; existing tests can be satisfied by fallback fixtures. |
| High | Progression | `scripts/GameManager.gd` | Finish stage 4-5 | Only emits a completion signal/warning; no ending, save flag, results, credits, or title return. |
| High | Game shell | `project.godot` | Start the project | Starts directly in `scenes/Level.tscn`; title, continue, pause, settings, and credits flows are absent. |
| High | Save/load | project-wide | Close and relaunch after a checkpoint | Run state is memory-only; no atomic save, backup, migration, or corruption recovery exists. |
| Medium | Architecture | `scripts/GameManager.gd` | Inspect persisted state | Configuration, run state, campaign progress, and transitions are coupled in one autoload. |
| Medium | Prototypes | generated stage scenes | Launch many campaign stages | `DesignGuide` prototype overlays are present in release scenes. |
| Medium | Duplicate systems | `scripts/AudioManager.gd`, `scripts/SoundManager.gd` | Inspect runtime configuration | Two audio implementations exist; only one is an autoload. |
| Medium | Export | repository root | Run command-line Windows export | `export_presets.cfg` is absent. |
| Medium | CI | `.github/workflows` | Inspect repository | No automated pull-request validation exists. |

Items are removed from this file only after a production-scene reproduction and an automated regression check both pass.
