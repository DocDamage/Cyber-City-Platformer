# Cyber City Platformer

Godot 4.7 project foundation for a neon cyberpunk action platformer.

## Controls

- Move: Left/Right arrows or gamepad left stick/D-pad
- Jump / wall jump: Space or the default `ui_accept` gamepad binding
- Melee: Z or gamepad Cross/A
- Shoot: X or gamepad Square/X
- Slide/dash input: C or gamepad Circle/B

## HUD and game loop

`GameManager` persists health, dash/weapon energy, credits, collected pickup IDs, and the active checkpoint position between scenes. Checkpoint terminals heal the player, refill energy, save a scene-scoped respawn position, and play a sync animation. Every exit advances to the next campaign sub-stage through the persistent `SceneTransition` fade overlay.

The screen-space HUD uses neon health and weapon-energy progress bars plus a live credits counter. Shooting costs 12 energy, dashing costs 30 energy, and energy recharges over time.

`AudioManager` is a persistent autoload with independent Music and SFX buses, pooled SFX players, one Act theme per campaign act, boss themes, and two-player BGM crossfades. Re-entering the same Act does not restart its track during level transitions. `play_sfx(name)` accepts `laser_shot`, `sword_slash`, `explosion`, `player_hurt`, `jump`, and the other gameplay cues used by the project.

`VFXSpawner.spawn_effect(name, global_position, direction)` creates reusable one-shot GPU particle effects and the particle roots auto-delete after their lifetime. Bullets emit hit sparks against hurtboxes or terrain, enemy and boss defeats emit expanding pixel explosion rings, and the player has a continuous foot-level wall-slide dust emitter.

Combat uses reusable `Hitbox` and `Hurtbox` Area2D scripts. Player attacks use physics layer 3 and detect enemy hurtboxes on layer 4; enemy attacks use layer 5 and detect the player's hurtbox on layer 6. A hurtbox's parent should implement `take_damage(amount)` unless its `damage_receiver` path points elsewhere.

`EnemyBase` provides reusable `IDLE`, `PATROL`, and `CHASE` states. Ground enemies reverse at ledges and walls using `FloorCheck` and `WallCheck` ray casts, while `DetectionArea` switches them into chase when the player enters its radius. Defeated enemies award credits through `GameManager`.

`BossBase` provides the campaign's three-state boss machine: Phase 1 pattern movement and projectiles, Phase 2 dash-slashes below 50% health, and Phase 3 sweeping desperation lasers below 20%. Each X-5 stage contains one Act-specific scene from `res://Characters/Bosses/Scenes`; its exit remains locked until `boss_defeated`, and the HUD binds to the boss health/phase signals when the arena activates.

The player camera has 5.0-speed position smoothing, facing-based look-ahead, and a lightweight shake API. Melee impacts trigger shake and a 0.05-second hit stop automatically. Explosion effects can trigger the same camera shake with `CombatFeedback.camera_shake(strength, duration)`.

After taking damage, the player hurtbox is disabled for one second while the sprite flashes. The movement collision remains enabled so i-frames cannot make the player fall through platforms.

The startup scene is `res://scenes/Level.tscn`. Canonical project asset roots are `res://Characters`, `res://Stages`, `res://Stage Props`, `res://Music`, `res://SFX`, `res://Parallax`, and `res://VFX`.

## Campaign asset registry

The `AssetRegistry` autoload resolves props, character textures, all 22 enemy scenes and animation libraries, all 20 campaign stages, OGG music, SFX, parallax textures, and VFX textures. Every campaign slot has a connected playable layout. Stages 1-1 and 2-1 retain their bespoke layouts; the other 18 use serialized multi-screen TileMap layouts generated from `PrototypeStage.tscn`.

Open `res://Characters/Enemies/EnemyCatalog.tscn` to browse all enemies. Open any `Stage.tscn` under an act folder to edit that level's painted terrain, props, checkpoints, hazards, enemies, VFX, lighting, and exit. Four collision-enabled atlas palettes are available under `res://Stages/TileSets`.

Rebuild generated editor assets after replacing source files:

```text
godot --headless --path . --script res://scripts/tools/EnemyLibraryBuilder.gd
godot --headless --path . --script res://scripts/tools/StageTileSetBuilder.gd
godot --headless --path . --script res://scripts/tools/CampaignPrototypeBuilder.gd
```

Run the registry validation with `godot --headless --path . --script res://scripts/AssetRegistrySmokeTest.gd`.

Run the full gameplay-system smoke test with `godot --headless --path . --script res://scripts/SystemsSmokeTest.gd`.

Run the boss, VFX, audio, X-5 gate, and boss-HUD validation with `godot --headless --path . --script res://scripts/BossSystemsSmokeTest.gd`.
