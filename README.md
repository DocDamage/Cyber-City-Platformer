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

`SoundManager` loops the included cyberpunk music and uses a positional `AudioStreamPlayer2D` pool for generated retro laser, melee, jump, dash, explosion, pickup, hurt, and checkpoint effects. Reusable GPU particle scenes under `res://scenes/vfx` provide impact sparks, movement dust, and enemy explosion smoke.

Combat uses reusable `Hitbox` and `Hurtbox` Area2D scripts. Player attacks use physics layer 3 and detect enemy hurtboxes on layer 4; enemy attacks use layer 5 and detect the player's hurtbox on layer 6. A hurtbox's parent should implement `take_damage(amount)` unless its `damage_receiver` path points elsewhere.

The player camera has 5.0-speed position smoothing, facing-based look-ahead, and a lightweight shake API. Melee impacts trigger shake and a 0.05-second hit stop automatically. Explosion effects can trigger the same camera shake with `CombatFeedback.camera_shake(strength, duration)`.

After taking damage, the player hurtbox is disabled for one second while the sprite flashes. The movement collision remains enabled so i-frames cannot make the player fall through platforms.

The complete source asset library is expected under `res://assets`, preserving its original category and folder structure. Assets are intentionally excluded from version control for now. The startup scene is `res://scenes/Level.tscn`.

Run the full gameplay-system smoke test with `godot --headless --path . --script res://scripts/SystemsSmokeTest.gd`.
