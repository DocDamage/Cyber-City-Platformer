# Cyber City Platformer

Godot 4.7 project foundation for a neon cyberpunk action platformer.

## Controls

- Move: Left/Right arrows or gamepad left stick/D-pad
- Jump / wall jump: Space or the default `ui_accept` gamepad binding
- Melee: Z or gamepad Cross/A
- Shoot: X or gamepad Square/X
- Slide/dash input: C or gamepad Circle/B

## HUD and game loop

`GameManager` persists health, dash/weapon energy, credits, collected pickup IDs, and checkpoint positions between scenes. The rooftop checkpoint terminal heals the player and becomes the active respawn position. The exit gate at the far right loads `res://scenes/Level2.tscn`.

The screen-space HUD uses segmented MegaMan-style health and energy blocks plus an animated coin counter. Shooting costs 12 energy, dashing costs 30 energy, and energy recharges over time.

`SoundManager` loops canonical OGG music from `res://Music/Library` and uses a positional `AudioStreamPlayer2D` pool backed by the supplied `res://SFX/Library`. Its generated retro sounds remain only as safe fallbacks. Reusable GPU particle scenes under `res://scenes/vfx` provide impact sparks, movement dust, and enemy explosion smoke; the full supplied source library is under `res://VFX/SourceArt`.

Combat uses reusable `Hitbox` and `Hurtbox` Area2D scripts. Player attacks use physics layer 3 and detect enemy hurtboxes on layer 4; enemy attacks use layer 5 and detect the player's hurtbox on layer 6. A hurtbox's parent should implement `take_damage(amount)` unless its `damage_receiver` path points elsewhere.

The player camera has 5.0-speed position smoothing, facing-based look-ahead, and a lightweight shake API. Melee impacts trigger shake and a 0.05-second hit stop automatically. Explosion effects can trigger the same camera shake with `CombatFeedback.camera_shake(strength, duration)`.

After taking damage, the player hurtbox is disabled for one second while the sprite flashes. The movement collision remains enabled so i-frames cannot make the player fall through platforms.

The startup scene is `res://scenes/Level.tscn`. Canonical project asset roots are `res://Characters`, `res://Stages`, `res://Stage Props`, `res://Music`, `res://SFX`, `res://Parallax`, and `res://VFX`.

## Campaign asset registry

The `AssetRegistry` autoload resolves props, character textures, all 22 enemy scenes and animation libraries, all 20 campaign stages, OGG music, SFX, parallax textures, and VFX textures. Every campaign slot has a real scene path: stage 1-1 is playable, stage 2-1 is the existing factory prototype, and the other 18 are editable blockout prototypes.

Open `res://Characters/Enemies/EnemyCatalog.tscn` to browse all enemies. Open any `Stage.tscn` under an act folder to edit that level's terrain, blockout, props, hazards, enemies, VFX, lighting, and markers. Four paint-ready atlas palettes are available under `res://Stages/TileSets`.

Rebuild generated editor assets after replacing source files:

```text
godot --headless --path . --script res://scripts/tools/EnemyLibraryBuilder.gd
godot --headless --path . --script res://scripts/tools/StageTileSetBuilder.gd
godot --headless --path . --script res://scripts/tools/CampaignPrototypeBuilder.gd
```

Run the registry validation with `godot --headless --path . --script res://scripts/AssetRegistrySmokeTest.gd`.

Run the full gameplay-system smoke test with `godot --headless --path . --script res://scripts/SystemsSmokeTest.gd`.
