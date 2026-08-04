# Cyber City Platformer

Godot 4.7 project foundation for a neon cyberpunk action platformer.

## Controls

- Move: Left/Right arrows or gamepad left stick/D-pad
- Jump / wall jump: Space or the default `ui_accept` gamepad binding
- Melee: Z or gamepad Cross/A
- Shoot: X or gamepad Square/X
- Slide/dash input: C or gamepad Circle/B

Enemies that can be hit by `Bullet.tscn` should implement a `take_damage(amount)` method.

The complete source asset library is expected under `res://assets`, preserving its original category and folder structure. Assets are intentionally excluded from version control for now. The startup scene is `res://scenes/Level.tscn`.
