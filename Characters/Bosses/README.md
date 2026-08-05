# Playable stage bosses

`Scenes/` contains the four campaign boss definitions used by sub-stages 1-5,
2-5, 3-5, and 4-5. Each scene inherits `res://scenes/BossBase.tscn` and supplies
its own name, health, timing, animations, scale, and neon accent.

The bulk `SourceArt/` mirror remains behind its own `.gdignore` so Godot does
not import thousands of animation-construction frames. The playable scenes use
the project's imported, animation-complete character libraries and can be
retargeted to exported boss SpriteFrames through `animation_library` without
changing the encounter logic.
