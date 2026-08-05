extends SceneTree

const SOURCE_ROOT := "res://Characters/Enemies/SourceArt"
const FRAMES_ROOT := "res://Characters/Enemies/SpriteFrames"
const SCENES_ROOT := "res://Characters/Enemies/Scenes"
const BASE_SCENE_PATH := "res://scenes/EnemyBase.tscn"
const CATALOG_SCENE_PATH := "res://Characters/Enemies/EnemyCatalog.tscn"
const INDEX_PATH := "res://Characters/Enemies/enemy_library.json"

const ENEMIES := [
	{"id": "centaur", "name": "Centaur", "pack": "Centaur 2D Pixel Art v1.2", "source": "New Version/Sprites/no_outline", "airborne": false},
	{"id": "cerberus", "name": "Cerberus", "pack": "Cerberus 2D Pixel Art v1.2", "source": "New Version/Sprites/no_outline", "airborne": false},
	{"id": "cyclops", "name": "Cyclops", "pack": "Cyclops 2D Pixel Art v1.2", "source": "New Version/Sprites/no_outline", "airborne": false},
	{"id": "death_knight", "name": "Death Knight", "pack": "death knight", "source": "", "airborne": false},
	{"id": "demon_boss", "name": "Demon Boss", "pack": "Demon Boss 2D Pixel Art", "source": "Sprites/without_outline", "airborne": true},
	{"id": "flying_eye", "name": "Flying Eye", "pack": "Flying Eye 2D Pixel Art", "source": "Sprites/without_outline", "airborne": true},
	{"id": "gargoyle", "name": "Gargoyle", "pack": "Gargoyle 2D Pixel Art v1.2", "source": "New Version/Sprites/no_outline", "airborne": true},
	{"id": "goblin", "name": "Goblin", "pack": "Goblin 2D Pixel Art v1.1", "source": "Sprites/without_outline", "airborne": false},
	{"id": "gryphon", "name": "Gryphon", "pack": "Gryphon 2D Pixel Art v1.2", "source": "NEW VERSION/Sprites/without_outline", "airborne": true},
	{"id": "harpy", "name": "Harpy", "pack": "Harpy 2D Pixel Art v1.2", "source": "New Version/Sprites/no_outline", "airborne": true},
	{"id": "headless_horseman", "name": "Headless Horseman", "pack": "Headless Horseman 2D Pixel Art", "source": "Sprites/without_outline", "airborne": false},
	{"id": "imp", "name": "Imp", "pack": "Imp 2D Pixel Art v1.2", "source": "Sprites/no_outline", "airborne": true},
	{"id": "medusa", "name": "Medusa", "pack": "Medusa V2.0", "source": "Sprite", "airborne": false},
	{"id": "mimic", "name": "Mimic", "pack": "Mimic 2D Pixel Art v1.2", "source": "New Version/Sprites/no_outline", "airborne": false},
	{"id": "minotaur", "name": "Minotaur", "pack": "Minotaur 2D Pixel Art v1.1", "source": "Sprites/without_outline", "airborne": false},
	{"id": "poison_skull", "name": "Poison Skull", "pack": "Poison Skull 2D Pixel Art v1.2", "source": "New Version/Sprites/no_outline", "airborne": true},
	{"id": "pyromancer", "name": "Pyromancer", "pack": "Pyromancer 2D Pixel Art", "source": "Sprites", "airborne": false},
	{"id": "satyr_archer", "name": "Satyr Archer", "pack": "Satyr Archer 2D Pixel Art v1.2", "source": "New Version/Sprites/no_outline", "airborne": false},
	{"id": "skeleton_warrior", "name": "Skeleton Warrior", "pack": "Skeleton Warrior  2D Pixel Art v1.1", "source": "Sprites/without_outline", "airborne": false},
	{"id": "stone_golem", "name": "Stone Golem", "pack": "Stone Golem 2D Pixel Art v1.2", "source": "new version/Sprites/without_outline", "airborne": false},
	{"id": "werewolf", "name": "Werewolf", "pack": "Werewolf 2D Pixel Art", "source": "Sprites/without_outline", "airborne": false},
	{"id": "witch", "name": "Witch", "pack": "Witch", "source": "Sprite", "airborne": true},
]


