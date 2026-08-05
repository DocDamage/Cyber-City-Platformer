extends SceneTree

const MANIFEST_PATH := "res://Stages/campaign_manifest.json"
const BASE_SCENE_PATH := "res://Stages/PrototypeStage.tscn"
const ENEMY_SCENE_ROOT := "res://Characters/Enemies/Scenes"
const CHECKPOINT_SCENE_PATH := "res://scenes/CheckpointTerminal.tscn"
const STAGE_EXIT_SCENE_PATH := "res://scenes/StageExit.tscn"
const STAGE_LENGTH := 4800.0

const BOSS_SCENES := {
	"1-5": "res://Characters/Bosses/Scenes/act1_helix_warden.tscn",
	"2-5": "res://Characters/Bosses/Scenes/act2_assembly_colossus.tscn",
	"3-5": "res://Characters/Bosses/Scenes/act3_lunar_oracle.tscn",
	"4-5": "res://Characters/Bosses/Scenes/act4_void_cerberus.tscn",
}

const ACT_VISUALS := {
	1: {
		"far": "res://Parallax/SourceArt/Rooftops 2/back.png",
		"middle": "res://Parallax/SourceArt/Rooftops 2/middle.png",
		"front": "res://Parallax/SourceArt/Rooftops 2/front.png",
		"music": "res://Music/Library/Rooftops 2/cyberpunk city 2.ogg",
		"tile_set": "res://Stages/TileSets/Act1_Rooftops2_Palette.tres",
		"tint": Color(0.82, 0.9, 1.0),
	},
	2: {
		"far": "res://Parallax/SourceArt/Neon Alley/Assets/layers/back.png",
		"middle": "res://Parallax/SourceArt/Neon Alley/Assets/layers/middle.png",
		"front": "res://Parallax/SourceArt/Neon Alley/Assets/layers/front.png",
		"music": "res://Music/Library/Robot Factory/Mega Robot Factory – 2 .ogg",
		"tile_set": "res://Stages/TileSets/Act2_RobotFactory_Palette.tres",
		"tint": Color(0.92, 0.78, 1.0),
	},
	3: {
		"far": "res://Parallax/SourceArt/Moonlight City/Assets/layers/back.png",
		"middle": "res://Parallax/SourceArt/Moonlight City/Assets/layers/middle.png",
		"front": "res://Parallax/SourceArt/Moonlight City/Assets/layers/front.png",
		"music": "res://Music/Library/Street Beats/DavidKBD - Street Beat - System Glitch-essential-edition.ogg",
		"tile_set": "res://Stages/TileSets/Act3_NeonMoon_Palette.tres",
		"tint": Color(0.7, 0.86, 1.0),
	},
	4: {
		"far": "res://Stages/Act4_AbyssalNight/SourceArt/Abyssal Night/Abyssal Night – Color (2)/Backgroud/backgroud (1).png",
		"middle": "res://Stages/Act4_AbyssalNight/SourceArt/Abyssal Night/Abyssal Night – Color (2)/Backgroud/backgroud (2).png",
		"front": "res://Stages/Act4_AbyssalNight/SourceArt/Abyssal Night/Abyssal Night – Color (2)/Backgroud/backgroud (4).png",
		"music": "res://Music/Library/Boss Battles/Loops/Ogg/6. Dread Requiem (Loop).ogg",
		"tile_set": "res://Stages/TileSets/Act4_AbyssalNight_Palette.tres",
		"tint": Color(0.72, 0.55, 0.82),
	},
}

