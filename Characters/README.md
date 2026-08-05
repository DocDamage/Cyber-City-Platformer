# Characters

`Player` contains the playable fighter source. `Enemies` is the single shared enemy library used by every campaign act.

All 22 supplied packs are configured under `Enemies/SpriteFrames` and `Enemies/Scenes`: Centaur, Cerberus, Cyclops, Death Knight, Demon Boss, Flying Eye, Gargoyle, Goblin, Gryphon, Harpy, Headless Horseman, Imp, Medusa, Mimic, Minotaur, Poison Skull, Pyromancer, Satyr Archer, Skeleton Warrior, Stone Golem, Werewolf, and Witch.

Open `Enemies/EnemyCatalog.tscn` to preview them together. Drag an individual scene from `Enemies/Scenes` into a stage's `Enemies` node. Each scene exposes patrol speed, health, gravity/flying behavior, animation names, direction, and visual scale in the Inspector. The `.tres` files expose every supplied animation strip, including alternate attacks and projectile/arrow strips where present.

Run `godot --headless --path . --script res://scripts/tools/EnemyLibraryBuilder.gd` after changing the mirrored source packs. The builder intentionally selects the no-outline or without-outline version when a pack provides one.