func _initialize() -> void:
	_build.call_deferred()


func _build() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(FRAMES_ROOT))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SCENES_ROOT))

	var built: Array[Dictionary] = []
	for enemy_value: Variant in ENEMIES:
		var enemy: Dictionary = enemy_value
		var entry := _build_enemy(enemy)
		if not entry.is_empty():
			built.append(entry)

	if built.size() != ENEMIES.size():
		push_error("Enemy library is incomplete: built %d of %d packs." % [built.size(), ENEMIES.size()])
		quit(1)
		return

	_build_catalog(built)
	_write_index(built)
	print("ENEMY_LIBRARY_BUILDER_OK enemies=", built.size())
	quit()


func _build_enemy(enemy: Dictionary) -> Dictionary:
	var source_dir := SOURCE_ROOT.path_join(String(enemy.pack))
	var source_subdir := String(enemy.source)
	if not source_subdir.is_empty():
		source_dir = source_dir.path_join(source_subdir)
	var directory := DirAccess.open(source_dir)
	if directory == null:
		push_error("Enemy source directory is missing: %s" % source_dir)
		return {}

	var files: Array[String] = []
	for file_name: String in directory.get_files():
		if file_name.get_extension().to_lower() == "png":
			files.append(file_name)
	files.sort_custom(_natural_less)
	if files.is_empty():
		push_error("Enemy source directory contains no PNG strips: %s" % source_dir)
		return {}

	var main_widths: Array[int] = []
	for file_name: String in files:
		var animation_name := _animation_name(file_name)
		if animation_name in [&"arrow", &"projectile"]:
			continue
		var texture := load(source_dir.path_join(file_name)) as Texture2D
		if texture != null:
			main_widths.append(texture.get_width())
	var frame_width := _greatest_common_divisor(main_widths)
	if frame_width <= 0:
		push_error("Could not derive a frame width for %s." % String(enemy.name))
		return {}

	var frames := SpriteFrames.new()
	frames.resource_name = "%s Animations" % String(enemy.name)
	frames.remove_animation(&"default")
	var animations: Array[String] = []
	var frame_height := 0
	for file_name: String in files:
		var texture := load(source_dir.path_join(file_name)) as Texture2D
		if texture == null:
			push_error("Could not load enemy strip: %s" % source_dir.path_join(file_name))
			continue
		var animation_name := _animation_name(file_name)
		var strip_frame_width := frame_width
		if animation_name in [&"arrow", &"projectile"] or texture.get_width() % frame_width != 0:
			strip_frame_width = texture.get_width()
		var frame_count := maxi(texture.get_width() / strip_frame_width, 1)
		frames.add_animation(animation_name)
		frames.set_animation_speed(animation_name, _animation_speed(animation_name))
		frames.set_animation_loop(animation_name, _animation_loops(animation_name))
		for frame_index in range(frame_count):
			var frame := AtlasTexture.new()
			frame.atlas = texture
			frame.region = Rect2(
				frame_index * strip_frame_width,
				0,
				strip_frame_width,
				texture.get_height()
			)
			frames.add_frame(animation_name, frame)
		animations.append(String(animation_name))
		if animation_name == &"idle" or frame_height == 0:
			frame_height = texture.get_height()

	var enemy_id := String(enemy.id)
	var frames_path := FRAMES_ROOT.path_join("%s.tres" % enemy_id)
	if ResourceSaver.save(frames, frames_path) != OK:
		push_error("Could not save SpriteFrames: %s" % frames_path)
		return {}

	var base_scene := load(BASE_SCENE_PATH) as PackedScene
	var instance := base_scene.instantiate() as EnemyBase
	instance.name = String(enemy.name)
	instance.enemy_id = StringName(enemy_id)
	instance.animation_library = load(frames_path) as SpriteFrames
	instance.uses_gravity = not bool(enemy.airborne)
	instance.movement_animation = _first_existing_animation(frames, [&"run", &"walk", &"move", &"flying", &"idle"])
	instance.death_animation = _first_existing_animation(frames, [&"death", &"hurt", &"idle"])
	instance.sprite_visual_scale = _recommended_scale(frame_height)
	var packed := PackedScene.new()
	if packed.pack(instance) != OK:
		push_error("Could not pack enemy scene: %s" % enemy_id)
		instance.free()
		return {}
	var scene_path := SCENES_ROOT.path_join("%s.tscn" % enemy_id)
	if ResourceSaver.save(packed, scene_path) != OK:
		push_error("Could not save enemy scene: %s" % scene_path)
		instance.free()
		return {}
	instance.free()

	return {
		"id": enemy_id,
		"name": String(enemy.name),
		"pack": String(enemy.pack),
		"source_directory": source_dir,
		"sprite_frames": frames_path,
		"scene": scene_path,
		"frame_width": frame_width,
		"frame_height": frame_height,
		"airborne": bool(enemy.airborne),
		"animations": animations,
	}