const ACT_PROPS := {
	1: [
		{"texture": "res://Stage Props/CyberCityProps/SourceArt/Rooftops 2/banner-a/banner-a1.png", "height": 76.0},
		{"texture": "res://Stage Props/CyberCityProps/SourceArt/Rooftops 2/banner-c/banner-c2.png", "height": 76.0},
		{"texture": "res://Stage Props/CyberCityProps/SourceArt/Rooftops 2/lights/lights2.png", "height": 82.0},
	],
	2: [
		{"texture": "res://Stage Props/FactoryProps/SourceArt/Mega Robot Factory/CENA COLOR (2)/TILESET/Tileset.png", "region": Rect2(0, 0, 160, 128), "height": 112.0},
		{"texture": "res://Stage Props/FactoryProps/SourceArt/Mega Robot Factory/CENA COLOR (2)/TILESET/Tileset.png", "region": Rect2(192, 0, 160, 128), "height": 112.0},
		{"texture": "res://Stage Props/FactoryProps/SourceArt/Mega Robot Factory/CENA COLOR (2)/TILESET/Tileset.png", "region": Rect2(160, 128, 160, 48), "height": 52.0},
	],
	3: [
		{"texture": "res://Stage Props/LunarProps/SourceArt/Space Props/space extra (125).png", "height": 62.0},
		{"texture": "res://Stage Props/LunarProps/SourceArt/Space Props/space extra (154).png", "height": 72.0},
		{"texture": "res://Stage Props/LunarProps/SourceArt/Neon Moon Portal/portal 96x96(1).png", "region": Rect2(0, 0, 96, 96), "height": 94.0},
	],
	4: [
		{"texture": "res://Stage Props/VoidProps/SourceArt/Abyssal Night/Abyssal Night – Color (2)/effect/effect 96x96 (3).png", "region": Rect2(0, 0, 96, 96), "height": 82.0},
		{"texture": "res://Stage Props/VoidProps/SourceArt/Abyssal Night/Abyssal Night – Color (2)/effect/effect 96x96 (3).png", "region": Rect2(192, 96, 96, 96), "height": 82.0},
		{"texture": "res://Stage Props/VoidProps/SourceArt/Abyssal Night/Abyssal Night – Color (2)/effect/effect 96x96 (3).png", "region": Rect2(384, 192, 96, 96), "height": 76.0},
	],
}

const STAGE_ENEMIES := {
	"1-2": ["centaur", "harpy"],
	"1-3": ["gargoyle", "gryphon"],
	"1-4": ["goblin"],
	"1-5": ["demon_boss"],
	"2-2": ["cyclops"],
	"2-3": ["stone_golem"],
	"2-4": ["pyromancer"],
	"2-5": ["minotaur"],
	"3-1": ["flying_eye"],
	"3-2": ["witch"],
	"3-3": ["satyr_archer"],
	"3-4": ["imp"],
	"3-5": ["medusa"],
	"4-1": ["skeleton_warrior"],
	"4-2": ["poison_skull"],
	"4-3": ["mimic"],
	"4-4": ["death_knight"],
	"4-5": ["cerberus", "headless_horseman", "werewolf"],
}


func _initialize() -> void:
	_build.call_deferred()


func _build() -> void:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST_PATH))
	if parsed is not Dictionary:
		push_error("Campaign manifest is invalid: %s" % MANIFEST_PATH)
		quit(1)
		return
	var manifest: Dictionary = parsed
	var built_count := 0
	var used_enemy_ids: Array[String] = []
	var acts: Array = manifest.get("acts", [])
	for act_value: Variant in acts:
		var act: Dictionary = act_value
		var act_number := int(act.get("number", 0))
		var stages: Array = act.get("stages", [])
		for stage_value: Variant in stages:
			var stage: Dictionary = stage_value
			if String(stage.get("id", "")) in ["1-1", "2-1"]:
				continue
			var next_scene_path := _get_next_scene_path(manifest, act_number, int(stage.get("number", 0)))
			if _build_stage(act_number, stage, used_enemy_ids, next_scene_path):
				stage["status"] = "boss-ready" if int(stage.get("number", 0)) == 5 else "layout"
				built_count += 1

	if built_count != 18:
		push_error("Expected 18 constructed layouts, built %d." % built_count)
		quit(1)
		return
	if used_enemy_ids.size() != 22:
		push_error("Expected all 22 enemy packs in stage layouts, used %d." % used_enemy_ids.size())
		quit(1)
		return

	var manifest_file := FileAccess.open(MANIFEST_PATH, FileAccess.WRITE)
	manifest_file.store_string(JSON.stringify(manifest, "  "))
	print("CAMPAIGN_LAYOUT_BUILDER_OK layouts=", built_count, " enemies=", used_enemy_ids.size())
	quit()


