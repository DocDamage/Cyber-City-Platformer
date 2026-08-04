extends SceneTree

const MANIFEST_PATH := "res://Stages/campaign_manifest.json"
const BASE_SCENE_PATH := "res://Stages/PrototypeStage.tscn"
const ENEMY_SCENE_ROOT := "res://Characters/Enemies/Scenes"

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
			if _build_stage(act_number, stage, used_enemy_ids):
				stage["status"] = "prototype"
				built_count += 1

	if built_count != 18:
		push_error("Expected 18 editable prototypes, built %d." % built_count)
		quit(1)
		return
	if used_enemy_ids.size() != 22:
		push_error("Expected all 22 enemy packs in stage prototypes, used %d." % used_enemy_ids.size())
		quit(1)
		return

	var manifest_file := FileAccess.open(MANIFEST_PATH, FileAccess.WRITE)
	manifest_file.store_string(JSON.stringify(manifest, "  "))
	print("CAMPAIGN_PROTOTYPE_BUILDER_OK prototypes=", built_count, " enemies=", used_enemy_ids.size())
	quit()


func _build_stage(act_number: int, stage: Dictionary, used_enemy_ids: Array[String]) -> bool:
	var base_scene := load(BASE_SCENE_PATH) as PackedScene
	if base_scene == null:
		push_error("Prototype base scene is missing: %s" % BASE_SCENE_PATH)
		return false
	var root := base_scene.instantiate() as Node2D
	var stage_id := String(stage.get("id", ""))
	root.name = String(stage.get("slug", stage_id))
	root.set("campaign_act", act_number)
	root.set("stage_id", StringName(stage_id))
	root.set("stage_title", String(stage.get("name", "Unnamed Stage")))
	root.set("design_notes", "Prototype goals: %s\nReplace blockout pieces as the stage design develops." % ", ".join(stage.get("assets", [])))

	var visuals: Dictionary = ACT_VISUALS[act_number]
	root.set("far_background", load(String(visuals.far)) as Texture2D)
	root.set("middle_background", load(String(visuals.middle)) as Texture2D)
	root.set("front_background", load(String(visuals.front)) as Texture2D)
	root.set("music_path", String(visuals.music))
	root.set("background_tint", visuals.tint)
	root.call(&"_apply_editor_metadata")
	root.call(&"_apply_backgrounds")

	var tile_set_path := String(visuals.tile_set)
	if not tile_set_path.is_empty():
		var terrain := root.get_node_or_null("Terrain") as TileMapLayer
		if terrain != null:
			terrain.tile_set = load(tile_set_path) as TileSet

	var enemy_parent := root.get_node_or_null("Enemies") as Node2D
	var enemy_ids: Array = STAGE_ENEMIES.get(stage_id, [])
	for enemy_index in range(enemy_ids.size()):
		var enemy_id := String(enemy_ids[enemy_index])
		var enemy_scene_path := ENEMY_SCENE_ROOT.path_join("%s.tscn" % enemy_id)
		var enemy_scene := load(enemy_scene_path) as PackedScene
		if enemy_scene == null:
			push_error("Enemy scene is missing: %s" % enemy_scene_path)
			root.free()
			return false
		var enemy := enemy_scene.instantiate() as EnemyBase
		enemy.name = enemy_id.to_pascal_case()
		enemy.position = Vector2(560.0 + enemy_index * 320.0, 330.0 if not enemy.uses_gravity else 452.0)
		enemy.starting_direction = 1 if enemy_index % 2 == 0 else -1
		enemy_parent.add_child(enemy)
		enemy.owner = root
		used_enemy_ids.append(enemy_id)

	var scene_path := String(stage.get("scene", ""))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(scene_path.get_base_dir()))
	var packed := PackedScene.new()
	if packed.pack(root) != OK:
		push_error("Could not pack stage prototype: %s" % stage_id)
		root.free()
		return false
	var error := ResourceSaver.save(packed, scene_path)
	root.free()
	if error != OK:
		push_error("Could not save stage prototype: %s" % scene_path)
		return false
	return true