func _build_catalog(entries: Array[Dictionary]) -> void:
	var catalog := Node2D.new()
	catalog.name = "EnemyCatalog"
	var heading := Label.new()
	heading.name = "Instructions"
	heading.text = "All enemy packs - drag scenes from Characters/Enemies/Scenes into a stage"
	heading.position = Vector2(24.0, 18.0)
	heading.add_theme_font_size_override("font_size", 22)
	catalog.add_child(heading)
	heading.owner = catalog

	for index in range(entries.size()):
		var entry := entries[index]
		var scene := load(String(entry.scene)) as PackedScene
		var enemy := scene.instantiate() as EnemyBase
		enemy.name = String(entry.name)
		enemy.position = Vector2(130.0 + (index % 4) * 260.0, 150.0 + (index / 4) * 190.0)
		enemy.set_physics_process(false)
		catalog.add_child(enemy)
		enemy.owner = catalog
		var label := Label.new()
		label.name = "%sLabel" % String(entry.id).to_pascal_case()
		label.text = "%s\n%s" % [String(entry.name), String(entry.id)]
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.position = enemy.position + Vector2(-120.0, 72.0)
		label.size = Vector2(240.0, 52.0)
		catalog.add_child(label)
		label.owner = catalog

	var packed := PackedScene.new()
	if packed.pack(catalog) == OK:
		ResourceSaver.save(packed, CATALOG_SCENE_PATH)
	catalog.free()


func _write_index(entries: Array[Dictionary]) -> void:
	var file := FileAccess.open(INDEX_PATH, FileAccess.WRITE)
	if file == null:
		push_error("Could not write enemy index: %s" % INDEX_PATH)
		return
	file.store_string(JSON.stringify({"enemy_count": entries.size(), "enemies": entries}, "  "))


func _animation_name(file_name: String) -> StringName:
	var value := file_name.get_basename().strip_edges().to_snake_case().to_lower()
	while value.contains("__"):
		value = value.replace("__", "_")
	value = value.trim_prefix("_").trim_suffix("_")
	if value == "i_dle":
		value = "idle"
	return StringName(value)


func _animation_speed(animation_name: StringName) -> float:
	var name := String(animation_name)
	if "attack" in name or "swing" in name or "combo" in name:
		return 12.0
	if name == "death":
		return 14.0
	if name in ["hurt", "transition", "transformation", "appear"]:
		return 10.0
	return 8.0


func _animation_loops(animation_name: StringName) -> bool:
	var name := String(animation_name)
	for token in ["attack", "swing", "combo", "hurt", "death", "transition", "transformation", "appear"]:
		if token in name:
			return false
	return true


func _first_existing_animation(frames: SpriteFrames, candidates: Array[StringName]) -> StringName:
	for candidate: StringName in candidates:
		if frames.has_animation(candidate):
			return candidate
	return frames.get_animation_names()[0] if not frames.get_animation_names().is_empty() else &""


func _recommended_scale(frame_height: int) -> Vector2:
	if frame_height <= 0:
		return Vector2.ONE
	var scale_value := minf(1.0, 112.0 / float(frame_height))
	return Vector2(scale_value, scale_value)


func _greatest_common_divisor(values: Array[int]) -> int:
	var result := 0
	for value: int in values:
		result = value if result == 0 else _gcd(result, value)
	return result


func _gcd(left: int, right: int) -> int:
	var a := absi(left)
	var b := absi(right)
	while b != 0:
		var remainder := a % b
		a = b
		b = remainder
	return a


func _natural_less(left: String, right: String) -> bool:
	return left.naturalnocasecmp_to(right) < 0