func _build_stage(
		act_number: int,
		stage: Dictionary,
		used_enemy_ids: Array[String],
		next_scene_path: String
) -> bool:
	var base_scene := load(BASE_SCENE_PATH) as PackedScene
	if base_scene == null:
		push_error("Prototype base scene is missing: %s" % BASE_SCENE_PATH)
		return false
	var root := base_scene.instantiate() as Node2D
	var stage_id := String(stage.get("id", ""))
	var stage_number := int(stage.get("number", 1))
	root.name = String(stage.get("slug", stage_id))
	root.set("campaign_act", act_number)
	root.set("stage_id", StringName(stage_id))
	root.set("stage_title", String(stage.get("name", "Unnamed Stage")))
	root.set("design_notes", "Layout pass: %s\nPainted terrain, themed props, two checkpoints, and a connected exit are ready for encounter polish." % ", ".join(stage.get("assets", [])))

	var visuals: Dictionary = ACT_VISUALS[act_number]
	root.set("far_background", load(String(visuals.far)) as Texture2D)
	root.set("middle_background", load(String(visuals.middle)) as Texture2D)
	root.set("front_background", load(String(visuals.front)) as Texture2D)
	root.set("music_path", String(visuals.music))
	root.set("background_tint", visuals.tint)
	root.call(&"_apply_editor_metadata")
	root.call(&"_apply_backgrounds")
	_expand_backgrounds(root)

	var terrain := root.get_node_or_null("Terrain") as TileMapLayer
	var tile_set := load(String(visuals.tile_set)) as TileSet
	if terrain == null or tile_set == null:
		push_error("Stage %s is missing its terrain TileSet." % stage_id)
		root.free()
		return false
	terrain.tile_set = tile_set
	_remove_blockout(root)
	_paint_layout(terrain, act_number, stage_number)
	var ground_top := _ground_top(tile_set)
	_place_props(root, act_number, stage_number, ground_top)
	_place_enemies(root, stage_id, stage_number, ground_top, used_enemy_ids)
	_place_gameplay_markers(root, stage_id, ground_top, next_scene_path)

	var scene_path := String(stage.get("scene", ""))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(scene_path.get_base_dir()))
	var packed := PackedScene.new()
	if packed.pack(root) != OK:
		push_error("Could not pack stage layout: %s" % stage_id)
		root.free()
		return false
	var error := ResourceSaver.save(packed, scene_path)
	root.free()
	if error != OK:
		push_error("Could not save stage layout: %s" % scene_path)
		return false
	return true


func _paint_layout(terrain: TileMapLayer, act_number: int, stage_number: int) -> void:
	terrain.clear()
	var tile_set := terrain.tile_set
	var atlas := tile_set.get_source(0) as TileSetAtlasSource
	if atlas == null or atlas.get_tiles_count() == 0:
		return
	var tile_size := tile_set.tile_size
	var floor_y := roundi(480.0 / tile_size.y)
	var stage_cells := ceili(STAGE_LENGTH / tile_size.x)
	var seed := act_number * 37 + stage_number * 53
	var top_tile := atlas.get_tile_id(seed % atlas.get_tiles_count())
	var fill_tile := atlas.get_tile_id((seed + 11) % atlas.get_tiles_count())
	var accent_tile := atlas.get_tile_id((seed + 29) % atlas.get_tiles_count())
	var gap_width := maxi(2, ceili(56.0 / tile_size.x))
	var gaps: Array[Vector2i] = []
	for gap_index in range(3):
		var center_px := 1120.0 + gap_index * 1300.0 + float((seed + gap_index * 71) % 181 - 90)
		var start_cell := roundi(center_px / tile_size.x) - gap_width / 2
		gaps.append(Vector2i(start_cell, start_cell + gap_width))

	for x in range(-4, stage_cells + 5):
		if _is_in_gap(x, gaps):
			continue
		terrain.set_cell(Vector2i(x, floor_y), 0, top_tile)
		terrain.set_cell(Vector2i(x, floor_y + 1), 0, fill_tile)

	var lift_rows := maxi(1, roundi(40.0 / tile_size.y))
	for platform_index in range(8):
		var start_px := 500.0 + platform_index * 520.0 + float((seed + platform_index * 43) % 121 - 60)
		var start_x := roundi(start_px / tile_size.x)
		var width := maxi(4, roundi((120.0 + float((seed + platform_index * 17) % 65)) / tile_size.x))
		var platform_y := floor_y - lift_rows
		if platform_index % 3 == 1:
			platform_y -= maxi(1, roundi(24.0 / tile_size.y))
		for x in range(start_x, start_x + width):
			terrain.set_cell(Vector2i(x, platform_y), 0, accent_tile)

	for gap: Vector2i in gaps:
		var bridge_y := floor_y - lift_rows
		for x in range(gap.x - 1, gap.y + 1):
			terrain.set_cell(Vector2i(x, bridge_y), 0, accent_tile)


func _place_props(root: Node2D, act_number: int, stage_number: int, ground_top: float) -> void:
	var props_parent := root.get_node_or_null("Props") as Node2D
	if props_parent == null:
		return
	var prop_defs: Array = ACT_PROPS.get(act_number, [])
	for prop_index in range(7):
		var definition: Dictionary = prop_defs[(prop_index + stage_number) % prop_defs.size()]
		var texture := load(String(definition.texture)) as Texture2D
		if texture == null:
			continue
		var sprite := Sprite2D.new()
		sprite.name = "ThemedProp%02d" % (prop_index + 1)
		sprite.texture = texture
		var visual_size := texture.get_size()
		var region: Rect2 = definition.get("region", Rect2())
		if region.size != Vector2.ZERO:
			sprite.region_enabled = true
			sprite.region_rect = region
			visual_size = region.size
		var target_height := float(definition.get("height", 72.0))
		var visual_scale := target_height / maxf(visual_size.y, 1.0)
		sprite.scale = Vector2(visual_scale, visual_scale)
		sprite.position = Vector2(
			560.0 + prop_index * 610.0 + float((stage_number * 47 + prop_index * 31) % 91 - 45),
			ground_top - target_height * 0.5
		)
		sprite.z_index = 1
		props_parent.add_child(sprite)
		sprite.owner = root


func _place_enemies(
		root: Node2D,
		stage_id: String,
		stage_number: int,
		ground_top: float,
		used_enemy_ids: Array[String]
) -> void:
	var enemy_parent := root.get_node_or_null("Enemies") as Node2D
	var enemy_ids: Array = STAGE_ENEMIES.get(stage_id, [])
	if BOSS_SCENES.has(stage_id):
		var boss_scene := load(String(BOSS_SCENES[stage_id])) as PackedScene
		if boss_scene == null:
			push_error("Boss scene is missing: %s" % BOSS_SCENES[stage_id])
			return
		var boss := boss_scene.instantiate() as BossBase
		boss.name = boss.boss_name.to_pascal_case().replace(" ", "")
		boss.position = Vector2(STAGE_LENGTH - 680.0, ground_top - 38.0)
		enemy_parent.add_child(boss)
		boss.owner = root
		for enemy_id_value: Variant in enemy_ids:
			used_enemy_ids.append(String(enemy_id_value))
		return
	for enemy_index in range(enemy_ids.size()):
		var enemy_id := String(enemy_ids[enemy_index])
		var enemy_scene_path := ENEMY_SCENE_ROOT.path_join("%s.tscn" % enemy_id)
		var enemy_scene := load(enemy_scene_path) as PackedScene
		if enemy_scene == null:
			push_error("Enemy scene is missing: %s" % enemy_scene_path)
			continue
		var enemy := enemy_scene.instantiate() as EnemyBase
		enemy.name = enemy_id.to_pascal_case()
		enemy.position = Vector2(
			1180.0 + enemy_index * 1320.0 + stage_number * 45.0,
			ground_top - (130.0 if not enemy.uses_gravity else 36.0)
		)
		enemy.starting_direction = 1 if enemy_index % 2 == 0 else -1
		enemy_parent.add_child(enemy)
		enemy.owner = root
		used_enemy_ids.append(enemy_id)


func _place_gameplay_markers(
		root: Node2D,
		stage_id: String,
		ground_top: float,
		next_scene_path: String
) -> void:
	var marker_parent := root.get_node_or_null("Markers") as Node2D
	var checkpoint_parent := root.get_node_or_null("Markers/Checkpoints") as Node2D
	var checkpoint_scene := load(CHECKPOINT_SCENE_PATH) as PackedScene
	for checkpoint_index in range(2):
		var checkpoint := checkpoint_scene.instantiate() as CheckpointTerminal
		checkpoint.name = "Checkpoint%02d" % (checkpoint_index + 1)
		checkpoint.checkpoint_id = StringName("%s_checkpoint_%02d" % [stage_id, checkpoint_index + 1])
		checkpoint.position = Vector2(1600.0 + checkpoint_index * 1600.0, ground_top - 34.0)
		checkpoint_parent.add_child(checkpoint)
		checkpoint.owner = root

	var exit_marker := root.get_node_or_null("Markers/Exit") as Marker2D
	if exit_marker != null:
		exit_marker.position = Vector2(STAGE_LENGTH - 150.0, ground_top - 58.0)
	var exit_scene := load(STAGE_EXIT_SCENE_PATH) as PackedScene
	var stage_exit := exit_scene.instantiate() as StageExit
	stage_exit.name = "StageExit"
	stage_exit.next_scene_path = next_scene_path
	stage_exit.position = Vector2(STAGE_LENGTH - 150.0, ground_top - 58.0)
	marker_parent.add_child(stage_exit)
	stage_exit.owner = root

	var player_spawn := root.get_node_or_null("Markers/PlayerSpawn") as Marker2D
	var player := root.get_node_or_null("Player") as Node2D
	var spawn_position := Vector2(140.0, ground_top - 46.0)
	if player_spawn != null:
		player_spawn.position = spawn_position
	if player != null:
		player.position = spawn_position

	var death_zone := root.get_node_or_null("DeathZone") as Area2D
	var death_shape := root.get_node_or_null("DeathZone/CollisionShape2D") as CollisionShape2D
	if death_zone != null:
		death_zone.position = Vector2(STAGE_LENGTH * 0.5, ground_top + 220.0)
	if death_shape != null and death_shape.shape is RectangleShape2D:
		var rectangle := death_shape.shape.duplicate() as RectangleShape2D
		rectangle.size = Vector2(STAGE_LENGTH + 700.0, 140.0)
		death_shape.shape = rectangle


func _expand_backgrounds(root: Node2D) -> void:
	for path in ["Background/Far", "Background/Middle", "Background/Front"]:
		var layer := root.get_node_or_null(path) as Parallax2D
		if layer != null:
			layer.repeat_times = 6


func _remove_blockout(root: Node2D) -> void:
	var blockout := root.get_node_or_null("Blockout")
	if blockout != null:
		blockout.free()


func _ground_top(tile_set: TileSet) -> float:
	var tile_size := tile_set.tile_size
	var floor_y := roundi(480.0 / tile_size.y)
	return floor_y * tile_size.y - tile_size.y * 0.5


func _is_in_gap(x: int, gaps: Array[Vector2i]) -> bool:
	for gap: Vector2i in gaps:
		if x >= gap.x and x < gap.y:
			return true
	return false


func _get_next_scene_path(manifest: Dictionary, act_number: int, stage_number: int) -> String:
	var next_act := act_number
	var next_stage := stage_number + 1
	if next_stage > 5:
		next_act += 1
		next_stage = 1
	for act_value: Variant in manifest.get("acts", []):
		var act: Dictionary = act_value
		if int(act.get("number", 0)) != next_act:
			continue
		for stage_value: Variant in act.get("stages", []):
			var stage: Dictionary = stage_value
			if int(stage.get("number", 0)) == next_stage:
				return String(stage.get("scene", ""))
	return ""
